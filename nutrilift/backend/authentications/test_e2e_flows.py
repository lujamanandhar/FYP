"""
End-to-end flow tests for user authentication and profile management system.

These tests validate complete user journeys from registration through profile management,
ensuring all components work together correctly.

Task 14.1: End-to-end flow testing
- Test complete registration → onboarding → home flow
- Test complete login → home → profile update flow  
- Test token expiry and re-authentication flow
- Verify all API endpoints work with Flutter frontend
"""

from django.test import TestCase, override_settings
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
import json
import time
from .models import User
from .jwt_utils import generate_jwt_token, validate_jwt_token
import jwt
from django.conf import settings

User = get_user_model()


@override_settings(
    DATABASES={
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': ':memory:',
        }
    },
    JWT_SECRET_KEY='test-secret-key-for-e2e-testing',
    JWT_ALGORITHM='HS256',
    JWT_EXPIRATION_DELTA=3600,  # 1 hour for testing
    ROOT_URLCONF='authentications.test_urls',
    REST_FRAMEWORK={
        'DEFAULT_AUTHENTICATION_CLASSES': [
            'authentications.authentication.JWTAuthentication',
        ],
        'DEFAULT_PERMISSION_CLASSES': [
            'rest_framework.permissions.AllowAny',
        ],
        'DEFAULT_RENDERER_CLASSES': [
            'rest_framework.renderers.JSONRenderer',
        ],
        'DEFAULT_PARSER_CLASSES': [
            'rest_framework.parsers.JSONParser',
        ],
    }
)
class EndToEndFlowTests(TestCase):
    """
    End-to-end flow tests for complete user journeys.
    
    Requirements: All requirements (comprehensive integration testing)
    """
    
    def setUp(self):
        """Set up test environment for end-to-end flow tests."""
        # Clean database state
        User.objects.all().delete()
        
        # Set up API client
        self.client = APIClient()
        
        # Test data
        self.test_user_data = {
            'email': 'testuser@example.com',
            'password': 'ComplexTestPass789!',
            'name': 'Test User'
        }
        
        self.profile_data = {
            'gender': 'Male',
            'age_group': 'Adult',
            'height': 175.0,
            'weight': 70.0,
            'fitness_level': 'Intermediate'
        }
    
    def test_complete_registration_onboarding_home_flow(self):
        """
        Test complete registration → onboarding → home flow
        
        This test simulates the complete user journey:
        1. User registers with email/password
        2. User completes onboarding with profile data
        3. User accesses home screen with profile data
        
        Requirements: 1.1, 1.5, 3.1, 3.2, 5.1, 5.3, 5.4
        """
        # Step 1: User Registration
        registration_data = {
            'email': self.test_user_data['email'],
            'password': self.test_user_data['password'],
            'name': self.test_user_data['name']
        }
        
        register_response = self.client.post('/api/auth/register/', registration_data, format='json')
        
        # Verify successful registration
        self.assertEqual(register_response.status_code, status.HTTP_201_CREATED)
        register_data = register_response.json()
        
        self.assertTrue(register_data['success'])
        self.assertIn('user', register_data['data'])
        self.assertIn('token', register_data['data'])
        
        # Extract token and user data
        auth_token = register_data['data']['token']
        user_data = register_data['data']['user']
        
        # Verify user data
        self.assertEqual(user_data['email'], self.test_user_data['email'].lower())
        self.assertEqual(user_data['name'], self.test_user_data['name'])
        # Gender should be empty string initially (not None)
        self.assertEqual(user_data['gender'], '')
        
        # Verify token is valid
        payload = validate_jwt_token(auth_token)
        self.assertEqual(payload['email'], self.test_user_data['email'].lower())
        
        # Step 2: Onboarding - Profile Update (simulating Flutter onboarding screens)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {auth_token}')
        
        profile_update_response = self.client.put('/api/auth/profile/', self.profile_data, format='json')
        
        # Verify successful profile update
        self.assertEqual(profile_update_response.status_code, status.HTTP_200_OK)
        profile_data = profile_update_response.json()
        
        self.assertTrue(profile_data['success'])
        self.assertIn('user', profile_data['data'])
        
        updated_user = profile_data['data']['user']
        
        # Verify all profile data was saved
        self.assertEqual(updated_user['gender'], self.profile_data['gender'])
        self.assertEqual(updated_user['age_group'], self.profile_data['age_group'])
        self.assertEqual(updated_user['height'], self.profile_data['height'])
        self.assertEqual(updated_user['weight'], self.profile_data['weight'])
        self.assertEqual(updated_user['fitness_level'], self.profile_data['fitness_level'])
        
        # Step 3: Home Screen - Profile Retrieval (simulating Flutter home screen)
        profile_get_response = self.client.get('/api/auth/me/')
        
        # Verify successful profile retrieval
        self.assertEqual(profile_get_response.status_code, status.HTTP_200_OK)
        home_data = profile_get_response.json()
        
        self.assertTrue(home_data['success'])
        self.assertIn('user', home_data['data'])
        
        home_user = home_data['data']['user']
        
        # Verify complete profile data is available for home screen
        self.assertEqual(home_user['email'], self.test_user_data['email'].lower())
        self.assertEqual(home_user['name'], self.test_user_data['name'])
        self.assertEqual(home_user['gender'], self.profile_data['gender'])
        self.assertEqual(home_user['age_group'], self.profile_data['age_group'])
        self.assertEqual(home_user['height'], self.profile_data['height'])
        self.assertEqual(home_user['weight'], self.profile_data['weight'])
        self.assertEqual(home_user['fitness_level'], self.profile_data['fitness_level'])
        
        # Verify user exists in database with complete profile
        db_user = User.objects.get(email=self.test_user_data['email'].lower())
        self.assertEqual(db_user.name, self.test_user_data['name'])
        self.assertEqual(db_user.gender, self.profile_data['gender'])
        self.assertEqual(db_user.age_group, self.profile_data['age_group'])
        self.assertEqual(db_user.height, self.profile_data['height'])
        self.assertEqual(db_user.weight, self.profile_data['weight'])
        self.assertEqual(db_user.fitness_level, self.profile_data['fitness_level'])
    
    def test_complete_login_home_profile_update_flow(self):
        """
        Test complete login → home → profile update flow
        
        This test simulates a returning user journey:
        1. User logs in with existing credentials
        2. User accesses home screen
        3. User updates profile information
        4. User sees updated information on home screen
        
        Requirements: 2.1, 2.4, 3.1, 3.2, 5.2, 5.4
        """
        # Pre-setup: Create an existing user with complete profile
        existing_user = User.objects.create(
            username=f"user_{self.test_user_data['email']}",
            email=self.test_user_data['email'].lower(),
            name=self.test_user_data['name'],
            gender=self.profile_data['gender'],
            age_group=self.profile_data['age_group'],
            height=self.profile_data['height'],
            weight=self.profile_data['weight'],
            fitness_level=self.profile_data['fitness_level']
        )
        existing_user.set_password(self.test_user_data['password'])
        existing_user.save()
        
        # Step 1: User Login
        login_data = {
            'email': self.test_user_data['email'],
            'password': self.test_user_data['password']
        }
        
        login_response = self.client.post('/api/auth/login/', login_data, format='json')
        
        # Verify successful login
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        login_response_data = login_response.json()
        
        self.assertTrue(login_response_data['success'])
        self.assertIn('user', login_response_data['data'])
        self.assertIn('token', login_response_data['data'])
        
        # Extract token and verify user data
        auth_token = login_response_data['data']['token']
        user_data = login_response_data['data']['user']
        
        self.assertEqual(user_data['email'], self.test_user_data['email'].lower())
        self.assertEqual(user_data['name'], self.test_user_data['name'])
        self.assertEqual(user_data['gender'], self.profile_data['gender'])
        
        # Step 2: Home Screen - Profile Retrieval
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {auth_token}')
        
        home_response = self.client.get('/api/auth/me/')
        
        # Verify successful profile retrieval
        self.assertEqual(home_response.status_code, status.HTTP_200_OK)
        home_data = home_response.json()
        
        self.assertTrue(home_data['success'])
        home_user = home_data['data']['user']
        
        # Verify complete profile data is displayed
        self.assertEqual(home_user['fitness_level'], self.profile_data['fitness_level'])
        self.assertEqual(home_user['height'], self.profile_data['height'])
        self.assertEqual(home_user['weight'], self.profile_data['weight'])
        
        # Step 3: Profile Update (simulating user editing profile)
        updated_profile_data = {
            'name': 'Updated Test User',
            'weight': 75.0,
            'fitness_level': 'Advance'
        }
        
        profile_update_response = self.client.put('/api/auth/profile/', updated_profile_data, format='json')
        
        # Verify successful profile update
        self.assertEqual(profile_update_response.status_code, status.HTTP_200_OK)
        update_data = profile_update_response.json()
        
        self.assertTrue(update_data['success'])
        updated_user = update_data['data']['user']
        
        # Verify updated fields
        self.assertEqual(updated_user['name'], updated_profile_data['name'])
        self.assertEqual(updated_user['weight'], updated_profile_data['weight'])
        self.assertEqual(updated_user['fitness_level'], updated_profile_data['fitness_level'])
        
        # Verify unchanged fields remain the same
        self.assertEqual(updated_user['gender'], self.profile_data['gender'])
        self.assertEqual(updated_user['height'], self.profile_data['height'])
        
        # Step 4: Home Screen Refresh - Verify Updated Data
        home_refresh_response = self.client.get('/api/auth/me/')
        
        # Verify updated profile data is reflected
        self.assertEqual(home_refresh_response.status_code, status.HTTP_200_OK)
        refresh_data = home_refresh_response.json()
        
        self.assertTrue(refresh_data['success'])
        refresh_user = refresh_data['data']['user']
        
        # Verify all updates are persisted and visible
        self.assertEqual(refresh_user['name'], updated_profile_data['name'])
        self.assertEqual(refresh_user['weight'], updated_profile_data['weight'])
        self.assertEqual(refresh_user['fitness_level'], updated_profile_data['fitness_level'])
        
        # Verify database persistence
        db_user = User.objects.get(id=existing_user.id)
        self.assertEqual(db_user.name, updated_profile_data['name'])
        self.assertEqual(db_user.weight, updated_profile_data['weight'])
        self.assertEqual(db_user.fitness_level, updated_profile_data['fitness_level'])
    
    def test_token_expiry_and_reauthentication_flow(self):
        """
        Test token expiry and re-authentication flow
        
        This test simulates token expiry scenarios:
        1. User logs in and gets a token
        2. Token expires (simulated)
        3. User gets 401 unauthorized on protected endpoints
        4. User re-authenticates and gets new token
        5. User can access protected endpoints again
        
        Requirements: 4.1, 4.2, 4.3, 8.4
        """
        # Pre-setup: Create an existing user
        existing_user = User.objects.create(
            username=f"user_{self.test_user_data['email']}",
            email=self.test_user_data['email'].lower(),
            name=self.test_user_data['name']
        )
        existing_user.set_password(self.test_user_data['password'])
        existing_user.save()
        
        # Step 1: Initial Login
        login_data = {
            'email': self.test_user_data['email'],
            'password': self.test_user_data['password']
        }
        
        login_response = self.client.post('/api/auth/login/', login_data, format='json')
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        
        auth_token = login_response.json()['data']['token']
        
        # Step 2: Verify token works initially
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {auth_token}')
        
        profile_response = self.client.get('/api/auth/me/')
        self.assertEqual(profile_response.status_code, status.HTTP_200_OK)
        
        # Step 3: Simulate token expiry by creating an expired token
        from datetime import datetime, timezone
        
        expired_payload = {
            'user_id': str(existing_user.id),
            'email': existing_user.email,
            'exp': datetime.now(timezone.utc) - timedelta(seconds=1),  # Expired 1 second ago
            'iat': datetime.now(timezone.utc) - timedelta(seconds=3600)  # Issued 1 hour ago
        }
        
        expired_token = jwt.encode(
            expired_payload,
            settings.JWT_SECRET_KEY,
            algorithm=settings.JWT_ALGORITHM
        )
        
        # Step 4: Try to access protected endpoint with expired token
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {expired_token}')
        
        expired_profile_response = self.client.get('/api/auth/me/')
        
        # Verify 401 unauthorized response
        self.assertEqual(expired_profile_response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        expired_data = expired_profile_response.json()
        # Handle both custom exception handler format and default DRF format
        if 'success' in expired_data:
            self.assertFalse(expired_data['success'])
            message_text = expired_data['message'].lower()
            self.assertTrue('authentication' in message_text or 'expired' in message_text or 'token' in message_text)
        else:
            # Default DRF format
            self.assertIn('detail', expired_data)
            detail_text = expired_data['detail'].lower()
            self.assertTrue('authentication' in detail_text or 'expired' in detail_text or 'token' in detail_text)
        
        # Step 5: Try to update profile with expired token
        profile_update_data = {'name': 'Should Not Work'}
        
        expired_update_response = self.client.put('/api/auth/profile/', profile_update_data, format='json')
        
        # Verify 401 unauthorized response
        self.assertEqual(expired_update_response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        # Step 6: Re-authenticate with valid credentials
        self.client.credentials()  # Clear expired token
        
        reauth_response = self.client.post('/api/auth/login/', login_data, format='json')
        self.assertEqual(reauth_response.status_code, status.HTTP_200_OK)
        
        new_auth_token = reauth_response.json()['data']['token']
        
        # Verify new token is different from expired token
        self.assertNotEqual(new_auth_token, expired_token)
        
        # Step 7: Verify new token works for protected endpoints
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {new_auth_token}')
        
        new_profile_response = self.client.get('/api/auth/me/')
        self.assertEqual(new_profile_response.status_code, status.HTTP_200_OK)
        
        new_profile_data = new_profile_response.json()
        self.assertTrue(new_profile_data['success'])
        self.assertEqual(new_profile_data['data']['user']['email'], self.test_user_data['email'].lower())
        
        # Step 8: Verify profile update works with new token
        valid_update_data = {'name': 'Successfully Updated'}
        
        valid_update_response = self.client.put('/api/auth/profile/', valid_update_data, format='json')
        self.assertEqual(valid_update_response.status_code, status.HTTP_200_OK)
        
        update_data = valid_update_response.json()
        self.assertTrue(update_data['success'])
        self.assertEqual(update_data['data']['user']['name'], valid_update_data['name'])
    
    def test_all_api_endpoints_integration(self):
        """
        Verify all API endpoints work correctly with proper request/response flow
        
        This test ensures all four main endpoints work together:
        - POST /api/auth/register/
        - POST /api/auth/login/
        - GET /api/auth/me/
        - PUT /api/auth/profile/
        
        Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
        """
        # Test 1: Registration endpoint
        registration_data = {
            'email': 'integration@example.com',
            'password': 'ComplexIntegrationPass789!',
            'name': 'Integration Test User'
        }
        
        register_response = self.client.post('/api/auth/register/', registration_data, format='json')
        
        # Verify registration endpoint response format
        self.assertEqual(register_response.status_code, status.HTTP_201_CREATED)
        register_data = register_response.json()
        
        # Verify consistent response format
        self.assertIn('success', register_data)
        self.assertIn('message', register_data)
        self.assertIn('data', register_data)
        self.assertTrue(register_data['success'])
        
        auth_token = register_data['data']['token']
        
        # Test 2: Login endpoint with same credentials
        login_data = {
            'email': registration_data['email'],
            'password': registration_data['password']
        }
        
        login_response = self.client.post('/api/auth/login/', login_data, format='json')
        
        # Verify login endpoint response format
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        login_response_data = login_response.json()
        
        # Verify consistent response format
        self.assertIn('success', login_response_data)
        self.assertIn('message', login_response_data)
        self.assertIn('data', login_response_data)
        self.assertTrue(login_response_data['success'])
        
        # Test 3: Profile retrieval endpoint
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {auth_token}')
        
        profile_response = self.client.get('/api/auth/me/')
        
        # Verify profile endpoint response format
        self.assertEqual(profile_response.status_code, status.HTTP_200_OK)
        profile_data = profile_response.json()
        
        # Verify consistent response format
        self.assertIn('success', profile_data)
        self.assertIn('message', profile_data)
        self.assertIn('data', profile_data)
        self.assertTrue(profile_data['success'])
        
        # Test 4: Profile update endpoint
        update_data = {
            'name': 'Updated Integration User',
            'gender': 'Female',
            'age_group': 'Mid-Age Adult',
            'height': 165.0,
            'weight': 60.0,
            'fitness_level': 'Beginner'
        }
        
        update_response = self.client.put('/api/auth/profile/', update_data, format='json')
        
        # Verify profile update endpoint response format
        self.assertEqual(update_response.status_code, status.HTTP_200_OK)
        update_response_data = update_response.json()
        
        # Verify consistent response format
        self.assertIn('success', update_response_data)
        self.assertIn('message', update_response_data)
        self.assertIn('data', update_response_data)
        self.assertTrue(update_response_data['success'])
        
        # Test 5: Verify data consistency across endpoints
        final_profile_response = self.client.get('/api/auth/me/')
        final_profile_data = final_profile_response.json()
        
        final_user = final_profile_data['data']['user']
        
        # Verify all data is consistent
        self.assertEqual(final_user['email'], registration_data['email'].lower())
        self.assertEqual(final_user['name'], update_data['name'])
        self.assertEqual(final_user['gender'], update_data['gender'])
        self.assertEqual(final_user['age_group'], update_data['age_group'])
        self.assertEqual(final_user['height'], update_data['height'])
        self.assertEqual(final_user['weight'], update_data['weight'])
        self.assertEqual(final_user['fitness_level'], update_data['fitness_level'])
        
        # Test 6: Error handling consistency
        # Test duplicate registration
        duplicate_response = self.client.post('/api/auth/register/', registration_data, format='json')
        # Should return 400 or 409 depending on implementation
        self.assertIn(duplicate_response.status_code, [status.HTTP_400_BAD_REQUEST, status.HTTP_409_CONFLICT])
        
        duplicate_data = duplicate_response.json()
        self.assertIn('success', duplicate_data)
        self.assertIn('message', duplicate_data)
        self.assertIn('errors', duplicate_data)
        self.assertFalse(duplicate_data['success'])
        
        # Test invalid login
        invalid_login_data = {
            'email': 'nonexistent@example.com',
            'password': 'wrongpassword'
        }
        
        invalid_login_response = self.client.post('/api/auth/login/', invalid_login_data, format='json')
        self.assertEqual(invalid_login_response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        invalid_login_response_data = invalid_login_response.json()
        self.assertIn('success', invalid_login_response_data)
        self.assertIn('message', invalid_login_response_data)
        self.assertIn('errors', invalid_login_response_data)
        self.assertFalse(invalid_login_response_data['success'])
        
        # Test unauthorized access
        self.client.credentials()  # Clear token
        
        unauthorized_response = self.client.get('/api/auth/me/')
        self.assertEqual(unauthorized_response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        unauthorized_data = unauthorized_response.json()
        # Handle both custom exception handler format and default DRF format
        if 'success' in unauthorized_data:
            self.assertIn('success', unauthorized_data)
            self.assertIn('message', unauthorized_data)
            self.assertIn('errors', unauthorized_data)
            self.assertFalse(unauthorized_data['success'])
        else:
            # Default DRF format
            self.assertIn('detail', unauthorized_data)
    
    def test_concurrent_user_operations(self):
        """
        Test concurrent user operations to ensure data consistency
        
        This test simulates multiple users performing operations simultaneously
        to verify database integrity and proper isolation.
        
        Requirements: 6.5 (Atomic Operations)
        """
        # Create multiple users concurrently
        users_data = [
            {
                'email': f'concurrentuser{i}@example.com',
                'password': f'ComplexPass{i}Word789!',
                'name': f'Concurrent User {i}'
            }
            for i in range(1, 4)
        ]
        
        # Ensure no users exist with these emails
        for user_data in users_data:
            User.objects.filter(email=user_data['email'].lower()).delete()
            # Also ensure no username conflicts
            User.objects.filter(username__icontains=f"concurrentuser{users_data.index(user_data) + 1}").delete()
        
        # Register all users
        tokens = []
        for user_data in users_data:
            response = self.client.post('/api/auth/register/', user_data, format='json')
            
            # Debug: Print response if it fails
            if response.status_code != status.HTTP_201_CREATED:
                print(f"Registration failed for {user_data['email']}: {response.status_code}")
                print(f"Response: {response.json()}")
            
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)
            
            response_data = response.json()
            tokens.append(response_data['data']['token'])
        
        # Verify all users were created with unique IDs
        all_users = User.objects.all()
        self.assertEqual(len(all_users), 3)
        
        user_ids = [user.id for user in all_users]
        self.assertEqual(len(user_ids), len(set(user_ids)))  # All IDs should be unique
        
        # Perform concurrent profile updates
        profile_updates = [
            {'name': f'Updated User {i}', 'height': 170.0 + i, 'weight': 65.0 + i}
            for i in range(1, 4)
        ]
        
        for i, (token, update_data) in enumerate(zip(tokens, profile_updates)):
            self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
            
            response = self.client.put('/api/auth/profile/', update_data, format='json')
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            
            response_data = response.json()
            self.assertTrue(response_data['success'])
            
            # Verify update was applied correctly
            updated_user = response_data['data']['user']
            self.assertEqual(updated_user['name'], update_data['name'])
            self.assertEqual(updated_user['height'], update_data['height'])
            self.assertEqual(updated_user['weight'], update_data['weight'])
        
        # Verify all updates were persisted correctly and didn't interfere with each other
        for i, user_data in enumerate(users_data):
            db_user = User.objects.get(email=user_data['email'].lower())
            expected_update = profile_updates[i]
            
            self.assertEqual(db_user.name, expected_update['name'])
            self.assertEqual(db_user.height, expected_update['height'])
            self.assertEqual(db_user.weight, expected_update['weight'])
    
    def tearDown(self):
        """Clean up after each test."""
        # Clear any authentication credentials
        self.client.credentials()
        
        # Clean up test data
        User.objects.all().delete()