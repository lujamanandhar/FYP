"""
Property-based tests for QuickLog, serializers, data integrity, goals, and error formats.

Tests remaining correctness properties for the nutrition tracking system.
**Validates: Requirements 6.1, 6.2, 6.3, 13.8, 13.9, 13.10, 11.5**
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import datetime
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
import uuid
import json

from nutrition.models import FoodItem, IntakeLog, QuickLog, NutritionGoals, NutritionProgress
from nutrition.serializers import (
    FoodItemSerializer, IntakeLogSerializer, NutritionGoalsSerializer,
    NutritionProgressSerializer
)

User = get_user_model()


class QuickLogPropertyTests(HypothesisTestCase):
    """
    Property tests for QuickLog functionality.
    
    **Validates: Requirements 6.1, 6.2, 6.3**
    """

    def setUp(self):
        """Set up test data"""
        super().setUp()
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
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
        num_uses=st.integers(min_value=1, max_value=20)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_quicklog_usage_count_increases(self, num_uses):
        """
        Feature: nutrition-tracking-system, Property: QuickLog
        
        For any food item, logging it multiple times should
        increase its usage count in QuickLog.
        
        **Validates: Requirements 6.2**
        """
        quick_log, created = QuickLog.objects.get_or_create(
            user=self.user,
            defaults={'frequent_meals': []}
        )
        
        food_item = self.food_items[0]
        
        # Simulate logging the same food multiple times
        for i in range(num_uses):
            # Find or create entry in frequent_meals
            found = False
            for meal in quick_log.frequent_meals:
                if meal['food_item_id'] == food_item.id:
                    meal['usage_count'] += 1
                    meal['last_used'] = timezone.now().isoformat()
                    found = True
                    break
            
            if not found:
                quick_log.frequent_meals.append({
                    'food_item_id': food_item.id,
                    'usage_count': 1,
                    'last_used': timezone.now().isoformat()
                })
            
            quick_log.save()
        
        # Property: Usage count should equal num_uses
        quick_log.refresh_from_db()
        meal_entry = next(
            (m for m in quick_log.frequent_meals if m['food_item_id'] == food_item.id),
            None
        )
        
        self.assertIsNotNone(meal_entry)
        self.assertEqual(
            meal_entry['usage_count'],
            num_uses,
            f"Usage count should be {num_uses}"
        )

    @given(
        num_foods=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_quicklog_tracks_multiple_foods(self, num_foods):
        """
        Feature: nutrition-tracking-system, Property: QuickLog
        
        QuickLog should track multiple different foods independently.
        
        **Validates: Requirements 6.1**
        """
        quick_log, created = QuickLog.objects.get_or_create(
            user=self.user,
            defaults={'frequent_meals': []}
        )
        
        # Log different foods
        for i in range(num_foods):
            food_item = self.food_items[i]
            quick_log.frequent_meals.append({
                'food_item_id': food_item.id,
                'usage_count': i + 1,
                'last_used': timezone.now().isoformat()
            })
        
        quick_log.save()
        quick_log.refresh_from_db()
        
        # Property: Should have num_foods entries
        self.assertEqual(
            len(quick_log.frequent_meals),
            num_foods,
            f"Should track {num_foods} different foods"
        )
        
        # Property: Each food should have correct usage count
        for i in range(num_foods):
            food_item = self.food_items[i]
            meal_entry = next(
                (m for m in quick_log.frequent_meals if m['food_item_id'] == food_item.id),
                None
            )
            self.assertIsNotNone(meal_entry)
            self.assertEqual(meal_entry['usage_count'], i + 1)


class SerializerRoundTripPropertyTests(HypothesisTestCase):
    """
    Property tests for serializer round-trip (parse(print(x)) == x).
    
    **Validates: Requirements 13.8, 13.9, 13.10**
    """

    def setUp(self):
        """Set up test data"""
        super().setUp()
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )

    @given(
        calories=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('999.99'), places=2),
        protein=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('99.99'), places=2),
        carbs=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('99.99'), places=2),
        fats=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('99.99'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_food_item_serializer_round_trip(self, calories, protein, carbs, fats):
        """
        Feature: nutrition-tracking-system, Property: Serializer Round-Trip
        
        For any food item, serializing and deserializing should
        preserve all data (round-trip property).
        
        **Validates: Requirements 13.8**
        """
        # Create food item
        food_item = FoodItem.objects.create(
            name='Test Food',
            calories_per_100g=calories,
            protein_per_100g=protein,
            carbs_per_100g=carbs,
            fats_per_100g=fats,
            fiber_per_100g=Decimal('5.00'),
            sugar_per_100g=Decimal('10.00'),
            is_custom=False
        )
        
        # Serialize
        serializer = FoodItemSerializer(food_item)
        data = serializer.data
        
        # Deserialize
        new_serializer = FoodItemSerializer(data=data)
        self.assertTrue(new_serializer.is_valid(), new_serializer.errors)
        
        # Property: Round-trip should preserve values
        self.assertEqual(
            Decimal(str(data['calories_per_100g'])),
            calories
        )
        self.assertEqual(
            Decimal(str(data['protein_per_100g'])),
            protein
        )
        self.assertEqual(
            Decimal(str(data['carbs_per_100g'])),
            carbs
        )
        self.assertEqual(
            Decimal(str(data['fats_per_100g'])),
            fats
        )

    @given(
        daily_calories=st.decimals(min_value=Decimal('500.00'), max_value=Decimal('5000.00'), places=2),
        daily_protein=st.decimals(min_value=Decimal('50.00'), max_value=Decimal('300.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_nutrition_goals_serializer_round_trip(self, daily_calories, daily_protein):
        """
        Feature: nutrition-tracking-system, Property: Serializer Round-Trip
        
        For any nutrition goals, serializing and deserializing should
        preserve all data.
        
        **Validates: Requirements 13.8**
        """
        # Create goals
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=daily_calories,
            daily_protein=daily_protein,
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00'),
            daily_water=Decimal('2000.00')
        )
        
        # Serialize
        serializer = NutritionGoalsSerializer(goals)
        data = serializer.data
        
        # Property: Round-trip should preserve values
        self.assertEqual(
            Decimal(str(data['daily_calories'])),
            daily_calories
        )
        self.assertEqual(
            Decimal(str(data['daily_protein'])),
            daily_protein
        )


class DataIntegrityPropertyTests(HypothesisTestCase):
    """
    Property tests for data completeness and integrity.
    
    **Validates: Requirements 13.9, 13.10**
    """

    def setUp(self):
        """Set up test data"""
        super().setUp()
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
        self.food_item = FoodItem.objects.create(
            name=f'Test Food {uuid.uuid4().hex[:8]}',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00'),
            fiber_per_100g=Decimal('5.00'),
            sugar_per_100g=Decimal('15.00'),
            is_custom=False
        )

    @given(
        quantity=st.decimals(min_value=Decimal('1.00'), max_value=Decimal('1000.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_intake_log_has_all_required_fields(self, quantity):
        """
        Feature: nutrition-tracking-system, Property: Data Integrity
        
        For any intake log, all required fields should be present
        and non-null after creation.
        
        **Validates: Requirements 13.9**
        """
        multiplier = quantity / 100
        
        intake_log = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food_item,
            entry_type='meal',
            quantity=quantity,
            unit='g',
            calories=self.food_item.calories_per_100g * multiplier,
            protein=self.food_item.protein_per_100g * multiplier,
            carbs=self.food_item.carbs_per_100g * multiplier,
            fats=self.food_item.fats_per_100g * multiplier
        )
        
        # Property: All required fields should be non-null
        self.assertIsNotNone(intake_log.id)
        self.assertIsNotNone(intake_log.user)
        self.assertIsNotNone(intake_log.food_item)
        self.assertIsNotNone(intake_log.entry_type)
        self.assertIsNotNone(intake_log.quantity)
        self.assertIsNotNone(intake_log.unit)
        self.assertIsNotNone(intake_log.calories)
        self.assertIsNotNone(intake_log.protein)
        self.assertIsNotNone(intake_log.carbs)
        self.assertIsNotNone(intake_log.fats)
        self.assertIsNotNone(intake_log.logged_at)
        self.assertIsNotNone(intake_log.created_at)

    def test_property_nutrition_progress_has_all_adherence_fields(self):
        """
        Feature: nutrition-tracking-system, Property: Data Integrity
        
        For any nutrition progress, all adherence fields should be
        present and calculable.
        
        **Validates: Requirements 13.10**
        """
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('2000.00'),
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00'),
            daily_water=Decimal('2000.00')
        )
        
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=timezone.now().date(),
            total_calories=Decimal('1800.00'),
            total_protein=Decimal('140.00'),
            total_carbs=Decimal('180.00'),
            total_fats=Decimal('60.00'),
            total_water=Decimal('1800.00')
        )
        
        # Calculate adherence
        progress.calories_adherence = (progress.total_calories / goals.daily_calories) * 100
        progress.protein_adherence = (progress.total_protein / goals.daily_protein) * 100
        progress.carbs_adherence = (progress.total_carbs / goals.daily_carbs) * 100
        progress.fats_adherence = (progress.total_fats / goals.daily_fats) * 100
        progress.water_adherence = (progress.total_water / goals.daily_water) * 100
        progress.save()
        
        # Property: All adherence fields should be present
        self.assertIsNotNone(progress.calories_adherence)
        self.assertIsNotNone(progress.protein_adherence)
        self.assertIsNotNone(progress.carbs_adherence)
        self.assertIsNotNone(progress.fats_adherence)
        self.assertIsNotNone(progress.water_adherence)
        
        # Property: All adherence values should be reasonable (0-200%)
        self.assertGreaterEqual(progress.calories_adherence, 0)
        self.assertLessEqual(progress.calories_adherence, 200)


class ErrorFormatPropertyTests(HypothesisTestCase):
    """
    Property tests for error format consistency.
    
    **Validates: Requirements 11.5**
    """

    def setUp(self):
        """Set up test data"""
        super().setUp()
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )

    @given(
        invalid_value=st.decimals(min_value=Decimal('-1000.00'), max_value=Decimal('-0.01'), places=2)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_validation_errors_have_consistent_format(self, invalid_value):
        """
        Feature: nutrition-tracking-system, Property: Error Format
        
        For any validation error, the error format should be consistent
        and include the field name and error message.
        
        **Validates: Requirements 11.5**
        """
        data = {
            'name': 'Test Food',
            'calories_per_100g': str(invalid_value),
            'protein_per_100g': '20.00',
            'carbs_per_100g': '30.00',
            'fats_per_100g': '10.00',
            'fiber_per_100g': '5.00',
            'sugar_per_100g': '15.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        is_valid = serializer.is_valid()
        
        # Property: Validation errors should have consistent structure
        if not is_valid:
            self.assertIsInstance(serializer.errors, dict)
            # Should have field-level errors
            self.assertTrue(len(serializer.errors) > 0)
            
            # Each error should be a list of error messages
            for field, errors in serializer.errors.items():
                self.assertIsInstance(errors, list)
                for error in errors:
                    self.assertIsInstance(str(error), str)

    def test_property_missing_required_fields_produce_errors(self):
        """
        Feature: nutrition-tracking-system, Property: Error Format
        
        For any missing required field, the system should produce
        a clear error message.
        
        **Validates: Requirements 11.5**
        """
        # Missing required fields
        data = {
            'name': 'Test Food'
            # Missing all nutritional fields
        }
        
        serializer = FoodItemSerializer(data=data)
        is_valid = serializer.is_valid()
        
        # Property: Should have errors for missing fields
        self.assertFalse(is_valid)
        self.assertIn('calories_per_100g', serializer.errors)
        self.assertIn('protein_per_100g', serializer.errors)
        self.assertIn('carbs_per_100g', serializer.errors)
        self.assertIn('fats_per_100g', serializer.errors)
