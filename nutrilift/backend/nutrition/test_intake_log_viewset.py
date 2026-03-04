from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from datetime import datetime, timedelta
from django.utils import timezone
from .models import FoodItem, IntakeLog

User = get_user_model()


class IntakeLogViewSetTest(TestCase):
    """
    Test suite for IntakeLogViewSet with date filtering and CRUD operations.
    
    Requirements: 2.9-2.12, 10.2, 10.4, 14.5, 16.5
    """
    
    def setUp(self):
        """Set up test data"""
        self.client = APIClient()
        
        # Create test users
        self.user1 = User.objects.create_user(
            email='user1@example.com',
            password='testpass123'
        )
        self.user2 = User.objects.create_user(
            email='user2@example.com',
            password='testpass123'
        )
        
        # Create test food items
        self.food1 = FoodItem.objects.create(
            name='Chicken Breast',
            brand='Generic',
            calories_per_100g=Decimal('165.00'),
            protein_per_100g=Decimal('31.00'),
            carbs_per_100g=Decimal('0.00'),
            fats_per_100g=Decimal('3.60'),
            is_custom=False
        )
        
        self.food2 = FoodItem.objects.create(
            name='Brown Rice',
            brand='',
            calories_per_100g=Decimal('111.00'),
            protein_per_100g=Decimal('2.60'),
            carbs_per_100g=Decimal('23.00'),
            fats_per_100g=Decimal('0.90'),
            is_custom=False
        )
        
        # Create intake logs for user1 with different dates
        self.today = timezone.now()
        self.yesterday = self.today - timedelta(days=1)
        self.two_days_ago = self.today - timedelta(days=2)
        
        self.log1_user1 = IntakeLog.objects.create(
            user=self.user1,
            food_item=self.food1,
            entry_type='meal',
            quantity=Decimal('200.00'),
            unit='g',
            calories=Decimal('330.00'),
            protein=Decimal('62.00'),
            carbs=Decimal('0.00'),
            fats=Decimal('7.20'),
            logged_at=self.today
        )
        
        self.log2_user1 = IntakeLog.objects.create(
            user=self.user1,
            food_item=self.food2,
            entry_type='snack',
            quantity=Decimal('150.00'),
            unit='g',
            calories=Decimal('166.50'),
            protein=Decimal('3.90'),
            carbs=Decimal('34.50'),
            fats=Decimal('1.35'),
            logged_at=self.yesterday
        )
        
        self.log3_user1 = IntakeLog.objects.create(
            user=self.user1,
            food_item=self.food1,
            entry_type='meal',
            quantity=Decimal('150.00'),
            unit='g',
            calories=Decimal('247.50'),
            protein=Decimal('46.50'),
            carbs=Decimal('0.00'),
            fats=Decimal('5.40'),
            logged_at=self.two_days_ago
        )
        
        # Create intake log for user2
        self.log1_user2 = IntakeLog.objects.create(
            user=self.user2,
            food_item=self.food1,
            entry_type='meal',
            quantity=Decimal('100.00'),
            unit='g',
            calories=Decimal('165.00'),
            protein=Decimal('31.00'),
            carbs=Decimal('0.00'),
            fats=Decimal('3.60'),
            logged_at=self.today
        )
    
    def test_authentication_required(self):
        """
        Test that authentication is required for all endpoints.
        
        Requirements: 10.1, 10.2
        """
        response = self.client.get('/api/nutrition/intake-logs/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_intake_logs_filtered_by_user(self):
        """
        Test that users only see their own intake logs.
        
        Requirements: 2.10, 10.2, 10.4
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/intake-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # User1 should see only their 3 logs
        self.assertEqual(len(response.data), 3)
        
        # Verify all logs belong to user1
        for log in response.data:
            self.assertEqual(log['user'], self.user1.id)
    
    def test_list_intake_logs_different_user(self):
        """
        Test that different users see different intake logs.
        
        Requirements: 10.2, 10.4
        """
        self.client.force_authenticate(user=self.user2)
        response = self.client.get('/api/nutrition/intake-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # User2 should see only their 1 log
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['user'], self.user2.id)
    
    def test_date_filtering_with_date_from(self):
        """
        Test filtering intake logs with date_from parameter.
        
        Requirements: 2.10, 16.5
        """
        self.client.force_authenticate(user=self.user1)
        
        # Filter from yesterday onwards
        date_from = self.yesterday.strftime('%Y-%m-%d')
        response = self.client.get(f'/api/nutrition/intake-logs/?date_from={date_from}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return 2 logs (today and yesterday, not two_days_ago)
        self.assertEqual(len(response.data), 2)
    
    def test_date_filtering_with_date_to(self):
        """
        Test filtering intake logs with date_to parameter.
        
        Requirements: 2.10, 16.5
        """
        self.client.force_authenticate(user=self.user1)
        
        # Filter up to yesterday
        date_to = self.yesterday.strftime('%Y-%m-%d')
        response = self.client.get(f'/api/nutrition/intake-logs/?date_to={date_to}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return 2 logs (yesterday and two_days_ago, not today)
        self.assertEqual(len(response.data), 2)
    
    def test_date_filtering_with_date_range(self):
        """
        Test filtering intake logs with both date_from and date_to parameters.
        
        Requirements: 2.10, 16.5
        """
        self.client.force_authenticate(user=self.user1)
        
        # Filter for yesterday only
        date_from = self.yesterday.strftime('%Y-%m-%d')
        date_to = self.yesterday.strftime('%Y-%m-%d')
        response = self.client.get(
            f'/api/nutrition/intake-logs/?date_from={date_from}&date_to={date_to}'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return 1 log (only yesterday)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], self.log2_user1.id)
    
    def test_create_intake_log(self):
        """
        Test creating an intake log entry.
        
        Requirements: 2.9, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'food_item': self.food1.id,
            'entry_type': 'meal',
            'description': 'Lunch',
            'quantity': '250.00',
            'unit': 'g',
            'logged_at': self.today.isoformat()
        }
        
        response = self.client.post('/api/nutrition/intake-logs/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify the log was created with correct attributes
        self.assertEqual(response.data['user'], self.user1.id)
        self.assertEqual(response.data['food_item'], self.food1.id)
        self.assertEqual(response.data['entry_type'], 'meal')
        self.assertEqual(response.data['description'], 'Lunch')
        self.assertEqual(float(response.data['quantity']), 250.00)
        
        # Verify macros were calculated
        self.assertIn('calories', response.data)
        self.assertIn('protein', response.data)
        self.assertIn('carbs', response.data)
        self.assertIn('fats', response.data)
    
    def test_create_intake_log_sets_user_from_jwt(self):
        """
        Test that created intake logs are associated with the authenticated user.
        
        Requirements: 2.9, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'food_item': self.food2.id,
            'entry_type': 'snack',
            'quantity': '100.00',
            'unit': 'g'
        }
        
        response = self.client.post('/api/nutrition/intake-logs/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['user'], self.user1.id)
        
        # Verify in database
        log = IntakeLog.objects.get(id=response.data['id'])
        self.assertEqual(log.user, self.user1)
    
    def test_retrieve_intake_log(self):
        """
        Test retrieving a single intake log entry.
        
        Requirements: 2.10, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get(f'/api/nutrition/intake-logs/{self.log1_user1.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], self.log1_user1.id)
        self.assertEqual(response.data['entry_type'], 'meal')
        
        # Verify food_item_details are included
        self.assertIn('food_item_details', response.data)
        self.assertEqual(response.data['food_item_details']['name'], 'Chicken Breast')
    
    def test_update_intake_log(self):
        """
        Test updating an intake log entry.
        
        Requirements: 2.11, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'food_item': self.food1.id,
            'entry_type': 'snack',
            'description': 'Updated description',
            'quantity': '180.00',
            'unit': 'g',
            'logged_at': self.log1_user1.logged_at.isoformat()
        }
        
        response = self.client.put(
            f'/api/nutrition/intake-logs/{self.log1_user1.id}/',
            data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['entry_type'], 'snack')
        self.assertEqual(response.data['description'], 'Updated description')
        self.assertEqual(float(response.data['quantity']), 180.00)
    
    def test_delete_intake_log(self):
        """
        Test deleting an intake log entry.
        
        Requirements: 2.12, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.delete(
            f'/api/nutrition/intake-logs/{self.log1_user1.id}/'
        )
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        
        # Verify the log was deleted
        self.assertFalse(
            IntakeLog.objects.filter(id=self.log1_user1.id).exists()
        )
    
    def test_select_related_optimization(self):
        """
        Test that food_item is included via select_related for performance.
        
        Requirements: 14.5
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get('/api/nutrition/intake-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify food_item_details are included in response
        for log in response.data:
            self.assertIn('food_item_details', log)
            self.assertIn('name', log['food_item_details'])
    
    def test_cannot_access_other_user_log(self):
        """
        Test that users cannot access other users' intake logs.
        
        Requirements: 10.4
        """
        self.client.force_authenticate(user=self.user1)
        
        # Try to access user2's log
        response = self.client.get(f'/api/nutrition/intake-logs/{self.log1_user2.id}/')
        
        # Should return 404 (not found) because queryset is filtered by user
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_cannot_update_other_user_log(self):
        """
        Test that users cannot update other users' intake logs.
        
        Requirements: 10.4
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'food_item': self.food1.id,
            'entry_type': 'meal',
            'quantity': '100.00',
            'unit': 'g',
            'logged_at': self.log1_user2.logged_at.isoformat()
        }
        
        # Try to update user2's log
        response = self.client.put(
            f'/api/nutrition/intake-logs/{self.log1_user2.id}/',
            data,
            format='json'
        )
        
        # Should return 404 (not found) because queryset is filtered by user
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_cannot_delete_other_user_log(self):
        """
        Test that users cannot delete other users' intake logs.
        
        Requirements: 10.4
        """
        self.client.force_authenticate(user=self.user1)
        
        # Try to delete user2's log
        response = self.client.delete(
            f'/api/nutrition/intake-logs/{self.log1_user2.id}/'
        )
        
        # Should return 404 (not found) because queryset is filtered by user
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        
        # Verify user2's log still exists
        self.assertTrue(
            IntakeLog.objects.filter(id=self.log1_user2.id).exists()
        )
    
    def test_ordering_by_logged_at_descending(self):
        """
        Test that intake logs are ordered by logged_at in descending order (newest first).
        
        Requirements: 2.10
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get('/api/nutrition/intake-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify ordering (newest first)
        log_ids = [log['id'] for log in response.data]
        self.assertEqual(log_ids[0], self.log1_user1.id)  # Today
        self.assertEqual(log_ids[1], self.log2_user1.id)  # Yesterday
        self.assertEqual(log_ids[2], self.log3_user1.id)  # Two days ago
