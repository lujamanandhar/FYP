#!/usr/bin/env python
"""Quick test script to check workout logging"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from workouts.models import Exercise
from authentications.models import User
from workouts.serializers import WorkoutLogSerializer

# Get a user and exercise
user = User.objects.first()
exercise = Exercise.objects.first()

print(f"User: {user.email}")
print(f"Exercise: {exercise.name} (ID: {exercise.id})")

# Test data matching frontend format
workout_data = {
    'workout_name': 'Test Workout',
    'duration_minutes': 60,
    'workout_exercises': [
        {
            'exercise': exercise.id,
            'sets': 3,
            'reps': 10,
            'weight': 100.0,
            'order': 0
        }
    ]
}

print("\nTest data:")
print(workout_data)

# Try to validate
serializer = WorkoutLogSerializer(data=workout_data, context={'request': None})
if serializer.is_valid():
    print("\n✓ Validation passed!")
    print("Validated data:", serializer.validated_data)
else:
    print("\n✗ Validation failed!")
    print("Errors:", serializer.errors)
