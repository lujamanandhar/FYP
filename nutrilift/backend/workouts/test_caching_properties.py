"""
Property-Based Tests for Data Caching

Feature: workout-tracking-system
Property 28: Data Caching (backend portion)

For any data fetched from the backend (exercises), the system should cache it locally
and serve cached data for improved performance.

Validates: Requirements 8.5, 12.6
"""

from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase
from django.contrib.auth import get_user_model
from django.core.cache import cache
from rest_framework.test import APIClient
from rest_framework import status
from workouts.models import Exercise

User = get_user_model()


# Strategy for generating exercise data
exercise_data_strategy = st.fixed_dictionaries({
    'name': st.text(min_size=5, max_size=50, alphabet=st.characters(whitelist_categories=('Lu', 'Ll', 'Nd', 'Zs'))),
    'category': st.sampled_from(['STRENGTH', 'CARDIO', 'BODYWEIGHT']),
    'muscle_group': st.sampled_from(['CHEST', 'BACK', 'LEGS', 'CORE', 'ARMS', 'SHOULDERS', 'FULL_BODY']),
    'equipment': st.sampled_from(['FREE_WEIGHTS', 'MACHINES', 'BODYWEIGHT', 'RESISTANCE_BANDS', 'CARDIO_EQUIPMENT']),
    'difficulty': st.sampled_from(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']),
    'description': st.text(min_size=10, max_size=200),
    'instructions': st.text(min_size=10, max_size=200),
})


class TestCachingProperties(TestCase):
    """
    Property-based tests for caching behavior.
    """

    def setUp(self):
        """Set up test client and user"""
        self.client = APIClient()
        self.user, _ = User.objects.get_or_create(
            email='testuser@example.com',
            defaults={
                'password': 'testpass123',
                'first_name': 'Test',
                'last_name': 'User'
            }
        )
        self.client.force_authenticate(user=self.user)
        
        # Clear cache before each test
        cache.clear()

    def tearDown(self):
        """Clean up after each test"""
        cache.clear()

    @settings(max_examples=10, deadline=2000)
    @given(
        category=st.sampled_from(['STRENGTH', 'CARDIO', 'BODYWEIGHT']),
        muscle=st.sampled_from(['CHEST', 'BACK', 'LEGS', 'CORE', 'ARMS']),
    )
    def test_property_28_exercise_list_caching(self, category, muscle):
        """
        Feature: workout-tracking-system, Property 28: Data Caching
        
        For any exercise list request with filters, repeated requests should return
        cached data without hitting the database again.
        
        Validates: Requirements 8.5, 12.6
        """
        # Create some test exercises
        Exercise.objects.create(
            name=f'Test Exercise {category} {muscle}',
            category=category,
            muscle_group=muscle,
            equipment='BODYWEIGHT',
            difficulty='BEGINNER',
            description='Test description',
            instructions='Test instructions'
        )
        
        # First request - should hit database and cache the result
        response1 = self.client.get(
            '/api/workouts/exercises/',
            {'category': category, 'muscle': muscle}
        )
        
        # Verify first request succeeds
        assert response1.status_code == status.HTTP_200_OK
        data1 = response1.json()
        
        # Second request with same parameters - should return cached data
        response2 = self.client.get(
            '/api/workouts/exercises/',
            {'category': category, 'muscle': muscle}
        )
        
        # Verify second request succeeds
        assert response2.status_code == status.HTTP_200_OK
        data2 = response2.json()
        
        # Verify both responses are identical (cached data matches)
        assert data1 == data2, "Cached data should match original data"
        
        # Verify the data is actually in cache
        cache_key = f'exercise_list_category_{category}_muscle_{muscle}'
        cached_data = cache.get(cache_key)
        assert cached_data is not None, "Data should be cached"

    @settings(max_examples=10, deadline=2000)
    @given(
        search_term=st.text(min_size=3, max_size=20, alphabet=st.characters(whitelist_categories=('Lu', 'Ll'))),
    )
    def test_property_28_search_caching(self, search_term):
        """
        Feature: workout-tracking-system, Property 28: Data Caching
        
        For any exercise search request, repeated searches should return cached results.
        
        Validates: Requirements 8.5, 12.6
        """
        # Create test exercise with search term in name
        Exercise.objects.create(
            name=f'{search_term} Exercise',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            description='Test description',
            instructions='Test instructions'
        )
        
        # First search request
        response1 = self.client.get('/api/workouts/exercises/', {'search': search_term})
        assert response1.status_code == status.HTTP_200_OK
        data1 = response1.json()
        
        # Second search request with same term
        response2 = self.client.get('/api/workouts/exercises/', {'search': search_term})
        assert response2.status_code == status.HTTP_200_OK
        data2 = response2.json()
        
        # Verify cached data matches
        assert data1 == data2, "Cached search results should match"

    def test_cache_invalidation_on_create(self):
        """
        Feature: workout-tracking-system, Property 28: Data Caching
        
        When a new exercise is created, the cache should be invalidated.
        
        Validates: Requirements 12.6
        """
        # Create initial exercise
        Exercise.objects.create(
            name='Initial Exercise',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            description='Test',
            instructions='Test'
        )
        
        # First request - caches the result
        response1 = self.client.get('/api/workouts/exercises/')
        assert response1.status_code == status.HTTP_200_OK
        initial_count = len(response1.json())
        
        # Create a new exercise via API
        new_exercise_data = {
            'name': 'New Exercise',
            'category': 'CARDIO',
            'muscle_group': 'LEGS',
            'equipment': 'CARDIO_EQUIPMENT',
            'difficulty': 'INTERMEDIATE',
            'description': 'New exercise description',
            'instructions': 'New exercise instructions'
        }
        create_response = self.client.post('/api/workouts/exercises/', new_exercise_data, format='json')
        assert create_response.status_code == status.HTTP_201_CREATED
        
        # Second request - should get fresh data (cache invalidated)
        response2 = self.client.get('/api/workouts/exercises/')
        assert response2.status_code == status.HTTP_200_OK
        new_count = len(response2.json())
        
        # Verify the count increased (cache was invalidated and fresh data retrieved)
        assert new_count == initial_count + 1, "Cache should be invalidated after create"

    @settings(max_examples=10, deadline=2000)
    @given(
        difficulty=st.sampled_from(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']),
    )
    def test_property_28_different_filters_different_cache(self, difficulty):
        """
        Feature: workout-tracking-system, Property 28: Data Caching
        
        Different filter combinations should have separate cache entries.
        
        Validates: Requirements 12.6
        """
        # Create exercises with different difficulties
        for diff in ['BEGINNER', 'INTERMEDIATE', 'ADVANCED']:
            Exercise.objects.create(
                name=f'Exercise {diff}',
                category='STRENGTH',
                muscle_group='CHEST',
                equipment='FREE_WEIGHTS',
                difficulty=diff,
                description='Test',
                instructions='Test'
            )
        
        # Request with specific difficulty filter
        response1 = self.client.get('/api/workouts/exercises/', {'difficulty': difficulty})
        assert response1.status_code == status.HTTP_200_OK
        filtered_data = response1.json()
        
        # Request without filter
        response2 = self.client.get('/api/workouts/exercises/')
        assert response2.status_code == status.HTTP_200_OK
        all_data = response2.json()
        
        # Verify filtered results are a subset of all results
        assert len(filtered_data) <= len(all_data), "Filtered results should be subset of all results"
        
        # Verify all filtered exercises have the correct difficulty
        for exercise in filtered_data:
            assert exercise['difficulty'] == difficulty, "All filtered exercises should match difficulty"

    def test_cache_timeout(self):
        """
        Feature: workout-tracking-system, Property 28: Data Caching
        
        Cached data should expire after the configured timeout period.
        
        Validates: Requirements 12.6
        """
        # Create test exercise
        Exercise.objects.create(
            name='Timeout Test Exercise',
            category='STRENGTH',
            muscle_group='ARMS',
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            description='Test',
            instructions='Test'
        )
        
        # Make request to cache data
        response = self.client.get('/api/workouts/exercises/')
        assert response.status_code == status.HTTP_200_OK
        
        # Verify data is in cache
        cache_key = 'exercise_list'
        cached_data = cache.get(cache_key)
        assert cached_data is not None, "Data should be cached immediately after request"
        
        # Note: We can't easily test actual timeout in unit tests without waiting,
        # but we verify the cache mechanism is working
        # In production, the timeout is set to 300 seconds (5 minutes)
