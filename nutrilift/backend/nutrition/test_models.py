"""
Unit tests for nutrition models.

Tests model creation, validation, constraints, and default values.

Requirements: 15.1, 15.2, 15.3, 15.8
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.utils import timezone

from nutrition.models import (
    FoodItem, IntakeLog, HydrationLog, 
    NutritionGoals, NutritionProgress, QuickLog
)

User = get_user_model()


class FoodItemModelTest(TestCase):
    """Test FoodItem model creation and validation."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_system_food_item(self):
        """Test creating a system food item with valid data."""
        food = FoodItem.objects.create(
            name='Chicken Breast',
            brand='Generic',
            calories_per_100g=Decimal('165.00'),
            protein_per_100g=Decimal('31.00'),
            carbs_per_100g=Decimal('0.00'),
            fats_per_100g=Decimal('3.60'),
            fiber_per_100g=Decimal('0.00'),
            sugar_per_100g=Decimal('0.00'),
            is_custom=False
        )
        
        self.assertEqual(food.name, 'Chicken Breast')
        self.assertEqual(food.brand, 'Generic')
        self.assertEqual(food.calories_per_100g, Decimal('165.00'))
        self.assertFalse(food.is_custom)
        self.assertIsNone(food.created_by)
    
    def test_create_custom_food_item(self):
        """Test creating a custom food item with user ownership."""
        food = FoodItem.objects.create(
            name='My Custom Recipe',
            calories_per_100g=Decimal('250.00'),
            protein_per_100g=Decimal('15.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('8.00'),
            is_custom=True,
            created_by=self.user
        )
        
        self.assertEqual(food.name, 'My Custom Recipe')
        self.assertTrue(food.is_custom)
        self.assertEqual(food.created_by, self.user)
    
    def test_food_item_default_values(self):
        """Test that fiber and sugar default to 0.0."""
        food = FoodItem.objects.create(
            name='Simple Food',
            calories_per_100g=Decimal('100.00'),
            protein_per_100g=Decimal('10.00'),
            carbs_per_100g=Decimal('20.00'),
            fats_per_100g=Decimal('5.00')
        )
        
        self.assertEqual(food.fiber_per_100g, Decimal('0.00'))
        self.assertEqual(food.sugar_per_100g, Decimal('0.00'))
        self.assertFalse(food.is_custom)
    
    def test_food_item_negative_calories_validation(self):
        """Test that negative calories are rejected by validator."""
        food = FoodItem(
            name='Invalid Food',
            calories_per_100g=Decimal('-100.00'),
            protein_per_100g=Decimal('10.00'),
            carbs_per_100g=Decimal('20.00'),
            fats_per_100g=Decimal('5.00')
        )
        
        with self.assertRaises(ValidationError):
            food.full_clean()
    
    def test_food_item_negative_protein_validation(self):
        """Test that negative protein is rejected by validator."""
        food = FoodItem(
            name='Invalid Food',
            calories_per_100g=Decimal('100.00'),
            protein_per_100g=Decimal('-10.00'),
            carbs_per_100g=Decimal('20.00'),
            fats_per_100g=Decimal('5.00')
        )
        
        with self.assertRaises(ValidationError):
            food.full_clean()
    
    def test_food_item_str_representation(self):
        """Test string representation of FoodItem."""
        food = FoodItem.objects.create(
            name='Test Food',
            brand='Test Brand',
            calories_per_100g=Decimal('100.00'),
            protein_per_100g=Decimal('10.00'),
            carbs_per_100g=Decimal('20.00'),
            fats_per_100g=Decimal('5.00')
        )
        
        self.assertEqual(str(food), 'Test Food (Test Brand)')
    
    def test_food_item_str_without_brand(self):
        """Test string representation without brand."""
        food = FoodItem.objects.create(
            name='Test Food',
            calories_per_100g=Decimal('100.00'),
            protein_per_100g=Decimal('10.00'),
            carbs_per_100g=Decimal('20.00'),
            fats_per_100g=Decimal('5.00')
        )
        
        self.assertEqual(str(food), 'Test Food')


class IntakeLogModelTest(TestCase):
    """Test IntakeLog model creation and validation."""
    
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
    
    def test_create_intake_log_meal(self):
        """Test creating an intake log with entry_type='meal'."""
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
        
        self.assertEqual(intake.user, self.user)
        self.assertEqual(intake.food_item, self.food)
        self.assertEqual(intake.entry_type, 'meal')
        self.assertEqual(intake.quantity, Decimal('100.00'))
        self.assertEqual(intake.unit, 'g')
    
    def test_create_intake_log_snack(self):
        """Test creating an intake log with entry_type='snack'."""
        intake = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='snack',
            quantity=Decimal('50.00'),
            unit='g',
            calories=Decimal('100.00'),
            protein=Decimal('10.00'),
            carbs=Decimal('15.00'),
            fats=Decimal('5.00')
        )
        
        self.assertEqual(intake.entry_type, 'snack')
    
    def test_create_intake_log_drink(self):
        """Test creating an intake log with entry_type='drink'."""
        intake = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='drink',
            quantity=Decimal('250.00'),
            unit='ml',
            calories=Decimal('500.00'),
            protein=Decimal('50.00'),
            carbs=Decimal('75.00'),
            fats=Decimal('25.00')
        )
        
        self.assertEqual(intake.entry_type, 'drink')
        self.assertEqual(intake.unit, 'ml')
    
    def test_intake_log_quantity_validation(self):
        """Test that quantity must be at least 0.01."""
        intake = IntakeLog(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('0.00'),
            unit='g',
            calories=Decimal('0.00'),
            protein=Decimal('0.00'),
            carbs=Decimal('0.00'),
            fats=Decimal('0.00')
        )
        
        with self.assertRaises(ValidationError):
            intake.full_clean()
    
    def test_intake_log_default_logged_at(self):
        """Test that logged_at defaults to current time."""
        before = timezone.now()
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
        after = timezone.now()
        
        self.assertGreaterEqual(intake.logged_at, before)
        self.assertLessEqual(intake.logged_at, after)
    
    def test_intake_log_str_representation(self):
        """Test string representation of IntakeLog."""
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
        
        self.assertIn(self.user.email, str(intake))
        self.assertIn(self.food.name, str(intake))
        self.assertIn('meal', str(intake))


class HydrationLogModelTest(TestCase):
    """Test HydrationLog model creation and validation."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_hydration_log(self):
        """Test creating a hydration log."""
        hydration = HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('250.00'),
            unit='ml'
        )
        
        self.assertEqual(hydration.user, self.user)
        self.assertEqual(hydration.amount, Decimal('250.00'))
        self.assertEqual(hydration.unit, 'ml')
    
    def test_hydration_log_default_unit(self):
        """Test that unit defaults to 'ml'."""
        hydration = HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('500.00')
        )
        
        self.assertEqual(hydration.unit, 'ml')
    
    def test_hydration_log_amount_validation(self):
        """Test that amount must be at least 0.01."""
        hydration = HydrationLog(
            user=self.user,
            amount=Decimal('0.00'),
            unit='ml'
        )
        
        with self.assertRaises(ValidationError):
            hydration.full_clean()
    
    def test_hydration_log_default_logged_at(self):
        """Test that logged_at defaults to current time."""
        before = timezone.now()
        hydration = HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('250.00')
        )
        after = timezone.now()
        
        self.assertGreaterEqual(hydration.logged_at, before)
        self.assertLessEqual(hydration.logged_at, after)
    
    def test_hydration_log_str_representation(self):
        """Test string representation of HydrationLog."""
        hydration = HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('250.00'),
            unit='ml'
        )
        
        self.assertIn(self.user.email, str(hydration))
        self.assertIn('250', str(hydration))
        self.assertIn('ml', str(hydration))


class NutritionGoalsModelTest(TestCase):
    """Test NutritionGoals model creation and validation."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_nutrition_goals(self):
        """Test creating nutrition goals."""
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('2500.00'),
            daily_protein=Decimal('180.00'),
            daily_carbs=Decimal('250.00'),
            daily_fats=Decimal('70.00'),
            daily_water=Decimal('3000.00')
        )
        
        self.assertEqual(goals.user, self.user)
        self.assertEqual(goals.daily_calories, Decimal('2500.00'))
        self.assertEqual(goals.daily_protein, Decimal('180.00'))
        self.assertEqual(goals.daily_carbs, Decimal('250.00'))
        self.assertEqual(goals.daily_fats, Decimal('70.00'))
        self.assertEqual(goals.daily_water, Decimal('3000.00'))
    
    def test_nutrition_goals_default_values(self):
        """Test that nutrition goals have default values."""
        goals = NutritionGoals.objects.create(user=self.user)
        
        self.assertEqual(goals.daily_calories, Decimal('2000.00'))
        self.assertEqual(goals.daily_protein, Decimal('150.00'))
        self.assertEqual(goals.daily_carbs, Decimal('200.00'))
        self.assertEqual(goals.daily_fats, Decimal('65.00'))
        self.assertEqual(goals.daily_water, Decimal('2000.00'))
    
    def test_nutrition_goals_one_per_user(self):
        """Test that each user can only have one NutritionGoals record."""
        NutritionGoals.objects.create(user=self.user)
        
        # Attempting to create a second goals record should fail
        with self.assertRaises(IntegrityError):
            NutritionGoals.objects.create(user=self.user)
    
    def test_nutrition_goals_negative_validation(self):
        """Test that negative goal values are rejected."""
        goals = NutritionGoals(
            user=self.user,
            daily_calories=Decimal('-100.00')
        )
        
        with self.assertRaises(ValidationError):
            goals.full_clean()
    
    def test_nutrition_goals_str_representation(self):
        """Test string representation of NutritionGoals."""
        goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('2000.00'),
            daily_protein=Decimal('150.00')
        )
        
        self.assertIn(self.user.email, str(goals))
        self.assertIn('2000', str(goals))
        self.assertIn('150', str(goals))


class NutritionProgressModelTest(TestCase):
    """Test NutritionProgress model creation and validation."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        self.today = timezone.now().date()
    
    def test_create_nutrition_progress(self):
        """Test creating nutrition progress."""
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=self.today,
            total_calories=Decimal('1500.00'),
            total_protein=Decimal('120.00'),
            total_carbs=Decimal('150.00'),
            total_fats=Decimal('50.00'),
            total_water=Decimal('2000.00'),
            calories_adherence=Decimal('75.00'),
            protein_adherence=Decimal('80.00'),
            carbs_adherence=Decimal('75.00'),
            fats_adherence=Decimal('76.92'),
            water_adherence=Decimal('100.00')
        )
        
        self.assertEqual(progress.user, self.user)
        self.assertEqual(progress.progress_date, self.today)
        self.assertEqual(progress.total_calories, Decimal('1500.00'))
        self.assertEqual(progress.calories_adherence, Decimal('75.00'))
    
    def test_nutrition_progress_default_values(self):
        """Test that nutrition progress has default zero values."""
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=self.today
        )
        
        self.assertEqual(progress.total_calories, Decimal('0.00'))
        self.assertEqual(progress.total_protein, Decimal('0.00'))
        self.assertEqual(progress.total_carbs, Decimal('0.00'))
        self.assertEqual(progress.total_fats, Decimal('0.00'))
        self.assertEqual(progress.total_water, Decimal('0.00'))
        self.assertEqual(progress.calories_adherence, Decimal('0.00'))
        self.assertEqual(progress.protein_adherence, Decimal('0.00'))
    
    def test_nutrition_progress_unique_constraint(self):
        """Test that user + progress_date must be unique."""
        NutritionProgress.objects.create(
            user=self.user,
            progress_date=self.today
        )
        
        # Attempting to create a second progress record for same user and date should fail
        with self.assertRaises(IntegrityError):
            NutritionProgress.objects.create(
                user=self.user,
                progress_date=self.today
            )
    
    def test_nutrition_progress_str_representation(self):
        """Test string representation of NutritionProgress."""
        progress = NutritionProgress.objects.create(
            user=self.user,
            progress_date=self.today,
            total_calories=Decimal('1500.00')
        )
        
        self.assertIn(self.user.email, str(progress))
        self.assertIn(str(self.today), str(progress))
        self.assertIn('1500', str(progress))


class QuickLogModelTest(TestCase):
    """Test QuickLog model creation and validation."""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_quick_log(self):
        """Test creating a quick log."""
        quick_log = QuickLog.objects.create(user=self.user)
        
        self.assertEqual(quick_log.user, self.user)
        self.assertEqual(quick_log.frequent_meals, [])
    
    def test_quick_log_with_frequent_meals(self):
        """Test creating a quick log with frequent meals data."""
        meals_data = [
            {
                'food_item_id': 1,
                'usage_count': 10,
                'last_used': '2024-01-15T10:30:00Z'
            },
            {
                'food_item_id': 2,
                'usage_count': 5,
                'last_used': '2024-01-14T12:00:00Z'
            }
        ]
        
        quick_log = QuickLog.objects.create(
            user=self.user,
            frequent_meals=meals_data
        )
        
        self.assertEqual(len(quick_log.frequent_meals), 2)
        self.assertEqual(quick_log.frequent_meals[0]['food_item_id'], 1)
        self.assertEqual(quick_log.frequent_meals[0]['usage_count'], 10)
    
    def test_quick_log_one_per_user(self):
        """Test that each user can only have one QuickLog record."""
        QuickLog.objects.create(user=self.user)
        
        # Attempting to create a second quick log should fail
        with self.assertRaises(IntegrityError):
            QuickLog.objects.create(user=self.user)
    
    def test_quick_log_str_representation(self):
        """Test string representation of QuickLog."""
        meals_data = [
            {'food_item_id': 1, 'usage_count': 10, 'last_used': '2024-01-15T10:30:00Z'},
            {'food_item_id': 2, 'usage_count': 5, 'last_used': '2024-01-14T12:00:00Z'}
        ]
        
        quick_log = QuickLog.objects.create(
            user=self.user,
            frequent_meals=meals_data
        )
        
        self.assertIn(self.user.email, str(quick_log))
        self.assertIn('2', str(quick_log))
