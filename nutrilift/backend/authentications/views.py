from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from django.contrib.auth.hashers import check_password
from django.db import transaction, IntegrityError
from .models import User
from .serializers import UserRegistrationSerializer, UserProfileSerializer, ProfileUpdateSerializer
from .jwt_utils import generate_jwt_token
from .exceptions import handle_authentication_error, handle_validation_error
import logging

logger = logging.getLogger(__name__)


@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    """
    API Root endpoint - Shows all available authentication endpoints
    
    GET /api/auth/
    """
    return Response({
        'success': True,
        'message': 'NutriLift Authentication API',
        'data': {
            'version': '1.0',
            'description': 'User authentication and profile management API',
            'endpoints': {
                'register': {
                    'url': '/api/auth/register/',
                    'methods': ['GET', 'POST'],
                    'description': 'User registration - GET for docs, POST to register'
                },
                'login': {
                    'url': '/api/auth/login/',
                    'methods': ['GET', 'POST'],
                    'description': 'User login - GET for docs, POST to login'
                },
                'profile_get': {
                    'url': '/api/auth/me/',
                    'methods': ['GET'],
                    'description': 'Get current user profile (requires authentication)'
                },
                'profile_update': {
                    'url': '/api/auth/profile/',
                    'methods': ['GET', 'PUT'],
                    'description': 'Update user profile - GET for docs, PUT to update (requires authentication)'
                }
            },
            'authentication': {
                'type': 'JWT Bearer Token',
                'header': 'Authorization: Bearer <token>',
                'note': 'Include the token received from login/register in the Authorization header'
            }
        }
    }, status=status.HTTP_200_OK)


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def register(request):
    """
    User registration endpoint
    
    GET /api/auth/register - Returns API documentation
    POST /api/auth/register - Registers a new user
    
    Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6
    """
    
    # Handle GET request - return API documentation
    if request.method == 'GET':
        return Response({
            'success': True,
            'message': 'User Registration API',
            'data': {
                'endpoint': '/api/auth/register/',
                'method': 'POST',
                'description': 'Register a new user account',
                'required_fields': {
                    'email': 'Valid email address',
                    'password': 'Password (minimum 8 characters)',
                    'name': 'Full name (optional)'
                },
                'example_request': {
                    'email': 'user@example.com',
                    'password': 'securepassword123',
                    'name': 'John Doe'
                },
                'example_response': {
                    'success': True,
                    'message': 'User registered successfully',
                    'data': {
                        'user': {
                            'id': 'uuid-string',
                            'email': 'user@example.com',
                            'name': 'John Doe',
                            'created_at': '2025-01-04T12:00:00Z'
                        },
                        'token': 'jwt-token-string'
                    }
                }
            }
        }, status=status.HTTP_200_OK)
    
    # Handle POST request - actual registration
    try:
        # Validate input data using UserRegistrationSerializer
        serializer = UserRegistrationSerializer(data=request.data)
        
        if not serializer.is_valid():
            return handle_validation_error(
                errors=serializer.errors,
                message='Registration validation failed'
            )
        
        # Check for existing email before attempting to create user
        email = serializer.validated_data.get('email', '').lower().strip()
        if User.objects.filter(email=email).exists():
            return Response({
                'success': False,
                'message': 'Email already exists',
                'errors': {'email': ['A user with this email already exists.']}
            }, status=status.HTTP_409_CONFLICT)
        
        # Create user with atomic transaction to ensure data consistency
        with transaction.atomic():
            # Create user record (password is already hashed in serializer)
            user = serializer.save()
            
            # Generate JWT token for the new user
            token = generate_jwt_token(user)
            
            # Prepare user profile data for response
            profile_serializer = UserProfileSerializer(user)
            
            return Response({
                'success': True,
                'message': 'User registered successfully',
                'data': {
                    'user': profile_serializer.data,
                    'token': token
                }
            }, status=status.HTTP_201_CREATED)
            
    except IntegrityError as e:
        # Handle database integrity errors (e.g., duplicate email)
        logger.warning(f"Registration integrity error: {str(e)}")
        return Response({
            'success': False,
            'message': 'Email already exists',
            'errors': {'email': ['A user with this email already exists.']}
        }, status=status.HTTP_409_CONFLICT)
        
    except Exception as e:
        logger.error(f"Registration error: {str(e)}", exc_info=True)
        return Response({
            'success': False,
            'message': 'Registration failed due to server error',
            'errors': {'detail': 'Internal server error occurred. Please try again later.'}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def login(request):
    """
    User login endpoint
    
    GET /api/auth/login - Returns API documentation
    POST /api/auth/login - Authenticates user
    
    Requirements: 2.1, 2.2, 2.3, 2.4
    """
    
    # Handle GET request - return API documentation
    if request.method == 'GET':
        return Response({
            'success': True,
            'message': 'User Login API',
            'data': {
                'endpoint': '/api/auth/login/',
                'method': 'POST',
                'description': 'Authenticate user and get access token',
                'required_fields': {
                    'email': 'Registered email address',
                    'password': 'User password'
                },
                'example_request': {
                    'email': 'user@example.com',
                    'password': 'securepassword123'
                },
                'example_response': {
                    'success': True,
                    'message': 'Login successful',
                    'data': {
                        'user': {
                            'id': 'uuid-string',
                            'email': 'user@example.com',
                            'name': 'John Doe',
                            'gender': 'Male',
                            'age_group': 'Adult',
                            'height': 175.0,
                            'weight': 70.0,
                            'fitness_level': 'Intermediate'
                        },
                        'token': 'jwt-token-string'
                    }
                }
            }
        }, status=status.HTTP_200_OK)
    
    # Handle POST request - actual login
    try:
        # Validate input data
        email = request.data.get('email')
        password = request.data.get('password')
        
        # Check for required fields
        if not email or not password:
            errors = {}
            if not email:
                errors['email'] = ['This field is required.']
            if not password:
                errors['password'] = ['This field is required.']
            
            return handle_validation_error(
                errors=errors,
                message='Email and password are required'
            )
        
        # Normalize email to lowercase for consistency
        email = email.lower().strip()
        
        # Validate email format (basic validation)
        if '@' not in email or '.' not in email.split('@')[-1]:
            return handle_validation_error(
                errors={'email': ['Enter a valid email address.']},
                message='Invalid email format'
            )
        
        # Find user by email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Return generic error to prevent email enumeration
            return handle_authentication_error('Invalid email or password')
        
        # Check if user account is active
        if not user.is_active:
            return handle_authentication_error('User account is disabled')
        
        # Verify password securely using Django's check_password
        if not check_password(password, user.password):
            return handle_authentication_error('Invalid email or password')
        
        # Generate JWT token for successful login
        token = generate_jwt_token(user)
        
        # Prepare user profile data for response
        profile_serializer = UserProfileSerializer(user)
        
        return Response({
            'success': True,
            'message': 'Login successful',
            'data': {
                'user': profile_serializer.data,
                'token': token
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Login error: {str(e)}", exc_info=True)
        return Response({
            'success': False,
            'message': 'Login failed due to server error',
            'errors': {'detail': 'Internal server error occurred. Please try again later.'}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_profile(request):
    """
    Profile retrieval endpoint
    
    GET /api/auth/me
    
    Requirements: 3.2, 8.4
    """
    try:
        # Get current authenticated user (set by JWT authentication middleware)
        user = request.user
        
        # Serialize user profile data
        profile_serializer = UserProfileSerializer(user)
        
        return Response({
            'success': True,
            'message': 'Profile retrieved successfully',
            'data': {
                'user': profile_serializer.data
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Profile retrieval error: {str(e)}", exc_info=True)
        return Response({
            'success': False,
            'message': 'Failed to retrieve profile',
            'errors': {'detail': 'Internal server error occurred. Please try again later.'}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Profile update endpoint
    
    GET /api/auth/profile - Returns API documentation
    PUT /api/auth/profile - Updates user profile
    
    Requirements: 3.1, 3.3, 3.4, 3.5, 8.4
    """
    
    # Handle GET request - return API documentation
    if request.method == 'GET':
        return Response({
            'success': True,
            'message': 'Profile Update API',
            'data': {
                'endpoint': '/api/auth/profile/',
                'method': 'PUT',
                'description': 'Update user profile information',
                'authentication': 'Required - Include Authorization: Bearer <token> header',
                'optional_fields': {
                    'name': 'Full name',
                    'gender': 'Male or Female',
                    'age_group': 'Adult, Mid-Age Adult, or Older Adult',
                    'height': 'Height in centimeters (positive number)',
                    'weight': 'Weight in kilograms (positive number)',
                    'fitness_level': 'Beginner, Intermediate, or Advance'
                },
                'example_request': {
                    'name': 'John Doe',
                    'gender': 'Male',
                    'age_group': 'Adult',
                    'height': 175.0,
                    'weight': 70.0,
                    'fitness_level': 'Intermediate'
                },
                'example_response': {
                    'success': True,
                    'message': 'Profile updated successfully',
                    'data': {
                        'user': {
                            'id': 'uuid-string',
                            'email': 'user@example.com',
                            'name': 'John Doe',
                            'gender': 'Male',
                            'age_group': 'Adult',
                            'height': 175.0,
                            'weight': 70.0,
                            'fitness_level': 'Intermediate'
                        }
                    }
                }
            }
        }, status=status.HTTP_200_OK)
    
    # Handle PUT request - actual profile update
    try:
        # Get current authenticated user
        user = request.user
        
        # Validate profile update data using ProfileUpdateSerializer
        serializer = ProfileUpdateSerializer(user, data=request.data, partial=True)
        
        if not serializer.is_valid():
            return handle_validation_error(
                errors=serializer.errors,
                message='Profile validation failed'
            )
        
        # Update user record with new profile information
        with transaction.atomic():
            updated_user = serializer.save()
            
            # Return updated profile data
            profile_serializer = UserProfileSerializer(updated_user)
            
            return Response({
                'success': True,
                'message': 'Profile updated successfully',
                'data': {
                    'user': profile_serializer.data
                }
            }, status=status.HTTP_200_OK)
            
    except Exception as e:
        logger.error(f"Profile update error: {str(e)}", exc_info=True)
        return Response({
            'success': False,
            'message': 'Failed to update profile',
            'errors': {'detail': 'Internal server error occurred. Please try again later.'}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
