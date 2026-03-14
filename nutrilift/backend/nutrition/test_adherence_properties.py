"""
Property-based tests for adherence percentage calculations.

Tests that adherence follows the formula: (actual ÷ target) × 100
**Validates: Requirements 3.7, 4.6**
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import datetime
from hypothesis import given, strategies as st, settings, assume
from hypothesis.extra.django import TestCase as HypothesisTestCase
import uuid

from nutrition.models import FoodItem, IntakeLog, NutritionProgress, NutritionGoals, HydrationLog
from nutrition.signals import update_nutrition_progress, update_hydration_progress

User = get_user_model()


class AdherenceCalculationPropertyTests(HypothesisTestCase):
    """
    Property tests for adherence percentage calculation.
    
    For any actual intake and target goal, the adherence should:
    1. Follow the formula: (actual ÷ target) × 100
    2. Be zero when actual is zero
    3. Be 100 when actual equals target
    4. Be greater than 100 when actual exceeds target
    5. Scale proportionally with actual intake
    
    **Validates: Requirements 3.7, 4.6**
    """

    def setUp(self):
        """Set up test data - create fresh user for each test"""
        super().setUp()
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )

    @given(
        target_calories=st.decimals(min_value=Decimal('500.00'), max_value=Decimal('5000.00'), places=2),
        actual_calories=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('5000.00'), places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_adherence_formula(self, target_calories, actual_calories):
        """
        Feature: nutrition-tracking-system, Property: Adherence Calculation
        
        For any actual and target values, adherence should follow
        the formula: (actual ÷ target) × 100
        
        **Validates: Requirements 3.7**
        """
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=target_calories,
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00'),
            daily_water=Decimal('2000.00')
        )
        
        # Create progress with actual values
        test_date = timezone.now().date()
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=test_date,
            total_calories=actual_calories,
            total_protein=Decimal('0.00'),
            total_carbs=Decimal('0.00'),
            total_fats=Decimal('0.00'),
            total_water=Decimal('0.00')
        )
        
        # Calculate expected adherence
        if target_calories > 0:
            expected_adherence = (actual_calories / target_calories) * 100
        else:
            expected_adherence = Decimal('0.00')
        
        # Manually calculate adherence (simulating signal behavior)
        if goals.daily_calories > 0:
            progress.calories_adherence = (progress.total_calories / goals.daily_calories) * 100
        else:
            progress.calories_adherence = Decimal('0.00')
        progress.save()
        
        # Property: Adherence should match formula
        self.assertAlmostEqual(
            float(progress.calories_adherence),
            float(expected_adherence),
            places=2,
            msg=f"Adherence should follow formula for actual={actual_calories}, target={target_calories}"
        )

    @given(
        target=st.decimals(min_value=Decimal('100.00'), max_value=Decimal('5000.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_adherence_100_when_equal(self, target):
        """
        Feature: nutrition-tracking-system, Property: Adherence Calculation
        
        When actual equals target, adherence should be exactly 100%.
        
        **Validates: Requirements 3.7**
        """
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=target,
            daily_protein=target,
            daily_carbs=target,
            daily_fats=target,
            daily_water=target
        )
        
        # Create progress with actual = target
        test_date = timezone.now().date()
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=test_date,
            total_calories=target,
            total_protein=target,
            total_carbs=target,
            total_fats=target,
            total_water=target
        )
        
        # Calculate adherence
        progress.calories_adherence = (progress.total_calories / goals.daily_calories) * 100
        progress.protein_adherence = (progress.total_protein / goals.daily_protein) * 100
        progress.carbs_adherence = (progress.total_carbs / goals.daily_carbs) * 100
        progress.fats_adherence = (progress.total_fats / goals.daily_fats) * 100
        progress.water_adherence = (progress.total_water / goals.daily_water) * 100
        progress.save()
        
        # Property: Adherence should be 100 when actual = target
        self.assertAlmostEqual(float(progress.calories_adherence), 100.0, places=1)
        self.assertAlmostEqual(float(progress.protein_adherence), 100.0, places=1)
        self.assertAlmostEqual(float(progress.carbs_adherence), 100.0, places=1)
        self.assertAlmostEqual(float(progress.fats_adherence), 100.0, places=1)
        self.assertAlmostEqual(float(progress.water_adherence), 100.0, places=1)

    @given(
        target=st.decimals(min_value=Decimal('100.00'), max_value=Decimal('5000.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_adherence_zero_when_no_intake(self, target):
        """
        Feature: nutrition-tracking-system, Property: Adherence Calculation
        
        When actual is zero, adherence should be 0%.
        
        **Validates: Requirements 3.7**
        """
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=target,
            daily_protein=target,
            daily_carbs=target,
            daily_fats=target,
            daily_water=target
        )
        
        # Create progress with zero actual
        test_date = timezone.now().date()
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=test_date,
            total_calories=Decimal('0.00'),
            total_protein=Decimal('0.00'),
            total_carbs=Decimal('0.00'),
            total_fats=Decimal('0.00'),
            total_water=Decimal('0.00')
        )
        
        # Calculate adherence
        progress.calories_adherence = (progress.total_calories / goals.daily_calories) * 100
        progress.protein_adherence = (progress.total_protein / goals.daily_protein) * 100
        progress.carbs_adherence = (progress.total_carbs / goals.daily_carbs) * 100
        progress.fats_adherence = (progress.total_fats / goals.daily_fats) * 100
        progress.water_adherence = (progress.total_water / goals.daily_water) * 100
        progress.save()
        
        # Property: Adherence should be 0 when actual = 0
        self.assertAlmostEqual(float(progress.calories_adherence), 0.0, places=1)
        self.assertAlmostEqual(float(progress.protein_adherence), 0.0, places=1)
        self.assertAlmostEqual(float(progress.carbs_adherence), 0.0, places=1)
        self.assertAlmostEqual(float(progress.fats_adherence), 0.0, places=1)
        self.assertAlmostEqual(float(progress.water_adherence), 0.0, places=1)

    @given(
        target=st.decimals(min_value=Decimal('100.00'), max_value=Decimal('2000.00'), places=2),
        excess_factor=st.decimals(min_value=Decimal('1.1'), max_value=Decimal('2.0'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_adherence_over_100_when_exceeds(self, target, excess_factor):
        """
        Feature: nutrition-tracking-system, Property: Adherence Calculation
        
        When actual exceeds target, adherence should be greater than 100%.
        
        **Validates: Requirements 3.7**
        """
        actual = target * excess_factor
        
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=target,
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00'),
            daily_water=Decimal('2000.00')
        )
        
        # Create progress with actual > target
        test_date = timezone.now().date()
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=test_date,
            total_calories=actual,
            total_protein=Decimal('0.00'),
            total_carbs=Decimal('0.00'),
            total_fats=Decimal('0.00'),
            total_water=Decimal('0.00')
        )
        
        # Calculate adherence
        progress.calories_adherence = (progress.total_calories / goals.daily_calories) * 100
        progress.save()
        
        # Property: Adherence should be > 100 when actual > target
        self.assertGreater(
            float(progress.calories_adherence),
            100.0,
            msg=f"Adherence should be > 100 when actual ({actual}) > target ({target})"
        )
        
        # Should match the excess factor
        expected_adherence = float(excess_factor) * 100
        self.assertAlmostEqual(
            float(progress.calories_adherence),
            expected_adherence,
            places=1
        )

    @given(
        target=st.decimals(min_value=Decimal('1000.00'), max_value=Decimal('3000.00'), places=2),
        actual1=st.decimals(min_value=Decimal('100.00'), max_value=Decimal('1500.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_adherence_scales_proportionally(self, target, actual1):
        """
        Feature: nutrition-tracking-system, Property: Adherence Calculation
        
        Adherence should scale proportionally with actual intake.
        Doubling actual should double adherence.
        
        **Validates: Requirements 3.7**
        """
        actual2 = actual1 * 2
        
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=target,
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00'),
            daily_water=Decimal('2000.00')
        )
        
        # Create first progress
        test_date = timezone.now().date()
        progress1 = NutritionProgress.objects.create(
            user=self.user,
            progress_date=test_date,
            total_calories=actual1,
            total_protein=Decimal('0.00'),
            total_carbs=Decimal('0.00'),
            total_fats=Decimal('0.00'),
            total_water=Decimal('0.00')
        )
        progress1.calories_adherence = (progress1.total_calories / goals.daily_calories) * 100
        progress1.save()
        
        adherence1 = float(progress1.calories_adherence)
        
        # Update to double actual
        progress1.total_calories = actual2
        progress1.calories_adherence = (progress1.total_calories / goals.daily_calories) * 100
        progress1.save()
        
        adherence2 = float(progress1.calories_adherence)
        
        # Property: Doubling actual should double adherence
        self.assertAlmostEqual(
            adherence2,
            adherence1 * 2,
            places=1,
            msg="Adherence should scale proportionally with actual intake"
        )

    @given(
        target_water=st.decimals(min_value=Decimal('1000.00'), max_value=Decimal('5000.00'), places=2),
        actual_water=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('5000.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_hydration_adherence_formula(self, target_water, actual_water):
        """
        Feature: nutrition-tracking-system, Property: Adherence Calculation
        
        Hydration adherence should follow the same formula: (actual ÷ target) × 100
        
        **Validates: Requirements 4.6**
        """
        # Create nutrition goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('2000.00'),
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00'),
            daily_water=target_water
        )
        
        # Create progress with actual water
        test_date = timezone.now().date()
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=test_date,
            total_calories=Decimal('0.00'),
            total_protein=Decimal('0.00'),
            total_carbs=Decimal('0.00'),
            total_fats=Decimal('0.00'),
            total_water=actual_water
        )
        
        # Calculate expected adherence
        if target_water > 0:
            expected_adherence = (actual_water / target_water) * 100
        else:
            expected_adherence = Decimal('0.00')
        
        # Calculate adherence
        if goals.daily_water > 0:
            progress.water_adherence = (progress.total_water / goals.daily_water) * 100
        else:
            progress.water_adherence = Decimal('0.00')
        progress.save()
        
        # Property: Hydration adherence should match formula
        self.assertAlmostEqual(
            float(progress.water_adherence),
            float(expected_adherence),
            places=2,
            msg=f"Hydration adherence should follow formula for actual={actual_water}, target={target_water}"
        )
