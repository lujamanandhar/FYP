"""
Custom throttle classes for workout API endpoints.

Implements rate limiting to prevent API abuse and ensure fair usage.
Requirements: 12.10
"""
from rest_framework.throttling import UserRateThrottle, AnonRateThrottle


class WorkoutUserRateThrottle(UserRateThrottle):
    """
    Rate limiting for authenticated users on workout endpoints.
    
    Allows 100 requests per hour for authenticated users.
    This is sufficient for normal usage while preventing abuse.
    
    Requirements: 12.10
    """
    scope = 'workout_user'


class WorkoutAnonRateThrottle(AnonRateThrottle):
    """
    Rate limiting for anonymous users on workout endpoints.
    
    Allows 20 requests per hour for anonymous users.
    Lower limit for unauthenticated requests to prevent abuse.
    
    Requirements: 12.10
    """
    scope = 'workout_anon'


class ExerciseUserRateThrottle(UserRateThrottle):
    """
    Rate limiting for authenticated users on exercise endpoints.
    
    Allows 200 requests per hour for authenticated users.
    Higher limit for exercise browsing which is read-heavy.
    
    Requirements: 12.10
    """
    scope = 'exercise_user'


class ExerciseAnonRateThrottle(AnonRateThrottle):
    """
    Rate limiting for anonymous users on exercise endpoints.
    
    Allows 50 requests per hour for anonymous users.
    
    Requirements: 12.10
    """
    scope = 'exercise_anon'


class PersonalRecordUserRateThrottle(UserRateThrottle):
    """
    Rate limiting for authenticated users on personal record endpoints.
    
    Allows 100 requests per hour for authenticated users.
    
    Requirements: 12.10
    """
    scope = 'pr_user'
