"""
Property-based tests for workout statistics calculation.

Tests:
- Property 41: Statistics Calculation Accuracy
- Property 42: Time Period Aggregation
- Property 43: Category Aggregation
- Property 44: Exercise Frequency Ranking

Validates: Requirements 15.1, 15.2, 15.3, 15.4, 15.5
"""

from datetime import timedelta
from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status

from workouts.models import (
    Exercise, WorkoutLog, WorkoutExercise
)

User = get_user_model()


class TestStatisticsProperties(TestCase):
    """Property-based tests for statistics calculation"""
    
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
        
        # Create exercises with different categories
        self.strength_exercise = Exercise.objects.create(
            name='Bench Press Stats',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            calories_per_minute=Decimal('8.0')
        )
        
        self.cardio_exercise = Exercise.objects.create(
            name='Running Stats',
            category='CARDIO',
            muscle_group='LEGS',
            equipment='CARDIO_EQUIPMENT',
            difficulty='BEGINNER',
            calories_per_minute=Decimal('10.0')
        )
        
        self.bodyweight_exercise = Exercise.objects.create(
            name='Push-ups Stats',
            category='BODYWEIGHT',
            muscle_group='CHEST',
            equipment='BODYWEIGHT',
            difficulty='BEGINNER',
            calories_per_minute=Decimal('6.0')
        )
    
    def test_property_41_statistics_calculation_accuracy(self):
        """
        Property 41: Statistics Calculation Accuracy
        
        For any set of workouts, the calculated statistics (total workouts,
        total calories, total duration, averages) should accurately reflect
        the sum and average of the workout data.
        
        Validates: Requirements 15.1, 15.5
        """
        # Create multiple workouts with known values
        workouts_data = [
            {'duration': 60, 'calories': Decimal('450.0')},
            {'duration': 75, 'calories': Decimal('520.0')},
            {'duration': 45, 'calories': Decimal('380.0')},
            {'duration': 90, 'calories': Decimal('600.0')},
        ]
        
        for data in workouts_data:
            workout = WorkoutLog.objects.create(
                user=self.user,
                workout_name='Test Workout',
                duration_minutes=data['duration'],
                calories_burned=data['calories']
            )
            WorkoutExercise.objects.create(
                workout_log=workout,
                exercise=self.strength_exercise,
                sets=3,
                reps=10,
                weight=Decimal('100.0'),
                order=0
            )
        
        # Get statistics
        response = self.client.get('/api/workouts/logs/statistics/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify total workouts
        self.assertEqual(response.data['total_workouts'], len(workouts_data))
        
        # Verify total duration
        expected_total_duration = sum(w['duration'] for w in workouts_data)
        self.assertEqual(response.data['total_duration_minutes'], expected_total_duration)
        
        # Verify total calories
        expected_total_calories = sum(float(w['calories']) for w in workouts_data)
        self.assertAlmostEqual(
            response.data['total_calories_burned'],
            expected_total_calories,
            places=2
        )
        
        # Verify average duration
        expected_avg_duration = expected_total_duration / len(workouts_data)
        self.assertAlmostEqual(
            response.data['average_duration_minutes'],
            expected_avg_duration,
            places=2
        )
        
        # Verify average calories
        expected_avg_calories = expected_total_calories / len(workouts_data)
        self.assertAlmostEqual(
            response.data['average_calories_burned'],
            expected_avg_calories,
            places=2
        )
    
    def test_property_42_time_period_aggregation(self):
        """
        Property 42: Time Period Aggregation
        
        For any statistics request with a time period filter, the returned
        data should be correctly grouped by the specified time period.
        
        Validates: Requirements 15.2
        """
        now = timezone.now()
        
        # Create workouts on different dates
        dates = [
            now - timedelta(days=5),
            now - timedelta(days=3),
            now - timedelta(days=3),  # Same day as previous
            now - timedelta(days=1),
        ]
        
        for i, date in enumerate(dates):
            workout = WorkoutLog.objects.create(
                user=self.user,
                workout_name=f'Workout {i}',
                duration_minutes=60,
                calories_burned=Decimal('450.0')
            )
            # Manually set logged_at since auto_now_add doesn't allow custom values
            workout.logged_at = date
            workout.save()
            
            WorkoutExercise.objects.create(
                workout_log=workout,
                exercise=self.strength_exercise,
                sets=3,
                reps=10,
                weight=Decimal('100.0'),
                order=0
            )
        
        # Get statistics
        response = self.client.get('/api/workouts/logs/statistics/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify workout_by_date contains correct grouping
        self.assertIn('workout_by_date', response.data)
        workout_by_date = response.data['workout_by_date']
        
        # Should have 3 unique dates (5 days ago, 3 days ago, 1 day ago)
        self.assertEqual(len(workout_by_date), 3)
        
        # Verify that the date with 2 workouts has count=2
        date_3_days_ago = (now - timedelta(days=3)).date().isoformat()
        if date_3_days_ago in workout_by_date:
            self.assertEqual(workout_by_date[date_3_days_ago]['count'], 2)
    
    def test_property_43_category_aggregation(self):
        """
        Property 43: Category Aggregation
        
        For any statistics request, the breakdown by exercise category should
        correctly count workouts for each category.
        
        Validates: Requirements 15.3
        """
        # Create workouts with different exercise categories
        workout1 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Strength Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.0')
        )
        WorkoutExercise.objects.create(
            workout_log=workout1,
            exercise=self.strength_exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        WorkoutExercise.objects.create(
            workout_log=workout1,
            exercise=self.strength_exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=1
        )
        
        workout2 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Cardio Workout',
            duration_minutes=45,
            calories_burned=Decimal('380.0')
        )
        WorkoutExercise.objects.create(
            workout_log=workout2,
            exercise=self.cardio_exercise,
            sets=1,
            reps=30,
            weight=Decimal('0.0'),
            order=0
        )
        
        workout3 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Bodyweight Workout',
            duration_minutes=30,
            calories_burned=Decimal('250.0')
        )
        WorkoutExercise.objects.create(
            workout_log=workout3,
            exercise=self.bodyweight_exercise,
            sets=3,
            reps=15,
            weight=Decimal('0.0'),
            order=0
        )
        
        # Get statistics
        response = self.client.get('/api/workouts/logs/statistics/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify workouts_by_category
        self.assertIn('workouts_by_category', response.data)
        workouts_by_category = response.data['workouts_by_category']
        
        # Should have counts for each category
        # Note: Each workout exercise is counted, not each workout
        self.assertIn('STRENGTH', workouts_by_category)
        self.assertEqual(workouts_by_category['STRENGTH'], 2)  # 2 strength exercises
        
        self.assertIn('CARDIO', workouts_by_category)
        self.assertEqual(workouts_by_category['CARDIO'], 1)  # 1 cardio exercise
        
        self.assertIn('BODYWEIGHT', workouts_by_category)
        self.assertEqual(workouts_by_category['BODYWEIGHT'], 1)  # 1 bodyweight exercise
    
    def test_property_44_exercise_frequency_ranking(self):
        """
        Property 44: Exercise Frequency Ranking
        
        For any set of workouts, the most frequently performed exercises
        should be correctly identified and ranked by frequency.
        
        Validates: Requirements 15.4
        """
        # Create workouts with different exercise frequencies
        # Bench Press: 3 times
        # Running: 2 times
        # Push-ups: 1 time
        
        for i in range(3):
            workout = WorkoutLog.objects.create(
                user=self.user,
                workout_name=f'Bench Press Workout {i}',
                duration_minutes=60,
                calories_burned=Decimal('450.0')
            )
            WorkoutExercise.objects.create(
                workout_log=workout,
                exercise=self.strength_exercise,
                sets=3,
                reps=10,
                weight=Decimal('100.0'),
                order=0
            )
        
        for i in range(2):
            workout = WorkoutLog.objects.create(
                user=self.user,
                workout_name=f'Running Workout {i}',
                duration_minutes=45,
                calories_burned=Decimal('380.0')
            )
            WorkoutExercise.objects.create(
                workout_log=workout,
                exercise=self.cardio_exercise,
                sets=1,
                reps=30,
                weight=Decimal('0.0'),
                order=0
            )
        
        workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push-ups Workout',
            duration_minutes=30,
            calories_burned=Decimal('250.0')
        )
        WorkoutExercise.objects.create(
            workout_log=workout,
            exercise=self.bodyweight_exercise,
            sets=3,
            reps=15,
            weight=Decimal('0.0'),
            order=0
        )
        
        # Get statistics
        response = self.client.get('/api/workouts/logs/statistics/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify most_frequent_exercises
        self.assertIn('most_frequent_exercises', response.data)
        most_frequent = response.data['most_frequent_exercises']
        
        # Should have all 3 exercises
        self.assertEqual(len(most_frequent), 3)
        
        # Verify ranking (most frequent first)
        self.assertEqual(most_frequent[0]['name'], 'Bench Press Stats')
        self.assertEqual(most_frequent[0]['count'], 3)
        
        self.assertEqual(most_frequent[1]['name'], 'Running Stats')
        self.assertEqual(most_frequent[1]['count'], 2)
        
        self.assertEqual(most_frequent[2]['name'], 'Push-ups Stats')
        self.assertEqual(most_frequent[2]['count'], 1)
        
        # Verify ordering is maintained (descending by count)
        for i in range(len(most_frequent) - 1):
            self.assertGreaterEqual(
                most_frequent[i]['count'],
                most_frequent[i + 1]['count']
            )
    
    def test_statistics_with_empty_data(self):
        """Test that statistics work correctly with no workouts"""
        response = self.client.get('/api/workouts/logs/statistics/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_workouts'], 0)
        self.assertEqual(response.data['total_duration_minutes'], 0)
        self.assertEqual(response.data['total_calories_burned'], 0.0)
        self.assertEqual(response.data['average_duration_minutes'], 0.0)
        self.assertEqual(response.data['average_calories_burned'], 0.0)
        self.assertEqual(len(response.data['workout_by_date']), 0)
        self.assertEqual(len(response.data['workouts_by_category']), 0)
        self.assertEqual(len(response.data['most_frequent_exercises']), 0)
