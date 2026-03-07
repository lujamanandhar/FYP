"""
Unit tests for nutrition signal handlers.

Tests signal handler behavior for progress updates, recalculation, and QuickLog updates.

Requirements: 15.9
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

from nutrition.models import (
    FoodItem, IntakeLog, HydrationLog, 
    NutritionGoals, NutritionProgress, QuickLog
)

User = get_user_model()


class IntakeLogSignalTest(TestCase):
    """Test IntakeLog signal handlers for progress updates."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.food = FoodItem.objects.create(
            name='Test Food',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00')
        )
        
        self.today = timezone.now()
    
    def test_signal_creates_progress_on_first_intake(self):
        """Test that creating an IntakeLog automatically creates NutritionProgress."""
        # Create intake log (should trigger signal)
        intake = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        # Verify NutritionProgress was created
        progress = NutritionProgress.objects.get(
            user=self.user,
            progress_date=self.today.date()
        )
        
        self.assertEqual(progress.total_calories, Decimal('200.00'))
        self.assertEqual(progress.total_protein, Decimal('20.00'))
        self.assertEqual(progress.total_carbs, Decimal('30.00'))
        self.assertEqual(progress.total_fats, Decimal('10.00'))
    
    def test_signal_aggregates_multiple_intakes(self):
        """Test that multiple IntakeLogs are aggregated correctly."""
        # Create first intake log
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        # Create second intake log
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='snack',
            quantity=Decimal('50.00'),
            unit='g',
            calories=Decimal('100.00'),
            protein=Decimal('10.00'),
            carbs=Decimal('15.00'),
            fats=Decimal('5.00'),
            logged_at=self.today
        )
        
        # Verify aggregated totals
        progress = NutritionProgress.objects.get(
            user=self.user,
            progress_date=self.today.date()
        )
        
        self.assertEqual(progress.total_calories, Decimal('300.00'))
        self.assertEqual(progress.total_protein, Decimal('30.00'))
        self.assertEqual(progress.total_carbs, Decimal('45.00'))
        self.assertEqual(progress.total_fats, Decimal('15.00'))
    
    def test_signal_calculates_adherence_with_goals(self):
        """Test that adherence percentages are calculated correctly with goals."""
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('2000.00'),
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00')
        )
        
        # Create intake log (50% of goals)
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('500.00'),
            unit='g',
            calories=Decimal('1000.00'),
            protein=Decimal('75.00'),
            carbs=Decimal('100.00'),
            fats=Decimal('32.50'),
            logged_at=self.today
        )
        
        # Verify adherence percentages
        progress = NutritionProgress.objects.get(user=self.user)
        
        self.assertEqual(progress.calories_adherence, Decimal('50.00'))
        self.assertEqual(progress.protein_adherence, Decimal('50.00'))
        self.assertEqual(progress.carbs_adherence, Decimal('50.00'))
        self.assertEqual(progress.fats_adherence, Decimal('50.00'))
    
    def test_signal_uses_default_goals(self):
        """Test that default goals are used when user has no goals set."""
        # Create intake log without setting goals
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('1000.00'),
            unit='g',
            calories=Decimal('2000.00'),
            protein=Decimal('150.00'),
            carbs=Decimal('200.00'),
            fats=Decimal('65.00'),
            logged_at=self.today
        )
        
        # Verify adherence percentages use default goals
        progress = NutritionProgress.objects.get(user=self.user)
        
        # Should be 100% adherence with default goals
        self.assertEqual(progress.calories_adherence, Decimal('100.00'))
        self.assertEqual(progress.protein_adherence, Decimal('100.00'))
        self.assertEqual(progress.carbs_adherence, Decimal('100.00'))
        self.assertEqual(progress.fats_adherence, Decimal('100.00'))
    
    def test_signal_recalculates_on_update(self):
        """Test that progress is recalculated when IntakeLog is updated."""
        # Create intake log
        intake = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        # Verify initial progress
        progress = NutritionProgress.objects.get(user=self.user)
        self.assertEqual(progress.total_calories, Decimal('200.00'))
        
        # Update intake log with different macros
        intake.calories = Decimal('300.00')
        intake.protein = Decimal('30.00')
        intake.carbs = Decimal('40.00')
        intake.fats = Decimal('15.00')
        intake.save()
        
        # Verify progress was recalculated
        progress.refresh_from_db()
        self.assertEqual(progress.total_calories, Decimal('300.00'))
        self.assertEqual(progress.total_protein, Decimal('30.00'))
    
    def test_signal_recalculates_on_delete(self):
        """Test that progress is recalculated when IntakeLog is deleted."""
        # Create two intake logs
        intake1 = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        intake2 = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='snack',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        # Verify aggregated progress
        progress = NutritionProgress.objects.get(user=self.user)
        self.assertEqual(progress.total_calories, Decimal('400.00'))
        
        # Delete one intake log
        intake1.delete()
        
        # Verify progress was recalculated
        progress.refresh_from_db()
        self.assertEqual(progress.total_calories, Decimal('200.00'))
        self.assertEqual(progress.total_protein, Decimal('20.00'))
    
    def test_signal_handles_zero_division_in_adherence(self):
        """Test that adherence calculation handles zero goals gracefully."""
        # Create goals with zero values
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('0.00'),
            daily_protein=Decimal('0.00'),
            daily_carbs=Decimal('0.00'),
            daily_fats=Decimal('0.00')
        )
        
        # Create intake log
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        # Verify adherence is 0 (not error)
        progress = NutritionProgress.objects.get(user=self.user)
        self.assertEqual(progress.calories_adherence, Decimal('0.00'))
        self.assertEqual(progress.protein_adherence, Decimal('0.00'))
    
    def test_signal_separates_progress_by_date(self):
        """Test that progress is calculated separately for different dates."""
        yesterday = self.today - timedelta(days=1)
        
        # Create intake log for today
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        # Create intake log for yesterday
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=yesterday
        )
        
        # Verify separate progress records
        progress_today = NutritionProgress.objects.get(
            user=self.user,
            progress_date=self.today.date()
        )
        progress_yesterday = NutritionProgress.objects.get(
            user=self.user,
            progress_date=yesterday.date()
        )
        
        self.assertEqual(progress_today.total_calories, Decimal('200.00'))
        self.assertEqual(progress_yesterday.total_calories, Decimal('200.00'))


class HydrationLogSignalTest(TestCase):
    """Test HydrationLog signal handlers for water tracking."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.today = timezone.now()
    
    def test_signal_updates_water_totals(self):
        """Test that HydrationLog updates water totals in progress."""
        # Create hydration log
        HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('250.00'),
            unit='ml',
            logged_at=self.today
        )
        
        # Verify progress was created/updated
        progress = NutritionProgress.objects.get(
            user=self.user,
            progress_date=self.today.date()
        )
        
        self.assertEqual(progress.total_water, Decimal('250.00'))
    
    def test_signal_aggregates_multiple_hydration_logs(self):
        """Test that multiple HydrationLogs are aggregated."""
        # Create multiple hydration logs
        HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('250.00'),
            unit='ml',
            logged_at=self.today
        )
        
        HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('500.00'),
            unit='ml',
            logged_at=self.today
        )
        
        # Verify aggregated water total
        progress = NutritionProgress.objects.get(user=self.user)
        self.assertEqual(progress.total_water, Decimal('750.00'))
    
    def test_signal_calculates_water_adherence(self):
        """Test that water adherence is calculated correctly."""
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_water=Decimal('2000.00')
        )
        
        # Create hydration log (50% of goal)
        HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('1000.00'),
            unit='ml',
            logged_at=self.today
        )
        
        # Verify water adherence
        progress = NutritionProgress.objects.get(user=self.user)
        self.assertEqual(progress.water_adherence, Decimal('50.00'))
    
    def test_signal_recalculates_on_hydration_delete(self):
        """Test that water totals are recalculated when HydrationLog is deleted."""
        # Create two hydration logs
        hydration1 = HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('500.00'),
            unit='ml',
            logged_at=self.today
        )
        
        hydration2 = HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('500.00'),
            unit='ml',
            logged_at=self.today
        )
        
        # Verify aggregated water
        progress = NutritionProgress.objects.get(user=self.user)
        self.assertEqual(progress.total_water, Decimal('1000.00'))
        
        # Delete one hydration log
        hydration1.delete()
        
        # Verify water was recalculated
        progress.refresh_from_db()
        self.assertEqual(progress.total_water, Decimal('500.00'))
    
    def test_signal_handles_zero_water_goal(self):
        """Test that water adherence handles zero goal gracefully."""
        # Create goals with zero water
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_water=Decimal('0.00')
        )
        
        # Create hydration log
        HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('500.00'),
            unit='ml',
            logged_at=self.today
        )
        
        # Verify adherence is 0 (not error)
        progress = NutritionProgress.objects.get(user=self.user)
        self.assertEqual(progress.water_adherence, Decimal('0.00'))


class QuickLogSignalTest(TestCase):
    """Test QuickLog signal handlers for frequent meals tracking."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.food = FoodItem.objects.create(
            name='Test Food',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00')
        )
        
        self.today = timezone.now()
    
    def test_signal_creates_quick_log_entry(self):
        """Test that IntakeLog creates QuickLog entry."""
        # Create intake log
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        # Verify QuickLog was created
        quick_log = QuickLog.objects.get(user=self.user)
        self.assertEqual(len(quick_log.frequent_meals), 1)
        self.assertEqual(quick_log.frequent_meals[0]['food_item_id'], self.food.id)
        self.assertEqual(quick_log.frequent_meals[0]['usage_count'], 1)
    
    def test_signal_increments_usage_count(self):
        """Test that logging same food increments usage_count."""
        # Log the same food 3 times
        for _ in range(3):
            IntakeLog.objects.create(
                user=self.user,
                food_item=self.food,
                entry_type='meal',
                quantity=Decimal('100.00'),
                unit='g',
                calories=Decimal('200.00'),
                protein=Decimal('20.00'),
                carbs=Decimal('30.00'),
                fats=Decimal('10.00'),
                logged_at=self.today
            )
        
        # Verify usage count is 3
        quick_log = QuickLog.objects.get(user=self.user)
        self.assertEqual(len(quick_log.frequent_meals), 1)
        self.assertEqual(quick_log.frequent_meals[0]['usage_count'], 3)
    
    def test_signal_updates_last_used_timestamp(self):
        """Test that logging food updates last_used timestamp."""
        # Log food first time
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        quick_log = QuickLog.objects.get(user=self.user)
        first_timestamp = quick_log.frequent_meals[0]['last_used']
        
        # Log food again
        IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.today
        )
        
        quick_log.refresh_from_db()
        second_timestamp = quick_log.frequent_meals[0]['last_used']
        
        # Verify timestamp was updated
        self.assertGreaterEqual(second_timestamp, first_timestamp)
    
    def test_signal_limits_to_20_items(self):
        """Test that QuickLog limits frequent_meals to 20 items."""
        # Create 25 different food items
        foods = []
        for i in range(25):
            food = FoodItem.objects.create(
                name=f'Food {i}',
                calories_per_100g=Decimal('100.00'),
                protein_per_100g=Decimal('10.00'),
                carbs_per_100g=Decimal('20.00'),
                fats_per_100g=Decimal('5.00')
            )
            foods.append(food)
        
        # Log each food once
        for food in foods:
            IntakeLog.objects.create(
                user=self.user,
                food_item=food,
                entry_type='meal',
                quantity=Decimal('100.00'),
                unit='g',
                calories=Decimal('100.00'),
                protein=Decimal('10.00'),
                carbs=Decimal('20.00'),
                fats=Decimal('5.00'),
                logged_at=self.today
            )
        
        # Verify only 20 items are kept
        quick_log = QuickLog.objects.get(user=self.user)
        self.assertEqual(len(quick_log.frequent_meals), 20)
    
    def test_signal_keeps_most_frequent_items(self):
        """Test that QuickLog keeps most frequently used items."""
        # Create 25 different food items
        foods = []
        for i in range(25):
            food = FoodItem.objects.create(
                name=f'Food {i}',
                calories_per_100g=Decimal('10.00'),
                protein_per_100g=Decimal('1.00'),
                carbs_per_100g=Decimal('2.00'),
                fats_per_100g=Decimal('0.50')
            )
            foods.append(food)
        
        # Log first 5 foods 10 times each
        for i in range(5):
            for _ in range(10):
                IntakeLog.objects.create(
                    user=self.user,
                    food_item=foods[i],
                    entry_type='meal',
                    quantity=Decimal('10.00'),
                    unit='g',
                    calories=Decimal('1.00'),
                    protein=Decimal('0.10'),
                    carbs=Decimal('0.20'),
                    fats=Decimal('0.05'),
                    logged_at=self.today
                )
        
        # Log remaining 20 foods once each
        for i in range(5, 25):
            IntakeLog.objects.create(
                user=self.user,
                food_item=foods[i],
                entry_type='meal',
                quantity=Decimal('10.00'),
                unit='g',
                calories=Decimal('1.00'),
                protein=Decimal('0.10'),
                carbs=Decimal('0.20'),
                fats=Decimal('0.05'),
                logged_at=self.today
            )
        
        # Verify the top 5 most frequent items are in the list
        quick_log = QuickLog.objects.get(user=self.user)
        self.assertEqual(len(quick_log.frequent_meals), 20)
        
        # Check that first 5 foods are in the list
        food_ids_in_quick_log = [entry['food_item_id'] for entry in quick_log.frequent_meals]
        for i in range(5):
            self.assertIn(foods[i].id, food_ids_in_quick_log)
        
        # Verify they have the highest usage counts
        top_entry = quick_log.frequent_meals[0]
        self.assertEqual(top_entry['usage_count'], 10)
