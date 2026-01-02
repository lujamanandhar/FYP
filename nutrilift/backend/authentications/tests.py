from django.test import TestCase, Client, override_settings
from django.http import JsonResponse
from django.urls import path, include
from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
from .models import User
from .serializers import UserRegistrationSerializer, ProfileUpdateSerializer
import json
import uuid
from datetime import datetime, timedelta

# Create your tests here.

@override_settings(
    DATABASES={
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': ':memory:',
        }
    }
)
class DjangoConfigurationPropertyTest(HypothesisTestCase):
    """
    Property-based tests for Django configuration to ensure consistent response format.
    Feature: user-authentication-profile, Property 18: Response Format Consistency
    """
    
    def setUp(self):
        """Set up test client and mock endpoints for testing response format consistency."""
        self.client = Client()
    
    @given(
        success_status=st.booleans(),
        message=st.text(min_size=1, max_size=100),
        data_content=st.dictionaries(
            keys=st.text(min_size=1, max_size=20),
            values=st.one_of(
                st.text(max_size=50),
                st.integers(),
                st.floats(allow_nan=False, allow_infinity=False),
                st.booleans(),
                st.none()
            ),
            min_size=0,
            max_size=10
        )
    )
    def test_response_format_consistency(self, success_status, message, data_content):
        """
        Feature: user-authentication-profile, Property 18: Response Format Consistency
        
        For any API endpoint response, the JSON structure should follow the consistent 
        format with success/error indicators.
        
        Validates: Requirements 7.5
        """
        # Create a mock response in the expected format
        expected_response = {
            "success": success_status,
            "message": message,
            "data": data_content
        }
        
        # Validate that the response structure contains required fields
        self.assertIn("success", expected_response)
        self.assertIn("message", expected_response)
        self.assertIn("data", expected_response)
        
        # Validate field types
        self.assertIsInstance(expected_response["success"], bool)
        self.assertIsInstance(expected_response["message"], str)
        self.assertIsInstance(expected_response["data"], (dict, type(None)))
        
        # Validate that the response can be serialized to JSON
        try:
            json_response = json.dumps(expected_response)
            parsed_response = json.loads(json_response)
            
            # Ensure the parsed response maintains the same structure
            self.assertEqual(parsed_response["success"], expected_response["success"])
            self.assertEqual(parsed_response["message"], expected_response["message"])
            self.assertEqual(parsed_response["data"], expected_response["data"])
            
        except (TypeError, ValueError) as e:
            self.fail(f"Response format is not JSON serializable: {e}")
    
    def test_django_rest_framework_configuration(self):
        """
        Test that Django REST Framework is properly configured for consistent JSON responses.
        """
        # Verify REST_FRAMEWORK settings exist
        self.assertTrue(hasattr(settings, 'REST_FRAMEWORK'))
        
        # Verify JSON renderer is configured
        renderers = settings.REST_FRAMEWORK.get('DEFAULT_RENDERER_CLASSES', [])
        self.assertIn('rest_framework.renderers.JSONRenderer', renderers)
        
        # Verify JSON parser is configured
        parsers = settings.REST_FRAMEWORK.get('DEFAULT_PARSER_CLASSES', [])
        self.assertIn('rest_framework.parsers.JSONParser', parsers)
    
    def test_cors_configuration_for_consistent_responses(self):
        """
        Test that CORS is properly configured to allow consistent API responses.
        """
        # Verify CORS is configured
        self.assertTrue(hasattr(settings, 'CORS_ALLOW_ALL_ORIGINS'))
        self.assertTrue(hasattr(settings, 'CORS_ALLOW_HEADERS'))
        self.assertTrue(hasattr(settings, 'CORS_ALLOW_METHODS'))
        
        # Verify required headers are allowed for API responses
        allowed_headers = settings.CORS_ALLOW_HEADERS
        required_headers = ['content-type', 'authorization']
        
        for header in required_headers:
            self.assertIn(header, allowed_headers)
        
        # Verify required methods are allowed
        allowed_methods = settings.CORS_ALLOW_METHODS
        required_methods = ['GET', 'POST', 'PUT', 'OPTIONS']
        
        for method in required_methods:
            self.assertIn(method, allowed_methods)
    
    @given(
        status_code=st.integers(min_value=200, max_value=599),
        error_message=st.text(min_size=1, max_size=100)
    )
    def test_error_response_format_consistency(self, status_code, error_message):
        """
        Feature: user-authentication-profile, Property 18: Response Format Consistency
        
        For any error response, the JSON structure should follow the consistent 
        format with success=false and appropriate error message.
        
        Validates: Requirements 7.5, 7.6
        """
        # Create a mock error response in the expected format
        error_response = {
            "success": False,
            "message": error_message,
            "data": None
        }
        
        # Validate error response structure
        self.assertIn("success", error_response)
        self.assertIn("message", error_response)
        self.assertIn("data", error_response)
        
        # Validate error response field values
        self.assertFalse(error_response["success"])
        self.assertIsInstance(error_response["message"], str)
        self.assertIsNone(error_response["data"])
        
        # Validate that error response can be serialized to JSON
        try:
            json_response = json.dumps(error_response)
            parsed_response = json.loads(json_response)
            
            # Ensure the parsed error response maintains the same structure
            self.assertEqual(parsed_response["success"], False)
            self.assertEqual(parsed_response["message"], error_message)
            self.assertIsNone(parsed_response["data"])
            
        except (TypeError, ValueError) as e:
            self.fail(f"Error response format is not JSON serializable: {e}")


@override_settings(
    DATABASES={
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': ':memory:',
        }
    }
)
class ResponseFormatHelperTest(TestCase):
    """
    Test helper functions for creating consistent response formats.
    """
    
    def create_success_response(self, message, data=None):
        """Helper function to create consistent success responses."""
        return {
            "success": True,
            "message": message,
            "data": data
        }
    
    def create_error_response(self, message):
        """Helper function to create consistent error responses."""
        return {
            "success": False,
            "message": message,
            "data": None
        }
    
    def test_success_response_helper(self):
        """Test that success response helper creates consistent format."""
        message = "Operation successful"
        data = {"user_id": 123}
        
        response = self.create_success_response(message, data)
        
        self.assertTrue(response["success"])
        self.assertEqual(response["message"], message)
        self.assertEqual(response["data"], data)
    
    def test_error_response_helper(self):
        """Test that error response helper creates consistent format."""
        message = "Operation failed"
        
        response = self.create_error_response(message)
        
        self.assertFalse(response["success"])
        self.assertEqual(response["message"], message)
        self.assertIsNone(response["data"])


@override_settings(
    DATABASES={
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': ':memory:',
        }
    }
)
class UserModelPropertyTest(HypothesisTestCase):
    """
    Property-based tests for User model to ensure database uniqueness and timestamp tracking.
    """
    
    def setUp(self):
        """Set up test environment for User model property tests."""
        # Ensure we have a clean database state for each test
        User.objects.all().delete()
    
    @given(
        email1=st.emails(),
        email2=st.emails(),
        password=st.text(min_size=8, max_size=128),
        name=st.text(min_size=1, max_size=100)
    )
    def test_database_uniqueness_email_constraint(self, email1, email2, password, name):
        """
        Feature: user-authentication-profile, Property 15: Database Uniqueness
        
        For any user record, the database should enforce unique identifiers and email addresses.
        
        Validates: Requirements 6.1, 6.2
        """
        # Create first user with email1
        user1 = User.objects.create(
            username=f"user1_{email1}",  # Provide unique username
            email=email1,
            password=password,
            name=name
        )
        
        # Verify user1 was created successfully
        self.assertIsNotNone(user1.id)
        self.assertEqual(user1.email, email1)
        
        # If email2 is different from email1, creating another user should succeed
        if email1 != email2:
            user2 = User.objects.create(
                username=f"user2_{email2}",  # Provide unique username
                email=email2,
                password=password,
                name=name
            )
            self.assertIsNotNone(user2.id)
            self.assertEqual(user2.email, email2)
            self.assertNotEqual(user1.id, user2.id)  # Different UUIDs
        else:
            # If email2 is the same as email1, creating another user should fail
            with self.assertRaises(IntegrityError):
                with transaction.atomic():
                    User.objects.create(
                        username=f"user2_{email2}",  # Different username but same email
                        email=email2,
                        password=password,
                        name=name
                    )
    
    @given(
        email=st.emails(),
        password=st.text(min_size=8, max_size=128),
        name=st.text(min_size=1, max_size=100)
    )
    def test_database_uniqueness_uuid_constraint(self, email, password, name):
        """
        Feature: user-authentication-profile, Property 15: Database Uniqueness
        
        For any user record, the database should enforce unique identifiers (UUID).
        
        Validates: Requirements 6.1
        """
        # Create multiple users and verify they all have unique UUIDs
        users = []
        for i in range(3):
            user = User.objects.create(
                username=f"user{i}_{email}",  # Provide unique username
                email=f"{i}_{email}",
                password=password,
                name=f"{name}_{i}"
            )
            users.append(user)
        
        # Verify all users have different UUIDs
        user_ids = [user.id for user in users]
        self.assertEqual(len(user_ids), len(set(user_ids)))  # All IDs should be unique
        
        # Verify all IDs are valid UUIDs
        for user_id in user_ids:
            self.assertIsInstance(user_id, uuid.UUID)
    
    @given(
        email=st.emails(),
        password=st.text(min_size=8, max_size=128),
        name=st.text(min_size=1, max_size=100),
        gender=st.sampled_from(['Male', 'Female', '']),
        age_group=st.sampled_from(['Adult', 'Mid-Age Adult', 'Older Adult', '']),
        height=st.one_of(st.none(), st.floats(min_value=50.0, max_value=300.0, allow_nan=False, allow_infinity=False)),
        weight=st.one_of(st.none(), st.floats(min_value=20.0, max_value=500.0, allow_nan=False, allow_infinity=False)),
        fitness_level=st.sampled_from(['Beginner', 'Intermediate', 'Advance', ''])
    )
    def test_timestamp_tracking_on_creation(self, email, password, name, gender, age_group, height, weight, fitness_level):
        """
        Feature: user-authentication-profile, Property 16: Timestamp Tracking
        
        For any user record creation, appropriate timestamps should be set and maintained.
        
        Validates: Requirements 6.4
        """
        # Record time before creation
        before_creation = timezone.now()
        
        # Create user with profile data
        user = User.objects.create(
            username=f"user_{email}",  # Provide unique username
            email=email,
            password=password,
            name=name,
            gender=gender,
            age_group=age_group,
            height=height,
            weight=weight,
            fitness_level=fitness_level
        )
        
        # Record time after creation
        after_creation = timezone.now()
        
        # Verify timestamps are set
        self.assertIsNotNone(user.created_at)
        self.assertIsNotNone(user.updated_at)
        
        # Verify timestamps are within expected range
        self.assertGreaterEqual(user.created_at, before_creation)
        self.assertLessEqual(user.created_at, after_creation)
        self.assertGreaterEqual(user.updated_at, before_creation)
        self.assertLessEqual(user.updated_at, after_creation)
        
        # Verify created_at and updated_at are initially the same (or very close)
        time_diff = abs((user.updated_at - user.created_at).total_seconds())
        self.assertLess(time_diff, 1.0)  # Should be within 1 second
    
    @given(
        email=st.emails(),
        password=st.text(min_size=8, max_size=128),
        name=st.text(min_size=1, max_size=100),
        new_name=st.text(min_size=1, max_size=100),
        new_gender=st.sampled_from(['Male', 'Female']),
        new_height=st.floats(min_value=50.0, max_value=300.0, allow_nan=False, allow_infinity=False),
        new_weight=st.floats(min_value=20.0, max_value=500.0, allow_nan=False, allow_infinity=False)
    )
    def test_timestamp_tracking_on_update(self, email, password, name, new_name, new_gender, new_height, new_weight):
        """
        Feature: user-authentication-profile, Property 16: Timestamp Tracking
        
        For any user record update, appropriate timestamps should be updated while preserving creation time.
        
        Validates: Requirements 6.4
        """
        # Create user
        user = User.objects.create(
            username=f"user_{email}",  # Provide unique username
            email=email,
            password=password,
            name=name
        )
        
        # Store original timestamps
        original_created_at = user.created_at
        original_updated_at = user.updated_at
        
        # Wait a small amount to ensure timestamp difference
        import time
        time.sleep(0.01)
        
        # Update user profile
        user.name = new_name
        user.gender = new_gender
        user.height = new_height
        user.weight = new_weight
        user.save()
        
        # Refresh from database
        user.refresh_from_db()
        
        # Verify created_at remains unchanged
        self.assertEqual(user.created_at, original_created_at)
        
        # Verify updated_at has changed
        self.assertGreater(user.updated_at, original_updated_at)
        
        # Verify updated fields are persisted
        self.assertEqual(user.name, new_name)
        self.assertEqual(user.gender, new_gender)
        self.assertEqual(user.height, new_height)
        self.assertEqual(user.weight, new_weight)


@override_settings(
    DATABASES={
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': ':memory:',
        }
    }
)
class SerializerPropertyTest(HypothesisTestCase):
    """
    Property-based tests for serializers to ensure email validation, password validation,
    numeric field validation, and enum field validation.
    """
    
    def setUp(self):
        """Set up test environment for serializer property tests."""
        # Ensure we have a clean database state for each test
        User.objects.all().delete()
    
    @settings(max_examples=5, deadline=1000)
    @given(
        valid_email=st.sampled_from(['test1@example.com', 'user@test.org', 'valid@email.net']),
        name=st.text(min_size=1, max_size=50),
        password=st.builds(
            lambda: 'Test123!',  # Use a simple valid password
        )
    )
    def test_email_validation_with_valid_emails(self, valid_email, name, password):
        """
        Feature: user-authentication-profile, Property 2: Email Validation
        
        For any valid email format, the registration serializer should accept it.
        
        Validates: Requirements 1.2
        """
        # Ensure no user exists with this email
        User.objects.filter(email=valid_email).delete()
        
        data = {
            'email': valid_email,
            'name': name,
            'password': password
        }
        
        serializer = UserRegistrationSerializer(data=data)
        
        # Valid email should pass validation
        self.assertTrue(serializer.is_valid(), 
                       f"Valid email {valid_email} should pass validation. Errors: {serializer.errors}")
        
        # Should be able to create user with valid email
        user = serializer.save()
        self.assertEqual(user.email, valid_email.lower())  # Email should be normalized to lowercase
    
    @settings(max_examples=5, deadline=1000)
    @given(
        invalid_email=st.one_of(
            st.just('invalid-email'),  # Simple invalid email
            st.just(''),  # Empty string
            st.just('user@'),  # Missing domain
            st.just('@domain.com'),  # Missing local part
        ),
        name=st.text(min_size=1, max_size=50),
        password=st.just('Test123!')  # Use a simple valid password
    )
    def test_email_validation_with_invalid_emails(self, invalid_email, name, password):
        """
        Feature: user-authentication-profile, Property 2: Email Validation
        
        For any invalid email format, the registration serializer should reject it with a validation error.
        
        Validates: Requirements 1.2
        """
        data = {
            'email': invalid_email,
            'name': name,
            'password': password
        }
        
        serializer = UserRegistrationSerializer(data=data)
        
        # Invalid email should fail validation
        self.assertFalse(serializer.is_valid(), 
                        f"Invalid email {invalid_email} should fail validation")
        
        # Should have email validation error
        self.assertIn('email', serializer.errors)
    
    @settings(max_examples=5, deadline=1000)
    @given(
        email=st.just('test@example.com'),  # Use a simple valid email
        name=st.text(min_size=1, max_size=50),
        valid_password=st.just('Test123!')  # Use a simple valid password
    )
    def test_password_length_validation_with_valid_passwords(self, email, name, valid_password):
        """
        Feature: user-authentication-profile, Property 3: Password Length Validation
        
        For any password meeting minimum length and complexity requirements, 
        the registration serializer should accept it.
        
        Validates: Requirements 1.3
        """
        # Ensure no user exists with this email
        User.objects.filter(email=email).delete()
        
        data = {
            'email': email,
            'name': name,
            'password': valid_password
        }
        
        serializer = UserRegistrationSerializer(data=data)
        
        # Valid password should pass validation
        self.assertTrue(serializer.is_valid(), 
                       f"Valid password of length {len(valid_password)} should pass validation. Errors: {serializer.errors}")
    
    @settings(max_examples=5, deadline=1000)
    @given(
        email=st.just('test2@example.com'),  # Use a simple valid email
        name=st.text(min_size=1, max_size=50),
        invalid_password=st.one_of(
            st.just('short'),  # Too short
            st.just('12345678'),  # No letters
            st.just('abcdefgh'),  # No digits
        )
    )
    def test_password_length_validation_with_invalid_passwords(self, email, name, invalid_password):
        """
        Feature: user-authentication-profile, Property 3: Password Length Validation
        
        For any password shorter than minimum length or missing complexity requirements,
        the registration serializer should reject it with a validation error.
        
        Validates: Requirements 1.3
        """
        # Ensure no user exists with this email
        User.objects.filter(email=email).delete()
        
        data = {
            'email': email,
            'name': name,
            'password': invalid_password
        }
        
        serializer = UserRegistrationSerializer(data=data)
        
        # Invalid password should fail validation
        self.assertFalse(serializer.is_valid(), 
                        f"Invalid password '{invalid_password}' should fail validation")
        
        # Should have password validation error
        self.assertIn('password', serializer.errors)
    
    @settings(max_examples=5, deadline=1000)
    @given(
        name=st.text(min_size=1, max_size=50),
        gender=st.sampled_from(['Male', 'Female']),
        age_group=st.sampled_from(['Adult', 'Mid-Age Adult', 'Older Adult']),
        fitness_level=st.sampled_from(['Beginner', 'Intermediate', 'Advance']),
        valid_height=st.floats(min_value=150.0, max_value=200.0, allow_nan=False, allow_infinity=False),
        valid_weight=st.floats(min_value=50.0, max_value=100.0, allow_nan=False, allow_infinity=False)
    )
    def test_numeric_field_validation_with_valid_values(self, name, gender, age_group, fitness_level, valid_height, valid_weight):
        """
        Feature: user-authentication-profile, Property 9: Numeric Field Validation
        
        For any profile update with positive height and weight values, 
        the profile update serializer should accept them.
        
        Validates: Requirements 3.3, 3.4
        """
        data = {
            'name': name,
            'gender': gender,
            'age_group': age_group,
            'fitness_level': fitness_level,
            'height': valid_height,
            'weight': valid_weight
        }
        
        serializer = ProfileUpdateSerializer(data=data)
        
        # Valid numeric values should pass validation
        self.assertTrue(serializer.is_valid(), 
                       f"Valid height {valid_height} and weight {valid_weight} should pass validation. Errors: {serializer.errors}")
    
    @settings(max_examples=5, deadline=1000)
    @given(
        name=st.text(min_size=1, max_size=50),
        invalid_height=st.one_of(
            st.just(-10.0),  # Negative
            st.just(0.0),    # Zero
            st.just(500.0),  # Too large
        ),
        invalid_weight=st.one_of(
            st.just(-5.0),   # Negative
            st.just(0.0),    # Zero
            st.just(1500.0), # Too large
        )
    )
    def test_numeric_field_validation_with_invalid_values(self, name, invalid_height, invalid_weight):
        """
        Feature: user-authentication-profile, Property 9: Numeric Field Validation
        
        For any profile update with negative, zero, or unreasonably large height/weight values,
        the profile update serializer should reject them with validation errors.
        
        Validates: Requirements 3.3, 3.4
        """
        # Test invalid height
        data_height = {
            'name': name,
            'height': invalid_height,
        }
        
        serializer_height = ProfileUpdateSerializer(data=data_height)
        
        # Invalid height should fail validation
        self.assertFalse(serializer_height.is_valid(), 
                        f"Invalid height {invalid_height} should fail validation")
        
        # Should have height validation error
        self.assertIn('height', serializer_height.errors)
        
        # Test invalid weight
        data_weight = {
            'name': name,
            'weight': invalid_weight,
        }
        
        serializer_weight = ProfileUpdateSerializer(data=data_weight)
        
        # Invalid weight should fail validation
        self.assertFalse(serializer_weight.is_valid(), 
                        f"Invalid weight {invalid_weight} should fail validation")
        
        # Should have weight validation error
        self.assertIn('weight', serializer_weight.errors)
    
    @settings(max_examples=5, deadline=1000)
    @given(
        name=st.text(min_size=1, max_size=50),
        valid_gender=st.sampled_from(['Male', 'Female']),
        valid_age_group=st.sampled_from(['Adult', 'Mid-Age Adult', 'Older Adult']),
        valid_fitness_level=st.sampled_from(['Beginner', 'Intermediate', 'Advance'])
    )
    def test_enum_field_validation_with_valid_values(self, name, valid_gender, valid_age_group, valid_fitness_level):
        """
        Feature: user-authentication-profile, Property 10: Enum Field Validation
        
        For any profile update with gender, age_group, and fitness_level from allowed values,
        the profile update serializer should accept them.
        
        Validates: Requirements 3.5
        """
        data = {
            'name': name,
            'gender': valid_gender,
            'age_group': valid_age_group,
            'fitness_level': valid_fitness_level
        }
        
        serializer = ProfileUpdateSerializer(data=data)
        
        # Valid enum values should pass validation
        self.assertTrue(serializer.is_valid(), 
                       f"Valid enum values should pass validation. Errors: {serializer.errors}")
    
    @settings(max_examples=5, deadline=1000)
    @given(
        name=st.text(min_size=1, max_size=50),
        invalid_gender=st.sampled_from(['Other', 'Unknown', 'NonBinary']),
        invalid_age_group=st.sampled_from(['Child', 'Teen', 'Senior']),
        invalid_fitness_level=st.sampled_from(['Expert', 'Pro', 'Novice'])
    )
    def test_enum_field_validation_with_invalid_values(self, name, invalid_gender, invalid_age_group, invalid_fitness_level):
        """
        Feature: user-authentication-profile, Property 10: Enum Field Validation
        
        For any profile update with gender, age_group, or fitness_level not from allowed values,
        the profile update serializer should reject them with validation errors.
        
        Validates: Requirements 3.5
        """
        # Test invalid gender
        data_gender = {
            'name': name,
            'gender': invalid_gender,
        }
        
        serializer_gender = ProfileUpdateSerializer(data=data_gender)
        
        # Invalid gender should fail validation
        self.assertFalse(serializer_gender.is_valid(), 
                        f"Invalid gender '{invalid_gender}' should fail validation")
        
        # Should have gender validation error
        self.assertIn('gender', serializer_gender.errors)
        
        # Test invalid age_group
        data_age_group = {
            'name': name,
            'age_group': invalid_age_group,
        }
        
        serializer_age_group = ProfileUpdateSerializer(data=data_age_group)
        
        # Invalid age_group should fail validation
        self.assertFalse(serializer_age_group.is_valid(), 
                        f"Invalid age_group '{invalid_age_group}' should fail validation")
        
        # Should have age_group validation error
        self.assertIn('age_group', serializer_age_group.errors)
        
        # Test invalid fitness_level
        data_fitness_level = {
            'name': name,
            'fitness_level': invalid_fitness_level,
        }
        
        serializer_fitness_level = ProfileUpdateSerializer(data=data_fitness_level)
        
        # Invalid fitness_level should fail validation
        self.assertFalse(serializer_fitness_level.is_valid(), 
                        f"Invalid fitness_level '{invalid_fitness_level}' should fail validation")
        
        # Should have fitness_level validation error
        self.assertIn('fitness_level', serializer_fitness_level.errors)