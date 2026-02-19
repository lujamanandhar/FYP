"""
Integration tests for workout API endpoints.

Tests:
- POST /api/workouts/log/ with valid data returns 201
- GET /api/workouts/history/ returns ordered workouts
- Test date_from filtering works correctly
- Property 1: Workout History Ordering
- Property 2: Date Range Filtering
- Property 8: Workout Persistence and Response

Validates: Requirements 1.1, 1.2, 1.7, 2.9, 14.1, 14.2
"""

from datetime import datetime, timedelta
from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from hypothesis import given, strategies as st, settings

from workouts.models import (
    Exercise, WorkoutLog, WorkoutExercise, Gym, PersonalRecord
)

User = get_user_model()


class TestLogWorkoutEndpoint(TestCase):
    """Test POST /api/workouts/log/ endpoint"""
    
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
        
        self.exercise = Exercise.objects.create(
            name='Bench Press',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            description='A compound upper body exercise',
            instructions='Lie on bench, lower bar to chest, press up',
            calories_per_minute=Decimal('8.0')
        )
        
        self.gym = Gym.objects.create(
            name="Gold's Gym",
            location='Downtown',
            address='123 Main St',
            rating=Decimal('4.5')
        )
    
    def test_log_workout_with_valid_data_returns_201(self):
        """
        Test that POST /api/workouts/log/ with valid data returns 201.
        Validates: Requirements 2.8, 2.9, 5.1, 14.1, 14.2
        """
        workout_data = {
            'workout_name': 'Push Day',
            'gym_id': self.gym.id,
            'duration_minutes': 60,
            'notes': 'Great workout!',
            'workout_exercises': [
                {
                    'exercise': self.exercise.id,
                    'sets': 3,
                    'reps': 10,
                    'weight': 100.0,
                    'order': 0
                }
            ]
        }
        
        response = self.client.post(
            '/api/workouts/logs/log_workout/',
            workout_data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('id', response.data)
        self.assertEqual(response.data['workout_name'], 'Push Day')
        self.assertEqual(response.data['duration_minutes'], 60)
        self.assertIn('calories_burned', response.data)
        self.assertIn('has_new_prs', response.data)
        self.assertEqual(len(response.data['workout_exercises']), 1)
        self.assertEqual(response.data['workout_exercises'][0]['exercise_name'], 'Bench Press')
        self.assertEqual(response.data['workout_exercises'][0]['volume'], 3000.0)
    
    def test_log_workout_creates_database_entry(self):
        """
        Test that logging a workout creates entries in the database.
        Validates: Requirements 14.1, 14.2
        """
        workout_data = {
            'workout_name': 'Leg Day',
            'duration_minutes': 75,
            'workout_exercises': [
                {
                    'exercise': self.exercise.id,
                    'sets': 4,
                    'reps': 8,
                    'weight': 120.0,
                    'order': 0
                }
            ]
        }
        
        initial_count = WorkoutLog.objects.count()
        
        response = self.client.post(
            '/api/workouts/logs/log_workout/',
            workout_data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(WorkoutLog.objects.count(), initial_count + 1)
        
        # Verify the workout was created correctly
        workout = WorkoutLog.objects.get(id=response.data['id'])
        self.assertEqual(workout.user, self.user)
        self.assertEqual(workout.workout_name, 'Leg Day')
        self.assertEqual(workout.duration_minutes, 75)
        self.assertEqual(workout.workout_exercises.count(), 1)
    
    def test_log_workout_without_authentication_returns_401(self):
        """Test that unauthenticated requests are rejected"""
        unauthenticated_client = APIClient()
        
        workout_data = {
            'workout_name': 'Test Workout',
            'duration_minutes': 60,
            'workout_exercises': [
                {
                    'exercise': self.exercise.id,
                    'sets': 3,
                    'reps': 10,
                    'weight': 100.0,
                    'order': 0
                }
            ]
        }
        
        response = unauthenticated_client.post(
            '/api/workouts/logs/log_workout/',
            workout_data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_log_workout_with_invalid_data_returns_400(self):
        """Test that invalid workout data is rejected"""
        # Missing required field (workout_name)
        workout_data = {
            'duration_minutes': 60,
            'workout_exercises': [
                {
                    'exercise': self.exercise.id,
                    'sets': 3,
                    'reps': 10,
                    'weight': 100.0,
                    'order': 0
                }
            ]
        }
        
        response = self.client.post(
            '/api/workouts/logs/log_workout/',
            workout_data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class TestGetHistoryEndpoint(TestCase):
    """Test GET /api/workouts/history/ endpoint"""
    
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
        
        self.exercise = Exercise.objects.create(
            name='Bench Press Test',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            description='A compound upper body exercise',
            instructions='Lie on bench, lower bar to chest, press up',
            calories_per_minute=Decimal('8.0')
        )
    
    def test_get_history_returns_ordered_workouts(self):
        """
        Test that GET /api/workouts/history/ returns workouts ordered by date descending.
        Property 1: Workout History Ordering
        Validates: Requirements 1.1, 1.7
        """
        # Create workouts with different dates
        now = timezone.now()
        workout1 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Workout 1',
            duration_minutes=60,
            calories_burned=Decimal('450.0'),
            logged_at=now - timedelta(days=2)
        )
        WorkoutExercise.objects.create(
            workout_log=workout1,
            exercise=self.exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        workout2 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Workout 2',
            duration_minutes=75,
            calories_burned=Decimal('520.0'),
            logged_at=now - timedelta(days=1)
        )
        WorkoutExercise.objects.create(
            workout_log=workout2,
            exercise=self.exercise,
            sets=4,
            reps=8,
            weight=Decimal('120.0'),
            order=0
        )
        
        workout3 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Workout 3',
            duration_minutes=55,
            calories_burned=Decimal('420.0'),
            logged_at=now
        )
        WorkoutExercise.objects.create(
            workout_log=workout3,
            exercise=self.exercise,
            sets=3,
            reps=12,
            weight=Decimal('90.0'),
            order=0
        )
        
        response = self.client.get('/api/workouts/logs/get_history/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 3)
        
        # Verify ordering (newest first)
        self.assertEqual(response.data[0]['workout_name'], 'Workout 3')
        self.assertEqual(response.data[1]['workout_name'], 'Workout 2')
        self.assertEqual(response.data[2]['workout_name'], 'Workout 1')
        
        # Verify dates are in descending order
        for i in range(len(response.data) - 1):
            date1 = datetime.fromisoformat(response.data[i]['logged_at'].replace('Z', '+00:00'))
            date2 = datetime.fromisoformat(response.data[i + 1]['logged_at'].replace('Z', '+00:00'))
            self.assertGreaterEqual(date1, date2)
    
    def test_get_history_with_date_from_filter(self):
        """
        Test that date_from filtering works correctly.
        Property 2: Date Range Filtering
        Validates: Requirements 1.2
        """
        now = timezone.now()
        
        # Create workouts with different dates
        workout1 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Old Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.0'),
            logged_at=now - timedelta(days=10)
        )
        WorkoutExercise.objects.create(
            workout_log=workout1,
            exercise=self.exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        workout2 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Recent Workout',
            duration_minutes=75,
            calories_burned=Decimal('520.0'),
            logged_at=now - timedelta(days=2)
        )
        WorkoutExercise.objects.create(
            workout_log=workout2,
            exercise=self.exercise,
            sets=4,
            reps=8,
            weight=Decimal('120.0'),
            order=0
        )
        
        # Filter to get only workouts from the last 5 days
        date_from = (now - timedelta(days=5)).isoformat()
        response = self.client.get(
            f'/api/workouts/logs/get_history/?date_from={date_from}'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should return only the recent workout (within last 5 days)
        # Note: Due to timezone handling, we check that at least the recent workout is returned
        self.assertGreaterEqual(len(response.data), 1)
        # Verify the recent workout is in the results
        workout_names = [w['workout_name'] for w in response.data]
        self.assertIn('Recent Workout', workout_names)
        
        # Verify all returned workouts are within the date range
        for workout in response.data:
            workout_date = datetime.fromisoformat(workout['logged_at'].replace('Z', '+00:00'))
            filter_date = datetime.fromisoformat(date_from.replace('Z', '+00:00'))
            self.assertGreaterEqual(workout_date, filter_date)
    
    def test_get_history_with_limit(self):
        """Test that limit parameter works correctly"""
        # Create 5 workouts
        for i in range(5):
            workout = WorkoutLog.objects.create(
                user=self.user,
                workout_name=f'Workout {i}',
                duration_minutes=60,
                calories_burned=Decimal('450.0')
            )
            WorkoutExercise.objects.create(
                workout_log=workout,
                exercise=self.exercise,
                sets=3,
                reps=10,
                weight=Decimal('100.0'),
                order=0
            )
        
        # Request only 3 workouts
        response = self.client.get('/api/workouts/logs/get_history/?limit=3')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 3)
    
    def test_get_history_only_returns_user_workouts(self):
        """Test that users only see their own workouts"""
        # Create another user
        other_user = User.objects.create_user(
            email='otheruser@example.com',
            password='testpass123',
            first_name='Other',
            last_name='User'
        )
        
        # Create workout for authenticated user
        workout1 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='My Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.0')
        )
        WorkoutExercise.objects.create(
            workout_log=workout1,
            exercise=self.exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        # Create workout for other user
        workout2 = WorkoutLog.objects.create(
            user=other_user,
            workout_name='Other Workout',
            duration_minutes=75,
            calories_burned=Decimal('520.0')
        )
        WorkoutExercise.objects.create(
            workout_log=workout2,
            exercise=self.exercise,
            sets=4,
            reps=8,
            weight=Decimal('120.0'),
            order=0
        )
        
        response = self.client.get('/api/workouts/logs/get_history/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['workout_name'], 'My Workout')


class TestWorkoutEndpointProperties(TestCase):
    """Property-based tests for workout endpoints"""
    
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
        
        self.exercise = Exercise.objects.create(
            name='Property Test Exercise',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            description='A compound upper body exercise',
            instructions='Lie on bench, lower bar to chest, press up',
            calories_per_minute=Decimal('8.0')
        )
    
    @settings(max_examples=100, deadline=None)
    @given(
        duration=st.integers(min_value=1, max_value=600),
        sets=st.integers(min_value=1, max_value=100),
        reps=st.integers(min_value=1, max_value=100),
        weight=st.floats(min_value=0.1, max_value=1000.0, allow_nan=False, allow_infinity=False)
    )
    def test_property_8_workout_persistence_and_response(self, duration, sets, reps, weight):
        """
        Property 8: Workout Persistence and Response
        
        For any valid workout submission, the backend should persist the workout
        to the database and return a 201 Created status with the complete workout
        object including calculated calories and PR flags.
        
        Validates: Requirements 2.9, 14.1, 14.2
        """
        workout_data = {
            'workout_name': 'Property Test Workout',
            'duration_minutes': duration,
            'workout_exercises': [
                {
                    'exercise': self.exercise.id,
                    'sets': sets,
                    'reps': reps,
                    'weight': round(weight, 2),
                    'order': 0
                }
            ]
        }
        
        initial_count = WorkoutLog.objects.count()
        
        response = self.client.post(
            '/api/workouts/logs/log_workout/',
            workout_data,
            format='json'
        )
        
        # Should return 201 Created
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Should have an ID
        self.assertIn('id', response.data)
        
        # Should persist to database
        self.assertEqual(WorkoutLog.objects.count(), initial_count + 1)
        
        # Should include calculated calories
        self.assertIn('calories_burned', response.data)
        self.assertGreater(float(response.data['calories_burned']), 0)
        
        # Should include PR flags
        self.assertIn('has_new_prs', response.data)
        self.assertIsInstance(response.data['has_new_prs'], bool)
        
        # Should include complete workout object
        self.assertEqual(response.data['workout_name'], 'Property Test Workout')
        self.assertEqual(response.data['duration_minutes'], duration)
        self.assertEqual(len(response.data['workout_exercises']), 1)
        
        # Should include exercise details
        exercise_data = response.data['workout_exercises'][0]
        self.assertIn('exercise_name', exercise_data)
        self.assertIn('volume', exercise_data)
        self.assertEqual(exercise_data['sets'], sets)
        self.assertEqual(exercise_data['reps'], reps)
        self.assertEqual(float(exercise_data['weight']), round(weight, 2))
        
        # Clean up
        WorkoutLog.objects.filter(id=response.data['id']).delete()
