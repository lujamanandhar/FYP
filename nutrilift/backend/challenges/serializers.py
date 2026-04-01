from rest_framework import serializers
from .models import (
    Challenge, ChallengeParticipant, Badge, UserBadge, Streak,
    Post, Comment, Like, Report, Follow, ChallengeDailyLog,
)


class ChallengeSerializer(serializers.ModelSerializer):
    participant_progress = serializers.SerializerMethodField()
    created_by_username = serializers.SerializerMethodField()
    created_by_id = serializers.SerializerMethodField()
    is_joined = serializers.SerializerMethodField()
    has_paid = serializers.SerializerMethodField()

    class Meta:
        model = Challenge
        fields = [
            'id', 'name', 'description', 'challenge_type',
            'goal_value', 'unit', 'start_date', 'end_date',
            'is_official', 'created_by_username', 'created_by_id',
            'participant_progress', 'is_joined', 'default_tasks',
            'is_paid', 'price', 'currency', 'prize_description', 'has_paid',
        ]

    def get_has_paid(self, obj):
        request = self.context.get('request')
        if not obj.is_paid or request is None or not request.user.is_authenticated:
            return True  # free challenge, no payment needed
        from .models import EsewaPayment
        return EsewaPayment.objects.filter(
            user=request.user, challenge=obj, status='COMPLETED'
        ).exists()

    def get_participant_progress(self, obj):
        request = self.context.get('request')
        if request is None or not request.user.is_authenticated:
            return 0
        try:
            participant = ChallengeParticipant.objects.get(
                challenge=obj, user=request.user
            )
            return participant.progress
        except ChallengeParticipant.DoesNotExist:
            return 0

    def get_is_joined(self, obj):
        request = self.context.get('request')
        if request is None or not request.user.is_authenticated:
            return False
        return ChallengeParticipant.objects.filter(
            challenge=obj, user=request.user
        ).exists()

    def get_created_by_username(self, obj):
        if obj.is_official or obj.created_by is None:
            return 'NutriLift'
        user = obj.created_by
        return getattr(user, 'name', None) or user.email

    def get_created_by_id(self, obj):
        if obj.created_by is None:
            return None
        return str(obj.created_by.pk)


class ChallengeParticipantSerializer(serializers.ModelSerializer):
    """Serializer for ChallengeParticipant (join/leave responses)."""

    class Meta:
        model = ChallengeParticipant
        fields = [
            'id', 'challenge', 'user', 'progress',
            'completed', 'joined_at', 'completed_at', 'rank',
        ]
        read_only_fields = ['id', 'joined_at']


class LeaderboardSerializer(serializers.ModelSerializer):
    """
    Serializer for leaderboard entries — top participants per challenge.
    Requirements: 3.4
    """
    user_id = serializers.SerializerMethodField()
    username = serializers.SerializerMethodField()
    avatar_url = serializers.SerializerMethodField()
    current_streak = serializers.SerializerMethodField()

    class Meta:
        model = ChallengeParticipant
        fields = ['rank', 'user_id', 'username', 'avatar_url', 'progress', 'current_streak']

    def get_user_id(self, obj):
        return str(obj.user_id)

    def get_username(self, obj):
        # User model uses email as USERNAME_FIELD; fall back to name or email
        user = obj.user
        return getattr(user, 'name', None) or user.email

    def get_avatar_url(self, obj):
        # No avatar field on the User model; return None
        return getattr(obj.user, 'avatar_url', None)

    def get_current_streak(self, obj):
        try:
            streak = Streak.objects.get(user=obj.user)
            return streak.current_streak
        except Streak.DoesNotExist:
            return 0


class BadgeSerializer(serializers.ModelSerializer):
    """Serializer for Badge details (used inside UserBadgeSerializer)."""

    class Meta:
        model = Badge
        fields = ['id', 'name', 'description', 'icon_url', 'points_reward']


class UserBadgeSerializer(serializers.ModelSerializer):
    """
    Serializer for UserBadge — earned badges for a user.
    Requirements: 4.1
    """
    badge_id = serializers.UUIDField(source='badge.id', read_only=True)
    name = serializers.CharField(source='badge.name', read_only=True)
    description = serializers.CharField(source='badge.description', read_only=True)
    icon_url = serializers.CharField(source='badge.icon_url', read_only=True)
    points_reward = serializers.IntegerField(source='badge.points_reward', read_only=True)

    class Meta:
        model = UserBadge
        fields = ['badge_id', 'name', 'description', 'icon_url', 'points_reward', 'earned_at']


class StreakSerializer(serializers.ModelSerializer):
    """
    Serializer for Streak record.
    Requirements: 4.2
    """

    class Meta:
        model = Streak
        fields = ['current_streak', 'longest_streak', 'last_active_date']


class PostSerializer(serializers.ModelSerializer):
    """
    Serializer for Post with computed is_liked_by_me for the requesting user.
    Requirements: 6.1
    """
    user_id = serializers.SerializerMethodField()
    username = serializers.SerializerMethodField()
    avatar_url = serializers.SerializerMethodField()
    is_liked_by_me = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'user_id', 'username', 'avatar_url',
            'content', 'image_urls', 'like_count', 'comment_count',
            'created_at', 'is_liked_by_me',
        ]
        read_only_fields = ['id', 'like_count', 'comment_count', 'created_at']

    def get_user_id(self, obj):
        return str(obj.user_id)

    def get_username(self, obj):
        user = obj.user
        return getattr(user, 'name', None) or user.email

    def get_avatar_url(self, obj):
        return getattr(obj.user, 'avatar_url', None)

    def get_is_liked_by_me(self, obj):
        request = self.context.get('request')
        if request is None or not request.user.is_authenticated:
            return False
        return Like.objects.filter(post=obj, user=request.user).exists()


class CommentSerializer(serializers.ModelSerializer):
    """
    Serializer for Comment.
    Requirements: 6.6, 6.7
    """
    user_id = serializers.SerializerMethodField()
    username = serializers.SerializerMethodField()
    avatar_url = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = ['id', 'user_id', 'username', 'avatar_url', 'content', 'created_at']
        read_only_fields = ['id', 'created_at']

    def get_user_id(self, obj):
        return str(obj.user_id)

    def get_username(self, obj):
        user = obj.user
        return getattr(user, 'name', None) or user.email

    def get_avatar_url(self, obj):
        return getattr(obj.user, 'avatar_url', None)


class UserProfileSerializer(serializers.Serializer):
    """
    Serializer for user profile social stats.
    Requirements: 7.1
    """
    id = serializers.UUIDField()
    username = serializers.CharField()
    avatar_url = serializers.CharField(allow_null=True)
    follower_count = serializers.IntegerField()
    following_count = serializers.IntegerField()
    post_count = serializers.IntegerField()
    is_following_me = serializers.BooleanField()


class ChallengeDailyLogSerializer(serializers.ModelSerializer):
    """
    Serializer for ChallengeDailyLog.
    task_items: [{"label": str, "completed": bool}]
    media_urls: [{"url": str, "is_video": bool}]
    Requirements: 19.1–19.5
    """

    class Meta:
        model = ChallengeDailyLog
        fields = [
            'id', 'day_number', 'task_items', 'media_urls',
            'is_complete', 'completed_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class DailyLogCompleteResponseSerializer(serializers.Serializer):
    """
    Response serializer for the complete-day endpoint.
    Includes the log and an optional shared_post.
    Requirements: 20.3
    """
    log = ChallengeDailyLogSerializer()
    shared_post = PostSerializer(allow_null=True, required=False)
