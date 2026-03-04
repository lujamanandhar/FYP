from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from datetime import datetime, timedelta
from django.utils import timezone
from .models import HydrationLog

User = get_user_model()


class HydrationLogViewSetTest(TestCase):
    """
    Test suite for HydrationLogViewSet with date filtering and CRUD operations.
    
    Requirements: 4.2, 4.3, 4.7, 10.2
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
        
        # Create hydration logs for user1 with different dates
        self.today = timezone.now()
        self.yesterday = self.today - timedelta(days=1)
        self.two_days_ago = self.today - timedelta(days=2)
        
        self.log1_user1 = HydrationLog.objects.create(
            user=self.user1,
            amount=Decimal('500.00'),
            unit='ml',
            logged_at=self.today
        )
        
        self.log2_user1 = HydrationLog.objects.create(
            user=self.user1,
            amount=Decimal('750.00'),
            unit='ml',
            logged_at=self.yesterday
        )
        
        self.log3_user1 = HydrationLog.objects.create(
            user=self.user1,
            amount=Decimal('300.00'),
            unit='ml',
            logged_at=self.two_days_ago
        )
        
        # Create hydration log for user2
        self.log1_user2 = HydrationLog.objects.create(
            user=self.user2,
            amount=Decimal('600.00'),
            unit='ml',
            logged_at=self.today
        )
    
    def test_authentication_required(self):
        """
        Test that authentication is required for all endpoints.
        
        Requirements: 10.1, 10.2
        """
        response = self.client.get('/api/nutrition/hydration-logs/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_hydration_logs_filtered_by_user(self):
        """
        Test that users only see their own hydration logs.
        
        Requirements: 4.3, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/nutrition/hydration-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # User1 should see only their 3 logs
        self.assertEqual(len(response.data), 3)
        
        # Verify all logs belong to user1
        for log in response.data:
            self.assertEqual(log['user'], self.user1.id)
    
    def test_list_hydration_logs_different_user(self):
        """
        Test that different users see different hydration logs.
        
        Requirements: 10.2
        """
        self.client.force_authenticate(user=self.user2)
        response = self.client.get('/api/nutrition/hydration-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # User2 should see only their 1 log
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['user'], self.user2.id)
    
    def test_date_filtering_with_date_from(self):
        """
        Test filtering hydration logs with date_from parameter.
        
        Requirements: 4.3
        """
        self.client.force_authenticate(user=self.user1)
        
        # Filter from yesterday onwards
        date_from = self.yesterday.strftime('%Y-%m-%d')
        response = self.client.get(f'/api/nutrition/hydration-logs/?date_from={date_from}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return 2 logs (today and yesterday, not two_days_ago)
        self.assertEqual(len(response.data), 2)
    
    def test_date_filtering_with_date_to(self):
        """
        Test filtering hydration logs with date_to parameter.
        
        Requirements: 4.3
        """
        self.client.force_authenticate(user=self.user1)
        
        # Filter up to yesterday
        date_to = self.yesterday.strftime('%Y-%m-%d')
        response = self.client.get(f'/api/nutrition/hydration-logs/?date_to={date_to}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return 2 logs (yesterday and two_days_ago, not today)
        self.assertEqual(len(response.data), 2)
    
    def test_date_filtering_with_date_range(self):
        """
        Test filtering hydration logs with both date_from and date_to parameters.
        
        Requirements: 4.3
        """
        self.client.force_authenticate(user=self.user1)
        
        # Filter for yesterday only
        date_from = self.yesterday.strftime('%Y-%m-%d')
        date_to = self.yesterday.strftime('%Y-%m-%d')
        response = self.client.get(
            f'/api/nutrition/hydration-logs/?date_from={date_from}&date_to={date_to}'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should return 1 log (only yesterday)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], self.log2_user1.id)
    
    def test_create_hydration_log(self):
        """
        Test creating a hydration log entry.
        
        Requirements: 4.2, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'amount': '400.00',
            'unit': 'ml',
            'logged_at': self.today.isoformat()
        }
        
        response = self.client.post('/api/nutrition/hydration-logs/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify the log was created with correct attributes
        self.assertEqual(response.data['user'], self.user1.id)
        self.assertEqual(float(response.data['amount']), 400.00)
        self.assertEqual(response.data['unit'], 'ml')
    
    def test_create_hydration_log_sets_user_from_jwt(self):
        """
        Test that created hydration logs are associated with the authenticated user.
        
        Requirements: 4.2, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'amount': '250.00',
            'unit': 'ml'
        }
        
        response = self.client.post('/api/nutrition/hydration-logs/', data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['user'], self.user1.id)
        
        # Verify in database
        log = HydrationLog.objects.get(id=response.data['id'])
        self.assertEqual(log.user, self.user1)
    
    def test_retrieve_hydration_log(self):
        """
        Test retrieving a single hydration log entry.
        
        Requirements: 4.3, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get(f'/api/nutrition/hydration-logs/{self.log1_user1.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], self.log1_user1.id)
        self.assertEqual(float(response.data['amount']), 500.00)
        self.assertEqual(response.data['unit'], 'ml')
    
    def test_update_hydration_log(self):
        """
        Test updating a hydration log entry.
        
        Requirements: 4.3, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'amount': '800.00',
            'unit': 'ml',
            'logged_at': self.log1_user1.logged_at.isoformat()
        }
        
        response = self.client.put(
            f'/api/nutrition/hydration-logs/{self.log1_user1.id}/',
            data,
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(float(response.data['amount']), 800.00)
    
    def test_delete_hydration_log(self):
        """
        Test deleting a hydration log entry.
        
        Requirements: 4.7, 10.2
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.delete(
            f'/api/nutrition/hydration-logs/{self.log1_user1.id}/'
        )
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        
        # Verify the log was deleted
        self.assertFalse(
            HydrationLog.objects.filter(id=self.log1_user1.id).exists()
        )
    
    def test_cannot_access_other_user_log(self):
        """
        Test that users cannot access other users' hydration logs.
        
        Requirements: 10.4
        """
        self.client.force_authenticate(user=self.user1)
        
        # Try to access user2's log
        response = self.client.get(f'/api/nutrition/hydration-logs/{self.log1_user2.id}/')
        
        # Should return 404 (not found) because queryset is filtered by user
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_cannot_update_other_user_log(self):
        """
        Test that users cannot update other users' hydration logs.
        
        Requirements: 10.4
        """
        self.client.force_authenticate(user=self.user1)
        
        data = {
            'amount': '1000.00',
            'unit': 'ml',
            'logged_at': self.log1_user2.logged_at.isoformat()
        }
        
        # Try to update user2's log
        response = self.client.put(
            f'/api/nutrition/hydration-logs/{self.log1_user2.id}/',
            data,
            format='json'
        )
        
        # Should return 404 (not found) because queryset is filtered by user
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_cannot_delete_other_user_log(self):
        """
        Test that users cannot delete other users' hydration logs.
        
        Requirements: 10.4
        """
        self.client.force_authenticate(user=self.user1)
        
        # Try to delete user2's log
        response = self.client.delete(
            f'/api/nutrition/hydration-logs/{self.log1_user2.id}/'
        )
        
        # Should return 404 (not found) because queryset is filtered by user
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        
        # Verify user2's log still exists
        self.assertTrue(
            HydrationLog.objects.filter(id=self.log1_user2.id).exists()
        )
    
    def test_ordering_by_logged_at_descending(self):
        """
        Test that hydration logs are ordered by logged_at in descending order (newest first).
        
        Requirements: 4.3
        """
        self.client.force_authenticate(user=self.user1)
        
        response = self.client.get('/api/nutrition/hydration-logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify ordering (newest first)
        log_ids = [log['id'] for log in response.data]
        self.assertEqual(log_ids[0], self.log1_user1.id)  # Today
        self.assertEqual(log_ids[1], self.log2_user1.id)  # Yesterday
        self.assertEqual(log_ids[2], self.log3_user1.id)  # Two days ago
