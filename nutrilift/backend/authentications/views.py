from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from django.contrib.auth.hashers import check_password
from django.db import transaction
from .models import User
from .serializers import UserRegistrationSerializer, UserProfileSerializer, ProfileUpdateSerializer
from .jwt_utils import generate_jwt_token
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
            return Response({
                'success': False,
                'message': 'Validation failed',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
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
            
    except Exception as e:
        logger.error(f"Registration error: {str(e)}")
        return Response({
            'success': False,
            'message': 'Registration failed due to server error',
            'errors': {'detail': 'Internal server error'}
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
            return Response({
                'success': False,
                'message': 'Email and password are required',
                'errors': {
                    'email': ['This field is required.'] if not email else [],
                    'password': ['This field is required.'] if not password else []
                }
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Normalize email to lowercase for consistency
        email = email.lower().strip()
        
        # Validate email format (basic validation)
        if '@' not in email or '.' not in email.split('@')[-1]:
            return Response({
                'success': False,
                'message': 'Invalid email format',
                'errors': {'email': ['Enter a valid email address.']}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Find user by email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Return generic error to prevent email enumeration
            return Response({
                'success': False,
                'message': 'Invalid credentials',
                'errors': {'detail': 'Invalid email or password'}
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Check if user account is active
        if not user.is_active:
            return Response({
                'success': False,
                'message': 'Account is disabled',
                'errors': {'detail': 'User account is disabled'}
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Verify password securely using Django's check_password
        if not check_password(password, user.password):
            return Response({
                'success': False,
                'message': 'Invalid credentials',
                'errors': {'detail': 'Invalid email or password'}
            }, status=status.HTTP_401_UNAUTHORIZED)
        
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
        logger.error(f"Login error: {str(e)}")
        return Response({
            'success': False,
            'message': 'Login failed due to server error',
            'errors': {'detail': 'Internal server error'}
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
        logger.error(f"Profile retrieval error: {str(e)}")
        return Response({
            'success': False,
            'message': 'Failed to retrieve profile',
            'errors': {'detail': 'Internal server error'}
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
            return Response({
                'success': False,
                'message': 'Validation failed',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
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
        logger.error(f"Profile update error: {str(e)}")
        return Response({
            'success': False,
            'message': 'Failed to update profile',
            'errors': {'detail': 'Internal server error'}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
