from django.urls import path
from . import views

app_name = 'admin'

urlpatterns = [
    # Dashboard
    path('dashboard/', views.AdminDashboardView.as_view(), name='dashboard'),
    
    # User Management
    path('users/', views.AdminUserListView.as_view(), name='users'),
    path('users/<uuid:user_id>/', views.AdminUserDetailView.as_view(), name='user-detail'),
    
    # Challenge Management
    path('challenges/', views.AdminChallengeListView.as_view(), name='challenges'),
    path('challenges/<uuid:challenge_id>/', views.AdminChallengeUpdateView.as_view(), name='challenge-update'),
    
    # Support Ticket Management
    path('support-tickets/', views.AdminSupportTicketListView.as_view(), name='support-tickets'),
    path('support-tickets/<uuid:ticket_id>/', views.AdminSupportTicketUpdateView.as_view(), name='support-ticket-update'),
    
    # FAQ Management
    path('faqs/', views.FAQListView.as_view(), name='faqs'),
    path('faqs/<uuid:faq_id>/', views.FAQDetailView.as_view(), name='faq-detail'),
]
