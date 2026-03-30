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
    actions = ['make_official', 'make_unofficial', 'activate_challenges', 'deactivate_challenges']
    
    @admin.action(description='Mark selected challenges as official')
    def make_official(self, request, queryset):
        updated = queryset.update(is_official=True)
        self.message_user(request, f'{updated} challenge(s) marked as official.')
    
    @admin.action(description='Mark selected challenges as unofficial')
    def make_unofficial(self, request, queryset):
        updated = queryset.update(is_official=False)
        self.message_user(request, f'{updated} challenge(s) marked as unofficial.')
    
    @admin.action(description='Activate selected challenges')
    def activate_challenges(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} challenge(s) activated.')
    
    @admin.action(description='Deactivate selected challenges')
    def deactivate_challenges(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} challenge(s) deactivated.')


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
    list_editable = ['is_removed']
    search_fields = ['user__email', 'content']
    ordering = ['-created_at']
    actions = ['remove_posts', 'restore_posts']

    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'
    
    @admin.action(description='Remove selected posts')
    def remove_posts(self, request, queryset):
        updated = queryset.update(is_removed=True)
        self.message_user(request, f'{updated} post(s) removed.')
    
    @admin.action(description='Restore selected posts')
    def restore_posts(self, request, queryset):
        updated = queryset.update(is_removed=False, is_reported=False)
        self.message_user(request, f'{updated} post(s) restored.')


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
    list_editable = ['status']
    search_fields = ['reported_by__email', 'reason']
    ordering = ['-created_at']
    actions = ['mark_reviewed', 'mark_dismissed']
    
    @admin.action(description='Mark selected reports as reviewed')
    def mark_reviewed(self, request, queryset):
        from django.utils import timezone
        updated = queryset.update(status='reviewed', reviewed_at=timezone.now())
        self.message_user(request, f'{updated} report(s) marked as reviewed.')
    
    @admin.action(description='Mark selected reports as dismissed')
    def mark_dismissed(self, request, queryset):
        from django.utils import timezone
        updated = queryset.update(status='dismissed', reviewed_at=timezone.now())
        self.message_user(request, f'{updated} report(s) dismissed.')


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



# Import reward models
from .reward_models import UserPoints, PointTransaction, Achievement, UserAchievement


@admin.register(UserPoints)
class UserPointsAdmin(admin.ModelAdmin):
    list_display = ['user', 'total_points', 'lifetime_points', 'points_spent', 'level', 'updated_at']
    search_fields = ['user__email']
    ordering = ['-total_points']
    readonly_fields = ['updated_at']


@admin.register(PointTransaction)
class PointTransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'transaction_type', 'source', 'points', 'description', 'created_at']
    list_filter = ['transaction_type', 'source', 'created_at']
    search_fields = ['user__email', 'description']
    ordering = ['-created_at']
    readonly_fields = ['created_at']


@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'points_reward', 'is_active', 'created_at']
    list_filter = ['category', 'is_active']
    list_editable = ['is_active']
    search_fields = ['name', 'description']
    ordering = ['category', 'name']
    actions = ['activate_achievements', 'deactivate_achievements']
    
    @admin.action(description='Activate selected achievements')
    def activate_achievements(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} achievement(s) activated.')
    
    @admin.action(description='Deactivate selected achievements')
    def deactivate_achievements(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} achievement(s) deactivated.')


@admin.register(UserAchievement)
class UserAchievementAdmin(admin.ModelAdmin):
    list_display = ['user', 'achievement', 'progress', 'is_completed', 'unlocked_at']
    list_filter = ['is_completed', 'unlocked_at']
    search_fields = ['user__email', 'achievement__name']
    ordering = ['-unlocked_at']
    readonly_fields = ['unlocked_at']



# Import payment models
from .payment_models import PaymentPlan, ChallengePayment, Subscription


@admin.register(PaymentPlan)
class PaymentPlanAdmin(admin.ModelAdmin):
    list_display = ['name', 'plan_type', 'price', 'currency', 'is_active', 'created_at']
    list_filter = ['plan_type', 'is_active']
    list_editable = ['is_active']
    search_fields = ['name']
    ordering = ['price']


@admin.register(ChallengePayment)
class ChallengePaymentAdmin(admin.ModelAdmin):
    list_display = ['user', 'challenge', 'amount', 'currency', 'status', 'paid_at', 'created_at']
    list_filter = ['status', 'currency', 'created_at']
    search_fields = ['user__email', 'challenge__name', 'stripe_payment_intent_id']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ['user', 'plan', 'status', 'current_period_start', 'current_period_end', 'cancel_at_period_end']
    list_filter = ['status', 'cancel_at_period_end']
    search_fields = ['user__email', 'stripe_subscription_id', 'stripe_customer_id']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']
