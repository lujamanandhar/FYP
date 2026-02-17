"""
Unit tests for PersonalRecord model improvement percentage calculation.
Tests requirement 4.3: Calculate improvement percentage over previous records.
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from workouts.models import Exercise, PersonalRecord, WorkoutLog

User = get_user_model()


class TestPersonalRecordImprovementPercentage(TestCase):
    """Test suite for PersonalRecord.get_improvement_percentage() method"""

    def setUp(self):
        """Set up test fixtures"""
        self.user = User.objects.create_user(
            email='testuser@example.com',
            password='testpass123'
        )
        
        self.exercise = Exercise.objects.create(
            name='Bench Press',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE'
        )
        
        self.workout_log = WorkoutLog.objects.create(
            user=self.user,
            workout_name='Push Day',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )

    def test_improvement_percentage_with_weight_improvement(self):
        """Test improvement percentage calculation when weight increases"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('120.00'),
            max_reps=10,
            max_volume=Decimal('1200.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('100.00'),
            previous_max_reps=10,
            previous_max_volume=Decimal('1000.00')
        )
        
        # Weight improved by 20% (from 100 to 120)
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        self.assertAlmostEqual(improvement, 20.0, places=2)

    def test_improvement_percentage_with_reps_improvement(self):
        """Test improvement percentage calculation when reps increase"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('100.00'),
            max_reps=12,
            max_volume=Decimal('1200.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('100.00'),
            previous_max_reps=10,
            previous_max_volume=Decimal('1000.00')
        )
        
        # Reps improved by 20% (from 10 to 12)
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        self.assertAlmostEqual(improvement, 20.0, places=2)

    def test_improvement_percentage_with_volume_improvement(self):
        """Test improvement percentage calculation when volume increases"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('100.00'),
            max_reps=10,
            max_volume=Decimal('1500.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('100.00'),
            previous_max_reps=10,
            previous_max_volume=Decimal('1000.00')
        )
        
        # Volume improved by 50% (from 1000 to 1500)
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        self.assertAlmostEqual(improvement, 50.0, places=2)

    def test_improvement_percentage_returns_max_improvement(self):
        """Test that get_improvement_percentage returns the highest improvement among all metrics"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('110.00'),  # 10% improvement
            max_reps=15,  # 50% improvement
            max_volume=Decimal('2475.00'),  # 65% improvement (110 * 15 * 1.5 sets assumed)
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('100.00'),
            previous_max_reps=10,
            previous_max_volume=Decimal('1500.00')
        )
        
        # Should return the highest improvement (volume at 65%)
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        self.assertAlmostEqual(improvement, 65.0, places=2)

    def test_improvement_percentage_with_no_previous_values(self):
        """Test that get_improvement_percentage returns None when no previous values exist"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('120.00'),
            max_reps=10,
            max_volume=Decimal('1200.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=None,
            previous_max_reps=None,
            previous_max_volume=None
        )
        
        improvement = pr.get_improvement_percentage()
        self.assertIsNone(improvement)

    def test_improvement_percentage_with_partial_previous_values(self):
        """Test improvement calculation when only some previous values exist"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('120.00'),
            max_reps=12,
            max_volume=Decimal('1440.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('100.00'),  # 20% improvement
            previous_max_reps=None,
            previous_max_volume=None
        )
        
        # Should return weight improvement since it's the only one available
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        self.assertAlmostEqual(improvement, 20.0, places=2)

    def test_improvement_percentage_with_zero_previous_weight(self):
        """Test that zero previous values are handled correctly (no division by zero)"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('120.00'),
            max_reps=10,
            max_volume=Decimal('1200.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('0.00'),  # Zero weight
            previous_max_reps=10,
            previous_max_volume=Decimal('1000.00')
        )
        
        # Should skip weight calculation and return volume improvement (20%)
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        self.assertAlmostEqual(improvement, 20.0, places=2)

    def test_improvement_percentage_with_negative_improvement(self):
        """Test improvement percentage when performance decreases"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('90.00'),
            max_reps=8,
            max_volume=Decimal('720.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('100.00'),
            previous_max_reps=10,
            previous_max_volume=Decimal('1000.00')
        )
        
        # All metrics decreased, should return the "best" (least negative) improvement
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        # Weight: -10%, Reps: -20%, Volume: -28%
        # Should return -10% (the highest/least negative)
        self.assertAlmostEqual(improvement, -10.0, places=2)

    def test_improvement_percentage_with_small_improvements(self):
        """Test improvement percentage with small decimal improvements"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('100.50'),
            max_reps=10,
            max_volume=Decimal('1005.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('100.00'),
            previous_max_reps=10,
            previous_max_volume=Decimal('1000.00')
        )
        
        # Weight improved by 0.5% (from 100 to 100.5)
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        self.assertAlmostEqual(improvement, 0.5, places=2)

    def test_improvement_percentage_with_large_improvements(self):
        """Test improvement percentage with large improvements"""
        pr = PersonalRecord.objects.create(
            user=self.user,
            exercise=self.exercise,
            max_weight=Decimal('200.00'),
            max_reps=20,
            max_volume=Decimal('4000.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log,
            previous_max_weight=Decimal('100.00'),
            previous_max_reps=10,
            previous_max_volume=Decimal('1000.00')
        )
        
        # Weight doubled (100% improvement), Reps doubled (100% improvement)
        # Volume quadrupled (300% improvement from 1000 to 4000)
        # Should return the highest improvement (volume at 300%)
        improvement = pr.get_improvement_percentage()
        self.assertIsNotNone(improvement)
        self.assertAlmostEqual(improvement, 300.0, places=2)

