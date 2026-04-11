"""
URL configuration for authentication endpoints

API versioning structure: /api/auth/
Requirements: 7.1, 7.2, 7.3, 7.4
"""
from django.urls import path
from . import views
from . import admin_views

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

    # Support ticket submission
    # POST /api/auth/support/
    path('support/', views.submit_support_ticket, name='auth-support'),

    # Password reset
    path('password-reset/', views.password_reset_request, name='auth-password-reset'),
    path('password-reset/confirm/', views.password_reset_confirm, name='auth-password-reset-confirm'),

    # Token refresh — exchange refresh token for new access token
    path('token/refresh/', views.token_refresh, name='auth-token-refresh'),

    # Admin endpoints
    path('admin/dashboard/', admin_views.AdminDashboardView.as_view(), name='admin-dashboard'),
    path('admin/users/', admin_views.AdminUserListView.as_view(), name='admin-users'),
    path('admin/users/<uuid:user_id>/', admin_views.AdminUserDetailView.as_view(), name='admin-user-detail'),
    path('admin/challenges/', admin_views.AdminChallengeListView.as_view(), name='admin-challenges'),
    path('admin/challenges/<uuid:challenge_id>/', admin_views.AdminChallengeUpdateView.as_view(), name='admin-challenge-update'),
    path('admin/support-tickets/', admin_views.AdminSupportTicketListView.as_view(), name='admin-support-tickets'),
    path('admin/support-tickets/<uuid:ticket_id>/', admin_views.AdminSupportTicketUpdateView.as_view(), name='admin-support-ticket-update'),
]