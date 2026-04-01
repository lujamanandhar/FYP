"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/

API Structure:
- /api/auth/ - Authentication endpoints
- /api/workouts/ - Workout tracking endpoints
- /api/nutrition/ - Nutrition tracking endpoints
- /admin/ - Django admin interface

Requirements: 7.1, 7.2, 7.3, 7.4, 16.1
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from admin import views as admin_views

urlpatterns = [
    # Django admin interface
    path('admin/', admin.site.urls),
    
    # API v1 authentication endpoints
    # All authentication endpoints are prefixed with /api/auth/
    path('api/auth/', include('authentications.urls', namespace='auth')),
    
    # API v1 workout endpoints
    # All workout endpoints are prefixed with /api/workouts/
    path('api/workouts/', include('workouts.urls', namespace='workouts')),
    
    # API v1 nutrition endpoints
    # All nutrition endpoints are prefixed with /api/nutrition/
    path('api/nutrition/', include('nutrition.urls', namespace='nutrition')),

    # Challenge & Community endpoints
    path('api/challenges/', include('challenges.urls')),
    path('api/community/', include('challenges.urls')),
    
    # Admin API endpoints
    path('api/admin/', include('admin.urls', namespace='admin_api')),
    
    # Gym comparison endpoints
    path('api/gyms/', include('gyms.urls', namespace='gyms')),

    # Notification endpoints
    path('api/notifications/', include('notifications.urls')),
    
    # Public FAQ endpoint (uses same view but without admin permission)
    path('api/faqs/', admin_views.FAQListView.as_view(), name='public-faqs'),
    
    # Media upload endpoint
    path('api/', include('challenges.upload_urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
