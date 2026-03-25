from django.contrib import admin
from .models import (
    Challenge, ChallengeParticipant, Badge, UserBadge, Streak,
    Post, Comment, Like, Report, Follow, ChallengeDailyLog,
)


@admin.register(Challenge)
class ChallengeAdmin(admin.ModelAdmin):
    list_display = ['name', 'challenge_type', 'goal_value', 'unit', 'start_date', 'end_date', 'is_official', 'is_active', 'created_by']
    list_filter = ['challenge_type', 'is_active', 'is_official', 'unit']
    list_editable = ['is_official', 'is_active']
    search_fields = ['name', 'description', 'created_by__email']
    ordering = ['-created_at']


@admin.register(ChallengeParticipant)
class ChallengeParticipantAdmin(admin.ModelAdmin):
    list_display = ['user', 'challenge', 'progress', 'completed', 'joined_at', 'rank']
    list_filter = ['completed', 'joined_at']
    search_fields = ['user__email', 'challenge__name']
    ordering = ['-joined_at']


@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ['name', 'points_reward', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['name', 'description']
    ordering = ['-created_at']


@admin.register(UserBadge)
class UserBadgeAdmin(admin.ModelAdmin):
    list_display = ['user', 'badge', 'earned_at']
    list_filter = ['earned_at']
    search_fields = ['user__email', 'badge__name']
    ordering = ['-earned_at']


@admin.register(Streak)
class StreakAdmin(admin.ModelAdmin):
    list_display = ['user', 'current_streak', 'longest_streak', 'last_active_date', 'updated_at']
    search_fields = ['user__email']
    ordering = ['-current_streak']


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['user', 'content_preview', 'like_count', 'comment_count', 'is_reported', 'is_removed', 'created_at']
    list_filter = ['is_reported', 'is_removed', 'created_at']
    search_fields = ['user__email', 'content']
    ordering = ['-created_at']

    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ['user', 'post', 'content', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__email', 'content']
    ordering = ['-created_at']


@admin.register(Like)
class LikeAdmin(admin.ModelAdmin):
    list_display = ['user', 'post', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__email']
    ordering = ['-created_at']


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ['reported_by', 'post', 'status', 'created_at', 'reviewed_at']
    list_filter = ['status', 'created_at']
    search_fields = ['reported_by__email', 'reason']
    ordering = ['-created_at']


@admin.register(Follow)
class FollowAdmin(admin.ModelAdmin):
    list_display = ['follower', 'following', 'created_at']
    list_filter = ['created_at']
    search_fields = ['follower__email', 'following__email']
    ordering = ['-created_at']


@admin.register(ChallengeDailyLog)
class ChallengeDailyLogAdmin(admin.ModelAdmin):
    list_display = ['participant', 'day_number', 'is_complete', 'completed_at', 'created_at']
    list_filter = ['is_complete', 'created_at']
    search_fields = ['participant__user__email', 'participant__challenge__name']
    ordering = ['-created_at']
