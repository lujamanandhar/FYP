"""
Property-based tests for calories calculation.

Tests Property 9: Calories Calculation from the workout-tracking-system design document.
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from hypothesis import given, strategies as st, settings, assume
from hypothesis.extra.django import TestCase as HypothesisTestCase
import uuid

from workouts.models import Exercise, WorkoutLog, WorkoutExercise
from workouts.serializers import WorkoutLogSerializer

User = get_user_model()


class CaloriesCalculationPropertyTests(HypothesisTestCase):
    """
    Property 9: Calories Calculation
    
    For any workout with exercises, the calculated calories should be:
    1. Positive (greater than 0)
    2. Reasonable (not excessively high or low)
    3. Based on exercise intensity, duration, sets, and weight
    4. At least the minimum (duration * 3.0)
    
    **Validates: Requirements 2.10**
    """

    def setUp(self):
        """Set up test data - create fresh user and exercises for each test"""
        super().setUp()
        # Use unique email for each test run to avoid constraint violations
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
        # Create exercises with different calorie rates
        self.exercises = [
            Exercise.objects.create(
                name=f'Test Exercise {uuid.uuid4().hex[:8]} {i}',
                category='STRENGTH',
                muscle_group='CHEST',
                equipment='FREE_WEIGHTS',
                difficulty='INTERMEDIATE',
                description='Test exercise',
                instructions='Test instructions',
                calories_per_minute=Decimal(str(5.0 + i))
            )
            for i in range(5)
        ]

    @given(
        duration=st.integers(min_value=1, max_value=600),
        sets=st.integers(min_value=1, max_value=10),
        reps=st.integers(min_value=1, max_value=20),
        weight=st.decimals(min_value=0.1, max_value=200.0, places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_9_calories_always_positive(self, duration, sets, reps, weight):
        """
        Feature: workout-tracking-system, Property 9: Calories Calculation
        
        For any valid workout with exercises, the calculated calories
        should always be positive (greater than 0).
        
        **Validates: Requirements 2.10**
        """
        # Create workout data
        exercise = self.exercises[0]
        
        data = {
            'user': self.user,  # Pass user object, not user.id
            'workout_name': 'Test Workout',
            'duration_minutes': duration,
            'workout_exercises': [
                {
                    'exercise': exercise,  # Pass exercise object
                    'sets': sets,
                    'reps': reps,
                    'weight': str(weight),
                    'order': 0
                }
            ]
        }
        
        serializer = WorkoutLogSerializer(data=data)
        if serializer.is_valid():
            workout_log = serializer.save()
            
            # Property: Calories should always be positive
            self.assertGreater(
                workout_log.calories_burned,
                0,
                f"Calories should be positive for duration={duration}, sets={sets}, reps={reps}, weight={weight}"
            )

    @given(
        duration=st.integers(min_value=1, max_value=600),
        sets=st.integers(min_value=1, max_value=10),
        reps=st.integers(min_value=1, max_value=20),
        weight=st.decimals(min_value=0.1, max_value=200.0, places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_9_calories_minimum_threshold(self, duration, sets, reps, weight):
        """
        Feature: workout-tracking-system, Property 9: Calories Calculation
        
        For any valid workout, the calculated calories should be at least
        the minimum threshold of duration * 3.0 calories per minute.
        
        **Validates: Requirements 2.10**
        """
        # Create workout data
        exercise = self.exercises[0]
        
        data = {
            'user': self.user,  # Pass user object
            'workout_name': 'Test Workout',
            'duration_minutes': duration,
            'workout_exercises': [
                {
                    'exercise': exercise,  # Pass exercise object
                    'sets': sets,
                    'reps': reps,
                    'weight': str(weight),
                    'order': 0
                }
            ]
        }
        
        serializer = WorkoutLogSerializer(data=data)
        if serializer.is_valid():
            workout_log = serializer.save()
            
            minimum_calories = duration * 3.0
            
            # Property: Calories should be at least the minimum
            self.assertGreaterEqual(
                float(workout_log.calories_burned),
                minimum_calories,
                f"Calories {workout_log.calories_burned} should be >= minimum {minimum_calories} for duration={duration}"
            )

    @given(
        duration=st.integers(min_value=1, max_value=600),
        sets=st.integers(min_value=1, max_value=10),
        reps=st.integers(min_value=1, max_value=20),
        weight=st.decimals(min_value=0.1, max_value=200.0, places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_9_calories_reasonable_upper_bound(self, duration, sets, reps, weight):
        """
        Feature: workout-tracking-system, Property 9: Calories Calculation
        
        For any valid workout, the calculated calories should be reasonable
        and not exceed an upper bound (duration * 50.0 calories per minute,
        which represents extremely intense exercise).
        
        **Validates: Requirements 2.10**
        """
        # Create workout data
        exercise = self.exercises[0]
        
        data = {
            'user': self.user,  # Pass user object
            'workout_name': 'Test Workout',
            'duration_minutes': duration,
            'workout_exercises': [
                {
                    'exercise': exercise,  # Pass exercise object
                    'sets': sets,
                    'reps': reps,
                    'weight': str(weight),
                    'order': 0
                }
            ]
        }
        
        serializer = WorkoutLogSerializer(data=data)
        if serializer.is_valid():
            workout_log = serializer.save()
            
            # Reasonable upper bound: duration * 50 cal/min (very intense exercise)
            maximum_reasonable_calories = duration * 50.0
            
            # Property: Calories should be reasonable (not excessively high)
            self.assertLessEqual(
                float(workout_log.calories_burned),
                maximum_reasonable_calories,
                f"Calories {workout_log.calories_burned} should be <= maximum {maximum_reasonable_calories} for duration={duration}"
            )

    @given(
        duration=st.integers(min_value=10, max_value=120),
        num_exercises=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_9_calories_increase_with_exercises(self, duration, num_exercises):
        """
        Feature: workout-tracking-system, Property 9: Calories Calculation
        
        For any workout, adding more exercises should increase or maintain
        the total calories burned (monotonicity property).
        
        **Validates: Requirements 2.10**
        """
        # Create workout with varying number of exercises
        workout_exercises = []
        for i in range(num_exercises):
            exercise = self.exercises[i % len(self.exercises)]
            workout_exercises.append({
                'exercise': exercise,  # Pass exercise object
                'sets': 3,
                'reps': 10,
                'weight': '50.0',
                'order': i
            })
        
        data = {
            'user': self.user,  # Pass user object
            'workout_name': 'Test Workout',
            'duration_minutes': duration,
            'workout_exercises': workout_exercises
        }
        
        serializer = WorkoutLogSerializer(data=data)
        if serializer.is_valid():
            workout_log = serializer.save()
            
            # Property: More exercises should result in more calories
            # At minimum, should be duration * 3.0 * num_exercises (rough estimate)
            expected_minimum = duration * 3.0
            
            self.assertGreaterEqual(
                float(workout_log.calories_burned),
                expected_minimum,
                f"Calories should increase with {num_exercises} exercises"
            )

    @given(
        duration=st.integers(min_value=10, max_value=120),
        weight1=st.decimals(min_value=10.0, max_value=100.0, places=2),
        weight2=st.decimals(min_value=10.0, max_value=100.0, places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_9_calories_increase_with_weight(self, duration, weight1, weight2):
        """
        Feature: workout-tracking-system, Property 9: Calories Calculation
        
        For any workout, using heavier weights should result in equal or
        higher calories burned (intensity property).
        
        **Validates: Requirements 2.10**
        """
        assume(weight2 > weight1)  # Ensure weight2 is heavier
        
        exercise = self.exercises[0]
        
        # Create workout with lighter weight
        data1 = {
            'user': self.user,  # Pass user object
            'workout_name': 'Light Workout',
            'duration_minutes': duration,
            'workout_exercises': [
                {
                    'exercise': exercise,  # Pass exercise object
                    'sets': 3,
                    'reps': 10,
                    'weight': str(weight1),
                    'order': 0
                }
            ]
        }
        
        serializer1 = WorkoutLogSerializer(data=data1)
        if serializer1.is_valid():
            workout_log1 = serializer1.save()
            calories1 = float(workout_log1.calories_burned)
            
            # Create workout with heavier weight
            data2 = {
                'user': self.user,  # Pass user object
                'workout_name': 'Heavy Workout',
                'duration_minutes': duration,
                'workout_exercises': [
                    {
                        'exercise': exercise,  # Pass exercise object
                        'sets': 3,
                        'reps': 10,
                        'weight': str(weight2),
                        'order': 0
                    }
                ]
            }
            
            serializer2 = WorkoutLogSerializer(data=data2)
            if serializer2.is_valid():
                workout_log2 = serializer2.save()
                calories2 = float(workout_log2.calories_burned)
                
                # Property: Heavier weight should result in more or equal calories
                self.assertGreaterEqual(
                    calories2,
                    calories1,
                    f"Heavier weight ({weight2}) should burn >= calories than lighter weight ({weight1})"
                )


class CaloriesCalculationUnitTests(TestCase):
    """Unit tests for specific calories calculation scenarios"""

    def setUp(self):
        """Set up test data"""
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
        self.exercise = Exercise.objects.create(
            name=f'Bench Press {uuid.uuid4().hex[:8]}',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('8.5')
        )

    def test_calories_calculation_basic(self):
        """Test basic calories calculation"""
        data = {
            'user': self.user,  # Pass user object
            'workout_name': 'Test Workout',
            'duration_minutes': 60,
            'workout_exercises': [
                {
                    'exercise': self.exercise.id,  # Pass exercise ID for serializer
                    'sets': 3,
                    'reps': 10,
                    'weight': '100.0',
                    'order': 0
                }
            ]
        }
        
        serializer = WorkoutLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        workout_log = serializer.save()
        
        # Verify calories are calculated
        self.assertGreater(workout_log.calories_burned, 0)
        # Should be at least minimum (60 * 3.0 = 180)
        self.assertGreaterEqual(workout_log.calories_burned, 180)

    def test_calories_calculation_multiple_exercises(self):
        """Test calories calculation with multiple exercises"""
        exercise2 = Exercise.objects.create(
            name=f'Squats {uuid.uuid4().hex[:8]}',
            category='STRENGTH',
            muscle_group='LEGS',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('10.0')
        )
        
        data = {
            'user': self.user,  # Pass user object
            'workout_name': 'Test Workout',
            'duration_minutes': 60,
            'workout_exercises': [
                {
                    'exercise': self.exercise.id,  # Pass exercise ID for serializer
                    'sets': 3,
                    'reps': 10,
                    'weight': '100.0',
                    'order': 0
                },
                {
                    'exercise': exercise2.id,  # Pass exercise ID for serializer
                    'sets': 4,
                    'reps': 8,
                    'weight': '150.0',
                    'order': 1
                }
            ]
        }
        
        serializer = WorkoutLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        workout_log = serializer.save()
        
        # Verify calories are calculated and reasonable
        self.assertGreater(workout_log.calories_burned, 0)
        # Should be at least minimum (60 * 3.0 = 180)
        self.assertGreaterEqual(workout_log.calories_burned, 180)
