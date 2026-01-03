"""
Custom exception handlers for consistent error responses

Requirements: 7.5, 7.6, 8.3
"""
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.http import Http404
import logging

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """
    Custom exception handler that returns consistent error response format
    
    All API responses follow this format:
    {
        "success": false,
        "message": "Human readable error message",
        "errors": {
            "field_name": ["Error message for field"],
            "detail": "General error message"
        }
    }
    
    Requirements: 7.5, 7.6, 8.3
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)
    
    # If DRF handled the exception, customize the response format
    if response is not None:
        custom_response_data = {
            'success': False,
            'message': 'Request failed',
            'errors': {}
        }
        
        # Handle different types of DRF exceptions
        if hasattr(exc, 'detail'):
            if isinstance(exc.detail, dict):
                # Field-specific validation errors
                custom_response_data['errors'] = exc.detail
                custom_response_data['message'] = 'Validation failed'
            elif isinstance(exc.detail, list):
                # List of errors
                custom_response_data['errors'] = {'detail': exc.detail}
                custom_response_data['message'] = 'Request failed'
            else:
                # Single error message
                custom_response_data['errors'] = {'detail': str(exc.detail)}
                
                # Customize message based on status code
                if response.status_code == status.HTTP_401_UNAUTHORIZED:
                    custom_response_data['message'] = 'Authentication required'
                elif response.status_code == status.HTTP_403_FORBIDDEN:
                    custom_response_data['message'] = 'Permission denied'
                elif response.status_code == status.HTTP_404_NOT_FOUND:
                    custom_response_data['message'] = 'Resource not found'
                elif response.status_code == status.HTTP_405_METHOD_NOT_ALLOWED:
                    custom_response_data['message'] = 'Method not allowed'
                else:
                    custom_response_data['message'] = 'Request failed'
        
        response.data = custom_response_data
        return response
    
    # Handle Django-specific exceptions that DRF doesn't handle
    if isinstance(exc, ValidationError):
        logger.warning(f"Django ValidationError: {exc}")
        return Response({
            'success': False,
            'message': 'Validation failed',
            'errors': {'detail': exc.messages if hasattr(exc, 'messages') else [str(exc)]}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    if isinstance(exc, IntegrityError):
        logger.warning(f"Database IntegrityError: {exc}")
        
        # Handle common integrity errors without exposing sensitive database info
        error_message = str(exc).lower()
        if 'unique constraint' in error_message or 'duplicate key' in error_message:
            if 'email' in error_message:
                return Response({
                    'success': False,
                    'message': 'Email already exists',
                    'errors': {'email': ['A user with this email already exists.']}
                }, status=status.HTTP_409_CONFLICT)
            else:
                return Response({
                    'success': False,
                    'message': 'Duplicate entry',
                    'errors': {'detail': 'This record already exists.'}
                }, status=status.HTTP_409_CONFLICT)
        else:
            return Response({
                'success': False,
                'message': 'Database constraint violation',
                'errors': {'detail': 'The operation violates database constraints.'}
            }, status=status.HTTP_400_BAD_REQUEST)
    
    if isinstance(exc, Http404):
        logger.info(f"Http404: {exc}")
        return Response({
            'success': False,
            'message': 'Resource not found',
            'errors': {'detail': 'The requested resource was not found.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Handle unexpected server errors
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return Response({
        'success': False,
        'message': 'Internal server error',
        'errors': {'detail': 'An unexpected error occurred. Please try again later.'}
    }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def handle_authentication_error(message="Authentication required"):
    """
    Helper function to create consistent authentication error responses
    
    Requirements: 8.3, 8.4
    """
    return Response({
        'success': False,
        'message': message,
        'errors': {'detail': message}
    }, status=status.HTTP_401_UNAUTHORIZED)


def handle_validation_error(errors, message="Validation failed"):
    """
    Helper function to create consistent validation error responses
    
    Requirements: 7.6, 8.2
    """
    return Response({
        'success': False,
        'message': message,
        'errors': errors
    }, status=status.HTTP_400_BAD_REQUEST)


def handle_permission_error(message="Permission denied"):
    """
    Helper function to create consistent permission error responses
    
    Requirements: 8.3, 8.4
    """
    return Response({
        'success': False,
        'message': message,
        'errors': {'detail': message}
    }, status=status.HTTP_403_FORBIDDEN)