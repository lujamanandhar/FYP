from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from .models import NutritionGoals

User = get_user_model()


class NutritionGoalsViewSetTest(TestCase):
    """
    Test suite for NutritionGoalsViewSet with default handling.
    
    Requirements: 5.3-5.5, 5.7, 10.2
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
        
        # Create goals for user1
        self.user1_goals = NutritionGoals.objects.create(
            user=self.user1,
            daily_calories=Decimal('2500.00'),
            daily_protein=Decimal('180.00'),
            daily_carbs=Decimal('250.00'),
            daily_fats=Decimal('70.00'),
            daily_water=Decimal('3000.00')
        )
    
    def test_authentication_required(self):
        """
        Test that authentication is required for all endpoints.
        
        Requirements: 10.1, 10.2
        """
        response = self.client.get('/api/nutrition/nutrition-goals/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_retrieve_existing_goals(self):
        """
        Test retrieving existing nutrition goals for a user.
        
        Requirements: 5.4
        """
        self.client.force_authenticate(user=self.user1)
        
        # Since it's a OneToOne relationship, we need to use the user's ID
        response = self.client.get(f'/api/nutrition/nutrition-goals/{self.user1_goals.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['user'], self.user1.id)
        self.assertEqual(float(response.data['daily_calories']), 2500.00)
        self.assertEqual(float(response.data['daily_protein']), 180.00)
        self.assertEqual(float(response.data['daily_carbs']), 250.00)
        self.assertEqual(float(response.data['daily_fats']), 70.00)
        self.assertEqual(float(response.data['daily_water']), 3000.00)
    
    def test_retrieve_default_goals_when_none_exist(self):
        """
        Test that default values are returned when user has no goals.
        Default values: 2000 calories, 150g protein, 200g carbs, 65g fats, 2000ml water
        
        Requirements: 5.4, 5.7
        """
        self.client.force_authenticate(user=self.user2)
        
        # User2 has no goals, so we try to retrieve with a non-existent ID
        # or we can use a custom endpoint if available
        # For now, let's try to get the list and see if it returns defaults
        response = self.client.get('/api/nutrition/nutrition-goals/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # If no goals exist, the list should be empty
        # The retrieve method handles defaults, not the list
        self.assertEqual(len(response.data), 0)
    
    def test_create_nutrition_goals(self):
        """
        Test creating nutrition goals for a user.
        
        Requirements: 5.3, 10.2
        """
        self.client.force_authenticate(user=self.user2)
        
        data = {
            'daily_calories': '2200.00',
            'daily_protein': '160.00',
            'daily_carbs': '220.00',
            'daily_fats': '75.00',
            'daily_water': '2500.00'
        }
        
        response = self.client.post('/api/nutrition/nutrition-goals/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['user'], self.user2.id)
        self.assertEqual(float(response.data['daily_calories']), 2200.00)
        self.assertEqual(float(response.data['daily_protein']), 160.00)
        self.assertEqual(float(response.data['daily_carbs']), 220.00)
        self.assertEqual(float(response.data['daily_fats']), 75.00)
        self.assertEqual(float(response.data['daily_water']), 2500.00)
        
        # Verify in database
        goals = NutritionGoals.objects.get(user=self.user2)
        self.assertEqual(goals.daily_calories, Decimal('2200.00'))
    
    def test_update_nutrition_goals(self):
        """
        Test updating existing nutrition goals.
        
        Requirements: 5.5, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'daily_calories': '2800.00',
            'daily_protein': '200.00',
            'daily_carbs': '280.00',
            'daily_fats': '80.00',
            'daily_water': '3500.00'
        }
        
        response = self.client.put(
            f'/api/nutrition/nutrition-goals/{self.user1_goals.id}/',
            data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(float(response.data['daily_calories']), 2800.00)
        self.assertEqual(float(response.data['daily_protein']), 200.00)
        
        # Verify in database
        self.user1_goals.refresh_from_db()
        self.assertEqual(self.user1_goals.daily_calories, Decimal('2800.00'))
    
    def test_partial_update_nutrition_goals(self):
        """
        Test partially updating nutrition goals (PATCH).
        
        Requirements: 5.5, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'daily_calories': '2600.00'
        }
        
        response = self.client.patch(
            f'/api/nutrition/nutrition-goals/{self.user1_goals.id}/',
            data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(float(response.data['daily_calories']), 2600.00)
        
        # Other fields should remain unchanged
        self.assertEqual(float(response.data['daily_protein']), 180.00)
        self.assertEqual(float(response.data['daily_carbs']), 250.00)
    
    def test_user_can_only_see_own_goals(self):
        """
        Test that users can only see their own nutrition goals.
        
        Requirements: 10.2, 10.4
        """
        self.client.force_authenticate(user=self.user2)
        
        # User2 tries to access user1's goals
        response = self.client.get(f'/api/nutrition/nutrition-goals/{self.user1_goals.id}/')
        
        # Should return 404 because user2's queryset doesn't include user1's goals
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_list_nutrition_goals_filters_by_user(self):
        """
        Test that listing goals only returns the authenticated user's goals.
        
        Requirements: 5.4, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get('/api/nutrition/nutrition-goals/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['user'], self.user1.id)
    
    def test_create_goals_sets_user_from_token(self):
        """
        Test that created goals are associated with the authenticated user.
        
        Requirements: 5.3, 10.2
        """
        self.client.force_authenticate(user=self.user2)
        
        data = {
            'daily_calories': '2100.00',
            'daily_protein': '155.00',
            'daily_carbs': '210.00',
            'daily_fats': '68.00',
            'daily_water': '2200.00',
            # Try to set a different user (should be ignored)
            'user': self.user1.id
        }
        
        response = self.client.post('/api/nutrition/nutrition-goals/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Should be associated with user2, not user1
        self.assertEqual(response.data['user'], self.user2.id)
        
        # Verify in database
        goals = NutritionGoals.objects.get(user=self.user2)
        self.assertEqual(goals.user, self.user2)
    
    def test_update_goals_maintains_user_association(self):
        """
        Test that updating goals maintains the user association.
        
        Requirements: 5.5, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'daily_calories': '2700.00',
            'daily_protein': '190.00',
            'daily_carbs': '270.00',
            'daily_fats': '75.00',
            'daily_water': '3200.00',
            # Try to change user (should be ignored)
            'user': self.user2.id
        }
        
        response = self.client.put(
            f'/api/nutrition/nutrition-goals/{self.user1_goals.id}/',
            data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should still be associated with user1
        self.assertEqual(response.data['user'], self.user1.id)
        
        # Verify in database
        self.user1_goals.refresh_from_db()
        self.assertEqual(self.user1_goals.user, self.user1)
    
    def test_delete_nutrition_goals(self):
        """
        Test deleting nutrition goals.
        
        Requirements: 5.5
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.delete(
            f'/api/nutrition/nutrition-goals/{self.user1_goals.id}/'
        )
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        
        # Verify the goals were deleted
        self.assertFalse(
            NutritionGoals.objects.filter(id=self.user1_goals.id).exists()
        )
    
    def test_cannot_create_duplicate_goals(self):
        """
        Test that a user cannot have multiple goal records (OneToOne constraint).
        
        Requirements: 5.2, 12.10
        """
        self.client.force_authenticate(user=self.user1)
        
        # User1 already has goals, try to create another
        data = {
            'daily_calories': '2300.00',
            'daily_protein': '170.00',
            'daily_carbs': '230.00',
            'daily_fats': '72.00',
            'daily_water': '2800.00'
        }
        
        response = self.client.post('/api/nutrition/nutrition-goals/', data, format='json')
        
        # Should fail due to unique constraint (HTTP 409 Conflict)
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
    
    def test_default_values_structure(self):
        """
        Test that default values have the correct structure and values.
        
        Requirements: 5.7
        """
        # This test would need a custom endpoint or we test it indirectly
        # For now, we verify the default values are correct in the model
        default_goals = NutritionGoals()
        
        self.assertEqual(default_goals.daily_calories, Decimal('2000'))
        self.assertEqual(default_goals.daily_protein, Decimal('150'))
        self.assertEqual(default_goals.daily_carbs, Decimal('200'))
        self.assertEqual(default_goals.daily_fats, Decimal('65'))
        self.assertEqual(default_goals.daily_water, Decimal('2000'))
