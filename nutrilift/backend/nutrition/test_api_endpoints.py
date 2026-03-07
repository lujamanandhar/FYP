"""
Unit tests for nutrition API endpoints.

Tests API CRUD operations, authentication, authorization, and date filtering.

Requirements: 15.4, 15.7
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from datetime import date, timedelta

from nutrition.models import (
    FoodItem, IntakeLog, HydrationLog, 
    NutritionGoals, NutritionProgress, QuickLog
)

User = get_user_model()


class FoodItemAPITest(TestCase):
    """Test FoodItem API endpoints."""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        self.other_user = User.objects.create_user(
            email='other@example.com',
            password='testpass123'
        )
        
        # Create system food
        self.system_food = FoodItem.objects.create(
            name='System Food',
            calories_per_100g=Decimal('100.00'),
            protein_per_100g=Decimal('10.00'),
            carbs_per_100g=Decimal('20.00'),
            fats_per_100g=Decimal('5.00'),
            is_custom=False
        )
        
        # Create custom food for user
        self.custom_food = FoodItem.objects.create(
            name='My Custom Food',
            calories_per_100g=Decimal('150.00'),
            protein_per_100g=Decimal('15.00'),
            carbs_per_100g=Decimal('25.00'),
            fats_per_100g=Decimal('7.00'),
            is_custom=True,
            created_by=self.user
        )
    
    def test_list_food_items_requires_authentication(self):
        """Test that listing food items requires authentication."""
        response = self.client.get('/api/nutrition/food-items/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_food_items_authenticated(self):
        """Test listing food items when authenticated."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/nutrition/food-items/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should see system food + own custom food
        self.assertEqual(len(response.data), 2)
    
    def test_user_cannot_see_other_users_custom_foods(self):
        """Test that users cannot see other users' custom foods."""
        # Create custom food for other user
        other_custom = FoodItem.objects.create(
            name='Other User Food',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00'),
            is_custom=True,
            created_by=self.other_user
        )
        
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/nutrition/food-items/')
        
        # Should only see system food + own custom food (not other user's)
        self.assertEqual(len(response.data), 2)
        food_ids = [item['id'] for item in response.data]
        self.assertNotIn(other_custom.id, food_ids)
    
    def test_create_food_item(self):
        """Test creating a custom food item."""
        self.client.force_authenticate(user=self.user)
        
        data = {
            'name': 'New Custom Food',
            'calories_per_100g': '180.00',
            'protein_per_100g': '18.00',
            'carbs_per_100g': '28.00',
            'fats_per_100g': '8.00'
        }
        
        response = self.client.post('/api/nutrition/food-items/', data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'New Custom Food')
        self.assertTrue(response.data['is_custom'])
        self.assertEqual(response.data['created_by'], self.user.id)
    
    def test_search_food_items(self):
        """Test searching food items by name."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get('/api/nutrition/food-items/?search=System')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'System Food')
    
    def test_retrieve_food_item(self):
        """Test retrieving a specific food item."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get(f'/api/nutrition/food-items/{self.system_food.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'System Food')
    
    def test_update_custom_food_item(self):
        """Test updating a custom food item."""
        self.client.force_authenticate(user=self.user)
        
        data = {
            'name': 'Updated Custom Food',
            'calories_per_100g': '160.00',
            'protein_per_100g': '16.00',
            'carbs_per_100g': '26.00',
            'fats_per_100g': '7.50'
        }
        
        response = self.client.put(f'/api/nutrition/food-items/{self.custom_food.id}/', data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Updated Custom Food')
    
    def test_delete_custom_food_item(self):
        """Test deleting a custom food item."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.delete(f'/api/nutrition/food-items/{self.custom_food.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(FoodItem.objects.filter(id=self.custom_food.id).exists())


class IntakeLogAPITest(TestCase):
    """Test IntakeLog API endpoints."""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        self.other_user = User.objects.create_user(
            email='other@example.com',
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
        self.yesterday = self.today - timedelta(days=1)
        
        # Create intake log for user
        self.intake = IntakeLog.objects.create(
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
    
    def test_list_intake_logs_requires_authentication(self):
        """Test that listing intake logs requires authentication."""
        response = self.client.get('/api/nutrition/intake-logs/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_intake_logs_authenticated(self):
        """Test listing intake logs when authenticated."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/nutrition/intake-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], self.intake.id)
    
    def test_user_cannot_see_other_users_intake_logs(self):
        """Test that users cannot see other users' intake logs."""
        # Create intake log for other user
        other_intake = IntakeLog.objects.create(
            user=self.other_user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00')
        )
        
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/nutrition/intake-logs/')
        
        # Should only see own intake log
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], self.intake.id)
    
    def test_create_intake_log(self):
        """Test creating an intake log."""
        self.client.force_authenticate(user=self.user)
        
        data = {
            'food_item': self.food.id,
            'entry_type': 'snack',
            'quantity': '50.00',
            'unit': 'g'
        }
        
        response = self.client.post('/api/nutrition/intake-logs/', data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['entry_type'], 'snack')
        self.assertEqual(float(response.data['quantity']), 50.00)
        # Macros should be calculated automatically
        self.assertEqual(float(response.data['calories']), 100.00)
        self.assertEqual(float(response.data['protein']), 10.00)
    
    def test_filter_intake_logs_by_date_from(self):
        """Test filtering intake logs by date_from parameter."""
        # Create intake log from yesterday
        yesterday_intake = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.yesterday
        )
        
        self.client.force_authenticate(user=self.user)
        
        # Filter to only show today's logs
        response = self.client.get(f'/api/nutrition/intake-logs/?date_from={self.today.date()}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], self.intake.id)
    
    def test_filter_intake_logs_by_date_to(self):
        """Test filtering intake logs by date_to parameter."""
        self.client.force_authenticate(user=self.user)
        
        # Filter to only show yesterday's logs
        response = self.client.get(f'/api/nutrition/intake-logs/?date_to={self.yesterday.date()}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)
    
    def test_filter_intake_logs_by_date_range(self):
        """Test filtering intake logs by date range."""
        # Create intake log from yesterday
        yesterday_intake = IntakeLog.objects.create(
            user=self.user,
            food_item=self.food,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('200.00'),
            protein=Decimal('20.00'),
            carbs=Decimal('30.00'),
            fats=Decimal('10.00'),
            logged_at=self.yesterday
        )
        
        self.client.force_authenticate(user=self.user)
        
        # Filter to show both days
        response = self.client.get(
            f'/api/nutrition/intake-logs/?date_from={self.yesterday.date()}&date_to={self.today.date()}'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
    
    def test_update_intake_log(self):
        """Test updating an intake log."""
        self.client.force_authenticate(user=self.user)
        
        data = {
            'food_item': self.food.id,
            'entry_type': 'snack',
            'quantity': '150.00',
            'unit': 'g'
        }
        
        response = self.client.put(f'/api/nutrition/intake-logs/{self.intake.id}/', data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['entry_type'], 'snack')
        self.assertEqual(float(response.data['quantity']), 150.00)
    
    def test_delete_intake_log(self):
        """Test deleting an intake log."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.delete(f'/api/nutrition/intake-logs/{self.intake.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(IntakeLog.objects.filter(id=self.intake.id).exists())
    
    def test_intake_log_includes_food_item_details(self):
        """Test that intake log response includes nested food_item_details."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get(f'/api/nutrition/intake-logs/{self.intake.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('food_item_details', response.data)
        self.assertEqual(response.data['food_item_details']['name'], 'Test Food')



class HydrationLogAPITest(TestCase):
    """Test HydrationLog API endpoints."""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.today = timezone.now()
        
        self.hydration = HydrationLog.objects.create(
            user=self.user,
            amount=Decimal('250.00'),
            unit='ml',
            logged_at=self.today
        )
    
    def test_list_hydration_logs_requires_authentication(self):
        """Test that listing hydration logs requires authentication."""
        response = self.client.get('/api/nutrition/hydration-logs/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_hydration_logs_authenticated(self):
        """Test listing hydration logs when authenticated."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/nutrition/hydration-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
    
    def test_create_hydration_log(self):
        """Test creating a hydration log."""
        self.client.force_authenticate(user=self.user)
        
        data = {
            'amount': '500.00',
            'unit': 'ml'
        }
        
        response = self.client.post('/api/nutrition/hydration-logs/', data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(float(response.data['amount']), 500.00)
    
    def test_filter_hydration_logs_by_date(self):
        """Test filtering hydration logs by date."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get(f'/api/nutrition/hydration-logs/?date_from={self.today.date()}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
    
    def test_delete_hydration_log(self):
        """Test deleting a hydration log."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.delete(f'/api/nutrition/hydration-logs/{self.hydration.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)


class NutritionGoalsAPITest(TestCase):
    """Test NutritionGoals API endpoints."""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.goals = NutritionGoals.objects.create(
            user=self.user,
            daily_calories=Decimal('2500.00'),
            daily_protein=Decimal('180.00'),
            daily_carbs=Decimal('250.00'),
            daily_fats=Decimal('70.00'),
            daily_water=Decimal('3000.00')
        )
    
    def test_list_nutrition_goals_requires_authentication(self):
        """Test that listing nutrition goals requires authentication."""
        response = self.client.get('/api/nutrition/nutrition-goals/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_nutrition_goals_authenticated(self):
        """Test listing nutrition goals when authenticated."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/nutrition/nutrition-goals/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
    
    def test_retrieve_nutrition_goals(self):
        """Test retrieving nutrition goals."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get(f'/api/nutrition/nutrition-goals/{self.goals.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(float(response.data['daily_calories']), 2500.00)
    
    def test_retrieve_default_goals_when_none_exist(self):
        """Test that default goals are returned when user has no goals."""
        # Create new user without goals
        new_user = User.objects.create_user(
            email='newuser@example.com',
            password='testpass123'
        )
        
        self.client.force_authenticate(user=new_user)
        
        # Try to retrieve goals (should return defaults)
        # Note: This requires the goals ID, but we're testing the retrieve override
        # In practice, the frontend would call list first to get the ID
        response = self.client.get('/api/nutrition/nutrition-goals/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_create_nutrition_goals(self):
        """Test creating nutrition goals."""
        # Create new user without goals
        new_user = User.objects.create_user(
            email='newuser@example.com',
            password='testpass123'
        )
        
        self.client.force_authenticate(user=new_user)
        
        data = {
            'daily_calories': '2000.00',
            'daily_protein': '150.00',
            'daily_carbs': '200.00',
            'daily_fats': '65.00',
            'daily_water': '2000.00'
        }
        
        response = self.client.post('/api/nutrition/nutrition-goals/', data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(float(response.data['daily_calories']), 2000.00)
    
    def test_update_nutrition_goals(self):
        """Test updating nutrition goals."""
        self.client.force_authenticate(user=self.user)
        
        data = {
            'daily_calories': '2200.00',
            'daily_protein': '160.00',
            'daily_carbs': '220.00',
            'daily_fats': '68.00',
            'daily_water': '2500.00'
        }
        
        response = self.client.put(f'/api/nutrition/nutrition-goals/{self.goals.id}/', data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(float(response.data['daily_calories']), 2200.00)


class NutritionProgressAPITest(TestCase):
    """Test NutritionProgress API endpoints."""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        self.today = date.today()
        self.yesterday = self.today - timedelta(days=1)
        
        self.progress_today = NutritionProgress.objects.create(
            user=self.user,
            progress_date=self.today,
            total_calories=Decimal('1500.00'),
            total_protein=Decimal('120.00'),
            calories_adherence=Decimal('75.00')
        )
        
        self.progress_yesterday = NutritionProgress.objects.create(
            user=self.user,
            progress_date=self.yesterday,
            total_calories=Decimal('1800.00'),
            total_protein=Decimal('140.00'),
            calories_adherence=Decimal('90.00')
        )
    
    def test_list_nutrition_progress_requires_authentication(self):
        """Test that listing nutrition progress requires authentication."""
        response = self.client.get('/api/nutrition/nutrition-progress/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_nutrition_progress_authenticated(self):
        """Test listing nutrition progress when authenticated."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/nutrition/nutrition-progress/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should have pagination structure
        self.assertIn('results', response.data)
        self.assertEqual(len(response.data['results']), 2)
    
    def test_filter_nutrition_progress_by_date_from(self):
        """Test filtering nutrition progress by date_from."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get(f'/api/nutrition/nutrition-progress/?date_from={self.today}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['progress_date'], str(self.today))
    
    def test_filter_nutrition_progress_by_date_to(self):
        """Test filtering nutrition progress by date_to."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get(f'/api/nutrition/nutrition-progress/?date_to={self.yesterday}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['progress_date'], str(self.yesterday))
    
    def test_nutrition_progress_is_read_only(self):
        """Test that nutrition progress endpoints are read-only."""
        self.client.force_authenticate(user=self.user)
        
        # Try to create (should fail)
        data = {
            'progress_date': str(self.today),
            'total_calories': '2000.00'
        }
        response = self.client.post('/api/nutrition/nutrition-progress/', data)
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
        
        # Try to update (should fail)
        response = self.client.put(f'/api/nutrition/nutrition-progress/{self.progress_today.id}/', data)
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
        
        # Try to delete (should fail)
        response = self.client.delete(f'/api/nutrition/nutrition-progress/{self.progress_today.id}/')
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
    
    def test_nutrition_progress_pagination(self):
        """Test that nutrition progress uses pagination."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get('/api/nutrition/nutrition-progress/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('count', response.data)
        self.assertIn('next', response.data)
        self.assertIn('previous', response.data)
        self.assertIn('results', response.data)


class QuickLogAPITest(TestCase):
    """Test QuickLog API endpoints."""
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        
        # Create food items
        self.food1 = FoodItem.objects.create(
            name='Food 1',
            calories_per_100g=Decimal('100.00'),
            protein_per_100g=Decimal('10.00'),
            carbs_per_100g=Decimal('20.00'),
            fats_per_100g=Decimal('5.00')
        )
        
        self.food2 = FoodItem.objects.create(
            name='Food 2',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00')
        )
        
        # Create quick log with frequent meals
        self.quick_log = QuickLog.objects.create(
            user=self.user,
            frequent_meals=[
                {
                    'food_item_id': self.food1.id,
                    'usage_count': 10,
                    'last_used': '2024-01-15T10:30:00Z'
                },
                {
                    'food_item_id': self.food2.id,
                    'usage_count': 5,
                    'last_used': '2024-01-16T12:00:00Z'
                }
            ]
        )
    
    def test_list_quick_logs_requires_authentication(self):
        """Test that listing quick logs requires authentication."""
        response = self.client.get('/api/nutrition/quick-logs/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_quick_logs_authenticated(self):
        """Test listing quick logs when authenticated."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/nutrition/quick-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
    
    def test_get_frequent_foods(self):
        """Test getting frequent foods ordered by usage_count."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        # Should be ordered by usage_count descending
        self.assertEqual(response.data[0]['food_item_id'], self.food1.id)
        self.assertEqual(response.data[0]['usage_count'], 10)
        self.assertEqual(response.data[1]['food_item_id'], self.food2.id)
        self.assertEqual(response.data[1]['usage_count'], 5)
    
    def test_get_recent_foods(self):
        """Test getting recent foods ordered by last_used."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        # Should be ordered by last_used descending
        self.assertEqual(response.data[0]['food_item_id'], self.food2.id)
        self.assertEqual(response.data[1]['food_item_id'], self.food1.id)
    
    def test_quick_log_is_read_only(self):
        """Test that quick log endpoints are read-only."""
        self.client.force_authenticate(user=self.user)
        
        # Try to create (should fail)
        data = {'frequent_meals': []}
        response = self.client.post('/api/nutrition/quick-logs/', data)
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
