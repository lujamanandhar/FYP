from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.hashers import make_password
from django.core.exceptions import ValidationError
from .models import User
import re


class UserRegistrationSerializer(serializers.ModelSerializer):
    """
    Serializer for user registration with email, password, and name fields.
    Includes password validation and hashing.
    """
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={'input_type': 'password'},
        help_text="Password must be at least 8 characters long"
    )
    
    class Meta:
        model = User
        fields = ['email', 'password', 'name']
        extra_kwargs = {
            'email': {
                'required': True,
                'help_text': 'Valid email address'
            },
            'name': {
                'required': False,
                'help_text': 'User\'s full name'
            }
        }
    
    def validate_email(self, value):
        """
        Validate email format and uniqueness.
        Requirements: 1.2 - email format validation
        """
        if not value:
            raise serializers.ValidationError("Email is required.")
        
        # Basic email format validation (Django's EmailField handles most of this)
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, value):
            raise serializers.ValidationError("Enter a valid email address.")
        
        # Check for uniqueness
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        
        return value.lower()  # Normalize email to lowercase
    
    def validate_password(self, value):
        """
        Validate password length and complexity.
        Requirements: 1.3 - password length validation
        """
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long.")
        
        # Additional password complexity validation
        if not re.search(r'[A-Za-z]', value):
            raise serializers.ValidationError("Password must contain at least one letter.")
        
        if not re.search(r'\d', value):
            raise serializers.ValidationError("Password must contain at least one number.")
        
        # Use Django's built-in password validators
        try:
            validate_password(value)
        except ValidationError as e:
            raise serializers.ValidationError(e.messages)
        
        return value
    
    def create(self, validated_data):
        """
        Create user with hashed password.
        Requirements: 1.6 - password hashing
        """
        # Hash the password before saving
        validated_data['password'] = make_password(validated_data['password'])
        
        # Create the user
        user = User.objects.create(**validated_data)
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    """
    Read-only serializer for user profile data.
    Used for returning user information in API responses.
    """
    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'gender', 'age_group', 
            'height', 'weight', 'fitness_level', 'created_at'
        ]
        read_only_fields = ['id', 'email', 'created_at']


class ProfileUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating user profile fields.
    Includes validation for numeric and enum fields.
    """
    class Meta:
        model = User
        fields = ['gender', 'age_group', 'height', 'weight', 'fitness_level', 'name']
        extra_kwargs = {
            'gender': {'required': False},
            'age_group': {'required': False},
            'height': {'required': False},
            'weight': {'required': False},
            'fitness_level': {'required': False},
            'name': {'required': False}
        }
    
    def validate_height(self, value):
        """
        Validate height is a positive number.
        Requirements: 3.4 - height validation
        """
        if value is not None and value <= 0:
            raise serializers.ValidationError("Height must be a positive number.")
        if value is not None and value > 300:  # Reasonable upper limit
            raise serializers.ValidationError("Height must be less than 300 cm.")
        return value
    
    def validate_weight(self, value):
        """
        Validate weight is a positive number.
        Requirements: 3.4 - weight validation
        """
        if value is not None and value <= 0:
            raise serializers.ValidationError("Weight must be a positive number.")
        if value is not None and value > 1000:  # Reasonable upper limit
            raise serializers.ValidationError("Weight must be less than 1000 kg.")
        return value
    
    def validate_gender(self, value):
        """
        Validate gender is from allowed values.
        Requirements: 3.5 - enum field validation
        """
        if value and value not in ['Male', 'Female']:
            raise serializers.ValidationError("Gender must be either 'Male' or 'Female'.")
        return value
    
    def validate_fitness_level(self, value):
        """
        Validate fitness_level is from allowed values.
        Requirements: 3.5 - enum field validation
        """
        allowed_levels = ['Beginner', 'Intermediate', 'Advance']
        if value and value not in allowed_levels:
            raise serializers.ValidationError(
                f"Fitness level must be one of: {', '.join(allowed_levels)}"
            )
        return value
    
    def validate_age_group(self, value):
        """
        Validate age_group is from allowed values.
        Requirements: 3.5 - enum field validation
        """
        allowed_groups = ['Adult', 'Mid-Age Adult', 'Older Adult']
        if value and value not in allowed_groups:
            raise serializers.ValidationError(
                f"Age group must be one of: {', '.join(allowed_groups)}"
            )
        return value