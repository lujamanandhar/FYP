"""
Basic test to verify signal handler functionality for Task 4.1.

This test verifies that the IntakeLog post-save signal correctly:
1. Aggregates all IntakeLog entries for the date
2. Retrieves or creates NutritionGoals with defaults
3. Calculates adherence percentages
4. Updates or creates NutritionProgress record
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone

from nutrition.models import FoodItem, IntakeLog, NutritionGoals, NutritionProgress

User = get_user_model()


class TestIntakeLogSignal(TestCase):
    """Test the IntakeLog post-save signal handler."""
    
    def test_signal_creates_progress_on_first_intake(self):
        """
        Test that creating an IntakeLog automatically creates NutritionProgress.
        
        Requirements: 3.1-3.8
        """
        # Create test user
        user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        # Create test food item
        food = FoodItem.objects.create(
            name='Test Food',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00')
        )
        
        # Create intake log (should trigger signal)
        intake = IntakeLog.objects.create(
            user=user,
            food_item=food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=timezone.now()
        )
        
        # Verify NutritionProgress was created
        progress = NutritionProgress.objects.get(
            user=user,
            progress_date=intake.logged_at.date()
        )
        
        assert progress.total_calories == Decimal('200.00')
        assert progress.total_protein == Decimal('20.00')
        assert progress.total_carbs == Decimal('30.00')
        assert progress.total_fats == Decimal('10.00')
    
    def test_signal_aggregates_multiple_intakes(self):
        """
        Test that multiple IntakeLogs are aggregated correctly.
        
        Requirements: 3.2-3.5
        """
        # Create test user
        user = User.objects.create_user(
            email='test2@example.com',
            password='testpass123'
        )
        
        # Create test food items
        food1 = FoodItem.objects.create(
            name='Food 1',
            calories_per_100g=Decimal('100.00'),
            protein_per_100g=Decimal('10.00'),
            carbs_per_100g=Decimal('15.00'),
            fats_per_100g=Decimal('5.00')
        )
        
        food2 = FoodItem.objects.create(
            name='Food 2',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('25.00'),
            fats_per_100g=Decimal('10.00')
        )
        
        today = timezone.now()
        
        # Create first intake log
        IntakeLog.objects.create(
            user=user,
            food_item=food1,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('100.00'),
            protein=Decimal('10.00'),
            carbs=Decimal('15.00'),
            fats=Decimal('5.00'),
            logged_at=today
        )
        
        # Create second intake log
        IntakeLog.objects.create(
            user=user,
            food_item=food2,
            entry_type='snack',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('25.00'),
            fats=Decimal('10.00'),
            logged_at=today
        )
        
        # Verify aggregated totals
        progress = NutritionProgress.objects.get(
            user=user,
            progress_date=today.date()
        )
        
        assert progress.total_calories == Decimal('300.00')
        assert progress.total_protein == Decimal('30.00')
        assert progress.total_carbs == Decimal('40.00')
        assert progress.total_fats == Decimal('15.00')
    
    def test_signal_calculates_adherence_with_goals(self):
        """
        Test that adherence percentages are calculated correctly.
        
        Requirements: 3.7
        """
        # Create test user
        user = User.objects.create_user(
            email='test3@example.com',
            password='testpass123'
        )
        
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=user,
            daily_calories=Decimal('2000.00'),
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00')
        )
        
        # Create test food item
        food = FoodItem.objects.create(
            name='Test Food',
            calories_per_100g=Decimal('1000.00'),
            protein_per_100g=Decimal('75.00'),
            carbs_per_100g=Decimal('100.00'),
            fats_per_100g=Decimal('32.50')
        )
        
        # Create intake log (50% of daily goals)
        IntakeLog.objects.create(
            user=user,
            food_item=food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('1000.00'),
            protein=Decimal('75.00'),
            carbs=Decimal('100.00'),
            fats=Decimal('32.50'),
            logged_at=timezone.now()
        )
        
        # Verify adherence percentages
        progress = NutritionProgress.objects.get(user=user)
        
        # (1000 / 2000) * 100 = 50%
        assert progress.calories_adherence == Decimal('50.00')
        # (75 / 150) * 100 = 50%
        assert progress.protein_adherence == Decimal('50.00')
        # (100 / 200) * 100 = 50%
        assert progress.carbs_adherence == Decimal('50.00')
        # (32.50 / 65) * 100 = 50%
        assert progress.fats_adherence == Decimal('50.00')
    
    def test_signal_uses_default_goals(self):
        """
        Test that default goals are used when user has no goals set.
        
        Requirements: 5.7
        """
        # Create test user without goals
        user = User.objects.create_user(
            email='test4@example.com',
            password='testpass123'
        )
        
        # Create test food item
        food = FoodItem.objects.create(
            name='Test Food',
            calories_per_100g=Decimal('2000.00'),
            protein_per_100g=Decimal('150.00'),
            carbs_per_100g=Decimal('200.00'),
            fats_per_100g=Decimal('65.00')
        )
        
        # Create intake log (100% of default goals)
        IntakeLog.objects.create(
            user=user,
            food_item=food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('2000.00'),
            protein=Decimal('150.00'),
            carbs=Decimal('200.00'),
            fats=Decimal('65.00'),
            logged_at=timezone.now()
        )
        
        # Verify adherence percentages use default goals
        progress = NutritionProgress.objects.get(user=user)
        
        # Should be 100% adherence with default goals
        assert progress.calories_adherence == Decimal('100.00')
        assert progress.protein_adherence == Decimal('100.00')
        assert progress.carbs_adherence == Decimal('100.00')
        assert progress.fats_adherence == Decimal('100.00')


class TestQuickLogSignal(TestCase):
    """Test the QuickLog update signal handler."""
    
    def test_signal_creates_quick_log_entry(self):
        """
        Test that creating an IntakeLog updates QuickLog with new food item.
        
        Requirements: 6.2, 6.3
        """
        from nutrition.models import QuickLog
        
        # Create test user
        user = User.objects.create_user(
            email='quicklog1@example.com',
            password='testpass123'
        )
        
        # Create test food item
        food = FoodItem.objects.create(
            name='Test Food',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00')
        )
        
        # Create intake log (should trigger QuickLog update)
        IntakeLog.objects.create(
            user=user,
            food_item=food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=timezone.now()
        )
        
        # Verify QuickLog was created and updated
        quick_log = QuickLog.objects.get(user=user)
        assert len(quick_log.frequent_meals) == 1
        
        entry = quick_log.frequent_meals[0]
        assert entry['food_item_id'] == food.id
        assert entry['usage_count'] == 1
        assert 'last_used' in entry
    
    def test_signal_increments_usage_count(self):
        """
        Test that logging the same food multiple times increments usage_count.
        
        Requirements: 6.2
        """
        from nutrition.models import QuickLog
        
        # Create test user
        user = User.objects.create_user(
            email='quicklog2@example.com',
            password='testpass123'
        )
        
        # Create test food item
        food = FoodItem.objects.create(
            name='Frequent Food',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00')
        )
        
        # Log the same food 3 times
        for _ in range(3):
            IntakeLog.objects.create(
                user=user,
                food_item=food,
                entry_type='meal',
                quantity=Decimal('100.00'),
                unit='g',
                calories=Decimal('200.00'),
                protein=Decimal('20.00'),
                carbs=Decimal('30.00'),
                fats=Decimal('10.00'),
                logged_at=timezone.now()
            )
        
        # Verify usage count is 3
        quick_log = QuickLog.objects.get(user=user)
        assert len(quick_log.frequent_meals) == 1
        assert quick_log.frequent_meals[0]['usage_count'] == 3
    
    def test_signal_updates_last_used_timestamp(self):
        """
        Test that logging a food updates the last_used timestamp.
        
        Requirements: 6.3
        """
        from nutrition.models import QuickLog
        from datetime import datetime
        
        # Create test user
        user = User.objects.create_user(
            email='quicklog3@example.com',
            password='testpass123'
        )
        
        # Create test food item
        food = FoodItem.objects.create(
            name='Timestamped Food',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00')
        )
        
        # Log the food first time
        IntakeLog.objects.create(
            user=user,
            food_item=food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=timezone.now()
        )
        
        quick_log = QuickLog.objects.get(user=user)
        first_timestamp = quick_log.frequent_meals[0]['last_used']
        
        # Log the food again
        IntakeLog.objects.create(
            user=user,
            food_item=food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=timezone.now()
        )
        
        quick_log.refresh_from_db()
        second_timestamp = quick_log.frequent_meals[0]['last_used']
        
        # Verify timestamp was updated
        assert second_timestamp >= first_timestamp
    
    def test_signal_limits_to_top_20_items(self):
        """
        Test that QuickLog limits frequent_meals to top 20 items by usage_count.
        
        Requirements: 6.6
        """
        from nutrition.models import QuickLog
        
        # Create test user
        user = User.objects.create_user(
            email='quicklog4@example.com',
            password='testpass123'
        )
        
        # Create 25 different food items
        foods = []
        for i in range(25):
            food = FoodItem.objects.create(
                name=f'Food {i}',
                calories_per_100g=Decimal('200.00'),
                protein_per_100g=Decimal('20.00'),
                carbs_per_100g=Decimal('30.00'),
                fats_per_100g=Decimal('10.00')
            )
            foods.append(food)
        
        # Log each food once (in order)
        for food in foods:
            IntakeLog.objects.create(
                user=user,
                food_item=food,
                entry_type='meal',
                quantity=Decimal('100.00'),
                unit='g',
                calories=Decimal('200.00'),
                protein=Decimal('20.00'),
                carbs=Decimal('30.00'),
                fats=Decimal('10.00'),
                logged_at=timezone.now()
            )
        
        # Verify only 20 items are kept
        quick_log = QuickLog.objects.get(user=user)
        assert len(quick_log.frequent_meals) == 20
    
    def test_signal_keeps_most_frequent_items(self):
        """
        Test that QuickLog keeps the most frequently used items when limiting to 20.
        
        Requirements: 6.6
        """
        from nutrition.models import QuickLog
        
        # Create test user
        user = User.objects.create_user(
            email='quicklog5@example.com',
            password='testpass123'
        )
        
        # Create 25 different food items with smaller nutritional values
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
        
        # Log first 5 foods multiple times (these should be kept)
        for i in range(5):
            for _ in range(10):  # Log 10 times each
                IntakeLog.objects.create(
                    user=user,
                    food_item=foods[i],
                    entry_type='meal',
                    quantity=Decimal('10.00'),
                    unit='g',
                    calories=Decimal('1.00'),
                    protein=Decimal('0.10'),
                    carbs=Decimal('0.20'),
                    fats=Decimal('0.05'),
                    logged_at=timezone.now()
                )
        
        # Log remaining 20 foods once each
        for i in range(5, 25):
            IntakeLog.objects.create(
                user=user,
                food_item=foods[i],
                entry_type='meal',
                quantity=Decimal('10.00'),
                unit='g',
                calories=Decimal('1.00'),
                protein=Decimal('0.10'),
                carbs=Decimal('0.20'),
                fats=Decimal('0.05'),
                logged_at=timezone.now()
            )
        
        # Verify the top 5 most frequent items are in the list
        quick_log = QuickLog.objects.get(user=user)
        assert len(quick_log.frequent_meals) == 20
        
        # Check that the first 5 foods (with 10 uses each) are in the list
        food_ids_in_quick_log = [entry['food_item_id'] for entry in quick_log.frequent_meals]
        for i in range(5):
            assert foods[i].id in food_ids_in_quick_log
        
        # Verify they have the highest usage counts
        top_entry = quick_log.frequent_meals[0]
        assert top_entry['usage_count'] == 10
