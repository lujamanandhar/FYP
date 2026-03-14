"""
Property-based tests for data validation.

Tests that validation rules are enforced correctly for all inputs.
**Validates: Requirements 1.4, 11.2, 11.3, 11.4**
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework import serializers as drf_serializers
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
import uuid

from nutrition.models import FoodItem, IntakeLog, HydrationLog, NutritionGoals
from nutrition.serializers import (
    FoodItemSerializer, IntakeLogSerializer, 
    HydrationLogSerializer, NutritionGoalsSerializer
)

User = get_user_model()


class ValidationPropertyTests(HypothesisTestCase):
    """
    Property tests for validation rules.
    
    For any input data, the system should:
    1. Reject negative nutritional values
    2. Reject zero or negative quantities
    3. Reject invalid entry types
    4. Accept valid data within constraints
    
    **Validates: Requirements 1.4, 11.2, 11.3, 11.4**
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
        calories=st.decimals(min_value=Decimal('-1000.00'), max_value=Decimal('-0.01'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_reject_negative_calories(self, calories):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any negative calorie value, the system should reject it.
        
        **Validates: Requirements 1.4, 11.3**
        """
        data = {
            'name': 'Test Food',
            'calories_per_100g': str(calories),
            'protein_per_100g': '20.00',
            'carbs_per_100g': '30.00',
            'fats_per_100g': '10.00',
            'fiber_per_100g': '5.00',
            'sugar_per_100g': '15.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        
        # Property: Negative calories should be rejected
        self.assertFalse(
            serializer.is_valid(),
            f"Negative calories {calories} should be rejected"
        )

    @given(
        protein=st.decimals(min_value=Decimal('-100.00'), max_value=Decimal('-0.01'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_reject_negative_protein(self, protein):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any negative protein value, the system should reject it.
        
        **Validates: Requirements 1.4, 11.3**
        """
        data = {
            'name': 'Test Food',
            'calories_per_100g': '200.00',
            'protein_per_100g': str(protein),
            'carbs_per_100g': '30.00',
            'fats_per_100g': '10.00',
            'fiber_per_100g': '5.00',
            'sugar_per_100g': '15.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        
        # Property: Negative protein should be rejected
        self.assertFalse(
            serializer.is_valid(),
            f"Negative protein {protein} should be rejected"
        )

    @given(
        quantity=st.decimals(min_value=Decimal('-1000.00'), max_value=Decimal('0.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_reject_zero_or_negative_quantity(self, quantity):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any zero or negative quantity, the system should reject it.
        
        **Validates: Requirements 11.2**
        """
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': 'meal',
            'quantity': str(quantity),
            'unit': 'g',
            'description': 'Test meal'
        }
        
        serializer = IntakeLogSerializer(data=data)
        
        # Property: Zero or negative quantity should be rejected
        self.assertFalse(
            serializer.is_valid(),
            f"Quantity {quantity} should be rejected"
        )

    @given(
        entry_type=st.text(min_size=1, max_size=20).filter(
            lambda x: x not in ['meal', 'snack', 'drink']
        )
    )
    @settings(max_examples=50, deadline=None)
    def test_property_reject_invalid_entry_type(self, entry_type):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any entry_type not in {meal, snack, drink}, the system should reject it.
        
        **Validates: Requirements 11.4**
        """
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': entry_type,
            'quantity': '100.00',
            'unit': 'g',
            'description': 'Test meal'
        }
        
        serializer = IntakeLogSerializer(data=data)
        
        # Property: Invalid entry_type should be rejected
        self.assertFalse(
            serializer.is_valid(),
            f"Invalid entry_type '{entry_type}' should be rejected"
        )

    @given(
        entry_type=st.sampled_from(['meal', 'snack', 'drink'])
    )
    @settings(max_examples=50, deadline=None)
    def test_property_accept_valid_entry_type(self, entry_type):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any valid entry_type in {meal, snack, drink}, the system should accept it.
        
        **Validates: Requirements 11.4**
        """
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': entry_type,
            'quantity': '100.00',
            'unit': 'g',
            'description': 'Test meal'
        }
        
        serializer = IntakeLogSerializer(data=data)
        
        # Property: Valid entry_type should be accepted
        self.assertTrue(
            serializer.is_valid(),
            f"Valid entry_type '{entry_type}' should be accepted. Errors: {serializer.errors}"
        )

    @given(
        calories=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('9999.99'), places=2),
        protein=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('999.99'), places=2),
        carbs=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('999.99'), places=2),
        fats=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('999.99'), places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_accept_valid_nutritional_values(self, calories, protein, carbs, fats):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any non-negative nutritional values within valid ranges,
        the system should accept them.
        
        **Validates: Requirements 1.4, 11.3**
        """
        data = {
            'name': 'Test Food',
            'calories_per_100g': str(calories),
            'protein_per_100g': str(protein),
            'carbs_per_100g': str(carbs),
            'fats_per_100g': str(fats),
            'fiber_per_100g': '5.00',
            'sugar_per_100g': '15.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        
        # Property: Valid nutritional values should be accepted
        self.assertTrue(
            serializer.is_valid(),
            f"Valid nutritional values should be accepted. Errors: {serializer.errors}"
        )

    @given(
        amount=st.decimals(min_value=Decimal('-1000.00'), max_value=Decimal('0.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_reject_zero_or_negative_hydration(self, amount):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any zero or negative hydration amount, the system should reject it.
        
        **Validates: Requirements 11.2**
        """
        data = {
            'user': self.user.id,
            'amount': str(amount),
            'unit': 'ml'
        }
        
        serializer = HydrationLogSerializer(data=data)
        
        # Property: Zero or negative amount should be rejected
        self.assertFalse(
            serializer.is_valid(),
            f"Hydration amount {amount} should be rejected"
        )

    @given(
        amount=st.decimals(min_value=Decimal('0.01'), max_value=Decimal('10000.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_accept_positive_hydration(self, amount):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any positive hydration amount, the system should accept it.
        
        **Validates: Requirements 11.2**
        """
        data = {
            'user': self.user.id,
            'amount': str(amount),
            'unit': 'ml'
        }
        
        serializer = HydrationLogSerializer(data=data)
        
        # Property: Positive amount should be accepted
        self.assertTrue(
            serializer.is_valid(),
            f"Positive hydration amount {amount} should be accepted. Errors: {serializer.errors}"
        )

    @given(
        daily_calories=st.decimals(min_value=Decimal('-5000.00'), max_value=Decimal('-0.01'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_reject_negative_goals(self, daily_calories):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any negative goal value, the system should reject it.
        
        **Validates: Requirements 11.3**
        """
        data = {
            'user': self.user.id,
            'daily_calories': str(daily_calories),
            'daily_protein': '150.00',
            'daily_carbs': '200.00',
            'daily_fats': '65.00',
            'daily_water': '2000.00'
        }
        
        serializer = NutritionGoalsSerializer(data=data)
        
        # Property: Negative goals should be rejected
        self.assertFalse(
            serializer.is_valid(),
            f"Negative goal {daily_calories} should be rejected"
        )

    @given(
        daily_calories=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('9999.99'), places=2),
        daily_protein=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('999.99'), places=2),
        daily_carbs=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('999.99'), places=2),
        daily_fats=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('999.99'), places=2),
        daily_water=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('9999.99'), places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_accept_valid_goals(self, daily_calories, daily_protein, daily_carbs, 
                                         daily_fats, daily_water):
        """
        Feature: nutrition-tracking-system, Property: Validation
        
        For any non-negative goal values within valid ranges,
        the system should accept them.
        
        **Validates: Requirements 11.3**
        """
        data = {
            'user': self.user.id,
            'daily_calories': str(daily_calories),
            'daily_protein': str(daily_protein),
            'daily_carbs': str(daily_carbs),
            'daily_fats': str(daily_fats),
            'daily_water': str(daily_water)
        }
        
        serializer = NutritionGoalsSerializer(data=data)
        
        # Property: Valid goals should be accepted
        self.assertTrue(
            serializer.is_valid(),
            f"Valid goal values should be accepted. Errors: {serializer.errors}"
        )
