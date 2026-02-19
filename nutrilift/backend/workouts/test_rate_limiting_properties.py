"""
Property-Based Tests for Rate Limiting

Tests Property 35: Rate Limiting
For any user making excessive API requests (more than configured threshold),
the system should throttle requests and return a 429 Too Many Requests status.

Requirements: 12.10
"""
from django.test import TestCase, override_settings
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from rest_framework.test import APIClient
from rest_framework import status
from hypothesis import given, strategies as st, settings, HealthCheck
from hypothesis.extra.django import TestCase as HypothesisTestCase
import jwt
from django.conf import settings as django_settings

from workouts.models import Exercise, WorkoutLog, WorkoutExercise, PersonalRecord


User = get_user_model()


# Override throttle rates for testing to make tests faster
TEST_THROTTLE_RATES = {
    'workout_user': '5/minute',   # Low limit for testing
    'workout_anon': '2/minute',   # Very low limit for anonymous
    'exercise_user': '10/minute', # Low limit for testing
    'exercise_anon': '3/minute',  # Very low limit for anonymous
    'pr_user': '5/minute',        # Low limit for testing
}


@override_settings(
    REST_FRAMEWORK={
        'DEFAULT_AUTHENTICATION_CLASSES': [
            'authentications.authentication.JWTAuthentication',
        ],
        'DEFAULT_PERMISSION_CLASSES': [
            'rest_framework.permissions.IsAuthenticated',
        ],
        'DEFAULT_RENDERER_CLASSES': [
            'rest_framework.renderers.JSONRenderer',
        ],
        'DEFAULT_PARSER_CLASSES': [
            'rest_framework.parsers.JSONParser',
        ],
        'EXCEPTION_HANDLER': 'authentications.exceptions.custom_exception_handler',
        'DEFAULT_THROTTLE_RATES': TEST_THROTTLE_RATES,
    },
    CACHES={
        'default': {
            'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
            'LOCATION': 'test-throttle-cache',
        }
    }
)
class TestRateLimitingProperties(HypothesisTestCase):
    """
    Property-based tests for rate limiting functionality.
    
    Feature: workout-tracking-system
    Property 35: Rate Limiting
    """
    
    def setUp(self):
        """Set up test fixtures."""
        # Clear cache before each test
        from django.core.cache import cache
        cache.clear()
        
        # Delete any existing test users to avoid unique constraint violations
        User.objects.filter(email__startswith='test').delete()
        
        # Create test user (using email, not username)
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        # Create test exercise
        self.exercise = Exercise.objects.create(
            name='Test Exercise',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions'
        )
        
        # Create API client
        self.client = APIClient()
    
    def tearDown(self):
        """Clean up after each test."""
        from django.core.cache import cache
        cache.clear()
    
    def _get_auth_token(self):
        """Helper to get authentication token."""
        payload = {
            'user_id': str(self.user.id),
            'email': self.user.email,
            'exp': timezone.now() + timedelta(hours=24)
        }
        token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
        return token
    
    @settings(
        max_examples=10,
        deadline=None,
        suppress_health_check=[HealthCheck.too_slow, HealthCheck.function_scoped_fixture]
    )
    @given(
        num_requests=st.integers(min_value=6, max_value=15)
    )
    def test_property_35_workout_endpoint_rate_limiting(self, num_requests):
        """
        Feature: workout-tracking-system, Property 35: Rate Limiting
        
        For any user making excessive API requests to workout endpoints
        (more than 5 per minute in test configuration),
        the system should throttle requests and return a 429 Too Many Requests status.
        
        Validates: Requirements 12.10
        """
        # Authenticate
        token = self._get_auth_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Make requests up to the limit
        throttled = False
        responses = []
        
        for i in range(num_requests):
            response = self.client.get('/api/workouts/logs/get_history/')
            responses.append(response.status_code)
            
            if response.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
                throttled = True
                break
        
        # Property: If we made more than 5 requests, at least one should be throttled
        if num_requests > 5:
            self.assertTrue(
                throttled,
                f"Expected throttling after 5 requests, but made {num_requests} requests without throttling. "
                f"Response codes: {responses}"
            )
            # Verify the throttled response has the correct status code
            self.assertEqual(responses[-1], status.HTTP_429_TOO_MANY_REQUESTS)
        else:
            # If we made 5 or fewer requests, none should be throttled
            self.assertFalse(
                throttled,
                f"Unexpected throttling with only {num_requests} requests. Response codes: {responses}"
            )
    
    @settings(
        max_examples=10,
        deadline=None,
        suppress_health_check=[HealthCheck.too_slow, HealthCheck.function_scoped_fixture]
    )
    @given(
        num_requests=st.integers(min_value=11, max_value=20)
    )
    def test_property_35_exercise_endpoint_rate_limiting(self, num_requests):
        """
        Feature: workout-tracking-system, Property 35: Rate Limiting
        
        For any user making excessive API requests to exercise endpoints
        (more than 10 per minute in test configuration),
        the system should throttle requests and return a 429 Too Many Requests status.
        
        Validates: Requirements 12.10
        """
        # Authenticate
        token = self._get_auth_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Make requests up to the limit
        throttled = False
        responses = []
        
        for i in range(num_requests):
            response = self.client.get('/api/exercises/')
            responses.append(response.status_code)
            
            if response.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
                throttled = True
                break
        
        # Property: If we made more than 10 requests, at least one should be throttled
        if num_requests > 10:
            self.assertTrue(
                throttled,
                f"Expected throttling after 10 requests, but made {num_requests} requests without throttling. "
                f"Response codes: {responses}"
            )
            # Verify the throttled response has the correct status code
            self.assertEqual(responses[-1], status.HTTP_429_TOO_MANY_REQUESTS)
        else:
            # If we made 10 or fewer requests, none should be throttled
            self.assertFalse(
                throttled,
                f"Unexpected throttling with only {num_requests} requests. Response codes: {responses}"
            )
    
    @settings(
        max_examples=10,
        deadline=None,
        suppress_health_check=[HealthCheck.too_slow, HealthCheck.function_scoped_fixture]
    )
    @given(
        num_requests=st.integers(min_value=6, max_value=15)
    )
    def test_property_35_personal_record_endpoint_rate_limiting(self, num_requests):
        """
        Feature: workout-tracking-system, Property 35: Rate Limiting
        
        For any user making excessive API requests to personal record endpoints
        (more than 5 per minute in test configuration),
        the system should throttle requests and return a 429 Too Many Requests status.
        
        Validates: Requirements 12.10
        """
        # Authenticate
        token = self._get_auth_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Make requests up to the limit
        throttled = False
        responses = []
        
        for i in range(num_requests):
            response = self.client.get('/api/personal-records/')
            responses.append(response.status_code)
            
            if response.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
                throttled = True
                break
        
        # Property: If we made more than 5 requests, at least one should be throttled
        if num_requests > 5:
            self.assertTrue(
                throttled,
                f"Expected throttling after 5 requests, but made {num_requests} requests without throttling. "
                f"Response codes: {responses}"
            )
            # Verify the throttled response has the correct status code
            self.assertEqual(responses[-1], status.HTTP_429_TOO_MANY_REQUESTS)
        else:
            # If we made 5 or fewer requests, none should be throttled
            self.assertFalse(
                throttled,
                f"Unexpected throttling with only {num_requests} requests. Response codes: {responses}"
            )
    
    def test_property_35_rate_limit_per_user(self):
        """
        Feature: workout-tracking-system, Property 35: Rate Limiting
        
        Rate limits should be applied per user, not globally.
        Different users should have independent rate limit counters.
        
        Validates: Requirements 12.10
        """
        # Create second user (using email, not username)
        user2 = User.objects.create_user(
            email='test2@example.com',
            password='testpass123'
        )
        
        # Get tokens for both users
        token1 = self._get_auth_token()
        payload2 = {
            'user_id': str(user2.id),
            'email': user2.email,
            'exp': timezone.now() + timedelta(hours=24)
        }
        token2 = jwt.encode(payload2, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
        
        # User 1 makes requests up to limit
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token1}')
        for i in range(5):
            response = self.client.get('/api/workouts/logs/get_history/')
            self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # User 1's next request should be throttled
        response = self.client.get('/api/workouts/logs/get_history/')
        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        
        # User 2 should still be able to make requests (independent rate limit)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token2}')
        response = self.client.get('/api/workouts/logs/get_history/')
        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
            "User 2 should have independent rate limit from User 1"
        )
    
    def test_property_35_rate_limit_response_format(self):
        """
        Feature: workout-tracking-system, Property 35: Rate Limiting
        
        When rate limit is exceeded, the response should be 429 Too Many Requests.
        The response may include retry-after information.
        
        Validates: Requirements 12.10
        """
        # Authenticate
        token = self._get_auth_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Make requests up to and beyond the limit
        for i in range(6):
            response = self.client.get('/api/workouts/logs/get_history/')
        
        # The last response should be throttled
        self.assertEqual(
            response.status_code,
            status.HTTP_429_TOO_MANY_REQUESTS,
            "Expected 429 status code when rate limit exceeded"
        )
        
        # Check if response contains throttle information
        # DRF throttling may include detail message
        if hasattr(response, 'data'):
            self.assertIsNotNone(response.data)


# Unit tests for specific rate limiting scenarios
class TestRateLimitingUnit(TestCase):
    """
    Unit tests for rate limiting edge cases and specific scenarios.
    """
    
    def setUp(self):
        """Set up test fixtures."""
        from django.core.cache import cache
        cache.clear()
        
        # Delete any existing test users to avoid unique constraint violations
        User.objects.filter(email__startswith='test').delete()
        
        # Create test user (using email, not username)
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.exercise = Exercise.objects.create(
            name='Test Exercise',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions'
        )
        
        self.client = APIClient()
    
    def tearDown(self):
        """Clean up after each test."""
        from django.core.cache import cache
        cache.clear()
    
    def _get_auth_token(self):
        """Helper to get authentication token."""
        payload = {
            'user_id': str(self.user.id),
            'email': self.user.email,
            'exp': timezone.now() + timedelta(hours=24)
        }
        token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
        return token
    
    @override_settings(
        REST_FRAMEWORK={
            'DEFAULT_AUTHENTICATION_CLASSES': [
                'authentications.authentication.JWTAuthentication',
            ],
            'DEFAULT_PERMISSION_CLASSES': [
                'rest_framework.permissions.IsAuthenticated',
            ],
            'DEFAULT_RENDERER_CLASSES': [
                'rest_framework.renderers.JSONRenderer',
            ],
            'DEFAULT_PARSER_CLASSES': [
                'rest_framework.parsers.JSONParser',
            ],
            'EXCEPTION_HANDLER': 'authentications.exceptions.custom_exception_handler',
            'DEFAULT_THROTTLE_RATES': TEST_THROTTLE_RATES,
        },
        CACHES={
            'default': {
                'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
                'LOCATION': 'test-throttle-cache',
            }
        }
    )
    def test_rate_limit_different_endpoints_independent(self):
        """
        Test that rate limits are independent across different endpoints.
        Exhausting the limit on one endpoint should not affect others.
        """
        token = self._get_auth_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Exhaust workout endpoint limit (5 requests)
        for i in range(5):
            response = self.client.get('/api/workouts/logs/get_history/')
            self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Workout endpoint should now be throttled
        response = self.client.get('/api/workouts/logs/get_history/')
        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        
        # Exercise endpoint should still work (independent limit of 10)
        response = self.client.get('/api/exercises/')
        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
            "Exercise endpoint should have independent rate limit"
        )
    
    @override_settings(
        REST_FRAMEWORK={
            'DEFAULT_AUTHENTICATION_CLASSES': [
                'authentications.authentication.JWTAuthentication',
            ],
            'DEFAULT_PERMISSION_CLASSES': [
                'rest_framework.permissions.IsAuthenticated',
            ],
            'DEFAULT_RENDERER_CLASSES': [
                'rest_framework.renderers.JSONRenderer',
            ],
            'DEFAULT_PARSER_CLASSES': [
                'rest_framework.parsers.JSONParser',
            ],
            'EXCEPTION_HANDLER': 'authentications.exceptions.custom_exception_handler',
            'DEFAULT_THROTTLE_RATES': TEST_THROTTLE_RATES,
        },
        CACHES={
            'default': {
                'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
                'LOCATION': 'test-throttle-cache',
            }
        }
    )
    def test_rate_limit_applies_to_all_methods(self):
        """
        Test that rate limiting applies to all HTTP methods (GET, POST, etc.).
        """
        token = self._get_auth_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Mix of GET and POST requests should count toward the same limit
        responses = []
        
        # Make 3 GET requests
        for i in range(3):
            response = self.client.get('/api/workouts/logs/get_history/')
            responses.append(response.status_code)
        
        # Make 2 POST requests (with minimal valid data)
        for i in range(2):
            response = self.client.post('/api/workouts/logs/log_workout/', {
                'duration_minutes': 60,
                'calories_burned': 400,
                'workout_exercises': []
            }, format='json')
            responses.append(response.status_code)
        
        # Next request should be throttled (total 5 requests made)
        response = self.client.get('/api/workouts/logs/get_history/')
        
        self.assertEqual(
            response.status_code,
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"Expected throttling after 5 mixed GET/POST requests. Response codes: {responses}"
        )
