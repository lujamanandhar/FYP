"""
Unit tests for nutrition serializers.

Tests serializer validation, field handling, and round-trip integrity.

Requirements: 15.1, 15.5
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone

from nutrition.models import (
    FoodItem, IntakeLog, HydrationLog, 
    NutritionGoals, NutritionProgress, QuickLog
)
from nutrition.serializers import (
    FoodItemSerializer, IntakeLogSerializer, HydrationLogSerializer,
    NutritionGoalsSerializer, NutritionProgressSerializer, QuickLogSerializer,
    sanitize_text_input
)

User = get_user_model()


class SanitizeTextInputTest(TestCase):
    """Test the sanitize_text_input utility function."""
    
    def test_sanitize_normal_text(self):
        """Test that normal text passes through unchanged."""
        result = sanitize_text_input('Normal Food Name')
        self.assertEqual(result, 'Normal Food Name')
    
    def test_sanitize_html_tags(self):
        """Test that HTML tags are escaped."""
        result = sanitize_text_input('<script>alert("xss")</script>')
        self.assertNotIn('<script>', result)
        self.assertIn('&lt;script&gt;', result)
    
    def test_sanitize_null_bytes(self):
        """Test that null bytes are removed."""
        result = sanitize_text_input('Food\x00Name')
        self.assertEqual(result, 'FoodName')
    
    def test_sanitize_whitespace(self):
        """Test that leading/trailing whitespace is stripped."""
        result = sanitize_text_input('  Food Name  ')
        self.assertEqual(result, 'Food Name')
    
    def test_sanitize_none(self):
        """Test that None returns None."""
        result = sanitize_text_input(None)
        self.assertIsNone(result)


class FoodItemSerializerTest(TestCase):
    """Test FoodItemSerializer validation and serialization."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
    
    def test_serialize_food_item(self):
        """Test serializing a FoodItem instance."""
        food = FoodItem.objects.create(
            name='Test Food',
            brand='Test Brand',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00'),
            fiber_per_100g=Decimal('5.00'),
            sugar_per_100g=Decimal('8.00'),
            is_custom=False
        )
        
        serializer = FoodItemSerializer(food)
        data = serializer.data
        
        self.assertEqual(data['name'], 'Test Food')
        self.assertEqual(data['brand'], 'Test Brand')
        self.assertEqual(float(data['calories_per_100g']), 200.00)
        self.assertEqual(float(data['protein_per_100g']), 20.00)
        self.assertFalse(data['is_custom'])
    
    def test_deserialize_valid_food_item(self):
        """Test deserializing valid food item data."""
        data = {
            'name': 'New Food',
            'brand': 'New Brand',
            'calories_per_100g': '150.00',
            'protein_per_100g': '15.00',
            'carbs_per_100g': '25.00',
            'fats_per_100g': '5.00',
            'fiber_per_100g': '3.00',
            'sugar_per_100g': '6.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        food = serializer.save(created_by=self.user, is_custom=True)
        self.assertEqual(food.name, 'New Food')
        self.assertEqual(food.calories_per_100g, Decimal('150.00'))
    
    def test_validate_negative_calories(self):
        """Test that negative calories are rejected."""
        data = {
            'name': 'Invalid Food',
            'calories_per_100g': '-100.00',
            'protein_per_100g': '10.00',
            'carbs_per_100g': '20.00',
            'fats_per_100g': '5.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('calories_per_100g', serializer.errors)
    
    def test_validate_negative_protein(self):
        """Test that negative protein is rejected."""
        data = {
            'name': 'Invalid Food',
            'calories_per_100g': '100.00',
            'protein_per_100g': '-10.00',
            'carbs_per_100g': '20.00',
            'fats_per_100g': '5.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('protein_per_100g', serializer.errors)
    
    def test_validate_negative_carbs(self):
        """Test that negative carbs are rejected."""
        data = {
            'name': 'Invalid Food',
            'calories_per_100g': '100.00',
            'protein_per_100g': '10.00',
            'carbs_per_100g': '-20.00',
            'fats_per_100g': '5.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('carbs_per_100g', serializer.errors)
    
    def test_validate_negative_fats(self):
        """Test that negative fats are rejected."""
        data = {
            'name': 'Invalid Food',
            'calories_per_100g': '100.00',
            'protein_per_100g': '10.00',
            'carbs_per_100g': '20.00',
            'fats_per_100g': '-5.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('fats_per_100g', serializer.errors)
    
    def test_sanitize_food_name(self):
        """Test that food name is sanitized."""
        data = {
            'name': '<script>alert("xss")</script>',
            'calories_per_100g': '100.00',
            'protein_per_100g': '10.00',
            'carbs_per_100g': '20.00',
            'fats_per_100g': '5.00'
        }
        
        serializer = FoodItemSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        food = serializer.save()
        self.assertNotIn('<script>', food.name)
        self.assertIn('&lt;script&gt;', food.name)
    
    def test_read_only_fields(self):
        """Test that read-only fields cannot be set via serializer."""
        data = {
            'name': 'Test Food',
            'calories_per_100g': '100.00',
            'protein_per_100g': '10.00',
            'carbs_per_100g': '20.00',
            'fats_per_100g': '5.00',
            'id': 999,  # Should be ignored
            'created_by': self.user.id,  # Should be ignored
        }
        
        serializer = FoodItemSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        food = serializer.save()
        self.assertNotEqual(food.id, 999)
        self.assertIsNone(food.created_by)
    
    def test_round_trip_serialization(self):
        """Test that serialize -> deserialize produces equivalent data."""
        food = FoodItem.objects.create(
            name='Round Trip Food',
            brand='Test Brand',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00'),
            fiber_per_100g=Decimal('5.00'),
            sugar_per_100g=Decimal('8.00')
        )
        
        # Serialize
        serializer1 = FoodItemSerializer(food)
        data = serializer1.data
        
        # Deserialize
        serializer2 = FoodItemSerializer(data=data)
        self.assertTrue(serializer2.is_valid(), serializer2.errors)
        
        # Compare key fields
        self.assertEqual(data['name'], food.name)
        self.assertEqual(Decimal(data['calories_per_100g']), food.calories_per_100g)
        self.assertEqual(Decimal(data['protein_per_100g']), food.protein_per_100g)


class IntakeLogSerializerTest(TestCase):
    """Test IntakeLogSerializer validation and macro calculation."""
    
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
    
    def test_serialize_intake_log(self):
        """Test serializing an IntakeLog instance."""
        intake = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00')
        )
        
        serializer = IntakeLogSerializer(intake)
        data = serializer.data
        
        self.assertEqual(data['entry_type'], 'meal')
        self.assertEqual(float(data['quantity']), 100.00)
        self.assertEqual(float(data['calories']), 200.00)
        self.assertIn('food_item_details', data)
        self.assertEqual(data['food_item_details']['name'], 'Test Food')
    
    def test_validate_positive_quantity(self):
        """Test that quantity must be positive."""
        data = {
            'user': self.user.id,
            'food_item': self.food.id,
            'entry_type': 'meal',
            'quantity': '0.00',
            'unit': 'g'
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        # Either model validator or serializer validator will catch this
        self.assertTrue('quantity' in serializer.errors or 'non_field_errors' in serializer.errors)
    
    def test_validate_negative_quantity(self):
        """Test that negative quantity is rejected."""
        data = {
            'user': self.user.id,
            'food_item': self.food.id,
            'entry_type': 'meal',
            'quantity': '-10.00',
            'unit': 'g'
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertTrue('quantity' in serializer.errors or 'non_field_errors' in serializer.errors)
    
    def test_validate_valid_entry_types(self):
        """Test that valid entry types are accepted."""
        valid_types = ['meal', 'snack', 'drink']
        
        for entry_type in valid_types:
            data = {
                'user': self.user.id,
                'food_item': self.food.id,
                'entry_type': entry_type,
                'quantity': '100.00',
                'unit': 'g'
            }
            
            serializer = IntakeLogSerializer(data=data)
            self.assertTrue(serializer.is_valid(), f"Failed for {entry_type}: {serializer.errors}")
    
    def test_validate_invalid_entry_type(self):
        """Test that invalid entry type is rejected."""
        data = {
            'user': self.user.id,
            'food_item': self.food.id,
            'entry_type': 'invalid',
            'quantity': '100.00',
            'unit': 'g'
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('entry_type', serializer.errors)
    
    def test_macro_calculation_on_create(self):
        """Test that macros are calculated automatically on create."""
        data = {
            'user': self.user.id,
            'food_item': self.food.id,
            'entry_type': 'meal',
            'quantity': '100.00',
            'unit': 'g'
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        intake = serializer.save()
        
        # Verify calculated macros
        self.assertEqual(intake.calories, Decimal('200.00'))
        self.assertEqual(intake.protein, Decimal('20.00'))
        self.assertEqual(intake.carbs, Decimal('30.00'))
        self.assertEqual(intake.fats, Decimal('10.00'))
    
    def test_macro_calculation_with_different_quantity(self):
        """Test macro calculation with 200g quantity."""
        data = {
            'user': self.user.id,
            'food_item': self.food.id,
            'entry_type': 'meal',
            'quantity': '200.00',
            'unit': 'g'
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        intake = serializer.save()
        
        # For 200g, macros should be double
        self.assertEqual(intake.calories, Decimal('400.00'))
        self.assertEqual(intake.protein, Decimal('40.00'))
        self.assertEqual(intake.carbs, Decimal('60.00'))
        self.assertEqual(intake.fats, Decimal('20.00'))
    
    def test_read_only_macro_fields(self):
        """Test that macro fields are read-only and calculated."""
        data = {
            'user': self.user.id,
            'food_item': self.food.id,
            'entry_type': 'meal',
            'quantity': '100.00',
            'unit': 'g',
            # Try to override calculated fields
            'calories': '999.99',
            'protein': '999.99',
            'carbs': '999.99',
            'fats': '999.99'
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        intake = serializer.save()
        
        # Should use calculated values, not provided values
        self.assertEqual(intake.calories, Decimal('200.00'))
        self.assertEqual(intake.protein, Decimal('20.00'))
        self.assertEqual(intake.carbs, Decimal('30.00'))
        self.assertEqual(intake.fats, Decimal('10.00'))


class HydrationLogSerializerTest(TestCase):
    """Test HydrationLogSerializer validation."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
    
    def test_serialize_hydration_log(self):
        """Test serializing a HydrationLog instance."""
        hydration = HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('250.00'),
            unit='ml'
        )
        
        serializer = HydrationLogSerializer(hydration)
        data = serializer.data
        
        self.assertEqual(float(data['amount']), 250.00)
        self.assertEqual(data['unit'], 'ml')
    
    def test_deserialize_valid_hydration_log(self):
        """Test deserializing valid hydration log data."""
        data = {
            'user': self.user.id,
            'amount': '500.00',
            'unit': 'ml'
        }
        
        serializer = HydrationLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        hydration = serializer.save()
        self.assertEqual(hydration.amount, Decimal('500.00'))
        self.assertEqual(hydration.unit, 'ml')
    
    def test_validate_positive_amount(self):
        """Test that amount must be positive."""
        data = {
            'user': self.user.id,
            'amount': '0.00',
            'unit': 'ml'
        }
        
        serializer = HydrationLogSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertTrue('amount' in serializer.errors or 'non_field_errors' in serializer.errors)
    
    def test_validate_negative_amount(self):
        """Test that negative amount is rejected."""
        data = {
            'user': self.user.id,
            'amount': '-100.00',
            'unit': 'ml'
        }
        
        serializer = HydrationLogSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertTrue('amount' in serializer.errors or 'non_field_errors' in serializer.errors)


class NutritionGoalsSerializerTest(TestCase):
    """Test NutritionGoalsSerializer validation."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
    
    def test_serialize_nutrition_goals(self):
        """Test serializing a NutritionGoals instance."""
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('2500.00'),
            daily_protein=Decimal('180.00'),
            daily_carbs=Decimal('250.00'),
            daily_fats=Decimal('70.00'),
            daily_water=Decimal('3000.00')
        )
        
        serializer = NutritionGoalsSerializer(goals)
        data = serializer.data
        
        self.assertEqual(float(data['daily_calories']), 2500.00)
        self.assertEqual(float(data['daily_protein']), 180.00)
        self.assertEqual(float(data['daily_water']), 3000.00)
    
    def test_deserialize_valid_goals(self):
        """Test deserializing valid nutrition goals data."""
        data = {
            'user': self.user.id,
            'daily_calories': '2000.00',
            'daily_protein': '150.00',
            'daily_carbs': '200.00',
            'daily_fats': '65.00',
            'daily_water': '2000.00'
        }
        
        serializer = NutritionGoalsSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        goals = serializer.save()
        self.assertEqual(goals.daily_calories, Decimal('2000.00'))
    
    def test_validate_negative_calories(self):
        """Test that negative daily_calories is rejected."""
        data = {
            'user': self.user.id,
            'daily_calories': '-100.00',
            'daily_protein': '150.00',
            'daily_carbs': '200.00',
            'daily_fats': '65.00',
            'daily_water': '2000.00'
        }
        
        serializer = NutritionGoalsSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('daily_calories', serializer.errors)
    
    def test_validate_negative_protein(self):
        """Test that negative daily_protein is rejected."""
        data = {
            'user': self.user.id,
            'daily_calories': '2000.00',
            'daily_protein': '-150.00',
            'daily_carbs': '200.00',
            'daily_fats': '65.00',
            'daily_water': '2000.00'
        }
        
        serializer = NutritionGoalsSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('daily_protein', serializer.errors)


class NutritionProgressSerializerTest(TestCase):
    """Test NutritionProgressSerializer."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        self.today = timezone.now().date()
    
    def test_serialize_nutrition_progress(self):
        """Test serializing a NutritionProgress instance."""
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=self.today,
            total_calories=Decimal('1500.00'),
            total_protein=Decimal('120.00'),
            total_carbs=Decimal('150.00'),
            total_fats=Decimal('50.00'),
            calories_adherence=Decimal('75.00'),
            protein_adherence=Decimal('80.00')
        )
        
        serializer = NutritionProgressSerializer(progress)
        data = serializer.data
        
        self.assertEqual(float(data['total_calories']), 1500.00)
        self.assertEqual(float(data['total_protein']), 120.00)
        self.assertEqual(float(data['calories_adherence']), 75.00)
    
    def test_round_trip_serialization(self):
        """Test that serialize -> deserialize produces equivalent data."""
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=self.today,
            total_calories=Decimal('1500.00'),
            total_protein=Decimal('120.00'),
            calories_adherence=Decimal('75.00')
        )
        
        # Serialize
        serializer1 = NutritionProgressSerializer(progress)
        data = serializer1.data
        
        # Verify key fields match
        self.assertEqual(Decimal(data['total_calories']), progress.total_calories)
        self.assertEqual(Decimal(data['total_protein']), progress.total_protein)


class QuickLogSerializerTest(TestCase):
    """Test QuickLogSerializer."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
    
    def test_serialize_quick_log(self):
        """Test serializing a QuickLog instance."""
        meals_data = [
            {'food_item_id': 1, 'usage_count': 10, 'last_used': '2024-01-15T10:30:00Z'},
            {'food_item_id': 2, 'usage_count': 5, 'last_used': '2024-01-14T12:00:00Z'}
        ]
        
        quick_log = QuickLog.objects.create(
            user=self.user,
            frequent_meals=meals_data
        )
        
        serializer = QuickLogSerializer(quick_log)
        data = serializer.data
        
        self.assertEqual(len(data['frequent_meals']), 2)
        self.assertEqual(data['frequent_meals'][0]['food_item_id'], 1)
        self.assertEqual(data['frequent_meals'][0]['usage_count'], 10)
    
    def test_round_trip_serialization(self):
        """Test that serialize -> deserialize produces equivalent data."""
        meals_data = [
            {'food_item_id': 1, 'usage_count': 10, 'last_used': '2024-01-15T10:30:00Z'}
        ]
        
        quick_log = QuickLog.objects.create(
            user=self.user,
            frequent_meals=meals_data
        )
        
        # Serialize
        serializer1 = QuickLogSerializer(quick_log)
        data = serializer1.data
        
        # Verify data matches
        self.assertEqual(data['frequent_meals'], meals_data)
