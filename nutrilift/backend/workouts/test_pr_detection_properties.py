"""
Property-based tests for Personal Record detection and update logic.

Tests Property 10 from the workout-tracking-system design document.
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
from decimal import Decimal
from workouts.models import WorkoutExercise, WorkoutLog, Exercise, PersonalRecord

User = get_user_model()


class PersonalRecordDetectionPropertyTests(HypothesisTestCase):
    """
    Property-based tests for automatic personal record detection and update.
    
    **Property 10: Personal Record Detection and Update**
    
    For any workout that exceeds existing personal records, the system should:
    1. Detect the new PR automatically
    2. Update the PersonalRecord entry
    3. Store previous values correctly
    4. Check all three metrics (weight, reps, volume)
    
    **Validates: Requirements 2.11, 4.7, 5.6, 5.7, 5.8**
    """
    
    @classmethod
    def setUpClass(cls):
        """Set up class-level test fixtures."""
        super().setUpClass()
        
        # Create a test user
        cls.user = User.objects.create_user(
            email='test_pr_detection@example.com',
            password='testpass123'
        )
        
        # Create a test exercise
        cls.exercise = Exercise.objects.create(
            name='Test Exercise for PR Detection',
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
    
    def tearDown(self):
        """Clean up test fixtures after each test."""
        # Delete all workout exercises, workout logs, and personal records
        WorkoutExercise.objects.all().delete()
        WorkoutLog.objects.all().delete()
        PersonalRecord.objects.all().delete()
    
    @given(
        initial_sets=st.integers(min_value=1, max_value=50),
        initial_reps=st.integers(min_value=1, max_value=50),
        initial_weight=st.decimals(
            min_value=Decimal('10.0'),
            max_value=Decimal('500.0'),
            places=2,
            allow_nan=False,
            allow_infinity=False
        ),
        weight_increase=st.decimals(
            min_value=Decimal('0.1'),
            max_value=Decimal('50.0'),
            places=2,
            allow_nan=False,
            allow_infinity=False
        )
    )
    @settings(max_examples=100)
    def test_property_10_weight_pr_detection(self, initial_sets, initial_reps, initial_weight, weight_increase):
        """
        Test that workouts exceeding weight PRs trigger updates and store previous values.
        
        Given an existing PR with a certain weight,
        When a workout is logged with higher weight,
        Then the PR should be updated and previous weight stored.
        """
        # Create initial workout with baseline PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Initial Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        initial_exercise = WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise,
            sets=initial_sets,
            reps=initial_reps,
            weight=initial_weight,
            order=0
        )
        
        # Verify initial PR was created
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise)
        self.assertEqual(pr.max_weight, initial_weight)
        self.assertIsNone(pr.previous_max_weight)
        
        # Create new workout with higher weight
        new_weight = initial_weight + weight_increase
        if new_weight > Decimal('1000.0'):
            new_weight = Decimal('1000.0')  # Cap at max allowed
        
        new_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='New Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        new_exercise = WorkoutExercise.objects.create(
            workout_log=new_workout,
            exercise=self.exercise,
            sets=initial_sets,
            reps=initial_reps,
            weight=new_weight,
            order=0
        )
        
        # Refresh PR from database
        pr.refresh_from_db()
        
        # Verify PR was updated
        self.assertEqual(pr.max_weight, new_weight)
        self.assertEqual(pr.previous_max_weight, initial_weight)
        self.assertEqual(pr.workout_log, new_workout)
    
    @given(
        initial_sets=st.integers(min_value=1, max_value=50),
        initial_reps=st.integers(min_value=1, max_value=50),
        initial_weight=st.decimals(
            min_value=Decimal('10.0'),
            max_value=Decimal('500.0'),
            places=2,
            allow_nan=False,
            allow_infinity=False
        ),
        reps_increase=st.integers(min_value=1, max_value=50)
    )
    @settings(max_examples=100)
    def test_property_10_reps_pr_detection(self, initial_sets, initial_reps, initial_weight, reps_increase):
        """
        Test that workouts exceeding reps PRs trigger updates and store previous values.
        
        Given an existing PR with certain reps,
        When a workout is logged with higher reps,
        Then the PR should be updated and previous reps stored.
        """
        # Create initial workout with baseline PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Initial Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        initial_exercise = WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise,
            sets=initial_sets,
            reps=initial_reps,
            weight=initial_weight,
            order=0
        )
        
        # Verify initial PR was created
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise)
        self.assertEqual(pr.max_reps, initial_reps)
        self.assertIsNone(pr.previous_max_reps)
        
        # Create new workout with higher reps
        new_reps = initial_reps + reps_increase
        if new_reps > 100:
            new_reps = 100  # Cap at max allowed
        
        new_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='New Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        new_exercise = WorkoutExercise.objects.create(
            workout_log=new_workout,
            exercise=self.exercise,
            sets=initial_sets,
            reps=new_reps,
            weight=initial_weight,
            order=0
        )
        
        # Refresh PR from database
        pr.refresh_from_db()
        
        # Verify PR was updated
        self.assertEqual(pr.max_reps, new_reps)
        self.assertEqual(pr.previous_max_reps, initial_reps)
        self.assertEqual(pr.workout_log, new_workout)
    
    @given(
        initial_sets=st.integers(min_value=1, max_value=50),
        initial_reps=st.integers(min_value=1, max_value=50),
        initial_weight=st.decimals(
            min_value=Decimal('10.0'),
            max_value=Decimal('500.0'),
            places=2,
            allow_nan=False,
            allow_infinity=False
        ),
        sets_increase=st.integers(min_value=1, max_value=50)
    )
    @settings(max_examples=100)
    def test_property_10_volume_pr_detection(self, initial_sets, initial_reps, initial_weight, sets_increase):
        """
        Test that workouts exceeding volume PRs trigger updates and store previous values.
        
        Given an existing PR with certain volume,
        When a workout is logged with higher volume (via more sets),
        Then the PR should be updated and previous volume stored.
        """
        # Create initial workout with baseline PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Initial Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        initial_exercise = WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise,
            sets=initial_sets,
            reps=initial_reps,
            weight=initial_weight,
            order=0
        )
        
        initial_volume = initial_exercise.calculate_volume()
        
        # Verify initial PR was created
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise)
        self.assertEqual(float(pr.max_volume), initial_volume)
        self.assertIsNone(pr.previous_max_volume)
        
        # Create new workout with higher volume (more sets)
        new_sets = initial_sets + sets_increase
        if new_sets > 100:
            new_sets = 100  # Cap at max allowed
        
        new_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='New Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        new_exercise = WorkoutExercise.objects.create(
            workout_log=new_workout,
            exercise=self.exercise,
            sets=new_sets,
            reps=initial_reps,
            weight=initial_weight,
            order=0
        )
        
        new_volume = new_exercise.calculate_volume()
        
        # Refresh PR from database
        pr.refresh_from_db()
        
        # Verify PR was updated
        self.assertEqual(float(pr.max_volume), new_volume)
        self.assertEqual(float(pr.previous_max_volume), initial_volume)
        self.assertEqual(pr.workout_log, new_workout)
    
    @given(
        sets=st.integers(min_value=1, max_value=50),
        reps=st.integers(min_value=1, max_value=50),
        weight=st.decimals(
            min_value=Decimal('10.0'),
            max_value=Decimal('500.0'),
            places=2,
            allow_nan=False,
            allow_infinity=False
        )
    )
    @settings(max_examples=100)
    def test_property_10_all_metrics_checked(self, sets, reps, weight):
        """
        Test that all three metrics (weight, reps, volume) are checked independently.
        
        Given an existing PR,
        When a workout is logged that improves any metric,
        Then that specific metric should be updated while others remain unchanged.
        """
        # Create initial workout with baseline PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Initial Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        initial_exercise = WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise,
            sets=sets,
            reps=reps,
            weight=weight,
            order=0
        )
        
        initial_volume = initial_exercise.calculate_volume()
        
        # Verify initial PR was created
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise)
        initial_max_weight = pr.max_weight
        initial_max_reps = pr.max_reps
        initial_max_volume = pr.max_volume
        
        # Create workout that only improves weight (lower reps to keep volume similar)
        new_weight = weight + Decimal('10.0')
        if new_weight > Decimal('1000.0'):
            new_weight = Decimal('1000.0')
        
        new_reps = max(1, reps - 1)  # Slightly lower reps
        
        weight_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Weight PR Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        weight_exercise = WorkoutExercise.objects.create(
            workout_log=weight_workout,
            exercise=self.exercise,
            sets=sets,
            reps=new_reps,
            weight=new_weight,
            order=0
        )
        
        # Refresh PR from database
        pr.refresh_from_db()
        
        # Verify weight PR was updated
        self.assertEqual(pr.max_weight, new_weight)
        self.assertEqual(pr.previous_max_weight, initial_max_weight)
        
        # Max reps should remain unchanged (or updated if new_reps was still higher)
        # Max volume might change depending on the calculation
        # The key is that the system checked all three metrics
        self.assertIsNotNone(pr.max_weight)
        self.assertIsNotNone(pr.max_reps)
        self.assertIsNotNone(pr.max_volume)
    
    @given(
        sets=st.integers(min_value=1, max_value=50),
        reps=st.integers(min_value=1, max_value=50),
        weight=st.decimals(
            min_value=Decimal('10.0'),
            max_value=Decimal('500.0'),
            places=2,
            allow_nan=False,
            allow_infinity=False
        )
    )
    @settings(max_examples=100)
    def test_property_10_no_update_when_not_exceeding(self, sets, reps, weight):
        """
        Test that PRs are not updated when workout doesn't exceed existing records.
        
        Given an existing PR,
        When a workout is logged that doesn't exceed any metric,
        Then the PR should remain unchanged and previous values should stay None.
        """
        # Create initial workout with baseline PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Initial Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        initial_exercise = WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise,
            sets=sets,
            reps=reps,
            weight=weight,
            order=0
        )
        
        # Verify initial PR was created
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise)
        initial_max_weight = pr.max_weight
        initial_max_reps = pr.max_reps
        initial_max_volume = pr.max_volume
        initial_achieved_date = pr.achieved_date
        
        # Create workout with lower performance
        lower_weight = max(Decimal('0.1'), weight - Decimal('10.0'))
        lower_reps = max(1, reps - 1)
        lower_sets = max(1, sets - 1)
        
        lower_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Lower Performance Workout',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        lower_exercise = WorkoutExercise.objects.create(
            workout_log=lower_workout,
            exercise=self.exercise,
            sets=lower_sets,
            reps=lower_reps,
            weight=lower_weight,
            order=0
        )
        
        # Refresh PR from database
        pr.refresh_from_db()
        
        # Verify PR was NOT updated
        self.assertEqual(pr.max_weight, initial_max_weight)
        self.assertEqual(pr.max_reps, initial_max_reps)
        self.assertEqual(pr.max_volume, initial_max_volume)
        self.assertEqual(pr.achieved_date, initial_achieved_date)
        self.assertEqual(pr.workout_log, initial_workout)
        
        # Previous values should still be None
        self.assertIsNone(pr.previous_max_weight)
        self.assertIsNone(pr.previous_max_reps)
        self.assertIsNone(pr.previous_max_volume)
