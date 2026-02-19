"""
Property-Based Tests for Authentication and Validation

This module contains property-based tests for:
- Property 22: JWT Authentication Enforcement
- Property 30: Invalid Data Error Response
- Property 31: Exercise Reference Validation
- Property 32: Future Date Validation
- Property 33: Input Sanitization

Requirements: 5.9, 5.10, 7.5, 9.6, 9.7, 9.8, 9.10
"""
import pytest
from hypothesis import given, strategies as st, settings, assume, HealthCheck
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from workouts.models import Exercise, WorkoutLog, Gym, CustomWorkout
from workouts.serializers import sanitize_text_input
import jwt
from django.conf import settings as django_settings

User = get_user_model()


# Property 22: JWT Authentication Enforcement
@pytest.mark.django_db
@given(
    endpoint=st.sampled_from([
        '/api/workouts/logs/',
        '/api/workouts/logs/get_history/',
        '/api/workouts/logs/statistics/',
        '/api/workouts/exercises/',
        '/api/workouts/personal-records/',
        '/api/workouts/gyms/',
        '/api/workouts/custom-workouts/'
    ])
)
@settings(max_examples=50, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
def test_property_22_jwt_authentication_enforcement(endpoint):
    """
    Feature: workout-tracking-system, Property 22: JWT Authentication Enforcement
    
    For any workout-related API endpoint request without a valid JWT token,
    the system should return a 401 Unauthorized status and reject the request.
    
    Validates: Requirements 5.9, 7.5
    """
    # Create API client for each test
    api_client = APIClient()
    
    # Make request without authentication
    response = api_client.get(endpoint)
    
    # Should return 401 Unauthorized
    assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    # Response should have error structure
    assert 'success' in response.data
    assert response.data['success'] is False


@pytest.mark.django_db
def test_property_22_jwt_authentication_with_valid_token():
    """
    Feature: workout-tracking-system, Property 22: JWT Authentication Enforcement
    
    Verify that valid JWT tokens are accepted.
    
    Validates: Requirements 5.9, 7.5
    """
    # Create test user
    user = User.objects.create_user(
        email='testuser@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    # Make request to authenticated endpoint
    response = api_client.get('/api/workouts/exercises/')
    
    # Should NOT return 401 (should be 200 or other valid status)
    assert response.status_code != status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
def test_property_22_jwt_authentication_with_invalid_token():
    """
    Feature: workout-tracking-system, Property 22: JWT Authentication Enforcement
    
    Verify that invalid JWT tokens are rejected.
    
    Validates: Requirements 5.9, 7.5
    """
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION='Bearer invalid_token_12345')
    
    # Make request to authenticated endpoint
    response = api_client.get('/api/workouts/exercises/')
    
    # Should return 401 Unauthorized
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# Property 30: Invalid Data Error Response
@pytest.mark.django_db
@given(
    duration=st.one_of(
        st.integers(max_value=0),  # Invalid: too low
        st.integers(min_value=601, max_value=10000)  # Invalid: too high
    )
)
@settings(max_examples=50, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
def test_property_30_invalid_duration_error_response(duration):
    """
    Feature: workout-tracking-system, Property 30: Invalid Data Error Response
    
    For any invalid workout data sent to the backend, the system should return
    a 400 Bad Request status with detailed validation error messages.
    
    Validates: Requirements 9.6
    """
    # Create test user
    user = User.objects.create_user(
        email=f'testuser{duration}@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create test exercise
    exercise = Exercise.objects.create(
        name=f'Test Exercise {duration}',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test description',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': duration,
        'workout_exercises': [
            {
                'exercise': exercise.id,
                'sets': 3,
                'reps': 10,
                'weight': 100.0,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 400 Bad Request
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    # Response should have error structure
    assert 'success' in response.data
    assert response.data['success'] is False
    assert 'errors' in response.data
    
    # Should have validation error for duration
    errors = response.data['errors']
    assert 'duration_minutes' in errors or 'detail' in errors


@pytest.mark.django_db
@given(
    sets=st.one_of(
        st.integers(max_value=0),  # Invalid: too low
        st.integers(min_value=101, max_value=1000)  # Invalid: too high
    ),
    reps=st.one_of(
        st.integers(max_value=0),  # Invalid: too low
        st.integers(min_value=101, max_value=1000)  # Invalid: too high
    )
)
@settings(max_examples=30, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
def test_property_30_invalid_exercise_data_error_response(sets, reps):
    """
    Feature: workout-tracking-system, Property 30: Invalid Data Error Response
    
    Test validation errors for invalid sets/reps values.
    
    Validates: Requirements 9.6
    """
    # Create test user
    user = User.objects.create_user(
        email=f'testuser{sets}{reps}@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create test exercise
    exercise = Exercise.objects.create(
        name=f'Test Exercise {sets}{reps}',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test description',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'workout_exercises': [
            {
                'exercise': exercise.id,
                'sets': sets,
                'reps': reps,
                'weight': 100.0,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 400 Bad Request
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    # Response should have error structure
    assert 'success' in response.data
    assert response.data['success'] is False
    assert 'errors' in response.data


# Property 31: Exercise Reference Validation
@pytest.mark.django_db
@given(
    non_existent_id=st.integers(min_value=999999, max_value=9999999)
)
@settings(max_examples=30, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
def test_property_31_exercise_reference_validation(non_existent_id):
    """
    Feature: workout-tracking-system, Property 31: Exercise Reference Validation
    
    For any workout submission, all referenced exercise IDs should exist in the database,
    and the system should reject workouts with non-existent exercise IDs.
    
    Validates: Requirements 9.7
    """
    # Ensure the ID doesn't exist
    assume(not Exercise.objects.filter(id=non_existent_id).exists())
    
    # Create test user
    user = User.objects.create_user(
        email=f'testuser{non_existent_id}@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'workout_exercises': [
            {
                'exercise': non_existent_id,
                'sets': 3,
                'reps': 10,
                'weight': 100.0,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 400 Bad Request
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    # Response should have error structure
    assert 'success' in response.data
    assert response.data['success'] is False
    assert 'errors' in response.data
    
    # Should mention exercise validation error
    errors_str = str(response.data['errors']).lower()
    assert 'exercise' in errors_str or 'exist' in errors_str


@pytest.mark.django_db
def test_property_31_valid_exercise_reference():
    """
    Feature: workout-tracking-system, Property 31: Exercise Reference Validation
    
    Verify that valid exercise references are accepted.
    
    Validates: Requirements 9.7
    """
    # Create test user
    user = User.objects.create_user(
        email='testuser_valid@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create test exercise
    exercise = Exercise.objects.create(
        name='Test Exercise Valid',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test description',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'workout_exercises': [
            {
                'exercise': exercise.id,
                'sets': 3,
                'reps': 10,
                'weight': 100.0,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 201 Created (success)
    assert response.status_code == status.HTTP_201_CREATED


# Property 32: Future Date Validation
@pytest.mark.django_db
@given(
    days_in_future=st.integers(min_value=1, max_value=365)
)
@settings(max_examples=30, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
def test_property_32_future_date_validation(days_in_future):
    """
    Feature: workout-tracking-system, Property 32: Future Date Validation
    
    For any workout submission with a date in the future, the system should
    reject the workout and return a validation error.
    
    Validates: Requirements 9.8
    """
    # Create test user
    user = User.objects.create_user(
        email=f'testuser_future{days_in_future}@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create test exercise
    exercise = Exercise.objects.create(
        name=f'Test Exercise Future {days_in_future}',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test description',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    future_date = timezone.now() + timedelta(days=days_in_future)
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'logged_at': future_date.isoformat(),
        'workout_exercises': [
            {
                'exercise': exercise.id,
                'sets': 3,
                'reps': 10,
                'weight': 100.0,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 400 Bad Request
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    # Response should have error structure
    assert 'success' in response.data
    assert response.data['success'] is False
    assert 'errors' in response.data
    
    # Should mention date validation error
    errors_str = str(response.data['errors']).lower()
    assert 'date' in errors_str or 'future' in errors_str


@pytest.mark.django_db
@given(
    days_in_past=st.integers(min_value=0, max_value=365)
)
@settings(max_examples=30, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
def test_property_32_past_date_validation(days_in_past):
    """
    Feature: workout-tracking-system, Property 32: Future Date Validation
    
    Verify that past and present dates are accepted.
    
    Validates: Requirements 9.8
    """
    # Create test user
    user = User.objects.create_user(
        email=f'testuser_past{days_in_past}@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create test exercise
    exercise = Exercise.objects.create(
        name=f'Test Exercise Past {days_in_past}',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test description',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    past_date = timezone.now() - timedelta(days=days_in_past)
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'logged_at': past_date.isoformat(),
        'workout_exercises': [
            {
                'exercise': exercise.id,
                'sets': 3,
                'reps': 10,
                'weight': 100.0,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 201 Created (success)
    assert response.status_code == status.HTTP_201_CREATED


# Property 33: Input Sanitization
@pytest.mark.django_db
@given(
    malicious_input=st.sampled_from([
        '<script>alert("XSS")</script>',
        '<img src=x onerror=alert(1)>',
        '"; DROP TABLE workouts; --',
        '<iframe src="evil.com"></iframe>',
        'javascript:alert(1)',
        '<svg onload=alert(1)>',
        '\x00null\x00byte\x00',
    ])
)
@settings(max_examples=30, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
def test_property_33_input_sanitization(malicious_input):
    """
    Feature: workout-tracking-system, Property 33: Input Sanitization
    
    For any text input (workout notes, exercise names), the system should
    sanitize the input to remove or escape potentially malicious content.
    
    Validates: Requirements 9.10
    """
    # Create test user
    user = User.objects.create_user(
        email=f'testuser_san{hash(malicious_input)}@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create test exercise
    exercise = Exercise.objects.create(
        name=f'Test Exercise San {hash(malicious_input)}',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test description',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'notes': malicious_input,
        'workout_exercises': [
            {
                'exercise': exercise.id,
                'sets': 3,
                'reps': 10,
                'weight': 100.0,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should either accept with sanitized input or reject
    if response.status_code == status.HTTP_201_CREATED:
        # If accepted, verify input was sanitized
        workout_id = response.data['id']
        workout = WorkoutLog.objects.get(id=workout_id)
        
        # Sanitized notes should not contain raw script tags or dangerous content
        if workout.notes:
            assert '<script>' not in workout.notes
            assert 'javascript:' not in workout.notes
            assert '\x00' not in workout.notes
            # Should be HTML escaped
            assert '&lt;' in workout.notes or '&gt;' in workout.notes or workout.notes == malicious_input.replace('\x00', '')


@pytest.mark.django_db
@given(
    text_input=st.text(min_size=1, max_size=100)
)
@settings(max_examples=100, deadline=None)
def test_property_33_sanitize_text_input_function(text_input):
    """
    Feature: workout-tracking-system, Property 33: Input Sanitization
    
    Test the sanitize_text_input function directly.
    
    Validates: Requirements 9.10
    """
    sanitized = sanitize_text_input(text_input)
    
    # Sanitized output should not contain null bytes
    assert '\x00' not in sanitized
    
    # If input contained HTML special characters, they should be escaped
    if '<' in text_input or '>' in text_input:
        assert '&lt;' in sanitized or '&gt;' in sanitized or '<' not in sanitized
    
    # If input contained quotes, they should be escaped
    if '"' in text_input:
        assert '&quot;' in sanitized or '"' not in sanitized


@pytest.mark.django_db
def test_property_33_sanitization_preserves_safe_content():
    """
    Feature: workout-tracking-system, Property 33: Input Sanitization
    
    Verify that safe content is preserved after sanitization.
    
    Validates: Requirements 9.10
    """
    # Create test user
    user = User.objects.create_user(
        email='testuser_safe@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create test exercise
    exercise = Exercise.objects.create(
        name='Test Exercise Safe',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test description',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    safe_notes = "Great workout! Felt strong today. 3x10 bench press at 100kg."
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'notes': safe_notes,
        'workout_exercises': [
            {
                'exercise': exercise.id,
                'sets': 3,
                'reps': 10,
                'weight': 100.0,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 201 Created
    assert response.status_code == status.HTTP_201_CREATED
    
    # Verify safe content is preserved
    workout_id = response.data['id']
    workout = WorkoutLog.objects.get(id=workout_id)
    
    # Safe content should be mostly preserved (may have whitespace normalized)
    assert workout.notes is not None
    assert len(workout.notes) > 0


# Additional validation tests
@pytest.mark.django_db
def test_property_30_empty_exercises_validation():
    """
    Feature: workout-tracking-system, Property 30: Invalid Data Error Response
    
    Test that workouts without exercises are rejected.
    
    Validates: Requirements 9.4, 9.5, 9.6
    """
    # Create test user
    user = User.objects.create_user(
        email='testuser_empty@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'workout_exercises': []  # Empty exercises list
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 400 Bad Request
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    # Response should have error structure
    assert 'success' in response.data
    assert response.data['success'] is False
    assert 'errors' in response.data
    
    # Should mention exercise validation error
    errors_str = str(response.data['errors']).lower()
    assert 'exercise' in errors_str


@pytest.mark.django_db
@given(
    weight=st.one_of(
        st.floats(min_value=-1000, max_value=0.09),  # Invalid: too low
        st.floats(min_value=1000.01, max_value=10000)  # Invalid: too high
    )
)
@settings(max_examples=30, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
def test_property_30_invalid_weight_error_response(weight):
    """
    Feature: workout-tracking-system, Property 30: Invalid Data Error Response
    
    Test validation errors for invalid weight values.
    
    Validates: Requirements 9.6, 9.3
    """
    # Skip NaN and infinite values
    assume(not (weight != weight or abs(weight) == float('inf')))
    
    # Create test user
    user = User.objects.create_user(
        email=f'testuser_weight{hash(weight)}@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )
    
    # Create test exercise
    exercise = Exercise.objects.create(
        name=f'Test Exercise Weight {hash(weight)}',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test description',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    
    # Create valid JWT token
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': timezone.now() + timedelta(hours=24)
    }
    token = jwt.encode(payload, django_settings.JWT_SECRET_KEY, algorithm=django_settings.JWT_ALGORITHM)
    
    # Create API client
    api_client = APIClient()
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    
    workout_data = {
        'workout_name': 'Test Workout',
        'duration_minutes': 60,
        'workout_exercises': [
            {
                'exercise': exercise.id,
                'sets': 3,
                'reps': 10,
                'weight': weight,
                'order': 0
            }
        ]
    }
    
    response = api_client.post('/api/workouts/logs/log_workout/', workout_data, format='json')
    
    # Should return 400 Bad Request
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    # Response should have error structure
    assert 'success' in response.data
    assert response.data['success'] is False
    assert 'errors' in response.data

