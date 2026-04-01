"""
URL patterns for the challenges app.

These patterns are included twice in backend/backend/urls.py:
  - path('api/challenges/', include('challenges.urls'))
  - path('api/community/', include('challenges.urls'))

So the same views serve both /api/challenges/... and /api/community/... prefixes.
"""
from django.urls import path
from . import views
from . import reward_views

urlpatterns = [
    # --- Challenge endpoints (api/challenges/...) ---
    path('active/', views.ActiveChallengeListView.as_view(), name='challenge-active'),
    path('create/', views.CreateChallengeView.as_view(), name='challenge-create'),
    path('<uuid:pk>/', views.DeleteChallengeView.as_view(), name='challenge-delete'),
    path('<uuid:pk>/join/', views.JoinChallengeView.as_view(), name='challenge-join'),
    path('<uuid:pk>/leave/', views.LeaveChallengeView.as_view(), name='challenge-leave'),
    path('<uuid:pk>/leaderboard/', views.LeaderboardView.as_view(), name='challenge-leaderboard'),
    path('<uuid:pk>/daily-log/', views.DailyLogView.as_view(), name='challenge-daily-log'),
    path('<uuid:pk>/daily-log/complete/', views.DailyLogCompleteView.as_view(), name='challenge-daily-log-complete'),
    path('<uuid:pk>/daily-logs/', views.DailyLogListView.as_view(), name='challenge-daily-logs'),
    path('badges/', views.BadgeView.as_view(), name='challenge-badges'),
    path('streak/', views.StreakView.as_view(), name='challenge-streak'),
    path('streaks/all/', views.AllStreaksView.as_view(), name='challenge-streaks-all'),

    # Payment endpoints
    path('<uuid:pk>/pay/initiate/', views.EsewaInitiateView.as_view(), name='esewa-initiate'),
    path('<uuid:pk>/pay/verify/', views.EsewaVerifyView.as_view(), name='esewa-verify'),
    path('<uuid:pk>/pay/failure/', views.EsewaFailureView.as_view(), name='esewa-failure'),
    path('<uuid:pk>/pay/success/', views.EsewaPaymentSuccessView.as_view(), name='esewa-success'),

    # Certificate endpoints
    path('completions/', views.ChallengeCompletionListView.as_view(), name='challenge-completions'),

    # --- Reward endpoints (api/rewards/...) ---
    path('rewards/points/', reward_views.UserPointsView.as_view(), name='rewards-points'),
    path('rewards/transactions/', reward_views.PointTransactionHistoryView.as_view(), name='rewards-transactions'),
    path('rewards/achievements/', reward_views.AchievementListView.as_view(), name='rewards-achievements'),
    path('rewards/my-achievements/', reward_views.UserAchievementsView.as_view(), name='rewards-my-achievements'),
    path('rewards/leaderboard/', reward_views.LeaderboardPointsView.as_view(), name='rewards-leaderboard'),

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
    path('users/<uuid:pk>/following/', views.UserFollowingView.as_view(), name='community-user-following'),
    path('users/<uuid:pk>/challenge-stats/', views.UserChallengeStatsView.as_view(), name='community-user-challenge-stats'),
]
