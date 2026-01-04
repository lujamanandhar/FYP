"""
Database performance tests with sample data.
"""

from django.test import TestCase, override_settings
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
import time
import statistics

User = get_user_model()


@override_settings(
    DATABASES={
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': ':memory:',
        }
    }
)
class DatabasePerformanceTests(TestCase):
    """Database performance tests with sample data."""
    
    def setUp(self):
        """Set up test environment."""
        self.client = APIClient()
        User.objects.all().delete()
    
    def test_bulk_user_creation_performance(self):
        """Test database performance with bulk user creation."""
        # Create 50 users via API (realistic scenario)
        users_data = []
        for i in range(50):
            users_data.append({
                'email': f'dbtest{i}@example.com',
                'password': f'ComplexDBTestPass{i}Word789!',
                'name': f'DB Test User {i}',
            })
        
        start_time = time.time()
        created_users = []
        
        for user_data in users_data:
            response = self.client.post('/api/auth/register/', user_data, format='json')
            if response.status_code == status.HTTP_201_CREATED:
                created_users.append(response.json()['data']['user'])
        
        bulk_create_time = time.time() - start_time
        
        # Verify all users were created
        self.assertEqual(len(created_users), 50)
        self.assertLess(bulk_create_time, 30.0, 
                       f"Bulk user creation took {bulk_create_time:.3f}s, should be under 30s")
        
        print(f"Created {len(created_users)} users in {bulk_create_time:.3f}s")
        print(f"Average time per user: {bulk_create_time/len(created_users):.3f}s")
    
    def test_query_performance(self):
        """Test database query performance."""
        # Create test users first
        for i in range(20):
            user_data = {
                'email': f'querytest{i}@example.com',
                'password': f'QueryTestPass{i}Word789!',
                'name': f'Query Test User {i}',
            }
            self.client.post('/api/auth/register/', user_data, format='json')
        
        # Test query performance
        query_times = []
        
        for i in range(10):
            email = f'querytest{i}@example.com'
            
            start_time = time.time()
            user = User.objects.get(email=email)
            query_time = time.time() - start_time
            
            query_times.append(query_time)
            
            # Verify user data integrity
            self.assertEqual(user.email, email)
            self.assertIsNotNone(user.name)
        
        avg_query_time = statistics.mean(query_times)
        self.assertLess(avg_query_time, 0.1, 
                       f"Average query time {avg_query_time:.4f}s should be under 0.1s")
        
        print(f"Average query time: {avg_query_time:.4f}s")
    
    def test_update_performance(self):
        """Test database update performance."""
        # Create test users first
        for i in range(10):
            user_data = {
                'email': f'updatetest{i}@example.com',
                'password': f'UpdateTestPass{i}Word789!',
                'name': f'Update Test User {i}',
            }
            response = self.client.post('/api/auth/register/', user_data, format='json')
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Test update performance via API
        update_times = []
        
        for i in range(5):
            # Login to get token
            login_data = {
                'email': f'updatetest{i}@example.com',
                'password': f'UpdateTestPass{i}Word789!',
            }
            login_response = self.client.post('/api/auth/login/', login_data, format='json')
            token = login_response.json()['data']['token']
            
            # Set authentication
            self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
            
            # Perform update
            update_data = {
                'name': f'Updated User {i}',
                'gender': 'Male',
                'height': 175.0 + i,
                'weight': 70.0 + i,
            }
            
            start_time = time.time()
            update_response = self.client.put('/api/auth/profile/', update_data, format='json')
            update_time = time.time() - start_time
            
            self.assertEqual(update_response.status_code, status.HTTP_200_OK)
            update_times.append(update_time)
            
            # Clear credentials
            self.client.credentials()
        
        avg_update_time = statistics.mean(update_times)
        self.assertLess(avg_update_time, 1.0, 
                       f"Average update time {avg_update_time:.4f}s should be under 1.0s")
        
        print(f"Average update time: {avg_update_time:.4f}s")
    
    def test_concurrent_operations(self):
        """Test database consistency under concurrent operations."""
        # Create a test user
        user_data = {
            'email': 'concurrenttest@example.com',
            'password': 'ConcurrentTestPass789!',
            'name': 'Concurrent Test User',
        }
        response = self.client.post('/api/auth/register/', user_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Get the user from database
        user = User.objects.get(email='concurrenttest@example.com')
        original_name = user.name
        
        # Simulate concurrent updates (sequential for testing)
        update_values = [f'Updated Name {i}' for i in range(5)]
        
        for i, new_name in enumerate(update_values):
            user.refresh_from_db()
            user.name = new_name
            user.save()
            
            # Verify update was applied
            user.refresh_from_db()
            self.assertEqual(user.name, new_name)
        
        # Verify final state
        final_user = User.objects.get(email='concurrenttest@example.com')
        self.assertEqual(final_user.name, update_values[-1])
        
        print("Concurrent operations test completed successfully")
    
    def tearDown(self):
        """Clean up test data."""
        User.objects.all().delete()