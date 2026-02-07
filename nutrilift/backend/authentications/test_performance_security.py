"""
Performance and security validation tests for user authentication system.

Task 14.2: Performance and security validation
- Test app performance with real API calls
- Verify secure token storage and transmission
- Test database performance with sample data
- Validate password hashing and security measures
"""

from django.test import TestCase, override_settings
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import check_password, is_password_usable
from django.utils import timezone
from datetime import timedelta
import time
import hashlib
import jwt
from django.conf import settings
from .models import User
from .jwt_utils import generate_jwt_token, validate_jwt_token
import threading
from concurrent.futures import ThreadPoolExecutor
import statistics

User = get_user_model()


@override_settings(
    DATABASES={
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': ':memory:',
        }
    },
    JWT_SECRET_KEY='test-secret-key-for-performance-testing',
    JWT_ALGORITHM='HS256',
    JWT_EXPIRATION_DELTA=3600,
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
class PerformanceSecurityTests(TestCase):
    """
    Performance and security validation tests.
    
    Requirements: 1.6, 4.1, 4.4, 8.1, 8.5
    """
    
    def setUp(self):
        """Set up test environment for performance and security tests."""
        # Clean database state
        User.objects.all().delete()
        
        # Set up API client
        self.client = APIClient()
        
        # Test data
        self.test_users = []
        for i in range(10):
            self.test_users.append({
                'email': f'perftest{i}@example.com',
                'password': f'ComplexTestPass{i}Word789!',
                'name': f'Performance Test User {i}'
            })
    
    def test_api_performance_with_real_calls(self):
        """
        Test app performance with real API calls
        
        This test measures response times for all API endpoints to ensure
        they meet acceptable performance standards.
        
        Requirements: 1.6, 4.1, 4.4, 8.1, 8.5
        """
        # Performance thresholds (in seconds)
        REGISTRATION_THRESHOLD = 2.0
        LOGIN_THRESHOLD = 1.0
        PROFILE_GET_THRESHOLD = 0.5
        PROFILE_UPDATE_THRESHOLD = 1.0
        
        response_times = {
            'registration': [],
            'login': [],
            'profile_get': [],
            'profile_update': []
        }
        
        # Test multiple iterations to get average performance
        iterations = 5
        
        for i in range(iterations):
            # Clean up before each iteration
            User.objects.filter(email=f'perftest{i}@example.com').delete()
            
            # Test 1: Registration Performance
            registration_data = {
                'email': f'perftest{i}@example.com',
                'password': f'ComplexTestPass{i}Word789!',
                'name': f'Performance Test User {i}'
            }
            
            start_time = time.time()
            register_response = self.client.post('/api/auth/register/', registration_data, format='json')
            registration_time = time.time() - start_time
            
            self.assertEqual(register_response.status_code, status.HTTP_201_CREATED)
            response_times['registration'].append(registration_time)
            
            auth_token = register_response.json()['data']['token']
            
            # Test 2: Login Performance
            login_data = {
                'email': registration_data['email'],
                'password': registration_data['password']
            }
            
            start_time = time.time()
            login_response = self.client.post('/api/auth/login/', login_data, format='json')
            login_time = time.time() - start_time
            
            self.assertEqual(login_response.status_code, status.HTTP_200_OK)
            response_times['login'].append(login_time)
            
            # Set up authentication for protected endpoints
            self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {auth_token}')
            
            # Test 3: Profile Retrieval Performance
            start_time = time.time()
            profile_response = self.client.get('/api/auth/me/')
            profile_get_time = time.time() - start_time
            
            self.assertEqual(profile_response.status_code, status.HTTP_200_OK)
            response_times['profile_get'].append(profile_get_time)
            
            # Test 4: Profile Update Performance
            profile_update_data = {
                'name': f'Updated User {i}',
                'gender': 'Male',
                'age_group': 'Adult',
                'height': 175.0 + i,
                'weight': 70.0 + i,
                'fitness_level': 'Intermediate'
            }
            
            start_time = time.time()
            update_response = self.client.put('/api/auth/profile/', profile_update_data, format='json')
            profile_update_time = time.time() - start_time
            
            self.assertEqual(update_response.status_code, status.HTTP_200_OK)
            response_times['profile_update'].append(profile_update_time)
            
            # Clear credentials for next iteration
            self.client.credentials()
        
        # Calculate and verify average response times
        avg_registration_time = statistics.mean(response_times['registration'])
        avg_login_time = statistics.mean(response_times['login'])
        avg_profile_get_time = statistics.mean(response_times['profile_get'])
        avg_profile_update_time = statistics.mean(response_times['profile_update'])
        
        # Print performance metrics for debugging
        print(f"\nAPI Performance Metrics (average over {iterations} iterations):")
        print(f"Registration: {avg_registration_time:.3f}s (threshold: {REGISTRATION_THRESHOLD}s)")
        print(f"Login: {avg_login_time:.3f}s (threshold: {LOGIN_THRESHOLD}s)")
        print(f"Profile Get: {avg_profile_get_time:.3f}s (threshold: {PROFILE_GET_THRESHOLD}s)")
        print(f"Profile Update: {avg_profile_update_time:.3f}s (threshold: {PROFILE_UPDATE_THRESHOLD}s)")
        
        # Assert performance meets thresholds
        self.assertLess(avg_registration_time, REGISTRATION_THRESHOLD, 
                       f"Registration took {avg_registration_time:.3f}s, exceeds {REGISTRATION_THRESHOLD}s threshold")
        self.assertLess(avg_login_time, LOGIN_THRESHOLD,
                       f"Login took {avg_login_time:.3f}s, exceeds {LOGIN_THRESHOLD}s threshold")
        self.assertLess(avg_profile_get_time, PROFILE_GET_THRESHOLD,
                       f"Profile retrieval took {avg_profile_get_time:.3f}s, exceeds {PROFILE_GET_THRESHOLD}s threshold")
        self.assertLess(avg_profile_update_time, PROFILE_UPDATE_THRESHOLD,
                       f"Profile update took {avg_profile_update_time:.3f}s, exceeds {PROFILE_UPDATE_THRESHOLD}s threshold")
    
    def test_secure_token_storage_and_transmission(self):
        """
        Verify secure token storage and transmission
        
        This test validates that JWT tokens are generated securely,
        transmitted properly, and validated correctly.
        
        Requirements: 4.1, 4.4, 8.5
        """
        # Create test user
        test_user = User.objects.create(
            username="tokentest_user",
            email='tokentest@example.com',
            name='Token Test User'
        )
        test_user.set_password('ComplexTokenTestPass789!')
        test_user.save()
        
        # Test 1: Token Generation Security
        login_data = {
            'email': 'tokentest@example.com',
            'password': 'ComplexTokenTestPass789!'
        }
        
        login_response = self.client.post('/api/auth/login/', login_data, format='json')
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        
        auth_token = login_response.json()['data']['token']
        
        # Verify token is not empty and has proper structure
        self.assertIsNotNone(auth_token)
        self.assertGreater(len(auth_token), 50)  # JWT tokens should be reasonably long
        
        # Verify token contains three parts (header.payload.signature)
        token_parts = auth_token.split('.')
        self.assertEqual(len(token_parts), 3, "JWT token should have 3 parts separated by dots")
        
        # Test 2: Token Validation
        payload = validate_jwt_token(auth_token)
        self.assertIsNotNone(payload)
        self.assertEqual(payload['email'], 'tokentest@example.com')
        self.assertEqual(payload['user_id'], str(test_user.id))
        self.assertIn('exp', payload)  # Expiration should be present
        self.assertIn('iat', payload)  # Issued at should be present
        
        # Test 3: Token Transmission Security (Authorization Header)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {auth_token}')
        
        profile_response = self.client.get('/api/auth/me/')
        self.assertEqual(profile_response.status_code, status.HTTP_200_OK)
        
        # Test 4: Invalid Token Rejection
        invalid_tokens = [
            'invalid.token.here',
            'Bearer invalid-token',
            '',
            'malformed-token-without-dots',
            'too.short',
            f'{auth_token}corrupted'  # Corrupted valid token
        ]
        
        for invalid_token in invalid_tokens:
            self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {invalid_token}')
            
            invalid_response = self.client.get('/api/auth/me/')
            self.assertEqual(invalid_response.status_code, status.HTTP_401_UNAUTHORIZED,
                           f"Invalid token '{invalid_token}' should be rejected")
        
        # Test 5: Token Expiry Validation
        # Create an expired token manually
        from datetime import datetime, timezone
        
        expired_payload = {
            'user_id': str(test_user.id),
            'email': test_user.email,
            'exp': datetime.now(timezone.utc) - timedelta(seconds=1),  # Expired
            'iat': datetime.now(timezone.utc) - timedelta(seconds=3600)
        }
        
        expired_token = jwt.encode(
            expired_payload,
            settings.JWT_SECRET_KEY,
            algorithm=settings.JWT_ALGORITHM
        )
        
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {expired_token}')
        
        expired_response = self.client.get('/api/auth/me/')
        self.assertEqual(expired_response.status_code, status.HTTP_401_UNAUTHORIZED,
                        "Expired token should be rejected")
        
        # Test 6: Token Uniqueness
        # Generate multiple tokens for the same user and verify they're different
        tokens = []
        for _ in range(3):
            time.sleep(0.1)  # Small delay to ensure different iat timestamps
            token_response = self.client.post('/api/auth/login/', login_data, format='json')
            tokens.append(token_response.json()['data']['token'])
        
        # All tokens should be different (due to different iat timestamps)
        self.assertEqual(len(tokens), len(set(tokens)), "Each login should generate a unique token")
    
    def test_database_performance_with_sample_data(self):
        """
        Test database performance with sample data
        
        This test creates a larger dataset and measures database
        operation performance to ensure scalability.
        
        Requirements: 6.1, 6.2, 6.4, 6.5
        """
        # Performance thresholds for database operations
        BULK_CREATE_THRESHOLD = 5.0  # seconds for creating 100 users
        QUERY_THRESHOLD = 0.1  # seconds for single user queries
        UPDATE_THRESHOLD = 0.1  # seconds for single user updates
        
        # Test 1: Bulk User Creation Performance
        users_data = []
        for i in range(100):
            users_data.append({
                'email': f'dbtest{i}@example.com',
                'password': f'ComplexDBTestPass{i}Word789!',
                'name': f'DB Test User {i}',
                'gender': 'Male' if i % 2 == 0 else 'Female',
                'age_group': ['Adult', 'Mid-Age Adult', 'Older Adult'][i % 3],
                'height': 160.0 + (i % 40),
                'weight': 50.0 + (i % 50),
                'fitness_level': ['Beginner', 'Intermediate', 'Advance'][i % 3]
            })
        
        # Clean up any existing test users
        User.objects.filter(email__startswith='dbtest').delete()
        
        start_time = time.time()
        
        # Create users via API (more realistic than bulk_create)
        created_users = []
        for user_data in users_data:
            response = self.client.post('/api/auth/register/', user_data, format='json')
            if response.status_code == status.HTTP_201_CREATED:
                created_users.append(response.json()['data']['user'])
        
        bulk_create_time = time.time() - start_time
        
        print(f"\nDatabase Performance Metrics:")
        print(f"Created {len(created_users)} users in {bulk_create_time:.3f}s")
        print(f"Average time per user creation: {bulk_create_time/len(created_users):.3f}s")
        
        # Verify all users were created
        self.assertEqual(len(created_users), 100)
        self.assertLess(bulk_create_time, BULK_CREATE_THRESHOLD,
                       f"Bulk user creation took {bulk_create_time:.3f}s, exceeds {BULK_CREATE_THRESHOLD}s threshold")
        
        # Test 2: Query Performance
        query_times = []
        
        for i in range(10):  # Test 10 random queries
            email = f'dbtest{i * 10}@example.com'
            
            start_time = time.time()
            user = User.objects.get(email=email)
            query_time = time.time() - start_time
            
            query_times.append(query_time)
            
            # Verify user data integrity
            self.assertEqual(user.email, email)
            self.assertIsNotNone(user.name)
            self.assertIsNotNone(user.created_at)
        
        avg_query_time = statistics.mean(query_times)
        print(f"Average query time: {avg_query_time:.4f}s (threshold: {QUERY_THRESHOLD}s)")
        
        self.assertLess(avg_query_time, QUERY_THRESHOLD,
                       f"Average query time {avg_query_time:.4f}s exceeds {QUERY_THRESHOLD}s threshold")
        
        # Test 3: Update Performance
        update_times = []
        
        for i in range(10):  # Test 10 random updates
            email = f'dbtest{i * 10 + 5}@example.com'
            user = User.objects.get(email=email)
            
            start_time = time.time()
            user.name = f'Updated DB Test User {i}'
            user.weight = 75.0 + i
            user.save()
            update_time = time.time() - start_time
            
            update_times.append(update_time)
        
        avg_update_time = statistics.mean(update_times)
        print(f"Average update time: {avg_update_time:.4f}s (threshold: {UPDATE_THRESHOLD}s)")
        
        self.assertLess(avg_update_time, UPDATE_THRESHOLD,
                       f"Average update time {avg_update_time:.4f}s exceeds {UPDATE_THRESHOLD}s threshold")
        
        # Test 4: Database Constraint Validation
        # Test unique email constraint
        duplicate_user_data = {
            'email': 'dbtest0@example.com',  # Already exists
            'password': 'AnotherComplexPass789!',
            'name': 'Duplicate User'
        }
        
        duplicate_response = self.client.post('/api/auth/register/', duplicate_user_data, format='json')
        # Should fail due to unique constraint
        self.assertIn(duplicate_response.status_code, [status.HTTP_400_BAD_REQUEST, status.HTTP_409_CONFLICT])
        
        # Test 5: Concurrent Database Operations
        def concurrent_update(user_id, update_value):
            """Helper function for concurrent updates"""
            try:
                user = User.objects.get(id=user_id)
                user.weight = update_value
                user.save()
                return True
            except Exception:
                return False
        
        # Get a test user for concurrent updates
        test_user = User.objects.filter(email__startswith='dbtest').first()
        
        # Perform concurrent updates using threading
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = []
            for i in range(5):
                future = executor.submit(concurrent_update, test_user.id, 80.0 + i)
                futures.append(future)
            
            # Wait for all updates to complete
            results = [future.result() for future in futures]
        
        # At least one update should succeed (database should handle concurrency)
        self.assertTrue(any(results), "At least one concurrent update should succeed")
        
        # Verify final state is consistent
        test_user.refresh_from_db()
        self.assertIsNotNone(test_user.weight)
        self.assertGreaterEqual(test_user.weight, 80.0)
        self.assertLessEqual(test_user.weight, 84.0)
    
    def test_password_hashing_and_security_measures(self):
        """
        Validate password hashing and security measures
        
        This test ensures passwords are hashed securely and
        security best practices are followed.
        
        Requirements: 1.6, 8.1
        """
        # Test 1: Password Hashing Validation
        test_passwords = [
            'SimplePassword123!',
            'ComplexP@ssw0rd!WithSpecialChars',
            'VeryLongPasswordWithManyCharactersToTestHashingPerformance123!@#',
            'Short1!',
            '12345678',  # Weak but meets minimum length
        ]
        
        hashed_passwords = []
        
        for i, password in enumerate(test_passwords):
            user_data = {
                'email': f'hashtest{i}@example.com',
                'password': password,
                'name': f'Hash Test User {i}'
            }
            
            # Clean up any existing user
            User.objects.filter(email=user_data['email']).delete()
            
            response = self.client.post('/api/auth/register/', user_data, format='json')
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)
            
            # Retrieve user from database
            user = User.objects.get(email=user_data['email'])
            
            # Verify password is hashed (not stored in plain text)
            self.assertNotEqual(user.password, password, "Password should not be stored in plain text")
            self.assertTrue(user.password.startswith('pbkdf2_sha256$'), "Should use Django's PBKDF2 hashing")
            
            # Verify password hash is usable
            self.assertTrue(is_password_usable(user.password), "Password hash should be usable")
            
            # Verify password can be checked correctly
            self.assertTrue(check_password(password, user.password), "Password should verify correctly")
            self.assertFalse(check_password('wrongpassword', user.password), "Wrong password should not verify")
            
            hashed_passwords.append(user.password)
        
        # Test 2: Hash Uniqueness
        # Same password should produce different hashes due to salt
        same_password = 'SamePasswordForTesting123!'
        same_password_hashes = []
        
        for i in range(3):
            user_data = {
                'email': f'samepasstest{i}@example.com',
                'password': same_password,
                'name': f'Same Password Test User {i}'
            }
            
            User.objects.filter(email=user_data['email']).delete()
            
            response = self.client.post('/api/auth/register/', user_data, format='json')
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)
            
            user = User.objects.get(email=user_data['email'])
            same_password_hashes.append(user.password)
        
        # All hashes should be different due to salt
        self.assertEqual(len(same_password_hashes), len(set(same_password_hashes)),
                        "Same password should produce different hashes due to salt")
        
        # Test 3: Password Validation During Login
        login_test_user = User.objects.create(
            username="logintest_user",
            email='logintest@example.com',
            name='Login Test User'
        )
        login_test_user.set_password('CorrectLoginPassword123!')
        login_test_user.save()
        
        # Test correct password
        correct_login_data = {
            'email': 'logintest@example.com',
            'password': 'CorrectLoginPassword123!'
        }
        
        correct_response = self.client.post('/api/auth/login/', correct_login_data, format='json')
        self.assertEqual(correct_response.status_code, status.HTTP_200_OK)
        
        # Test incorrect passwords
        incorrect_passwords = [
            'WrongPassword123!',
            'correctloginpassword123!',  # Wrong case
            'CorrectLoginPassword123',   # Missing special char
            '',  # Empty password
            'CorrectLoginPassword123! ',  # Extra space
        ]
        
        for wrong_password in incorrect_passwords:
            wrong_login_data = {
                'email': 'logintest@example.com',
                'password': wrong_password
            }
            
            wrong_response = self.client.post('/api/auth/login/', wrong_login_data, format='json')
            self.assertEqual(wrong_response.status_code, status.HTTP_401_UNAUTHORIZED,
                           f"Wrong password '{wrong_password}' should be rejected")
        
        # Test 4: Password Hashing Performance
        # Ensure password hashing doesn't take too long
        HASH_PERFORMANCE_THRESHOLD = 1.0  # seconds
        
        performance_password = 'PerformanceTestPassword123!'
        
        start_time = time.time()
        
        performance_user_data = {
            'email': 'perfhashtest@example.com',
            'password': performance_password,
            'name': 'Performance Hash Test User'
        }
        
        User.objects.filter(email=performance_user_data['email']).delete()
        
        hash_response = self.client.post('/api/auth/register/', performance_user_data, format='json')
        hash_time = time.time() - start_time
        
        self.assertEqual(hash_response.status_code, status.HTTP_201_CREATED)
        self.assertLess(hash_time, HASH_PERFORMANCE_THRESHOLD,
                       f"Password hashing took {hash_time:.3f}s, exceeds {HASH_PERFORMANCE_THRESHOLD}s threshold")
        
        print(f"Password hashing performance: {hash_time:.3f}s")
        
        # Test 5: Security Headers and Response Validation
        # Verify no sensitive information is leaked in responses
        user_data = {
            'email': 'securitytest@example.com',
            'password': 'SecurityTestPassword123!',
            'name': 'Security Test User'
        }
        
        User.objects.filter(email=user_data['email']).delete()
        
        security_response = self.client.post('/api/auth/register/', user_data, format='json')
        self.assertEqual(security_response.status_code, status.HTTP_201_CREATED)
        
        response_data = security_response.json()
        
        # Verify password is not included in response
        self.assertNotIn('password', str(response_data))
        self.assertNotIn('SecurityTestPassword123!', str(response_data))
        
        # Verify user data doesn't contain sensitive fields
        user_response_data = response_data['data']['user']
        self.assertNotIn('password', user_response_data)
        self.assertNotIn('is_superuser', user_response_data)
        self.assertNotIn('is_staff', user_response_data)
        
        # Test login response security
        login_data = {
            'email': user_data['email'],
            'password': user_data['password']
        }
        
        login_response = self.client.post('/api/auth/login/', login_data, format='json')
        login_response_data = login_response.json()
        
        # Verify password is not included in login response
        self.assertNotIn('password', str(login_response_data))
        self.assertNotIn('SecurityTestPassword123!', str(login_response_data))
    
    def tearDown(self):
        """Clean up after each test."""
        # Clear any authentication credentials
        self.client.credentials()
        
        # Clean up test data
        User.objects.filter(email__contains='test').delete()
        User.objects.filter(email__startswith='perf').delete()
        User.objects.filter(email__startswith='db').delete()
        User.objects.filter(email__startswith='hash').delete()
        User.objects.filter(email__startswith='same').delete()
        User.objects.filter(email__startswith='login').delete()
        User.objects.filter(email__startswith='security').delete()
        User.objects.filter(email__startswith='concurrent').delete()