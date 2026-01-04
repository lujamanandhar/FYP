"""
Simple performance and security validation tests.
"""

from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
import time

User = get_user_model()


class SimplePerformanceTests(TestCase):
    """Simple performance and security tests."""
    
    def setUp(self):
        """Set up test environment."""
        self.client = APIClient()
        User.objects.all().delete()
    
    def test_api_performance_basic(self):
        """Test basic API performance."""
        # Test registration performance
        registration_data = {
            'email': 'perftest@example.com',
            'password': 'ComplexTestPass789!',
            'name': 'Performance Test User'
        }
        
        start_time = time.time()
        response = self.client.post('/api/auth/register/', registration_data, format='json')
        registration_time = time.time() - start_time
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertLess(registration_time, 2.0, f"Registration took {registration_time:.3f}s")
        
        print(f"Registration performance: {registration_time:.3f}s")
    
    def test_password_security_basic(self):
        """Test basic password security."""
        user_data = {
            'email': 'sectest@example.com',
            'password': 'SecureTestPassword123!',
            'name': 'Security Test User'
        }
        
        response = self.client.post('/api/auth/register/', user_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify password is not in response
        response_data = response.json()
        self.assertNotIn('password', str(response_data))
        self.assertNotIn('SecureTestPassword123!', str(response_data))
        
        # Verify user password is hashed in database
        user = User.objects.get(email='sectest@example.com')
        self.assertNotEqual(user.password, 'SecureTestPassword123!')
        self.assertTrue(user.password.startswith('pbkdf2_sha256$'))
        
        print("Password security validation passed")
    
    def test_token_security_basic(self):
        """Test basic token security."""
        # Create user first
        user = User.objects.create(
            username="tokentest_user",
            email='tokentest@example.com',
            name='Token Test User'
        )
        user.set_password('TokenTestPass123!')
        user.save()
        
        # Login to get token
        login_data = {
            'email': 'tokentest@example.com',
            'password': 'TokenTestPass123!'
        }
        
        response = self.client.post('/api/auth/login/', login_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        token = response.json()['data']['token']
        
        # Verify token structure
        self.assertIsNotNone(token)
        self.assertGreater(len(token), 50)
        
        token_parts = token.split('.')
        self.assertEqual(len(token_parts), 3, "JWT should have 3 parts")
        
        # Test token usage
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        profile_response = self.client.get('/api/auth/me/')
        self.assertEqual(profile_response.status_code, status.HTTP_200_OK)
        
        print("Token security validation passed")
    
    def tearDown(self):
        """Clean up."""
        self.client.credentials()
        User.objects.all().delete()