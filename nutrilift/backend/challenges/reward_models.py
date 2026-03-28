"""
Reward system models for points and achievements.
Phase 3 - Advanced Features
"""
from django.db import models
from django.conf import settings


class UserPoints(models.Model):
    """Track user points earned from various activities"""
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='points'
    )
    total_points = models.IntegerField(default=0)
    lifetime_points = models.IntegerField(default=0)
    points_spent = models.IntegerField(default=0)
    level = models.IntegerField(default=1)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_points'
        ordering = ['-total_points']
    
    def __str__(self):
        return f"{self.user.email} - {self.total_points} points (Level {self.level})"


class PointTransaction(models.Model):
    """Individual point earning/spending transactions"""
    TRANSACTION_TYPE_CHOICES = [
        ('EARN', 'Earned'),
        ('SPEND', 'Spent'),
        ('BONUS', 'Bonus'),
        ('REFUND', 'Refund'),
    ]
    
    SOURCE_CHOICES = [
        ('WORKOUT', 'Workout Completed'),
        ('NUTRITION', 'Nutrition Logged'),
        ('CHALLENGE', 'Challenge Completed'),
        ('STREAK', 'Streak Milestone'),
        ('SOCIAL', 'Social Activity'),
        ('REFERRAL', 'Referral'),
        ('REDEMPTION', 'Reward Redemption'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='point_transactions'
    )
    transaction_type = models.CharField(max_length=10, choices=TRANSACTION_TYPE_CHOICES)
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES)
    points = models.IntegerField()
    description = models.CharField(max_length=255)
    reference_id = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'point_transactions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['source']),
        ]
    
    def __str__(self):
        sign = '+' if self.transaction_type in ['EARN', 'BONUS', 'REFUND'] else '-'
        return f"{self.user.email} {sign}{self.points} - {self.source}"


class Achievement(models.Model):
    """Achievements that users can unlock"""
    CATEGORY_CHOICES = [
        ('WORKOUT', 'Workout'),
        ('NUTRITION', 'Nutrition'),
        ('SOCIAL', 'Social'),
        ('CHALLENGE', 'Challenge'),
        ('STREAK', 'Streak'),
    ]
    
    name = models.CharField(max_length=255)
    description = models.TextField()
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    icon_url = models.URLField(blank=True, null=True)
    criteria = models.JSONField(help_text="Achievement unlock criteria")
    points_reward = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'achievements'
        ordering = ['category', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.category})"


class UserAchievement(models.Model):
    """Track which achievements users have unlocked"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='achievements'
    )
    achievement = models.ForeignKey(
        Achievement,
        on_delete=models.CASCADE
    )
    unlocked_at = models.DateTimeField(auto_now_add=True)
    progress = models.IntegerField(default=0)
    is_completed = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'user_achievements'
        unique_together = ['user', 'achievement']
        ordering = ['-unlocked_at']
    
    def __str__(self):
        return f"{self.user.email} - {self.achievement.name}"
