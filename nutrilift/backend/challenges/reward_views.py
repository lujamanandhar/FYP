"""
API views for reward system.
Phase 3 - Advanced Features
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .reward_models import UserPoints, PointTransaction, Achievement, UserAchievement
from rest_framework import serializers


class UserPointsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserPoints
        fields = ['total_points', 'lifetime_points', 'points_spent', 'level', 'updated_at']


class PointTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PointTransaction
        fields = ['id', 'transaction_type', 'source', 'points', 'description', 'created_at']


class AchievementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Achievement
        fields = ['id', 'name', 'description', 'category', 'icon_url', 'points_reward', 'is_active']


class UserAchievementSerializer(serializers.ModelSerializer):
    achievement = AchievementSerializer(read_only=True)
    
    class Meta:
        model = UserAchievement
        fields = ['id', 'achievement', 'unlocked_at', 'progress', 'is_completed']


class UserPointsView(APIView):
    """
    GET /api/rewards/points/
    Returns current user's points and level
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            user_points = UserPoints.objects.get(user=request.user)
            serializer = UserPointsSerializer(user_points)
            return Response(serializer.data)
        except UserPoints.DoesNotExist:
            return Response({
                'total_points': 0,
                'lifetime_points': 0,
                'points_spent': 0,
                'level': 1,
            })


class PointTransactionHistoryView(APIView):
    """
    GET /api/rewards/transactions/
    Returns user's point transaction history
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        transactions = PointTransaction.objects.filter(
            user=request.user
        ).order_by('-created_at')[:50]
        
        serializer = PointTransactionSerializer(transactions, many=True)
        return Response(serializer.data)


class AchievementListView(APIView):
    """
    GET /api/rewards/achievements/
    Returns all active achievements
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        achievements = Achievement.objects.filter(is_active=True)
        serializer = AchievementSerializer(achievements, many=True)
        return Response(serializer.data)


class UserAchievementsView(APIView):
    """
    GET /api/rewards/my-achievements/
    Returns user's unlocked achievements
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user_achievements = UserAchievement.objects.filter(
            user=request.user
        ).select_related('achievement').order_by('-unlocked_at')
        
        serializer = UserAchievementSerializer(user_achievements, many=True)
        return Response(serializer.data)


class LeaderboardPointsView(APIView):
    """
    GET /api/rewards/leaderboard/
    Returns top 100 users by points
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        top_users = UserPoints.objects.select_related('user').order_by('-total_points')[:100]
        
        data = []
        for rank, user_points in enumerate(top_users, start=1):
            data.append({
                'rank': rank,
                'user_id': user_points.user.id,
                'username': getattr(user_points.user, 'name', None) or user_points.user.email,
                'avatar_url': getattr(user_points.user, 'avatar_url', None),
                'total_points': user_points.total_points,
                'level': user_points.level,
            })
        
        return Response(data)
