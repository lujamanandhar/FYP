from django.test import TestCase
from django.contrib.auth import get_user_model
from decimal import Decimal
from .models import FoodItem, IntakeLog
from .serializers import IntakeLogSerializer

User = get_user_model()


class IntakeLogSerializerTest(TestCase):
    """
    Test suite for IntakeLogSerializer with macro calculation.
    
    Requirements: 2.2-2.5, 2.7, 11.2, 11.4, 13.2
    """
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        # Create a test food item with known nutritional values
        self.food_item = FoodItem.objects.create(
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
    
    def test_macro_calculation_with_100g_quantity(self):
        """
        Test that macros are calculated correctly for 100g quantity.
        Formula: (nutrient_per_100g ÷ 100) × quantity
        
        Requirements: 2.2, 2.3, 2.4, 2.5
        """
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': 'meal',
            'quantity': Decimal('100.00'),
            'unit': 'g',
            'description': 'Test meal'
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        intake_log = serializer.save()
        
        # For 100g, macros should equal the per_100g values
        self.assertEqual(intake_log.calories, Decimal('200.00'))
        self.assertEqual(intake_log.protein, Decimal('20.00'))
        self.assertEqual(intake_log.carbs, Decimal('30.00'))
        self.assertEqual(intake_log.fats, Decimal('10.00'))
    
    def test_macro_calculation_with_200g_quantity(self):
        """
        Test that macros are calculated correctly for 200g quantity.
        
        Requirements: 2.2, 2.3, 2.4, 2.5
        """
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': 'snack',
            'quantity': Decimal('200.00'),
            'unit': 'g',
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        intake_log = serializer.save()
        
        # For 200g, macros should be double the per_100g values
        self.assertEqual(intake_log.calories, Decimal('400.00'))
        self.assertEqual(intake_log.protein, Decimal('40.00'))
        self.assertEqual(intake_log.carbs, Decimal('60.00'))
        self.assertEqual(intake_log.fats, Decimal('20.00'))
    
    def test_macro_calculation_with_50g_quantity(self):
        """
        Test that macros are calculated correctly for 50g quantity.
        
        Requirements: 2.2, 2.3, 2.4, 2.5
        """
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': 'drink',
            'quantity': Decimal('50.00'),
            'unit': 'g',
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        intake_log = serializer.save()
        
        # For 50g, macros should be half the per_100g values
        self.assertEqual(intake_log.calories, Decimal('100.00'))
        self.assertEqual(intake_log.protein, Decimal('10.00'))
        self.assertEqual(intake_log.carbs, Decimal('15.00'))
        self.assertEqual(intake_log.fats, Decimal('5.00'))
    
    def test_validate_quantity_positive(self):
        """
        Test that quantity validation rejects zero and negative values.
        
        Requirements: 11.2
        """
        # Test zero quantity
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': 'meal',
            'quantity': Decimal('0.00'),
            'unit': 'g',
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('quantity', serializer.errors)
        # Model validator catches this with "greater than or equal to 0.01"
        self.assertIn('greater than', str(serializer.errors['quantity']).lower())
        
        # Test negative quantity
        data['quantity'] = Decimal('-10.00')
        serializer = IntakeLogSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('quantity', serializer.errors)
    
    def test_validate_entry_type_valid(self):
        """
        Test that entry_type validation accepts valid types.
        
        Requirements: 2.7, 11.4
        """
        valid_types = ['meal', 'snack', 'drink']
        
        for entry_type in valid_types:
            data = {
                'user': self.user.id,
                'food_item': self.food_item.id,
                'entry_type': entry_type,
                'quantity': Decimal('100.00'),
                'unit': 'g',
            }
            
            serializer = IntakeLogSerializer(data=data)
            self.assertTrue(serializer.is_valid(), f"Failed for {entry_type}: {serializer.errors}")
    
    def test_validate_entry_type_invalid(self):
        """
        Test that entry_type validation rejects invalid types.
        
        Requirements: 2.7, 11.4
        """
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': 'invalid_type',
            'quantity': Decimal('100.00'),
            'unit': 'g',
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('entry_type', serializer.errors)
        # Model choices validation catches this
        self.assertIn('not a valid choice', str(serializer.errors['entry_type']).lower())
    
    def test_nested_food_item_details(self):
        """
        Test that food_item_details is properly nested in serialized output.
        
        Requirements: 13.2
        """
        intake_log = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food_item,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00')
        )
        
        serializer = IntakeLogSerializer(intake_log)
        data = serializer.data
        
        # Verify food_item_details is present and contains expected fields
        self.assertIn('food_item_details', data)
        self.assertEqual(data['food_item_details']['name'], 'Test Food')
        self.assertEqual(data['food_item_details']['brand'], 'Test Brand')
        self.assertEqual(float(data['food_item_details']['calories_per_100g']), 200.00)
    
    def test_read_only_fields(self):
        """
        Test that calculated macro fields are read-only.
        
        Requirements: 13.2
        """
        data = {
            'user': self.user.id,
            'food_item': self.food_item.id,
            'entry_type': 'meal',
            'quantity': Decimal('100.00'),
            'unit': 'g',
            # Try to override calculated fields (should be ignored)
            'calories': Decimal('999.99'),
            'protein': Decimal('999.99'),
            'carbs': Decimal('999.99'),
            'fats': Decimal('999.99'),
        }
        
        serializer = IntakeLogSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        intake_log = serializer.save()
        
        # Calculated values should be based on formula, not provided values
        self.assertEqual(intake_log.calories, Decimal('200.00'))
        self.assertEqual(intake_log.protein, Decimal('20.00'))
        self.assertEqual(intake_log.carbs, Decimal('30.00'))
        self.assertEqual(intake_log.fats, Decimal('10.00'))
