"""
Simple tests for transaction handling, audit logging, and soft deletes.
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import transaction, IntegrityError
from rest_framework.test import APIRequestFactory

from .models import (
    WorkoutLog, WorkoutExercise, Exercise, AuditLog
)
from .serializers import WorkoutLogSerializer

User = get_user_model()


class TestTransactionRollback(TestCase):
    """Test Property 36: Transaction Rollback on Failure"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.exercise = Exercise.objects.create(
            name='Test Exercise',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
    
    def test_transaction_rollback_on_validation_error(self):
        """Test that transaction rolls back when validation fails"""
        initial_workout_count = WorkoutLog.objects.count()
        initial_exercise_count = WorkoutExercise.objects.count()
        
        # Create invalid workout data (weight exceeds max)
        workout_data = {
            'user': self.user.id,
            'workout_name': 'Test Workout',
            'duration_minutes': 60,
            'workout_exercises': [
                {
                    'exercise': self.exercise.id,
                    'sets': 3,
                    'reps': 10,
                    'weight': 10000.0,  # Invalid: exceeds max of 1000
                    'order': 0
                }
            ]
        }
        
        factory = APIRequestFactory()
        request = factory.post('/api/workouts/log/')
        request.user = self.user
        
        serializer = WorkoutLogSerializer(data=workout_data, context={'request': request})
        
        # Validation should fail
        self.assertFalse(serializer.is_valid())
        
        # Verify no records were created
        self.assertEqual(WorkoutLog.objects.count(), initial_workout_count)
        self.assertEqual(WorkoutExercise.objects.count(), initial_exercise_count)
    
    def test_successful_transaction_commits_all_changes(self):
        """Test that successful transactions commit all changes"""
        initial_workout_count = WorkoutLog.objects.count()
        initial_exercise_count = WorkoutExercise.objects.count()
        
        # Create valid workout data
        workout_data = {
            'user': self.user.id,
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
        
        factory = APIRequestFactory()
        request = factory.post('/api/workouts/log/')
        request.user = self.user
        
        serializer = WorkoutLogSerializer(data=workout_data, context={'request': request})
        
        # Should be valid and save successfully
        self.assertTrue(serializer.is_valid(), serializer.errors)
        workout_log = serializer.save()
        
        # Verify all records were created
        self.assertEqual(WorkoutLog.objects.count(), initial_workout_count + 1)
        self.assertEqual(WorkoutExercise.objects.count(), initial_exercise_count + 1)
        self.assertEqual(workout_log.workout_exercises.count(), 1)


class TestAuditLogCreation(TestCase):
    """Test Property 39: Audit Log Creation"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.exercise = Exercise.objects.create(
            name='Test Exercise',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
    
    def test_audit_log_created_on_workout_create(self):
        """Test that audit log is created when workout is created"""
        initial_audit_count = AuditLog.objects.count()
        
        workout_data = {
            'user': self.user.id,
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
        
        factory = APIRequestFactory()
        request = factory.post('/api/workouts/log/')
        request.user = self.user
        
        serializer = WorkoutLogSerializer(data=workout_data, context={'request': request})
        self.assertTrue(serializer.is_valid(), serializer.errors)
        workout_log = serializer.save()
        
        # Verify audit log was created
        self.assertEqual(AuditLog.objects.count(), initial_audit_count + 1)
        
        # Verify audit log details
        audit_log = AuditLog.objects.filter(
            user=self.user,
            action='CREATE',
            model_name='WorkoutLog',
            object_id=workout_log.id
        ).first()
        
        self.assertIsNotNone(audit_log)
        self.assertEqual(audit_log.user, self.user)
        self.assertEqual(audit_log.action, 'CREATE')
        self.assertEqual(audit_log.model_name, 'WorkoutLog')
        self.assertEqual(audit_log.object_id, workout_log.id)
        self.assertIn('workout_name', audit_log.changes)
        self.assertIn('duration_minutes', audit_log.changes)
        self.assertIsNotNone(audit_log.timestamp)


class TestSoftDeleteBehavior(TestCase):
    """Test Property 40: Soft Delete Behavior"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.exercise = Exercise.objects.create(
            name='Test Exercise',
            category='Strength',
            muscle_group='Chest',
            equipment='Free Weights',
            difficulty='Intermediate',
            description='Test exercise',
            instructions='Test instructions',
            calories_per_minute=Decimal('5.0')
        )
    
    def test_delete_marks_workout_as_deleted(self):
        """Test that calling delete() marks workout as deleted"""
        workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Test Workout',
            duration_minutes=60,
            calories_burned=Decimal('100.0')
        )
        
        WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=self.exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        workout_id = workout_log.id
        
        # Verify workout exists and is not deleted
        self.assertTrue(WorkoutLog.objects.filter(id=workout_id).exists())
        self.assertFalse(workout_log.is_deleted)
        self.assertIsNone(workout_log.deleted_at)
        
        # Delete the workout
        workout_log.delete()
        
        # Verify workout still exists in database
        self.assertTrue(WorkoutLog.objects.filter(id=workout_id).exists())
        
        # Verify workout is marked as deleted
        workout_log.refresh_from_db()
        self.assertTrue(workout_log.is_deleted)
        self.assertIsNotNone(workout_log.deleted_at)
        self.assertLessEqual(workout_log.deleted_at, timezone.now())
    
    def test_soft_deleted_workout_can_be_recovered(self):
        """Test that soft deleted workouts can be recovered"""
        workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Test Workout',
            duration_minutes=60,
            calories_burned=Decimal('100.0')
        )
        
        # Soft delete the workout
        workout_log.delete()
        self.assertTrue(workout_log.is_deleted)
        
        # Recover the workout
        workout_log.is_deleted = False
        workout_log.deleted_at = None
        workout_log.save()
        
        # Verify workout is recovered
        workout_log.refresh_from_db()
        self.assertFalse(workout_log.is_deleted)
        self.assertIsNone(workout_log.deleted_at)
    
    def test_hard_delete_permanently_removes_workout(self):
        """Test that hard_delete() permanently removes workout"""
        workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Test Workout',
            duration_minutes=60,
            calories_burned=Decimal('100.0')
        )
        
        workout_id = workout_log.id
        
        # Hard delete the workout
        workout_log.hard_delete()
        
        # Verify workout is permanently removed
        self.assertFalse(WorkoutLog.objects.filter(id=workout_id).exists())
    
    def test_soft_deleted_workouts_retain_relationships(self):
        """Test that soft deleted workouts retain their relationships"""
        workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Test Workout',
            duration_minutes=60,
            calories_burned=Decimal('100.0')
        )
        
        workout_exercise = WorkoutExercise.objects.create(
            workout_log=workout_log,
            exercise=self.exercise,
            sets=3,
            reps=10,
            weight=Decimal('100.0'),
            order=0
        )
        
        # Soft delete the workout
        workout_log.delete()
        
        # Verify relationships are retained
        workout_log.refresh_from_db()
        self.assertEqual(workout_log.workout_exercises.count(), 1)
        self.assertEqual(workout_log.workout_exercises.first().id, workout_exercise.id)
        self.assertEqual(workout_log.user, self.user)
