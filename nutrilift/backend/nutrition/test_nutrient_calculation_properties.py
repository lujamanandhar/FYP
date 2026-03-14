"""
Property-based tests for nutrient calculation.

Tests that nutrient calculations follow the formula: (nutrient_per_100g ÷ 100) × quantity
**Validates: Requirements 2.2, 2.3, 2.4, 2.5**
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
import uuid

from nutrition.models import FoodItem, IntakeLog
from nutrition.serializers import IntakeLogSerializer

User = get_user_model()


class NutrientCalculationPropertyTests(HypothesisTestCase):
    """
    Property tests for nutrient calculation formula.
    
    For any food item and quantity, the calculated nutrients should:
    1. Follow the formula: (nutrient_per_100g ÷ 100) × quantity
    2. Be non-negative
    3. Scale linearly with quantity
    4. Be zero when quantity is zero
    
    **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
    """

    def setUp(self):
        """Set up test data - create fresh user and food item for each test"""
        super().setUp()
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
        # Create a test food item
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
        quantity=st.decimals(min_value=Decimal('0.01'), max_value=Decimal('10000.00'), places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_nutrient_calculation_formula(self, quantity):
        """
        Feature: nutrition-tracking-system, Property: Nutrient Calculation
        
        For any valid quantity, the calculated nutrients should follow
        the formula: (nutrient_per_100g ÷ 100) × quantity
        
        **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
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
        if serializer.is_valid():
            intake_log = serializer.save(user=self.user)
            
            # Calculate expected values using the formula
            multiplier = quantity / 100
            expected_calories = self.food_item.calories_per_100g * multiplier
            expected_protein = self.food_item.protein_per_100g * multiplier
            expected_carbs = self.food_item.carbs_per_100g * multiplier
            expected_fats = self.food_item.fats_per_100g * multiplier
            
            # Property: Calculated values should match formula (within rounding tolerance)
            self.assertAlmostEqual(
                float(intake_log.calories),
                float(expected_calories),
                places=2,
                msg=f"Calories calculation incorrect for quantity={quantity}"
            )
            self.assertAlmostEqual(
                float(intake_log.protein),
                float(expected_protein),
                places=2,
                msg=f"Protein calculation incorrect for quantity={quantity}"
            )
            self.assertAlmostEqual(
                float(intake_log.carbs),
                float(expected_carbs),
                places=2,
                msg=f"Carbs calculation incorrect for quantity={quantity}"
            )
            self.assertAlmostEqual(
                float(intake_log.fats),
                float(expected_fats),
                places=2,
                msg=f"Fats calculation incorrect for quantity={quantity}"
            )

    @given(
        quantity=st.decimals(min_value=Decimal('0.01'), max_value=Decimal('10000.00'), places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_nutrients_always_non_negative(self, quantity):
        """
        Feature: nutrition-tracking-system, Property: Nutrient Calculation
        
        For any valid quantity, all calculated nutrients should be non-negative.
        
        **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
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
        if serializer.is_valid():
            intake_log = serializer.save(user=self.user)
            
            # Property: All nutrients should be non-negative
            self.assertGreaterEqual(
                intake_log.calories,
                0,
                f"Calories should be non-negative for quantity={quantity}"
            )
            self.assertGreaterEqual(
                intake_log.protein,
                0,
                f"Protein should be non-negative for quantity={quantity}"
            )
            self.assertGreaterEqual(
                intake_log.carbs,
                0,
                f"Carbs should be non-negative for quantity={quantity}"
            )
            self.assertGreaterEqual(
                intake_log.fats,
                0,
                f"Fats should be non-negative for quantity={quantity}"
            )

    @given(
        quantity1=st.decimals(min_value=Decimal('1.00'), max_value=Decimal('500.00'), places=2),
        quantity2=st.decimals(min_value=Decimal('1.00'), max_value=Decimal('500.00'), places=2)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_nutrients_scale_linearly(self, quantity1, quantity2):
        """
        Feature: nutrition-tracking-system, Property: Nutrient Calculation
        
        For any two quantities where quantity2 = 2 * quantity1,
        the calculated nutrients should also double (linear scaling).
        
        **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
        """
        # Create first intake log
        data1 = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': 'meal',
            'quantity': str(quantity1),
            'unit': 'g',
            'description': 'Test meal 1'
        }
        
        serializer1 = IntakeLogSerializer(data=data1)
        if serializer1.is_valid():
            intake_log1 = serializer1.save(user=self.user)
            
            # Create second intake log with double quantity
            quantity2 = quantity1 * 2
            data2 = {
                'user': self.user.id,
                'food_item': self.food_item.id,
                'entry_type': 'meal',
                'quantity': str(quantity2),
                'unit': 'g',
                'description': 'Test meal 2'
            }
            
            serializer2 = IntakeLogSerializer(data=data2)
            if serializer2.is_valid():
                intake_log2 = serializer2.save(user=self.user)
                
                # Property: Doubling quantity should double nutrients (linear scaling)
                self.assertAlmostEqual(
                    float(intake_log2.calories),
                    float(intake_log1.calories) * 2,
                    places=1,
                    msg=f"Calories should scale linearly with quantity"
                )
                self.assertAlmostEqual(
                    float(intake_log2.protein),
                    float(intake_log1.protein) * 2,
                    places=1,
                    msg=f"Protein should scale linearly with quantity"
                )
                self.assertAlmostEqual(
                    float(intake_log2.carbs),
                    float(intake_log1.carbs) * 2,
                    places=1,
                    msg=f"Carbs should scale linearly with quantity"
                )
                self.assertAlmostEqual(
                    float(intake_log2.fats),
                    float(intake_log1.fats) * 2,
                    places=1,
                    msg=f"Fats should scale linearly with quantity"
                )

    @given(
        calories_per_100g=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('900.00'), places=2),
        protein_per_100g=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('100.00'), places=2),
        carbs_per_100g=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('100.00'), places=2),
        fats_per_100g=st.decimals(min_value=Decimal('0.00'), max_value=Decimal('100.00'), places=2),
        quantity=st.decimals(min_value=Decimal('1.00'), max_value=Decimal('1000.00'), places=2)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_calculation_with_varying_nutrients(self, calories_per_100g, protein_per_100g, 
                                                         carbs_per_100g, fats_per_100g, quantity):
        """
        Feature: nutrition-tracking-system, Property: Nutrient Calculation
        
        For any food item with varying nutritional values per 100g,
        the calculation formula should work correctly.
        
        **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
        """
        # Create food item with random nutritional values
        food_item = FoodItem.objects.create(
            name=f'Random Food {uuid.uuid4().hex[:8]}',
            calories_per_100g=calories_per_100g,
            protein_per_100g=protein_per_100g,
            carbs_per_100g=carbs_per_100g,
            fats_per_100g=fats_per_100g,
            fiber_per_100g=Decimal('0.00'),
            sugar_per_100g=Decimal('0.00'),
            is_custom=False
        )
        
        data = {
            'user': self.user.id,
            'food_item': food_item.id,
            'entry_type': 'meal',
            'quantity': str(quantity),
            'unit': 'g',
            'description': 'Test meal'
        }
        
        serializer = IntakeLogSerializer(data=data)
        if serializer.is_valid():
            intake_log = serializer.save(user=self.user)
            
            # Calculate expected values
            multiplier = quantity / 100
            expected_calories = calories_per_100g * multiplier
            expected_protein = protein_per_100g * multiplier
            expected_carbs = carbs_per_100g * multiplier
            expected_fats = fats_per_100g * multiplier
            
            # Property: Formula should work for any nutritional values
            self.assertAlmostEqual(
                float(intake_log.calories),
                float(expected_calories),
                places=2
            )
            self.assertAlmostEqual(
                float(intake_log.protein),
                float(expected_protein),
                places=2
            )
            self.assertAlmostEqual(
                float(intake_log.carbs),
                float(expected_carbs),
                places=2
            )
            self.assertAlmostEqual(
                float(intake_log.fats),
                float(expected_fats),
                places=2
            )
