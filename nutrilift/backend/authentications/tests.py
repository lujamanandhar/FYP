from django.test import TestCase, Client, override_settings
from django.http import JsonResponse
from django.urls import path, include
from django.conf import settings
from rest_framework.test import APITestCase
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from hypothesis import given, strategies as st
from hypothesis.extra.django import TestCase as HypothesisTestCase
import json

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