from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from datetime import datetime, timezone
from .models import FoodItem, QuickLog

User = get_user_model()


class QuickLogViewSetTest(TestCase):
    """
    Test suite for QuickLogViewSet with frequent/recent endpoints.
    
    Requirements: 1.7, 6.4, 6.5, 10.2
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
        
        # Create food items
        self.food1 = FoodItem.objects.create(
            name='Chicken Breast',
            calories_per_100g=Decimal('165.00'),
            protein_per_100g=Decimal('31.00'),
            carbs_per_100g=Decimal('0.00'),
            fats_per_100g=Decimal('3.60'),
            is_custom=False
        )
        
        self.food2 = FoodItem.objects.create(
            name='Brown Rice',
            calories_per_100g=Decimal('111.00'),
            protein_per_100g=Decimal('2.60'),
            carbs_per_100g=Decimal('23.00'),
            fats_per_100g=Decimal('0.90'),
            is_custom=False
        )
        
        self.food3 = FoodItem.objects.create(
            name='Broccoli',
            calories_per_100g=Decimal('34.00'),
            protein_per_100g=Decimal('2.80'),
            carbs_per_100g=Decimal('7.00'),
            fats_per_100g=Decimal('0.40'),
            is_custom=False
        )
        
        # Create QuickLog for user1 with sample data
        self.quick_log_user1 = QuickLog.objects.create(
            user=self.user1,
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
                },
                {
                    'food_item_id': self.food3.id,
                    'usage_count': 15,
                    'last_used': '2024-01-14T08:00:00Z'
                }
            ]
        )
    
    def test_authentication_required(self):
        """
        Test that authentication is required for all endpoints.
        
        Requirements: 10.2
        """
        response = self.client.get('/api/nutrition/quick-logs/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_frequent_foods_ordered_by_usage_count(self):
        """
        Test that frequent endpoint returns foods ordered by usage_count descending.
        
        Requirements: 6.4
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 3)
        
        # Verify ordering by usage_count (descending)
        # food3: 15, food1: 10, food2: 5
        self.assertEqual(response.data[0]['food_item_id'], self.food3.id)
        self.assertEqual(response.data[0]['usage_count'], 15)
        
        self.assertEqual(response.data[1]['food_item_id'], self.food1.id)
        self.assertEqual(response.data[1]['usage_count'], 10)
        
        self.assertEqual(response.data[2]['food_item_id'], self.food2.id)
        self.assertEqual(response.data[2]['usage_count'], 5)
    
    def test_frequent_foods_includes_food_item_details(self):
        """
        Test that frequent endpoint includes full food item details.
        
        Requirements: 1.7, 6.4
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check first item has food_item details
        first_item = response.data[0]
        self.assertIn('food_item', first_item)
        self.assertEqual(first_item['food_item']['name'], 'Broccoli')
        self.assertEqual(float(first_item['food_item']['calories_per_100g']), 34.00)
    
    def test_recent_foods_ordered_by_last_used(self):
        """
        Test that recent endpoint returns foods ordered by last_used descending.
        
        Requirements: 6.5
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 3)
        
        # Verify ordering by last_used (descending)
        # food2: 2024-01-16, food1: 2024-01-15, food3: 2024-01-14
        self.assertEqual(response.data[0]['food_item_id'], self.food2.id)
        self.assertEqual(response.data[0]['last_used'], '2024-01-16T12:00:00Z')
        
        self.assertEqual(response.data[1]['food_item_id'], self.food1.id)
        self.assertEqual(response.data[1]['last_used'], '2024-01-15T10:30:00Z')
        
        self.assertEqual(response.data[2]['food_item_id'], self.food3.id)
        self.assertEqual(response.data[2]['last_used'], '2024-01-14T08:00:00Z')
    
    def test_recent_foods_includes_food_item_details(self):
        """
        Test that recent endpoint includes full food item details.
        
        Requirements: 1.7, 6.5
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check first item has food_item details
        first_item = response.data[0]
        self.assertIn('food_item', first_item)
        self.assertEqual(first_item['food_item']['name'], 'Brown Rice')
        self.assertEqual(float(first_item['food_item']['calories_per_100g']), 111.00)
    
    def test_frequent_foods_empty_quick_log(self):
        """
        Test frequent endpoint with user who has no QuickLog.
        
        Requirements: 6.4
        """
        self.client.force_authenticate(user=self.user2)
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)
    
    def test_recent_foods_empty_quick_log(self):
        """
        Test recent endpoint with user who has no QuickLog.
        
        Requirements: 6.5
        """
        self.client.force_authenticate(user=self.user2)
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)
    
    def test_frequent_foods_user_isolation(self):
        """
        Test that users only see their own frequent foods.
        
        Requirements: 10.2
        """
        # Create QuickLog for user2
        QuickLog.objects.create(
            user=self.user2,
            frequent_meals=[
                {
                    'food_item_id': self.food1.id,
                    'usage_count': 3,
                    'last_used': '2024-01-10T10:00:00Z'
                }
            ]
        )
        
        # User1 should only see their own data
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 3)  # User1 has 3 items
        
        # User2 should only see their own data
        self.client.force_authenticate(user=self.user2)
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)  # User2 has 1 item
        self.assertEqual(response.data[0]['usage_count'], 3)
    
    def test_recent_foods_user_isolation(self):
        """
        Test that users only see their own recent foods.
        
        Requirements: 10.2
        """
        # Create QuickLog for user2
        QuickLog.objects.create(
            user=self.user2,
            frequent_meals=[
                {
                    'food_item_id': self.food2.id,
                    'usage_count': 2,
                    'last_used': '2024-01-17T14:00:00Z'
                }
            ]
        )
        
        # User1 should only see their own data
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 3)  # User1 has 3 items
        
        # User2 should only see their own data
        self.client.force_authenticate(user=self.user2)
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)  # User2 has 1 item
        self.assertEqual(response.data[0]['last_used'], '2024-01-17T14:00:00Z')
    
    def test_frequent_foods_with_deleted_food_item(self):
        """
        Test that frequent endpoint handles deleted food items gracefully.
        
        Requirements: 6.4
        """
        # Add a reference to a non-existent food item
        self.quick_log_user1.frequent_meals.append({
            'food_item_id': 99999,
            'usage_count': 20,
            'last_used': '2024-01-18T10:00:00Z'
        })
        self.quick_log_user1.save()
        
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should only return 3 items (the valid ones)
        self.assertEqual(len(response.data), 3)
    
    def test_recent_foods_with_deleted_food_item(self):
        """
        Test that recent endpoint handles deleted food items gracefully.
        
        Requirements: 6.5
        """
        # Add a reference to a non-existent food item
        self.quick_log_user1.frequent_meals.append({
            'food_item_id': 99999,
            'usage_count': 1,
            'last_used': '2024-01-20T10:00:00Z'
        })
        self.quick_log_user1.save()
        
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should only return 3 items (the valid ones)
        self.assertEqual(len(response.data), 3)
    
    def test_frequent_foods_response_structure(self):
        """
        Test that frequent endpoint returns correct response structure.
        
        Requirements: 6.4
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/frequent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check response structure
        first_item = response.data[0]
        self.assertIn('food_item_id', first_item)
        self.assertIn('usage_count', first_item)
        self.assertIn('last_used', first_item)
        self.assertIn('food_item', first_item)
        
        # Check food_item nested structure
        food_item = first_item['food_item']
        self.assertIn('id', food_item)
        self.assertIn('name', food_item)
        self.assertIn('calories_per_100g', food_item)
        self.assertIn('protein_per_100g', food_item)
        self.assertIn('carbs_per_100g', food_item)
        self.assertIn('fats_per_100g', food_item)
    
    def test_recent_foods_response_structure(self):
        """
        Test that recent endpoint returns correct response structure.
        
        Requirements: 6.5
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/quick-logs/recent/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check response structure
        first_item = response.data[0]
        self.assertIn('food_item_id', first_item)
        self.assertIn('usage_count', first_item)
        self.assertIn('last_used', first_item)
        self.assertIn('food_item', first_item)
        
        # Check food_item nested structure
        food_item = first_item['food_item']
        self.assertIn('id', food_item)
        self.assertIn('name', food_item)
        self.assertIn('calories_per_100g', food_item)
        self.assertIn('protein_per_100g', food_item)
        self.assertIn('carbs_per_100g', food_item)
        self.assertIn('fats_per_100g', food_item)
