from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from .models import FoodItem

User = get_user_model()


class FoodItemViewSetTest(TestCase):
    """
    Test suite for FoodItemViewSet with search and filtering.
    
    Requirements: 1.3, 1.5, 1.6, 10.1, 10.2, 16.1, 16.2
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
        
        # Create system foods (is_custom=False)
        self.system_food1 = FoodItem.objects.create(
            name='Chicken Breast',
            brand='Generic',
            calories_per_100g=Decimal('165.00'),
            protein_per_100g=Decimal('31.00'),
            carbs_per_100g=Decimal('0.00'),
            fats_per_100g=Decimal('3.60'),
            is_custom=False
        )
        
        self.system_food2 = FoodItem.objects.create(
            name='Brown Rice',
            brand='',
            calories_per_100g=Decimal('111.00'),
            protein_per_100g=Decimal('2.60'),
            carbs_per_100g=Decimal('23.00'),
            fats_per_100g=Decimal('0.90'),
            is_custom=False
        )
        
        # Create custom foods for user1
        self.user1_custom_food = FoodItem.objects.create(
            name='My Custom Protein Shake',
            brand='Homemade',
            calories_per_100g=Decimal('120.00'),
            protein_per_100g=Decimal('25.00'),
            carbs_per_100g=Decimal('5.00'),
            fats_per_100g=Decimal('2.00'),
            is_custom=True,
            created_by=self.user1
        )
        
        # Create custom foods for user2
        self.user2_custom_food = FoodItem.objects.create(
            name='User2 Custom Meal',
            brand='Homemade',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('15.00'),
            carbs_per_100g=Decimal('20.00'),
            fats_per_100g=Decimal('8.00'),
            is_custom=True,
            created_by=self.user2
        )
    
    def test_authentication_required(self):
        """
        Test that authentication is required for all endpoints.
        
        Requirements: 10.1
        """
        response = self.client.get('/api/nutrition/food-items/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_food_items_returns_system_and_user_custom(self):
        """
        Test that authenticated user sees system foods + their own custom foods.
        
        Requirements: 1.3, 1.5
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/food-items/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # User1 should see: 2 system foods + 1 their custom food = 3 total
        self.assertEqual(len(response.data), 3)
        
        # Extract food names from response
        food_names = [item['name'] for item in response.data]
        
        # Should include system foods
        self.assertIn('Chicken Breast', food_names)
        self.assertIn('Brown Rice', food_names)
        
        # Should include user1's custom food
        self.assertIn('My Custom Protein Shake', food_names)
        
        # Should NOT include user2's custom food
        self.assertNotIn('User2 Custom Meal', food_names)
    
    def test_list_food_items_user2_sees_different_custom_foods(self):
        """
        Test that different users see different custom foods.
        
        Requirements: 1.5, 10.2
        """
        self.client.force_authenticate(user=self.user2)
        response = self.client.get('/api/nutrition/food-items/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # User2 should see: 2 system foods + 1 their custom food = 3 total
        self.assertEqual(len(response.data), 3)
        
        food_names = [item['name'] for item in response.data]
        
        # Should include system foods
        self.assertIn('Chicken Breast', food_names)
        self.assertIn('Brown Rice', food_names)
        
        # Should include user2's custom food
        self.assertIn('User2 Custom Meal', food_names)
        
        # Should NOT include user1's custom food
        self.assertNotIn('My Custom Protein Shake', food_names)
    
    def test_search_by_name(self):
        """
        Test search functionality by food name.
        
        Requirements: 1.3, 16.1
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/food-items/?search=Chicken')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'Chicken Breast')
    
    def test_search_by_brand(self):
        """
        Test search functionality by brand name.
        
        Requirements: 1.3, 16.1
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/food-items/?search=Homemade')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should find user1's custom food with "Homemade" brand
        # Should NOT find user2's custom food (different user)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'My Custom Protein Shake')
    
    def test_create_custom_food(self):
        """
        Test creating a custom food item.
        
        Requirements: 1.5, 1.6
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'name': 'New Custom Food',
            'brand': 'My Brand',
            'calories_per_100g': '150.00',
            'protein_per_100g': '20.00',
            'carbs_per_100g': '10.00',
            'fats_per_100g': '5.00',
            'fiber_per_100g': '3.00',
            'sugar_per_100g': '2.00'
        }
        
        response = self.client.post('/api/nutrition/food-items/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify the food was created with correct attributes
        self.assertEqual(response.data['name'], 'New Custom Food')
        self.assertEqual(response.data['is_custom'], True)
        self.assertEqual(response.data['created_by'], self.user1.id)
    
    def test_create_custom_food_sets_is_custom_true(self):
        """
        Test that created foods are automatically marked as custom.
        
        Requirements: 1.6
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'name': 'Another Custom Food',
            'calories_per_100g': '100.00',
            'protein_per_100g': '10.00',
            'carbs_per_100g': '15.00',
            'fats_per_100g': '2.00',
            # Try to set is_custom=False (should be overridden)
            'is_custom': False
        }
        
        response = self.client.post('/api/nutrition/food-items/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Should be marked as custom regardless of input
        self.assertEqual(response.data['is_custom'], True)
        self.assertEqual(response.data['created_by'], self.user1.id)
    
    def test_create_custom_food_sets_created_by(self):
        """
        Test that created foods are associated with the authenticated user.
        
        Requirements: 1.5, 1.6
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'name': 'User1 Food',
            'calories_per_100g': '100.00',
            'protein_per_100g': '10.00',
            'carbs_per_100g': '15.00',
            'fats_per_100g': '2.00'
        }
        
        response = self.client.post('/api/nutrition/food-items/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['created_by'], self.user1.id)
        
        # Verify in database
        food = FoodItem.objects.get(id=response.data['id'])
        self.assertEqual(food.created_by, self.user1)
    
    def test_retrieve_food_item(self):
        """
        Test retrieving a single food item.
        
        Requirements: 1.6, 16.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get(f'/api/nutrition/food-items/{self.system_food1.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Chicken Breast')
        self.assertEqual(float(response.data['calories_per_100g']), 165.00)
    
    def test_update_custom_food(self):
        """
        Test updating a custom food item.
        
        Requirements: 1.6, 16.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'name': 'Updated Protein Shake',
            'brand': 'Homemade',
            'calories_per_100g': '130.00',
            'protein_per_100g': '26.00',
            'carbs_per_100g': '6.00',
            'fats_per_100g': '2.50'
        }
        
        response = self.client.put(
            f'/api/nutrition/food-items/{self.user1_custom_food.id}/',
            data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Updated Protein Shake')
        self.assertEqual(float(response.data['calories_per_100g']), 130.00)
    
    def test_delete_custom_food(self):
        """
        Test deleting a custom food item.
        
        Requirements: 1.6, 16.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.delete(
            f'/api/nutrition/food-items/{self.user1_custom_food.id}/'
        )
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        
        # Verify the food was deleted
        self.assertFalse(
            FoodItem.objects.filter(id=self.user1_custom_food.id).exists()
        )
    
    def test_ordering_by_name(self):
        """
        Test ordering food items by name.
        
        Requirements: 16.1
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get('/api/nutrition/food-items/?ordering=name')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify ordering (alphabetical)
        names = [item['name'] for item in response.data]
        self.assertEqual(names, sorted(names))
    
    def test_case_insensitive_search(self):
        """
        Test that search is case-insensitive.
        
        Requirements: 1.3, 16.1
        """
        self.client.force_authenticate(user=self.user1)
        
        # Search with lowercase
        response = self.client.get('/api/nutrition/food-items/?search=chicken')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'Chicken Breast')
        
        # Search with uppercase
        response = self.client.get('/api/nutrition/food-items/?search=CHICKEN')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'Chicken Breast')
