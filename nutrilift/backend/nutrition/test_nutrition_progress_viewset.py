from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from datetime import date, timedelta
from .models import NutritionProgress, NutritionGoals

User = get_user_model()


class NutritionProgressViewSetTest(TestCase):
    """
    Test suite for NutritionProgressViewSet (read-only).
    
    Requirements: 3.9, 10.2, 14.1, 14.3, 14.6, 16.7
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
        
        # Create progress records for user1
        today = date.today()
        self.progress1 = NutritionProgress.objects.create(
            user=self.user1,
            progress_date=today,
            total_calories=Decimal('2000.00'),
            total_protein=Decimal('150.00'),
            total_carbs=Decimal('200.00'),
            total_fats=Decimal('60.00'),
            total_water=Decimal('2500.00'),
            calories_adherence=Decimal('80.00'),
            protein_adherence=Decimal('83.33'),
            carbs_adherence=Decimal('80.00'),
            fats_adherence=Decimal('85.71'),
            water_adherence=Decimal('83.33')
        )
        
        self.progress2 = NutritionProgress.objects.create(
            user=self.user1,
            progress_date=today - timedelta(days=1),
            total_calories=Decimal('2300.00'),
            total_protein=Decimal('170.00'),
            total_carbs=Decimal('230.00'),
            total_fats=Decimal('65.00'),
            total_water=Decimal('2800.00'),
            calories_adherence=Decimal('92.00'),
            protein_adherence=Decimal('94.44'),
            carbs_adherence=Decimal('92.00'),
            fats_adherence=Decimal('92.86'),
            water_adherence=Decimal('93.33')
        )
        
        self.progress3 = NutritionProgress.objects.create(
            user=self.user1,
            progress_date=today - timedelta(days=2),
            total_calories=Decimal('1800.00'),
            total_protein=Decimal('140.00'),
            total_carbs=Decimal('180.00'),
            total_fats=Decimal('55.00'),
            total_water=Decimal('2200.00'),
            calories_adherence=Decimal('72.00'),
            protein_adherence=Decimal('77.78'),
            carbs_adherence=Decimal('72.00'),
            fats_adherence=Decimal('78.57'),
            water_adherence=Decimal('73.33')
        )
        
        # Create progress for user2
        self.progress_user2 = NutritionProgress.objects.create(
            user=self.user2,
            progress_date=today,
            total_calories=Decimal('1900.00'),
            total_protein=Decimal('145.00'),
            total_carbs=Decimal('190.00'),
            total_fats=Decimal('58.00'),
            total_water=Decimal('2300.00'),
            calories_adherence=Decimal('95.00'),
            protein_adherence=Decimal('96.67'),
            carbs_adherence=Decimal('95.00'),
            fats_adherence=Decimal('89.23'),
            water_adherence=Decimal('115.00')
        )
    
    def test_authentication_required(self):
        """
        Test that authentication is required for all endpoints.
        
        Requirements: 10.1, 10.2
        """
        response = self.client.get('/api/nutrition/nutrition-progress/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_nutrition_progress(self):
        """
        Test listing nutrition progress records for authenticated user.
        
        Requirements: 3.9, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get('/api/nutrition/nutrition-progress/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return paginated response
        self.assertIn('results', response.data)
        self.assertIn('count', response.data)
        
        # Should return 3 progress records for user1
        self.assertEqual(len(response.data['results']), 3)
        self.assertEqual(response.data['count'], 3)
        
        # Verify ordering (most recent first)
        self.assertEqual(response.data['results'][0]['progress_date'], str(date.today()))
        self.assertEqual(response.data['results'][1]['progress_date'], str(date.today() - timedelta(days=1)))
        self.assertEqual(response.data['results'][2]['progress_date'], str(date.today() - timedelta(days=2)))
    
    def test_retrieve_specific_progress(self):
        """
        Test retrieving a specific progress record.
        
        Requirements: 3.9, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get(f'/api/nutrition/nutrition-progress/{self.progress1.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['user'], self.user1.id)
        self.assertEqual(response.data['progress_date'], str(date.today()))
        self.assertEqual(float(response.data['total_calories']), 2000.00)
        self.assertEqual(float(response.data['total_protein']), 150.00)
        self.assertEqual(float(response.data['calories_adherence']), 80.00)
    
    def test_user_can_only_see_own_progress(self):
        """
        Test that users can only see their own progress records.
        
        Requirements: 10.2, 10.4
        """
        self.client.force_authenticate(user=self.user2)
        
        # User2 tries to access user1's progress
        response = self.client.get(f'/api/nutrition/nutrition-progress/{self.progress1.id}/')
        
        # Should return 404 because user2's queryset doesn't include user1's progress
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_date_range_filtering_with_date_from(self):
        """
        Test filtering progress records by date_from parameter.
        
        Requirements: 3.9, 16.7
        """
        self.client.force_authenticate(user=self.user1)
        
        date_from = str(date.today() - timedelta(days=1))
        response = self.client.get(f'/api/nutrition/nutrition-progress/?date_from={date_from}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return paginated response with 2 records (today and yesterday)
        self.assertIn('results', response.data)
        self.assertEqual(len(response.data['results']), 2)
        
        # Verify dates are within range
        for record in response.data['results']:
            self.assertGreaterEqual(record['progress_date'], date_from)
    
    def test_date_range_filtering_with_date_to(self):
        """
        Test filtering progress records by date_to parameter.
        
        Requirements: 3.9, 16.7
        """
        self.client.force_authenticate(user=self.user1)
        
        date_to = str(date.today() - timedelta(days=1))
        response = self.client.get(f'/api/nutrition/nutrition-progress/?date_to={date_to}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return paginated response with 2 records (yesterday and 2 days ago)
        self.assertIn('results', response.data)
        self.assertEqual(len(response.data['results']), 2)
        
        # Verify dates are within range
        for record in response.data['results']:
            self.assertLessEqual(record['progress_date'], date_to)
    
    def test_date_range_filtering_with_both_dates(self):
        """
        Test filtering progress records with both date_from and date_to.
        
        Requirements: 3.9, 16.7
        """
        self.client.force_authenticate(user=self.user1)
        
        date_from = str(date.today() - timedelta(days=2))
        date_to = str(date.today() - timedelta(days=1))
        response = self.client.get(
            f'/api/nutrition/nutrition-progress/?date_from={date_from}&date_to={date_to}'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return paginated response with 2 records (yesterday and 2 days ago)
        self.assertIn('results', response.data)
        self.assertEqual(len(response.data['results']), 2)
        
        # Verify dates are within range
        for record in response.data['results']:
            self.assertGreaterEqual(record['progress_date'], date_from)
            self.assertLessEqual(record['progress_date'], date_to)
    
    def test_read_only_no_create(self):
        """
        Test that progress records cannot be created via API.
        
        Requirements: 14.1
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'progress_date': str(date.today()),
            'total_calories': '2100.00',
            'total_protein': '160.00',
            'total_carbs': '210.00',
            'total_fats': '62.00',
            'total_water': '2600.00',
            'calories_adherence': '84.00',
            'protein_adherence': '88.89',
            'carbs_adherence': '84.00',
            'fats_adherence': '88.57',
            'water_adherence': '86.67'
        }
        
        response = self.client.post('/api/nutrition/nutrition-progress/', data, format='json')
        
        # Should return 405 Method Not Allowed
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
    
    def test_read_only_no_update(self):
        """
        Test that progress records cannot be updated via API.
        
        Requirements: 14.1
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'total_calories': '2200.00'
        }
        
        response = self.client.patch(
            f'/api/nutrition/nutrition-progress/{self.progress1.id}/',
            data,
            format='json'
        )
        
        # Should return 405 Method Not Allowed
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
    
    def test_read_only_no_delete(self):
        """
        Test that progress records cannot be deleted via API.
        
        Requirements: 14.1
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.delete(f'/api/nutrition/nutrition-progress/{self.progress1.id}/')
        
        # Should return 405 Method Not Allowed
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
        
        # Verify the record still exists
        self.assertTrue(
            NutritionProgress.objects.filter(id=self.progress1.id).exists()
        )
    
    def test_pagination_page_size(self):
        """
        Test that pagination is configured to 50 items per page.
        
        Requirements: 14.6, 16.7
        """
        self.client.force_authenticate(user=self.user1)
        
        # Create more progress records to test pagination
        today = date.today()
        for i in range(3, 55):  # Create 52 more records (total 55)
            NutritionProgress.objects.create(
                user=self.user1,
                progress_date=today - timedelta(days=i),
                total_calories=Decimal('2000.00'),
                total_protein=Decimal('150.00'),
                total_carbs=Decimal('200.00'),
                total_fats=Decimal('60.00'),
                total_water=Decimal('2500.00'),
                calories_adherence=Decimal('80.00'),
                protein_adherence=Decimal('83.33'),
                carbs_adherence=Decimal('80.00'),
                fats_adherence=Decimal('85.71'),
                water_adherence=Decimal('83.33')
            )
        
        response = self.client.get('/api/nutrition/nutrition-progress/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return paginated response with 50 items
        self.assertIn('results', response.data)
        self.assertIn('count', response.data)
        self.assertIn('next', response.data)
        self.assertIn('previous', response.data)
        
        # First page should have 50 items
        self.assertEqual(len(response.data['results']), 50)
        
        # Total count should be 55
        self.assertEqual(response.data['count'], 55)
        
        # Next page should exist
        self.assertIsNotNone(response.data['next'])
    
    def test_response_includes_all_fields(self):
        """
        Test that response includes all required fields.
        
        Requirements: 3.9, 13.5
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get(f'/api/nutrition/nutrition-progress/{self.progress1.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify all fields are present
        required_fields = [
            'id', 'user', 'progress_date',
            'total_calories', 'total_protein', 'total_carbs', 'total_fats', 'total_water',
            'calories_adherence', 'protein_adherence', 'carbs_adherence',
            'fats_adherence', 'water_adherence',
            'updated_at'
        ]
        
        for field in required_fields:
            self.assertIn(field, response.data)
    
    def test_empty_result_for_user_with_no_progress(self):
        """
        Test that users with no progress records get an empty list.
        
        Requirements: 3.9, 10.2
        """
        # Create a new user with no progress
        user3 = User.objects.create_user(
            email='user3@example.com',
            password='testpass123'
        )
        
        self.client.force_authenticate(user=user3)
        
        response = self.client.get('/api/nutrition/nutrition-progress/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return paginated response with empty results
        self.assertIn('results', response.data)
        self.assertEqual(len(response.data['results']), 0)
        self.assertEqual(response.data['count'], 0)
