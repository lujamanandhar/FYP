"""
URL configuration for authentication endpoints

API versioning structure: /api/auth/
Requirements: 7.1, 7.2, 7.3, 7.4
"""
from django.urls import path
from . import views

# URL namespace for authentication endpoints
app_name = 'authentications'

urlpatterns = [
    # User registration endpoint
    # POST /api/auth/register/
    path('register/', views.register, name='auth-register'),
    
    # User login endpoint  
    # POST /api/auth/login/
    path('login/', views.login, name='auth-login'),
    
    # Profile retrieval endpoint (requires authentication)
    # GET /api/auth/me/
    path('me/', views.get_profile, name='auth-profile-get'),
    
    # Profile update endpoint (requires authentication)
    # PUT /api/auth/profile/
    path('profile/', views.update_profile, name='auth-profile-update'),
]