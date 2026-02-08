"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/

API Structure:
- /api/auth/ - Authentication endpoints
- /api/workouts/ - Workout tracking endpoints
- /admin/ - Django admin interface

Requirements: 7.1, 7.2, 7.3, 7.4
"""
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    # Django admin interface
    path('admin/', admin.site.urls),
    
    # API v1 authentication endpoints
    # All authentication endpoints are prefixed with /api/auth/
    path('api/auth/', include('authentications.urls', namespace='auth')),
    
    # API v1 workout endpoints
    # All workout endpoints are prefixed with /api/workouts/
    path('api/workouts/', include('workouts.urls', namespace='workouts')),
]
