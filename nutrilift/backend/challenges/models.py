import uuid
from django.db import models
from django.conf import settings


# --- Challenge & Gamification ---

class Challenge(models.Model):
    TYPE_CHOICES = [('nutrition', 'Nutrition'), ('workout', 'Workout'), ('mixed', 'Mixed')]
    UNIT_CHOICES = [('kcal', 'kcal'), ('reps', 'reps'), ('days', 'days')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    description = models.TextField()
    challenge_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    goal_value = models.FloatField()
    unit = models.CharField(max_length=10, choices=UNIT_CHOICES)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        null=True, blank=True, related_name='created_challenges'
    )
    is_official = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    default_tasks = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)

    # Payment fields
    is_paid = models.BooleanField(default=False)
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    currency = models.CharField(max_length=10, default='NPR')
    prize_description = models.TextField(blank=True)  # e.g. "Gift hamper + NutriLift voucher"

    def __str__(self):
        return self.name


class ChallengeParticipant(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='participants')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    progress = models.FloatField(default=0)
    completed = models.BooleanField(default=False)
    joined_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    rank = models.IntegerField(null=True, blank=True)
    prize_paid = models.BooleanField(default=False)
    prize_paid_at = models.DateTimeField(null=True, blank=True)
    prize_notes = models.TextField(blank=True)

    class Meta:
        unique_together = [('challenge', 'user')]

    def __str__(self):
        return f"{self.user} in {self.challenge}"


class Badge(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    description = models.TextField()
    icon_url = models.CharField(max_length=500)
    criteria = models.JSONField()
    points_reward = models.IntegerField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class UserBadge(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE)
    earned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [('user', 'badge')]

    def __str__(self):
        return f"{self.user} earned {self.badge}"


class Streak(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    current_streak = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_active_date = models.DateField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user} streak: {self.current_streak}"


# --- Community ---

class Post(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    content = models.TextField(max_length=1000)
    image_urls = models.JSONField(default=list)
    like_count = models.IntegerField(default=0)
    comment_count = models.IntegerField(default=0)
    is_reported = models.BooleanField(default=False)
    is_removed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Post by {self.user} at {self.created_at}"


class Comment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Comment by {self.user} on {self.post}"


class Like(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='likes')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [('post', 'user')]

    def __str__(self):
        return f"{self.user} likes {self.post}"


class Report(models.Model):
    STATUS_CHOICES = [('pending', 'Pending'), ('reviewed', 'Reviewed'), ('dismissed', 'Dismissed')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    reported_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    reason = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Report by {self.reported_by} on {self.post}"


class ChallengeDailyLog(models.Model):
    """Daily log entry for a challenge participant. Requirements: 18.2, 18.3"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    participant = models.ForeignKey(
        ChallengeParticipant, on_delete=models.CASCADE, related_name='daily_logs'
    )
    day_number = models.PositiveIntegerField()
    task_items = models.JSONField(default=list)   # [{"label": str, "completed": bool}]
    media_urls = models.JSONField(default=list)   # [{"url": str, "is_video": bool}]
    is_complete = models.BooleanField(default=False)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [('participant', 'day_number')]

    def __str__(self):
        return f"Day {self.day_number} log for {self.participant}"


class Follow(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    follower = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='following'
    )
    following = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='followers'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [('follower', 'following')]

    def __str__(self):
        return f"{self.follower} follows {self.following}"


# Import reward and payment models to register with Django
from .reward_models import UserPoints, PointTransaction, Achievement, UserAchievement
from .payment_models import PaymentPlan, ChallengePayment, Subscription


# --- Separate Feature Streaks ---

class ChallengeCompletion(models.Model):
    """Certificate record generated when a user completes a challenge."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='challenge_completions')
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='completions')
    participant = models.OneToOneField(ChallengeParticipant, on_delete=models.CASCADE, related_name='completion')
    certificate_number = models.CharField(max_length=20, unique=True)
    days_taken = models.IntegerField(default=0)
    rank = models.IntegerField(null=True, blank=True)
    total_participants = models.IntegerField(default=0)
    completed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-completed_at']

    def __str__(self):
        return f"{self.user} completed {self.challenge.name} — #{self.certificate_number}"

    def save(self, *args, **kwargs):
        if not self.certificate_number:
            import random, string
            self.certificate_number = 'NL-' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        super().save(*args, **kwargs)


class EsewaPayment(models.Model):
    """eSewa payment record for paid challenges."""
    STATUS_CHOICES = [('PENDING', 'Pending'), ('COMPLETED', 'Completed'), ('FAILED', 'Failed')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='esewa_payments')
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='esewa_payments')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_uuid = models.CharField(max_length=100, unique=True)
    esewa_ref_id = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user} — {self.challenge.name} — NPR {self.amount} [{self.status}]"


class WorkoutStreak(models.Model):
    """Tracks consecutive days a user has logged a workout."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='workout_streak')
    current_streak = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_active_date = models.DateField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user} - Workout Streak: {self.current_streak}"


class NutritionStreak(models.Model):
    """Tracks consecutive days a user has logged nutrition/meals."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='nutrition_streak')
    current_streak = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_active_date = models.DateField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user} - Nutrition Streak: {self.current_streak}"
