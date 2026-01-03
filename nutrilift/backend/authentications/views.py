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


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """
    User registration endpoint
    
    POST /api/auth/register
    
    Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6
    """
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


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """
    User login endpoint
    
    POST /api/auth/login
    
    Requirements: 2.1, 2.2, 2.3, 2.4
    """
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


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Profile update endpoint
    
    PUT /api/auth/profile
    
    Requirements: 3.1, 3.3, 3.4, 3.5, 8.4
    """
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
