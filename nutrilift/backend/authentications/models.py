from django.contrib.auth.models import AbstractUser
from django.db import models
import uuid


class User(AbstractUser):
    """
    Custom User model extending Django's AbstractUser with profile fields
    for the NutriLift fitness app.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    name = models.CharField(max_length=100, blank=True)
    
    # Profile fields for fitness app
    gender = models.CharField(
        max_length=10, 
        choices=[('Male', 'Male'), ('Female', 'Female')], 
        blank=True
    )
    age_group = models.CharField(
        max_length=20, 
        choices=[
            ('Adult', 'Adult'),
            ('Mid-Age Adult', 'Mid-Age Adult'),
            ('Older Adult', 'Older Adult')
        ], 
        blank=True
    )
    height = models.FloatField(null=True, blank=True, help_text="Height in cm")
    weight = models.FloatField(null=True, blank=True, help_text="Weight in kg")
    fitness_level = models.CharField(
        max_length=20, 
        choices=[
            ('Beginner', 'Beginner'),
            ('Intermediate', 'Intermediate'),
            ('Advance', 'Advance')
        ], 
        blank=True
    )
    
    # Timestamp fields
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Use email as the username field
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []  # Remove 'username' from required fields
    
    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
    
    def __str__(self):
        return self.email
    
    def get_full_name(self):
        """Return the user's full name or email if name is not set."""
        return self.name if self.name else self.email
    
    def get_short_name(self):
        """Return the user's short name or email if name is not set."""
        return self.name if self.name else self.email
