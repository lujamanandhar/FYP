"""
Property-based tests for Exercise API filtering.

Tests:
- Property 11: Exercise Filter Combination
- Property 5: Exercise Search Filtering

Validates: Requirements 2.3, 3.2, 3.3, 3.4, 3.5, 3.6, 3.9
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
from decimal import Decimal

from workouts.models import Exercise

User = get_user_model()


class ExerciseFilteringPropertyTests(HypothesisTestCase):
    """Property-based tests for exercise filtering API"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='testuser@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        self.client.force_authenticate(user=self.user)
        
        # Create a diverse set of exercises for testing
        self.exercises = [
            Exercise.objects.create(
                name='Bench Press',
                category='STRENGTH',
                muscle_group='CHEST',
                equipment='FREE_WEIGHTS',
                difficulty='INTERMEDIATE',
                description='A compound upper body exercise',
                instructions='Lie on bench, lower bar to chest, press up',
                calories_per_minute=Decimal('8.0')
            ),
            Exercise.objects.create(
                name='Squats',
                category='STRENGTH',
                muscle_group='LEGS',
                equipment='FREE_WEIGHTS',
                difficulty='INTERMEDIATE',
                description='A compound lower body exercise',
                instructions='Stand with bar on shoulders, squat down, stand up',
                calories_per_minute=Decimal('10.0')
            ),
            Exercise.objects.create(
                name='Push-ups',
                category='BODYWEIGHT',
                muscle_group='CHEST',
                equipment='BODYWEIGHT',
                difficulty='BEGINNER',
                description='A bodyweight upper body exercise',
                instructions='Lower body to ground, push back up',
                calories_per_minute=Decimal('6.0')
            ),
            Exercise.objects.create(
                name='Running',
                category='CARDIO',
                muscle_group='FULL_BODY',
                equipment='CARDIO_EQUIPMENT',
                difficulty='BEGINNER',
                description='Cardiovascular exercise',
                instructions='Run at steady pace',
                calories_per_minute=Decimal('12.0')
            ),
            Exercise.objects.create(
                name='Deadlift',
                category='STRENGTH',
                muscle_group='BACK',
                equipment='FREE_WEIGHTS',
                difficulty='ADVANCED',
                description='A compound posterior chain exercise',
                instructions='Lift bar from ground to standing position',
                calories_per_minute=Decimal('9.0')
            ),
            Exercise.objects.create(
                name='Pull-ups',
                category='BODYWEIGHT',
                muscle_group='BACK',
                equipment='BODYWEIGHT',
                difficulty='INTERMEDIATE',
                description='A bodyweight pulling exercise',
                instructions='Hang from bar, pull body up until chin over bar',
                calories_per_minute=Decimal('7.0')
            ),
            Exercise.objects.create(
                name='Leg Press Machine',
                category='STRENGTH',
                muscle_group='LEGS',
                equipment='MACHINES',
                difficulty='BEGINNER',
                description='A machine-based leg exercise',
                instructions='Push platform away with legs',
                calories_per_minute=Decimal('8.0')
            ),
            Exercise.objects.create(
                name='Bicep Curls',
                category='STRENGTH',
                muscle_group='ARMS',
                equipment='FREE_WEIGHTS',
                difficulty='BEGINNER',
                description='An isolation arm exercise',
                instructions='Curl dumbbells up to shoulders',
                calories_per_minute=Decimal('5.0')
            ),
        ]
    
    @settings(max_examples=100, deadline=None)
    @given(
        category=st.sampled_from(['STRENGTH', 'CARDIO', 'BODYWEIGHT']),
        muscle=st.sampled_from(['CHEST', 'BACK', 'LEGS', 'CORE', 'ARMS', 'SHOULDERS', 'FULL_BODY']),
        equipment=st.sampled_from(['FREE_WEIGHTS', 'MACHINES', 'BODYWEIGHT', 'RESISTANCE_BANDS', 'CARDIO_EQUIPMENT']),
        difficulty=st.sampled_from(['BEGINNER', 'INTERMEDIATE', 'ADVANCED'])
    )
    def test_property_11_exercise_filter_combination(self, category, muscle, equipment, difficulty):
        """
        Property 11: Exercise Filter Combination
        
        For any combination of filters (category, muscle group, equipment, difficulty),
        all returned exercises should match ALL applied filters simultaneously.
        
        Validates: Requirements 3.2, 3.3, 3.4, 3.5, 3.9
        """
        # Build query parameters
        params = {
            'category': category,
            'muscle': muscle,
            'equipment': equipment,
            'difficulty': difficulty
        }
        
        # Make API request
        response = self.client.get('/api/workouts/exercises/', params)
        
        # Should return 200 OK
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify all returned exercises match ALL filters
        for exercise in response.data:
            self.assertEqual(
                exercise['category'], category,
                f"Exercise {exercise['name']} has category {exercise['category']}, expected {category}"
            )
            self.assertEqual(
                exercise['muscle_group'], muscle,
                f"Exercise {exercise['name']} has muscle_group {exercise['muscle_group']}, expected {muscle}"
            )
            self.assertEqual(
                exercise['equipment'], equipment,
                f"Exercise {exercise['name']} has equipment {exercise['equipment']}, expected {equipment}"
            )
            self.assertEqual(
                exercise['difficulty'], difficulty,
                f"Exercise {exercise['name']} has difficulty {exercise['difficulty']}, expected {difficulty}"
            )
    
    @settings(max_examples=100, deadline=None)
    @given(
        category=st.sampled_from(['STRENGTH', 'CARDIO', 'BODYWEIGHT']),
        muscle=st.sampled_from(['CHEST', 'BACK', 'LEGS', 'ARMS', 'FULL_BODY'])
    )
    def test_property_11_two_filter_combination(self, category, muscle):
        """
        Property 11: Exercise Filter Combination (Two Filters)
        
        Test that combining two filters works correctly.
        
        Validates: Requirements 3.2, 3.3, 3.9
        """
        params = {
            'category': category,
            'muscle': muscle
        }
        
        response = self.client.get('/api/workouts/exercises/', params)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify all returned exercises match both filters
        for exercise in response.data:
            self.assertEqual(exercise['category'], category)
            self.assertEqual(exercise['muscle_group'], muscle)
    
    @settings(max_examples=100, deadline=None)
    @given(
        search_term=st.sampled_from(['Press', 'Pull', 'Squat', 'Run', 'Curl', 'Leg', 'push', 'BENCH'])
    )
    def test_property_5_exercise_search_filtering(self, search_term):
        """
        Property 5: Exercise Search Filtering
        
        For any search term, all returned exercises should have names that contain
        the search term (case-insensitive).
        
        Validates: Requirements 2.3, 3.6
        """
        params = {'search': search_term}
        
        response = self.client.get('/api/workouts/exercises/', params)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify all returned exercises contain the search term (case-insensitive)
        for exercise in response.data:
            self.assertIn(
                search_term.lower(),
                exercise['name'].lower(),
                f"Exercise '{exercise['name']}' does not contain search term '{search_term}'"
            )
    
    @settings(max_examples=100, deadline=None)
    @given(
        search_term=st.text(
            min_size=1,
            max_size=20,
            alphabet=st.characters(whitelist_categories=('Lu', 'Ll'), whitelist_characters=' -')
        )
    )
    def test_property_5_exercise_search_filtering_arbitrary_text(self, search_term):
        """
        Property 5: Exercise Search Filtering (Arbitrary Text)
        
        Test search filtering with arbitrary text strings.
        
        Validates: Requirements 2.3, 3.6
        """
        params = {'search': search_term}
        
        response = self.client.get('/api/workouts/exercises/', params)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify all returned exercises contain the search term (case-insensitive)
        for exercise in response.data:
            self.assertIn(
                search_term.lower(),
                exercise['name'].lower(),
                f"Exercise '{exercise['name']}' does not contain search term '{search_term}'"
            )
    
    def test_exercise_filter_by_category_only(self):
        """Test filtering by category only"""
        response = self.client.get('/api/workouts/exercises/', {'category': 'STRENGTH'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data), 0)
        
        for exercise in response.data:
            self.assertEqual(exercise['category'], 'STRENGTH')
    
    def test_exercise_filter_by_muscle_only(self):
        """Test filtering by muscle group only"""
        response = self.client.get('/api/workouts/exercises/', {'muscle': 'CHEST'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data), 0)
        
        for exercise in response.data:
            self.assertEqual(exercise['muscle_group'], 'CHEST')
    
    def test_exercise_filter_by_equipment_only(self):
        """Test filtering by equipment only"""
        response = self.client.get('/api/workouts/exercises/', {'equipment': 'FREE_WEIGHTS'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data), 0)
        
        for exercise in response.data:
            self.assertEqual(exercise['equipment'], 'FREE_WEIGHTS')
    
    def test_exercise_filter_by_difficulty_only(self):
        """Test filtering by difficulty only"""
        response = self.client.get('/api/workouts/exercises/', {'difficulty': 'BEGINNER'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data), 0)
        
        for exercise in response.data:
            self.assertEqual(exercise['difficulty'], 'BEGINNER')
    
    def test_exercise_search_case_insensitive(self):
        """Test that search is case-insensitive"""
        # Search for 'bench' (lowercase)
        response1 = self.client.get('/api/workouts/exercises/', {'search': 'bench'})
        
        # Search for 'BENCH' (uppercase)
        response2 = self.client.get('/api/workouts/exercises/', {'search': 'BENCH'})
        
        # Search for 'Bench' (mixed case)
        response3 = self.client.get('/api/workouts/exercises/', {'search': 'Bench'})
        
        self.assertEqual(response1.status_code, status.HTTP_200_OK)
        self.assertEqual(response2.status_code, status.HTTP_200_OK)
        self.assertEqual(response3.status_code, status.HTTP_200_OK)
        
        # All should return the same results
        self.assertEqual(len(response1.data), len(response2.data))
        self.assertEqual(len(response1.data), len(response3.data))
        
        # All should contain 'Bench Press'
        for response in [response1, response2, response3]:
            exercise_names = [ex['name'] for ex in response.data]
            self.assertIn('Bench Press', exercise_names)
    
    def test_exercise_no_filters_returns_all(self):
        """Test that no filters returns all exercises"""
        response = self.client.get('/api/workouts/exercises/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), len(self.exercises))
    
    def test_exercise_filter_combination_no_results(self):
        """Test that incompatible filter combinations return empty results"""
        # CARDIO exercises with CHEST muscle group (no such exercise exists)
        response = self.client.get('/api/workouts/exercises/', {
            'category': 'CARDIO',
            'muscle': 'CHEST'
        })
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)
    
    def test_exercise_search_and_filter_combination(self):
        """Test combining search with other filters"""
        response = self.client.get('/api/workouts/exercises/', {
            'search': 'Press',
            'category': 'STRENGTH',
            'muscle': 'CHEST'
        })
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return only exercises matching all criteria
        for exercise in response.data:
            self.assertIn('Press', exercise['name'])
            self.assertEqual(exercise['category'], 'STRENGTH')
            self.assertEqual(exercise['muscle_group'], 'CHEST')
    
    def test_exercise_retrieve_single_exercise(self):
        """Test retrieving a single exercise by ID"""
        exercise_id = self.exercises[0].id
        
        response = self.client.get(f'/api/workouts/exercises/{exercise_id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], exercise_id)
        self.assertEqual(response.data['name'], 'Bench Press')
        self.assertIn('category', response.data)
        self.assertIn('muscle_group', response.data)
        self.assertIn('equipment', response.data)
        self.assertIn('difficulty', response.data)
        self.assertIn('description', response.data)
        self.assertIn('instructions', response.data)
    
    def test_exercise_retrieve_nonexistent_returns_404(self):
        """Test that retrieving a non-existent exercise returns 404"""
        response = self.client.get('/api/workouts/exercises/99999/')
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_exercise_unauthenticated_request_returns_401(self):
        """Test that unauthenticated requests are rejected"""
        unauthenticated_client = APIClient()
        
        response = unauthenticated_client.get('/api/workouts/exercises/')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
