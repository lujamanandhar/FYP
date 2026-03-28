"""
Models for camera-based rep counting feature.
Requirements: 12.1, 12.2
"""
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from .models import Exercise, WorkoutLog


class RepSession(models.Model):
    """
    A camera-based rep counting session.
    Stores the overall session data before conversion to WorkoutLog.
    """
    EXERCISE_TYPE_CHOICES = [
        ('PUSH_UP', 'Push-ups'),
        ('SQUAT', 'Squats'),
        ('PULL_UP', 'Pull-ups'),
        ('BICEP_CURL', 'Bicep Curls'),
        ('SHOULDER_PRESS', 'Shoulder Press'),
        ('LUNGE', 'Lunges'),
        ('SIT_UP', 'Sit-ups'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='rep_sessions'
    )
    exercise_type = models.CharField(max_length=20, choices=EXERCISE_TYPE_CHOICES)
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='rep_sessions'
    )
    start_time = models.DateTimeField(auto_now_add=True)
    end_time = models.DateTimeField(null=True, blank=True)
    total_reps = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    confidence_avg = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)],
        default=0.0
    )
    workout_log = models.ForeignKey(
        WorkoutLog,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='rep_sessions'
    )
    is_converted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'rep_sessions'
        ordering = ['-start_time']
        indexes = [
            models.Index(fields=['user', '-start_time']),
            models.Index(fields=['is_converted']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.exercise_type} ({self.total_reps} reps)"


class RepEvent(models.Model):
    """
    Individual rep detection event within a session.
    Stores timestamp and confidence for each detected rep.
    """
    session = models.ForeignKey(
        RepSession,
        on_delete=models.CASCADE,
        related_name='rep_events'
    )
    rep_number = models.IntegerField(validators=[MinValueValidator(1)])
    timestamp = models.DateTimeField(auto_now_add=True)
    confidence = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)]
    )
    angle_data = models.JSONField(
        default=dict,
        help_text="Joint angles at the time of rep detection"
    )
    
    class Meta:
        db_table = 'rep_events'
        ordering = ['rep_number']
        unique_together = ['session', 'rep_number']
    
    def __str__(self):
        return f"Rep {self.rep_number} - Session {self.session.id}"
