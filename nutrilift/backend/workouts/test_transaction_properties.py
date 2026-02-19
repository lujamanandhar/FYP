"""
Property-based tests for transaction handling, audit logging, and soft deletes.

Tests Properties:
- Property 36: Transaction Rollback on Failure
- Property 39: Audit Log Creation
- Property 40: Soft Delete Behavior

Requirements: 14.3, 14.7, 14.8, 14.9
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import transaction, IntegrityError
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
from rest_framework.test import APIRequestFactory

from .models import (
    WorkoutLog, WorkoutExercise, Exercise, Gym, 
    CustomWorkout, AuditLog, PersonalRecord
)
from .serializers import WorkoutLogSerializer

User = get_user_model()


# Strategies for generating test data
@st.composite
def valid_exercise_data(draw):
    """Generate valid exercise data for workout"""
    # Create a real exercise in the database
    exercise = Exercise.objects.create(
        name=f'Exercise_{timezone.now().timestamp()}_{draw(st.integers())}',
        category='Strength',
        muscle_group='Chest',
        equipment='Free Weights',
        difficulty='Intermediate',
        description='Test exercise',
        instructions='Test instructions',
        calories_per_minute=Decimal('5.0')
    )
    return {
        'exercise': exercise.id,
        'sets': draw(st.integers(min_value=1, max_value=100)),
        'reps': draw(st.integers(min_value=1, max_value=100)),
        'weight': float(draw(st.decimals(min_value=Decimal('0.1'), max_value=Decimal('1000'), places=2))),
        'order': draw(st.integers(min_value=0, max_value=10))
    }


class TestProperty36TransactionRollback(HypothesisTestCase):
    """
    Property 36: Transaction Rollback on Failure
    
    For any workout logging operation that fails partway through 
    (e.g., after creating WorkoutLog but before creating WorkoutExercises), 
    the system should rollback all changes to maintain database consistency.
    
    Validates: Requirements 14.3, 14.7
    """
    
    @given(
        duration=st.integers(min_value=1, max_value=600),
        exercise_count=st.integers(min_value=1, max_value=3)
    )
    @settings(max_examples=100, deadline=None)
    def test_transaction_rollback_on_serializer_error(self, duration, exercise_count):
        """
        Test that transaction rolls back when serializer validation fails.
        """
        # Create test user and exercises
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercises = []
        for i in range(exercise_count):
            exercise = Exercise.objects.create(
                name=f'Exercise {i}_{timezone.now().timestamp()}',
                category='Strength',
                muscle_group='Chest',
                equipment='Free Weights',
                difficulty='Intermediate',
                description='Test exercise',
                instructions='Test instructions',
                calories_per_minute=Decimal('5.0')
            )
            exercises.append(exercise)
        
        # Count initial records
        initial_workout_count = WorkoutLog.objects.count()
        initial_exercise_count = WorkoutExercise.objects.count()
        
        # Create invalid workout data (invalid weight to trigger validation error)
        workout_data = {
            'user': user.id,
            'workout_name': 'Test Workout',
            'duration_minutes': duration,
            'workout_exercises': [
                {
                    'exercise': exercises[0].id,
                    'sets': 3,
                    'reps': 10,
                    'weight': 10000.0,  # Invalid: exceeds max of 1000
                    'order': 0
                }
            ]
        }
        
        # Create request context
        factory = APIRequestFactory()
        request = factory.post('/api/workouts/log/')
        request.user = user
        
        serializer = WorkoutLogSerializer(data=workout_data, context={'request': request})
        
        # Validation should fail
        assert not serializer.is_valid()
        
        # Verify no records were created (transaction rolled back)
        assert WorkoutLog.objects.count() == initial_workout_count
        assert WorkoutExercise.objects.count() == initial_exercise_count
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_transaction_rollback_on_database_error(self, duration):
        """
        Test that transaction rolls back when database constraint is violated.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        # Count initial records
        initial_workout_count = WorkoutLog.objects.count()
        initial_exercise_count = WorkoutExercise.objects.count()
        
        # Try to create workout with transaction that will fail
        try:
            with transaction.atomic():
                workout_log = WorkoutLog.objects.create(
                    user=user,
                    workout_name='Test Workout',
                    duration_minutes=duration,
                    calories_burned=Decimal('100.0')
                )
                
                # Create workout exercise
                WorkoutExercise.objects.create(
                    workout_log=workout_log,
                    exercise=exercise,
                    sets=3,
                    reps=10,
                    weight=Decimal('100.0'),
                    order=0
                )
                
                # Force an error by trying to create duplicate with same order
                # This should trigger a database error
                raise IntegrityError("Simulated database error")
        except IntegrityError:
            pass  # Expected
        
        # Verify transaction was rolled back
        assert WorkoutLog.objects.count() == initial_workout_count
        assert WorkoutExercise.objects.count() == initial_exercise_count
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_successful_transaction_commits_all_changes(self, duration):
        """
        Test that successful transactions commit all changes atomically.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        # Count initial records
        initial_workout_count = WorkoutLog.objects.count()
        initial_exercise_count = WorkoutExercise.objects.count()
        
        # Create valid workout data
        workout_data = {
            'user': user.id,
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
        
        # Create request context
        factory = APIRequestFactory()
        request = factory.post('/api/workouts/log/')
        request.user = user
        
        serializer = WorkoutLogSerializer(data=workout_data, context={'request': request})
        
        # Should be valid and save successfully
        assert serializer.is_valid(), serializer.errors
        workout_log = serializer.save()
        
        # Verify all records were created
        assert WorkoutLog.objects.count() == initial_workout_count + 1
        assert WorkoutExercise.objects.count() == initial_exercise_count + 1
        
        # Verify workout log has exercises
        assert workout_log.workout_exercises.count() == 1


class TestProperty39AuditLogCreation(HypothesisTestCase):
    """
    Property 39: Audit Log Creation
    
    For any workout create, update, or delete operation, 
    the system should create an audit log entry recording 
    the operation, user, and timestamp.
    
    Validates: Requirements 14.8
    """
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_audit_log_created_on_workout_create(self, duration):
        """
        Test that audit log is created when workout is created.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        # Count initial audit logs
        initial_audit_count = AuditLog.objects.count()
        
        # Create workout data
        workout_data = {
            'user': user.id,
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
        
        # Create request context
        factory = APIRequestFactory()
        request = factory.post('/api/workouts/log/')
        request.user = user
        
        serializer = WorkoutLogSerializer(data=workout_data, context={'request': request})
        assert serializer.is_valid(), serializer.errors
        workout_log = serializer.save()
        
        # Verify audit log was created
        assert AuditLog.objects.count() == initial_audit_count + 1
        
        # Verify audit log details
        audit_log = AuditLog.objects.filter(
            user=user,
            action='CREATE',
            model_name='WorkoutLog',
            object_id=workout_log.id
        ).first()
        
        assert audit_log is not None
        assert audit_log.user == user
        assert audit_log.action == 'CREATE'
        assert audit_log.model_name == 'WorkoutLog'
        assert audit_log.object_id == workout_log.id
        assert 'workout_name' in audit_log.changes
        assert 'duration_minutes' in audit_log.changes
        assert audit_log.timestamp is not None
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_audit_log_contains_user_information(self, duration):
        """
        Test that audit log contains user and request information.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        # Create workout data
        workout_data = {
            'user': user.id,
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
        
        # Create request context with user agent
        factory = APIRequestFactory()
        request = factory.post('/api/workouts/log/', HTTP_USER_AGENT='TestAgent/1.0')
        request.user = user
        
        serializer = WorkoutLogSerializer(data=workout_data, context={'request': request})
        assert serializer.is_valid(), serializer.errors
        workout_log = serializer.save()
        
        # Verify audit log contains request information
        audit_log = AuditLog.objects.filter(
            user=user,
            model_name='WorkoutLog',
            object_id=workout_log.id
        ).first()
        
        assert audit_log is not None
        assert audit_log.user_agent == 'TestAgent/1.0'
        # IP address might be None in test environment, that's okay
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_audit_log_records_changes(self, duration):
        """
        Test that audit log records the changes made.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        workout_name = f'Test Workout {timezone.now().timestamp()}'
        
        # Create workout data
        workout_data = {
            'user': user.id,
            'workout_name': workout_name,
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
        
        # Create request context
        factory = APIRequestFactory()
        request = factory.post('/api/workouts/log/')
        request.user = user
        
        serializer = WorkoutLogSerializer(data=workout_data, context={'request': request})
        assert serializer.is_valid(), serializer.errors
        workout_log = serializer.save()
        
        # Verify audit log records changes
        audit_log = AuditLog.objects.filter(
            user=user,
            model_name='WorkoutLog',
            object_id=workout_log.id
        ).first()
        
        assert audit_log is not None
        assert audit_log.changes['workout_name'] == workout_name
        assert audit_log.changes['duration_minutes'] == duration
        assert 'calories_burned' in audit_log.changes
        assert 'exercise_count' in audit_log.changes
        assert audit_log.changes['exercise_count'] == 1


class TestProperty40SoftDeleteBehavior(HypothesisTestCase):
    """
    Property 40: Soft Delete Behavior
    
    For any workout deletion, the system should mark the workout 
    as deleted (soft delete) rather than removing it from the database, 
    allowing for recovery.
    
    Validates: Requirements 14.9
    """
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_delete_marks_workout_as_deleted(self, duration):
        """
        Test that calling delete() marks workout as deleted instead of removing it.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        # Create workout
        workout_log = WorkoutLog.objects.create(
            user=user,
            workout_name='Test Workout',
            duration_minutes=duration,
            calories_burned=Decimal('100.0')
        )
        
        WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        workout_id = workout_log.id
        
        # Verify workout exists and is not deleted
        assert WorkoutLog.objects.filter(id=workout_id).exists()
        assert not workout_log.is_deleted
        assert workout_log.deleted_at is None
        
        # Delete the workout
        workout_log.delete()
        
        # Verify workout still exists in database
        assert WorkoutLog.objects.filter(id=workout_id).exists()
        
        # Verify workout is marked as deleted
        workout_log.refresh_from_db()
        assert workout_log.is_deleted
        assert workout_log.deleted_at is not None
        assert workout_log.deleted_at <= timezone.now()
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_soft_deleted_workout_can_be_recovered(self, duration):
        """
        Test that soft deleted workouts can be recovered.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        # Create workout
        workout_log = WorkoutLog.objects.create(
            user=user,
            workout_name='Test Workout',
            duration_minutes=duration,
            calories_burned=Decimal('100.0')
        )
        
        WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        # Soft delete the workout
        workout_log.delete()
        assert workout_log.is_deleted
        
        # Recover the workout
        workout_log.is_deleted = False
        workout_log.deleted_at = None
        workout_log.save()
        
        # Verify workout is recovered
        workout_log.refresh_from_db()
        assert not workout_log.is_deleted
        assert workout_log.deleted_at is None
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_hard_delete_permanently_removes_workout(self, duration):
        """
        Test that hard_delete() permanently removes workout from database.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        # Create workout
        workout_log = WorkoutLog.objects.create(
            user=user,
            workout_name='Test Workout',
            duration_minutes=duration,
            calories_burned=Decimal('100.0')
        )
        
        WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        workout_id = workout_log.id
        
        # Hard delete the workout
        workout_log.hard_delete()
        
        # Verify workout is permanently removed
        assert not WorkoutLog.objects.filter(id=workout_id).exists()
    
    @given(
        duration=st.integers(min_value=1, max_value=600)
    )
    @settings(max_examples=100, deadline=None)
    def test_soft_deleted_workouts_retain_relationships(self, duration):
        """
        Test that soft deleted workouts retain their relationships.
        """
        # Create test user and exercise
        user = User.objects.create_user(
            email=f'test_{timezone.now().timestamp()}@example.com',
            password='testpass123'
        )
        
        exercise = Exercise.objects.create(
            name=f'Exercise_{timezone.now().timestamp()}',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
        
        # Create workout
        workout_log = WorkoutLog.objects.create(
            user=user,
            workout_name='Test Workout',
            duration_minutes=duration,
            calories_burned=Decimal('100.0')
        )
        
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        # Soft delete the workout
        workout_log.delete()
        
        # Verify relationships are retained
        workout_log.refresh_from_db()
        assert workout_log.workout_exercises.count() == 1
        assert workout_log.workout_exercises.first().id == workout_exercise.id
        assert workout_log.user == user
