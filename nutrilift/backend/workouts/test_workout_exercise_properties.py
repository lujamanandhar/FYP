"""
Property-based tests for WorkoutExercise model validation.

Tests Property 7 from the workout-tracking-system design document.
"""

from django.test import TestCase
from django.core.exceptions import ValidationError
from django.contrib.auth import get_user_model
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
from decimal import Decimal
from workouts.models import WorkoutExercise, WorkoutLog, Exercise

User = get_user_model()


class WorkoutExerciseValidationPropertyTests(HypothesisTestCase):
    """Property-based tests for WorkoutExercise model validation."""
    
    @classmethod
    def setUpClass(cls):
        """Set up class-level test fixtures."""
        super().setUpClass()
        
        # Create a test user
        cls.user = User.objects.create_user(
            email='test_workout_exercise@example.com',
            password='testpass123'
        )
        
        # Create a test exercise
        cls.exercise = Exercise.objects.create(
            name='Test Exercise for WorkoutExercise',
            description='Test description',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            instructions='Test instructions'
        )
    
    @classmethod
    def tearDownClass(cls):
        """Clean up class-level test fixtures."""
        cls.user.delete()
        cls.exercise.delete()
        super().tearDownClass()
    
    def setUp(self):
        """Set up test fixtures for each test."""
        # Create a test workout log for each test
        self.workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Test Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
    
    def tearDown(self):
        """Clean up test fixtures after each test."""
        # Delete all workout exercises and workout logs
        WorkoutExercise.objects.all().delete()
        WorkoutLog.objects.all().delete()
    
    @given(
        sets=st.integers(min_value=1, max_value=100),
        reps=st.integers(min_value=1, max_value=100),
        weight=st.decimals(
            min_value=Decimal('0.11'),  # Slightly above 0.1 to avoid precision issues
            max_value=Decimal('1000'),
            places=2,
            allow_nan=False,
            allow_infinity=False
        )
    )
    @settings(max_examples=100)
    def test_property_7_input_validation_ranges_valid(self, sets, reps, weight):
        """
        Feature: workout-tracking-system, Property 7: Input Validation Ranges
        For any workout submission, the system should accept inputs within valid ranges:
        - sets: 1-100
        - reps: 1-100
        - weight: 0.1-1000 kg
        
        **Validates: Requirements 2.5, 2.6, 2.7, 9.1, 9.2, 9.3, 9.9**
        
        This test verifies that valid inputs are accepted.
        """
        workout_exercise = WorkoutExercise(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=sets,
            reps=reps,
            weight=weight,
            order=0
        )
        
        # Should not raise ValidationError for valid inputs
        try:
            workout_exercise.full_clean()
            workout_exercise.save()
        except ValidationError as e:
            self.fail(
                f"Valid inputs (sets={sets}, reps={reps}, weight={weight}) "
                f"were rejected: {e}"
            )
        finally:
            # Cleanup
            WorkoutExercise.objects.filter(
                workout_log=self.workout_log,
                exercise=self.exercise
            ).delete()
    
    @given(
        sets=st.integers().filter(lambda x: x < 1 or x > 100)
    )
    @settings(max_examples=100)
    def test_property_7_input_validation_ranges_invalid_sets(self, sets):
        """
        Feature: workout-tracking-system, Property 7: Input Validation Ranges
        
        This test verifies that invalid sets (outside 1-100) are rejected.
        """
        workout_exercise = WorkoutExercise(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=sets,
            reps=10,
            weight=Decimal('50.0'),
            order=0
        )
        
        # Should raise ValidationError for invalid sets
        with self.assertRaises(ValidationError) as context:
            workout_exercise.full_clean()
        
        # Check that the error is related to sets field
        self.assertTrue(
            'sets' in context.exception.message_dict,
            f"Expected 'sets' validation error for sets={sets}, "
            f"got: {context.exception.message_dict}"
        )
    
    @given(
        reps=st.integers().filter(lambda x: x < 1 or x > 100)
    )
    @settings(max_examples=100)
    def test_property_7_input_validation_ranges_invalid_reps(self, reps):
        """
        Feature: workout-tracking-system, Property 7: Input Validation Ranges
        
        This test verifies that invalid reps (outside 1-100) are rejected.
        """
        workout_exercise = WorkoutExercise(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=3,
            reps=reps,
            weight=Decimal('50.0'),
            order=0
        )
        
        # Should raise ValidationError for invalid reps
        with self.assertRaises(ValidationError) as context:
            workout_exercise.full_clean()
        
        # Check that the error is related to reps field
        self.assertTrue(
            'reps' in context.exception.message_dict,
            f"Expected 'reps' validation error for reps={reps}, "
            f"got: {context.exception.message_dict}"
        )
    
    @given(
        weight=st.one_of(
            st.decimals(
                min_value=Decimal('-1000'),
                max_value=Decimal('0.09'),
                places=2,
                allow_nan=False,
                allow_infinity=False
            ),
            st.decimals(
                min_value=Decimal('1000.01'),
                max_value=Decimal('10000'),
                places=2,
                allow_nan=False,
                allow_infinity=False
            )
        )
    )
    @settings(max_examples=100)
    def test_property_7_input_validation_ranges_invalid_weight(self, weight):
        """
        Feature: workout-tracking-system, Property 7: Input Validation Ranges
        
        This test verifies that invalid weight (outside 0.1-1000 kg) is rejected.
        """
        workout_exercise = WorkoutExercise(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=3,
            reps=10,
            weight=weight,
            order=0
        )
        
        # Should raise ValidationError for invalid weight
        with self.assertRaises(ValidationError) as context:
            workout_exercise.full_clean()
        
        # Check that the error is related to weight field
        self.assertTrue(
            'weight' in context.exception.message_dict,
            f"Expected 'weight' validation error for weight={weight}, "
            f"got: {context.exception.message_dict}"
        )



class WorkoutExerciseCalculateVolumeTests(TestCase):
    """Unit tests for WorkoutExercise calculate_volume method."""
    
    def setUp(self):
        """Set up test fixtures."""
        # Create a test user
        self.user = User.objects.create_user(
            email='test_volume@example.com',
            password='testpass123'
        )
        
        # Create a test exercise
        self.exercise = Exercise.objects.create(
            name='Test Exercise for Volume',
            description='Test description',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            instructions='Test instructions'
        )
        
        # Create a test workout log
        self.workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Test Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
    
    def tearDown(self):
        """Clean up test fixtures."""
        WorkoutExercise.objects.all().delete()
        WorkoutLog.objects.all().delete()
        Exercise.objects.all().delete()
        User.objects.all().delete()
    
    def test_calculate_volume_basic(self):
        """
        Test volume calculation: sets * reps * weight
        
        **Validates: Requirements 2.10**
        """
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        expected_volume = 3 * 10 * 100.00
        actual_volume = workout_exercise.calculate_volume()
        
        self.assertEqual(actual_volume, expected_volume)
    
    def test_calculate_volume_single_set(self):
        """Test volume calculation with single set."""
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=1,
            reps=5,
            weight=Decimal('50.00'),
            order=0
        )
        
        expected_volume = 1 * 5 * 50.00
        actual_volume = workout_exercise.calculate_volume()
        
        self.assertEqual(actual_volume, expected_volume)
    
    def test_calculate_volume_high_reps(self):
        """Test volume calculation with high reps."""
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=4,
            reps=20,
            weight=Decimal('25.50'),
            order=0
        )
        
        expected_volume = 4 * 20 * 25.50
        actual_volume = workout_exercise.calculate_volume()
        
        self.assertEqual(actual_volume, expected_volume)
    
    def test_calculate_volume_decimal_weight(self):
        """Test volume calculation with decimal weight."""
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=3,
            reps=12,
            weight=Decimal('75.25'),
            order=0
        )
        
        expected_volume = 3 * 12 * 75.25
        actual_volume = workout_exercise.calculate_volume()
        
        self.assertEqual(actual_volume, expected_volume)
    
    def test_calculate_volume_minimum_weight(self):
        """Test volume calculation with minimum weight (0.1 kg)."""
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=5,
            reps=15,
            weight=Decimal('0.10'),
            order=0
        )
        
        expected_volume = 5 * 15 * 0.10
        actual_volume = workout_exercise.calculate_volume()
        
        self.assertAlmostEqual(actual_volume, expected_volume, places=2)
    
    def test_calculate_volume_maximum_values(self):
        """Test volume calculation with maximum allowed values."""
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=100,
            reps=100,
            weight=Decimal('1000.00'),
            order=0
        )
        
        expected_volume = 100 * 100 * 1000.00
        actual_volume = workout_exercise.calculate_volume()
        
        self.assertEqual(actual_volume, expected_volume)
    
    def test_calculate_volume_returns_float(self):
        """Test that calculate_volume returns a float."""
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=self.workout_log,
            exercise=self.exercise,
            sets=3,
            reps=10,
            weight=Decimal('50.00'),
            order=0
        )
        
        volume = workout_exercise.calculate_volume()
        
        self.assertIsInstance(volume, float)
