"""
Test URL configuration for authentication views property tests
"""
from django.urls import path, include

urlpatterns = [
    path('api/auth/', include('authentications.urls')),
]