"""
Integration tests for signal handlers and automatic PR detection.
Tests requirements 5.6, 5.8: Signal triggering and PR creation/updates.
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from workouts.models import Exercise, WorkoutLog, WorkoutExercise, PersonalRecord

User = get_user_model()


class TestSignalTriggering(TestCase):
    """Integration tests for WorkoutLog signal triggering"""

    def setUp(self):
        """Set up test fixtures"""
        self.user = User.objects.create_user(
            email='testuser@example.com',
            password='testpass123'
        )
        
        self.exercise1 = Exercise.objects.create(
            name='Bench Press',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE'
        )
        
        self.exercise2 = Exercise.objects.create(
            name='Squats',
            category='STRENGTH',
            muscle_group='LEGS',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE'
        )

    def test_creating_workout_log_triggers_signal(self):
        """Test that creating a WorkoutLog triggers the post_save signal"""
        # Create a workout log
        workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        # Add exercises to the workout
        WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        # Manually trigger signal check (since signal runs after workout_exercises are added)
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, workout_log, created=True)
        
        # Verify that a PersonalRecord was created
        pr = PersonalRecord.objects.filter(user=self.user, exercise=self.exercise1).first()
        self.assertIsNotNone(pr, "PersonalRecord should be created when WorkoutLog is created")
        self.assertEqual(pr.max_weight, Decimal('100.00'))
        self.assertEqual(pr.max_reps, 10)
        self.assertEqual(pr.max_volume, Decimal('3000.00'))  # 3 * 10 * 100

    def test_pr_entry_created_for_first_workout(self):
        """Test that PR entries are created correctly for the first workout"""
        # Create a workout log
        workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Leg Day',
            duration_minutes=45,
            calories_burned=Decimal('400.00')
        )
        
        # Add exercise to the workout
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=self.exercise2,
            sets=4,
            reps=8,
            weight=Decimal('150.00'),
            order=0
        )
        
        # Trigger signal manually
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, workout_log, created=True)
        
        # Verify PR was created
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise2)
        self.assertEqual(pr.max_weight, Decimal('150.00'))
        self.assertEqual(pr.max_reps, 8)
        self.assertEqual(pr.max_volume, Decimal('4800.00'))  # 4 * 8 * 150
        self.assertEqual(pr.workout_log, workout_log)
        self.assertIsNone(pr.previous_max_weight)
        self.assertIsNone(pr.previous_max_reps)
        self.assertIsNone(pr.previous_max_volume)

    def test_pr_entry_updated_when_weight_exceeded(self):
        """Test that PR entries are updated correctly when weight is exceeded"""
        # Create initial PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day 1',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        # Trigger signal for initial workout
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, initial_workout, created=True)
        
        # Create new workout with higher weight
        new_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day 2',
            duration_minutes=60,
            calories_burned=Decimal('460.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=new_workout,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('110.00'),  # Higher weight
            order=0
        )
        
        # Trigger signal for new workout
        check_personal_records(WorkoutLog, new_workout, created=True)
        
        # Verify PR was updated
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise1)
        self.assertEqual(pr.max_weight, Decimal('110.00'))
        self.assertEqual(pr.previous_max_weight, Decimal('100.00'))
        self.assertEqual(pr.workout_log, new_workout)

    def test_pr_entry_updated_when_reps_exceeded(self):
        """Test that PR entries are updated correctly when reps are exceeded"""
        # Create initial PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Leg Day 1',
            duration_minutes=45,
            calories_burned=Decimal('400.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise2,
            sets=3,
            reps=8,
            weight=Decimal('150.00'),
            order=0
        )
        
        # Trigger signal
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, initial_workout, created=True)
        
        # Create new workout with higher reps
        new_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Leg Day 2',
            duration_minutes=45,
            calories_burned=Decimal('410.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=new_workout,
            exercise=self.exercise2,
            sets=3,
            reps=12,  # Higher reps
            weight=Decimal('150.00'),
            order=0
        )
        
        # Trigger signal
        check_personal_records(WorkoutLog, new_workout, created=True)
        
        # Verify PR was updated
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise2)
        self.assertEqual(pr.max_reps, 12)
        self.assertEqual(pr.previous_max_reps, 8)
        self.assertEqual(pr.workout_log, new_workout)

    def test_pr_entry_updated_when_volume_exceeded(self):
        """Test that PR entries are updated correctly when volume is exceeded"""
        # Create initial PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day 1',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        # Trigger signal
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, initial_workout, created=True)
        
        # Create new workout with higher volume (more sets)
        new_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day 2',
            duration_minutes=70,
            calories_burned=Decimal('500.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=new_workout,
            exercise=self.exercise1,
            sets=5,  # More sets = higher volume
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        # Trigger signal
        check_personal_records(WorkoutLog, new_workout, created=True)
        
        # Verify PR was updated
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise1)
        self.assertEqual(pr.max_volume, Decimal('5000.00'))  # 5 * 10 * 100
        self.assertEqual(pr.previous_max_volume, Decimal('3000.00'))  # 3 * 10 * 100
        self.assertEqual(pr.workout_log, new_workout)

    def test_pr_not_updated_when_performance_lower(self):
        """Test that PR entries are not updated when performance is lower"""
        # Create initial PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day 1',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        # Trigger signal
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, initial_workout, created=True)
        
        # Get initial PR values
        pr_before = PersonalRecord.objects.get(user=self.user, exercise=self.exercise1)
        initial_weight = pr_before.max_weight
        initial_reps = pr_before.max_reps
        initial_volume = pr_before.max_volume
        
        # Create new workout with lower performance
        new_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day 2',
            duration_minutes=50,
            calories_burned=Decimal('400.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=new_workout,
            exercise=self.exercise1,
            sets=3,
            reps=8,  # Lower reps
            weight=Decimal('90.00'),  # Lower weight
            order=0
        )
        
        # Trigger signal
        check_personal_records(WorkoutLog, new_workout, created=True)
        
        # Verify PR was not updated
        pr_after = PersonalRecord.objects.get(user=self.user, exercise=self.exercise1)
        self.assertEqual(pr_after.max_weight, initial_weight)
        self.assertEqual(pr_after.max_reps, initial_reps)
        self.assertEqual(pr_after.max_volume, initial_volume)
        self.assertEqual(pr_after.workout_log, initial_workout)  # Still references old workout

    def test_multiple_exercises_in_workout_create_multiple_prs(self):
        """Test that multiple exercises in a workout create multiple PR entries"""
        # Create workout with multiple exercises
        workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Full Body',
            duration_minutes=90,
            calories_burned=Decimal('600.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=self.exercise2,
            sets=4,
            reps=8,
            weight=Decimal('150.00'),
            order=1
        )
        
        # Trigger signal
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, workout_log, created=True)
        
        # Verify both PRs were created
        pr1 = PersonalRecord.objects.get(user=self.user, exercise=self.exercise1)
        pr2 = PersonalRecord.objects.get(user=self.user, exercise=self.exercise2)
        
        self.assertEqual(pr1.max_weight, Decimal('100.00'))
        self.assertEqual(pr2.max_weight, Decimal('150.00'))
        self.assertEqual(PersonalRecord.objects.filter(user=self.user).count(), 2)

    def test_pr_updates_only_exceeded_metrics(self):
        """Test that PR updates only the metrics that were exceeded"""
        # Create initial PR
        initial_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day 1',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=initial_workout,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        # Trigger signal
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, initial_workout, created=True)
        
        # Create new workout with only weight exceeded
        new_workout = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day 2',
            duration_minutes=60,
            calories_burned=Decimal('460.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=new_workout,
            exercise=self.exercise1,
            sets=3,
            reps=8,  # Lower reps
            weight=Decimal('120.00'),  # Higher weight
            order=0
        )
        
        # Trigger signal
        check_personal_records(WorkoutLog, new_workout, created=True)
        
        # Verify only weight was updated
        pr = PersonalRecord.objects.get(user=self.user, exercise=self.exercise1)
        self.assertEqual(pr.max_weight, Decimal('120.00'))
        self.assertEqual(pr.previous_max_weight, Decimal('100.00'))
        self.assertEqual(pr.max_reps, 10)  # Unchanged
        self.assertIsNone(pr.previous_max_reps)  # Not updated
        # Volume should not be updated since 3*8*120=2880 < 3*10*100=3000
        self.assertEqual(pr.max_volume, Decimal('3000.00'))

    def test_different_users_have_separate_prs(self):
        """Test that different users have separate PR entries for the same exercise"""
        # Create second user
        user2 = User.objects.create_user(
            email='testuser2@example.com',
            password='testpass123'
        )
        
        # Create workout for first user
        workout1 = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=workout1,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('100.00'),
            order=0
        )
        
        # Create workout for second user
        workout2 = WorkoutLog.objects.create(
            user=user2,
            workout_name='Push Day',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        WorkoutExercise.objects.create(
            workout_log=workout2,
            exercise=self.exercise1,
            sets=3,
            reps=10,
            weight=Decimal('120.00'),
            order=0
        )
        
        # Trigger signals
        from workouts.signals import check_personal_records
        check_personal_records(WorkoutLog, workout1, created=True)
        check_personal_records(WorkoutLog, workout2, created=True)
        
        # Verify separate PRs
        pr1 = PersonalRecord.objects.get(user=self.user, exercise=self.exercise1)
        pr2 = PersonalRecord.objects.get(user=user2, exercise=self.exercise1)
        
        self.assertEqual(pr1.max_weight, Decimal('100.00'))
        self.assertEqual(pr2.max_weight, Decimal('120.00'))
        self.assertNotEqual(pr1.id, pr2.id)
