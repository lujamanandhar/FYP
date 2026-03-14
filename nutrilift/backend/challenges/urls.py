"""
URL patterns for the challenges app.

These patterns are included twice in backend/backend/urls.py:
  - path('api/challenges/', include('challenges.urls'))
  - path('api/community/', include('challenges.urls'))

So the same views serve both /api/challenges/... and /api/community/... prefixes.
"""
from django.urls import path
from . import views

urlpatterns = [
    # --- Challenge endpoints (api/challenges/...) ---
    path('active/', views.ActiveChallengeListView.as_view(), name='challenge-active'),
    path('<uuid:pk>/join/', views.JoinChallengeView.as_view(), name='challenge-join'),
    path('<uuid:pk>/leave/', views.LeaveChallengeView.as_view(), name='challenge-leave'),
    path('<uuid:pk>/leaderboard/', views.LeaderboardView.as_view(), name='challenge-leaderboard'),
    path('badges/', views.BadgeView.as_view(), name='challenge-badges'),
    path('streak/', views.StreakView.as_view(), name='challenge-streak'),

    # --- Community endpoints (api/community/...) ---
    path('feed/', views.FeedView.as_view(), name='community-feed'),
    path('posts/', views.CreatePostView.as_view(), name='community-post-create'),
    path('posts/<uuid:pk>/', views.DeletePostView.as_view(), name='community-post-delete'),
    path('posts/<uuid:pk>/like/', views.LikePostView.as_view(), name='community-post-like'),
    path('posts/<uuid:pk>/comment/', views.CommentPostView.as_view(), name='community-post-comment'),
    path('posts/<uuid:pk>/comments/', views.ListCommentsView.as_view(), name='community-post-comments'),
    path('posts/<uuid:pk>/report/', views.ReportPostView.as_view(), name='community-post-report'),
    path('users/<uuid:pk>/profile/', views.UserProfileView.as_view(), name='community-user-profile'),
    path('users/<uuid:pk>/follow/', views.FollowView.as_view(), name='community-user-follow'),
    path('users/<uuid:pk>/posts/', views.UserPostsView.as_view(), name='community-user-posts'),
    path('users/<uuid:pk>/followers/', views.UserFollowersView.as_view(), name='community-user-followers'),
]
