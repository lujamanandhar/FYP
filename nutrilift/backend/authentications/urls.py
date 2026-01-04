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
    # API Root endpoint
    # GET /api/auth/
    path('', views.api_root, name='auth-root'),
    
    # User registration endpoint
    # GET /api/auth/register/ - API documentation
    # POST /api/auth/register/ - Register user
    path('register/', views.register, name='auth-register'),
    
    # User login endpoint  
    # GET /api/auth/login/ - API documentation
    # POST /api/auth/login/ - Login user
    path('login/', views.login, name='auth-login'),
    
    # Profile retrieval endpoint (requires authentication)
    # GET /api/auth/me/
    path('me/', views.get_profile, name='auth-profile-get'),
    
    # Profile update endpoint (requires authentication)
    # GET /api/auth/profile/ - API documentation
    # PUT /api/auth/profile/ - Update profile
    path('profile/', views.update_profile, name='auth-profile-update'),
]