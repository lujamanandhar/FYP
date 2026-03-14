"""
Property-based tests for daily progress aggregation.

Tests that aggregation correctly sums intake logs for a given date.
**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import datetime, timedelta
from hypothesis import given, strategies as st, settings, assume
from hypothesis.extra.django import TestCase as HypothesisTestCase
import uuid

from nutrition.models import FoodItem, IntakeLog, NutritionProgress, NutritionGoals, HydrationLog
from nutrition.signals import update_nutrition_progress, update_hydration_progress

User = get_user_model()


class AggregationPropertyTests(HypothesisTestCase):
    """
    Property tests for daily progress aggregation.
    
    For any set of intake logs on a given date, the aggregated progress should:
    1. Sum all calories correctly
    2. Sum all protein correctly
    3. Sum all carbs correctly
    4. Sum all fats correctly
    5. Match the sum of individual logs
    
    **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
    """

    def setUp(self):
        """Set up test data - create fresh user and food items for each test"""
        super().setUp()
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
        # Create nutrition goals for the user
        self.goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('2000.00'),
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00'),
            daily_water=Decimal('2000.00')
        )
        
        # Create test food items
        self.food_items = [
            FoodItem.objects.create(
                name=f'Test Food {uuid.uuid4().hex[:8]} {i}',
                calories_per_100g=Decimal(str(100.0 + i * 50)),
                protein_per_100g=Decimal(str(10.0 + i * 5)),
                carbs_per_100g=Decimal(str(20.0 + i * 10)),
                fats_per_100g=Decimal(str(5.0 + i * 2)),
                fiber_per_100g=Decimal('5.00'),
                sugar_per_100g=Decimal('10.00'),
                is_custom=False
            )
            for i in range(5)
        ]

    @given(
        num_logs=st.integers(min_value=1, max_value=10)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_aggregation_sums_all_logs(self, num_logs):
        """
        Feature: nutrition-tracking-system, Property: Aggregation
        
        For any number of intake logs on a date, the aggregated progress
        should equal the sum of all individual log values.
        
        **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
        """
        test_date = timezone.now().date()
        
        # Create multiple intake logs
        total_calories = Decimal('0.00')
        total_protein = Decimal('0.00')
        total_carbs = Decimal('0.00')
        total_fats = Decimal('0.00')
        
        for i in range(num_logs):
            food_item = self.food_items[i % len(self.food_items)]
            quantity = Decimal('100.00')
            
            # Calculate macros
            multiplier = quantity / 100
            calories = food_item.calories_per_100g * multiplier
            protein = food_item.protein_per_100g * multiplier
            carbs = food_item.carbs_per_100g * multiplier
            fats = food_item.fats_per_100g * multiplier
            
            intake_log = IntakeLog.objects.create(
                user=self.user,
                food_item=food_item,
                entry_type='meal',
                quantity=quantity,
                unit='g',
                calories=calories,
                protein=protein,
                carbs=carbs,
                fats=fats,
                logged_at=timezone.make_aware(datetime.combine(test_date, datetime.min.time()))
            )
            
            total_calories += calories
            total_protein += protein
            total_carbs += carbs
            total_fats += fats
        
        # Trigger aggregation signal manually
        update_nutrition_progress(IntakeLog, intake_log, created=True)
        
        # Get the aggregated progress
        progress = NutritionProgress.objects.filter(
            user=self.user,
            progress_date=test_date
        ).first()
        
        self.assertIsNotNone(progress, "Progress should be created")
        
        # Property: Aggregated values should equal sum of individual logs
        self.assertAlmostEqual(
            float(progress.total_calories),
            float(total_calories),
            places=2,
            msg=f"Total calories should equal sum of {num_logs} logs"
        )
        self.assertAlmostEqual(
            float(progress.total_protein),
            float(total_protein),
            places=2,
            msg=f"Total protein should equal sum of {num_logs} logs"
        )
        self.assertAlmostEqual(
            float(progress.total_carbs),
            float(total_carbs),
            places=2,
            msg=f"Total carbs should equal sum of {num_logs} logs"
        )
        self.assertAlmostEqual(
            float(progress.total_fats),
            float(total_fats),
            places=2,
            msg=f"Total fats should equal sum of {num_logs} logs"
        )

    @given(
        num_logs=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_aggregation_updates_on_delete(self, num_logs):
        """
        Feature: nutrition-tracking-system, Property: Aggregation
        
        When an intake log is deleted, the aggregated progress should
        be recalculated and reflect the removal.
        
        **Validates: Requirements 3.10**
        """
        test_date = timezone.now().date()
        
        # Create multiple intake logs
        logs = []
        for i in range(num_logs):
            food_item = self.food_items[i % len(self.food_items)]
            quantity = Decimal('100.00')
            
            multiplier = quantity / 100
            calories = food_item.calories_per_100g * multiplier
            protein = food_item.protein_per_100g * multiplier
            carbs = food_item.carbs_per_100g * multiplier
            fats = food_item.fats_per_100g * multiplier
            
            intake_log = IntakeLog.objects.create(
                user=self.user,
                food_item=food_item,
                entry_type='meal',
                quantity=quantity,
                unit='g',
                calories=calories,
                protein=protein,
                carbs=carbs,
                fats=fats,
                logged_at=timezone.make_aware(datetime.combine(test_date, datetime.min.time()))
            )
            logs.append(intake_log)
        
        # Trigger aggregation
        update_nutrition_progress(IntakeLog, logs[-1], created=True)
        
        # Get initial progress
        progress_before = NutritionProgress.objects.get(
            user=self.user,
            progress_date=test_date
        )
        initial_calories = progress_before.total_calories
        
        # Delete one log
        deleted_log = logs[0]
        deleted_calories = deleted_log.calories
        deleted_log.delete()
        
        # Trigger aggregation after delete
        if len(logs) > 1:
            update_nutrition_progress(IntakeLog, logs[1], created=False)
        
        # Get updated progress
        progress_after = NutritionProgress.objects.filter(
            user=self.user,
            progress_date=test_date
        ).first()
        
        if progress_after:
            # Property: Total should decrease by deleted amount
            expected_calories = initial_calories - deleted_calories
            self.assertAlmostEqual(
                float(progress_after.total_calories),
                float(expected_calories),
                places=2,
                msg="Aggregation should update after delete"
            )

    @given(
        num_hydration_logs=st.integers(min_value=1, max_value=10)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_hydration_aggregation(self, num_hydration_logs):
        """
        Feature: nutrition-tracking-system, Property: Aggregation
        
        For any number of hydration logs on a date, the aggregated water
        should equal the sum of all individual log amounts.
        
        **Validates: Requirements 4.4**
        """
        test_date = timezone.now().date()
        
        # Create multiple hydration logs
        total_water = Decimal('0.00')
        
        for i in range(num_hydration_logs):
            amount = Decimal(str(250.0 + i * 50))
            
            hydration_log = HydrationLog.objects.create(
                user=self.user,
                amount=amount,
                unit='ml',
                logged_at=timezone.make_aware(datetime.combine(test_date, datetime.min.time()))
            )
            
            total_water += amount
        
        # Trigger aggregation signal manually
        update_hydration_progress(HydrationLog, hydration_log, created=True)
        
        # Get the aggregated progress
        progress = NutritionProgress.objects.filter(
            user=self.user,
            progress_date=test_date
        ).first()
        
        self.assertIsNotNone(progress, "Progress should be created")
        
        # Property: Aggregated water should equal sum of individual logs
        self.assertAlmostEqual(
            float(progress.total_water),
            float(total_water),
            places=2,
            msg=f"Total water should equal sum of {num_hydration_logs} logs"
        )

    @given(
        num_logs_day1=st.integers(min_value=1, max_value=5),
        num_logs_day2=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_aggregation_per_date(self, num_logs_day1, num_logs_day2):
        """
        Feature: nutrition-tracking-system, Property: Aggregation
        
        Aggregation should be isolated per date - logs from different
        dates should not affect each other's aggregated totals.
        
        **Validates: Requirements 3.1**
        """
        date1 = timezone.now().date()
        date2 = date1 - timedelta(days=1)
        
        # Create logs for date1
        total_calories_day1 = Decimal('0.00')
        for i in range(num_logs_day1):
            food_item = self.food_items[i % len(self.food_items)]
            quantity = Decimal('100.00')
            multiplier = quantity / 100
            calories = food_item.calories_per_100g * multiplier
            
            intake_log = IntakeLog.objects.create(
                user=self.user,
                food_item=food_item,
                entry_type='meal',
                quantity=quantity,
                unit='g',
                calories=calories,
                protein=food_item.protein_per_100g * multiplier,
                carbs=food_item.carbs_per_100g * multiplier,
                fats=food_item.fats_per_100g * multiplier,
                logged_at=timezone.make_aware(datetime.combine(date1, datetime.min.time()))
            )
            total_calories_day1 += calories
        
        update_nutrition_progress(IntakeLog, intake_log, created=True)
        
        # Create logs for date2
        total_calories_day2 = Decimal('0.00')
        for i in range(num_logs_day2):
            food_item = self.food_items[i % len(self.food_items)]
            quantity = Decimal('150.00')
            multiplier = quantity / 100
            calories = food_item.calories_per_100g * multiplier
            
            intake_log = IntakeLog.objects.create(
                user=self.user,
                food_item=food_item,
                entry_type='meal',
                quantity=quantity,
                unit='g',
                calories=calories,
                protein=food_item.protein_per_100g * multiplier,
                carbs=food_item.carbs_per_100g * multiplier,
                fats=food_item.fats_per_100g * multiplier,
                logged_at=timezone.make_aware(datetime.combine(date2, datetime.min.time()))
            )
            total_calories_day2 += calories
        
        update_nutrition_progress(IntakeLog, intake_log, created=True)
        
        # Get progress for both dates
        progress1 = NutritionProgress.objects.get(user=self.user, progress_date=date1)
        progress2 = NutritionProgress.objects.get(user=self.user, progress_date=date2)
        
        # Property: Each date should have independent aggregation
        self.assertAlmostEqual(
            float(progress1.total_calories),
            float(total_calories_day1),
            places=2,
            msg="Date1 aggregation should be independent"
        )
        self.assertAlmostEqual(
            float(progress2.total_calories),
            float(total_calories_day2),
            places=2,
            msg="Date2 aggregation should be independent"
        )
        self.assertNotEqual(
            float(progress1.total_calories),
            float(progress2.total_calories),
            msg="Different dates should have different totals"
        )
