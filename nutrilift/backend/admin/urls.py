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
    path('challenges/create/', views.AdminChallengeCreateView.as_view(), name='challenge-create'),
    path('challenges/<uuid:challenge_id>/', views.AdminChallengeUpdateView.as_view(), name='challenge-update'),
    path('challenges/<uuid:challenge_id>/leaderboard/', views.AdminChallengeLeaderboardView.as_view(), name='challenge-leaderboard'),
    path('challenges/<uuid:challenge_id>/award-prize/', views.AdminAwardPrizeView.as_view(), name='challenge-award-prize'),
    path('challenges/<uuid:challenge_id>/participants/<uuid:participant_id>/', views.AdminDisqualifyParticipantView.as_view(), name='challenge-disqualify'),
    
    # Support Ticket Management
    path('support-tickets/', views.AdminSupportTicketListView.as_view(), name='support-tickets'),
    path('support-tickets/<uuid:ticket_id>/', views.AdminSupportTicketUpdateView.as_view(), name='support-ticket-update'),
    
    # FAQ Management
    path('faqs/', views.FAQListView.as_view(), name='faqs'),
    path('faqs/<uuid:faq_id>/', views.FAQDetailView.as_view(), name='faq-detail'),

    # Reported Posts Management
    path('reported-posts/', views.AdminReportedPostsView.as_view(), name='reported-posts'),
    path('reported-posts/<uuid:post_id>/remove/', views.AdminRemovePostView.as_view(), name='remove-post'),
    path('reported-posts/<uuid:post_id>/dismiss/', views.AdminDismissReportsView.as_view(), name='dismiss-reports'),
]
