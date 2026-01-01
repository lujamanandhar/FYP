"""
JWT Token utilities for user authentication
"""
import jwt
from django.conf import settings
from datetime import datetime, timedelta, timezone


def generate_jwt_token(user):
    """
    Generate a JWT token for the given user
    
    Args:
        user: User instance
        
    Returns:
        str: JWT token string
    """
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': datetime.now(timezone.utc) + timedelta(seconds=settings.JWT_EXPIRATION_DELTA),
        'iat': datetime.now(timezone.utc)
    }
    
    token = jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM
    )
    
    return token


def validate_jwt_token(token):
    """
    Validate and decode a JWT token
    
    Args:
        token (str): JWT token string
        
    Returns:
        dict: Decoded token payload
        
    Raises:
        jwt.InvalidTokenError: If token is invalid or expired
    """
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise jwt.InvalidTokenError('Token has expired')
    except jwt.InvalidTokenError as e:
        raise jwt.InvalidTokenError(f'Invalid token: {str(e)}')