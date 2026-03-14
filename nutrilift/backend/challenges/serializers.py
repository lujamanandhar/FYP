from rest_framework import serializers
from .models import (
    Challenge, ChallengeParticipant, Badge, UserBadge, Streak,
    Post, Comment, Like, Report, Follow,
)


class ChallengeSerializer(serializers.ModelSerializer):
    """
    Serializer for Challenge with computed participant_progress for the requesting user.
    Returns 0 if the user has not joined the challenge.
    Requirements: 3.1
    """
    participant_progress = serializers.SerializerMethodField()

    class Meta:
        model = Challenge
        fields = [
            'id', 'name', 'description', 'challenge_type',
            'goal_value', 'unit', 'start_date', 'end_date',
            'participant_progress',
        ]

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

    class Meta:
        model = ChallengeParticipant
        fields = ['rank', 'user_id', 'username', 'avatar_url', 'progress']

    def get_user_id(self, obj):
        return str(obj.user_id)

    def get_username(self, obj):
        # User model uses email as USERNAME_FIELD; fall back to name or email
        user = obj.user
        return getattr(user, 'name', None) or user.email

    def get_avatar_url(self, obj):
        # No avatar field on the User model; return None
        return getattr(obj.user, 'avatar_url', None)


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
