import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone

logger = logging.getLogger(__name__)


def _update_streak(user):
    """Update or create the user's Streak record based on today's activity."""
    from challenges.models import Streak

    today = timezone.now().date()
    yesterday = today - timezone.timedelta(days=1)

    streak, created = Streak.objects.get_or_create(
        user=user,
        defaults={
            'current_streak': 1,
            'longest_streak': 1,
            'last_active_date': today,
        }
    )

    if not created:
        if streak.last_active_date == today:
            # Already logged today — no-op
            return
        elif streak.last_active_date == yesterday:
            # Consecutive day — increment
            streak.current_streak += 1
        else:
            # Gap of more than one day — reset
            streak.current_streak = 1

        if streak.current_streak > streak.longest_streak:
            streak.longest_streak = streak.current_streak

        streak.last_active_date = today
        streak.save(update_fields=['current_streak', 'longest_streak', 'last_active_date'])


def _award_badges(user):
    """Award any active challenge_complete badges not yet earned by the user."""
    from challenges.models import Badge, UserBadge

    eligible_badges = Badge.objects.filter(
        is_active=True,
        criteria={"type": "challenge_complete"},
    ).exclude(
        userbadge__user=user
    )

    for badge in eligible_badges:
        UserBadge.objects.get_or_create(user=user, badge=badge)


def _update_challenge_progress(user, calories, challenge_types):
    """
    Increment progress for all active ChallengeParticipant records matching
    the given challenge_types, check completion, and award badges.
    """
    from challenges.models import ChallengeParticipant

    now = timezone.now()

    participants = ChallengeParticipant.objects.select_related('challenge').filter(
        user=user,
        challenge__challenge_type__in=challenge_types,
        challenge__is_active=True,
        challenge__end_date__gt=now,
        completed=False,
    )

    for participant in participants:
        participant.progress = float(participant.progress) + float(calories)

        if participant.progress >= participant.challenge.goal_value:
            participant.completed = True
            participant.completed_at = now
            participant.save(update_fields=['progress', 'completed', 'completed_at'])
            _award_badges(user)
        else:
            participant.save(update_fields=['progress'])


def handle_workout_log_saved(sender, instance, **kwargs):
    """
    post_save handler for workouts.WorkoutLog.

    Increments progress on active workout/mixed ChallengeParticipant records,
    updates the user's streak, and awards badges on completion.
    """
    try:
        _update_challenge_progress(
            user=instance.user,
            calories=instance.calories_burned,
            challenge_types=['workout', 'mixed'],
        )
        _update_streak(instance.user)
    except Exception:
        logger.error(
            "Error in handle_workout_log_saved for WorkoutLog pk=%s",
            instance.pk,
            exc_info=True,
        )


def handle_intake_log_saved(sender, instance, **kwargs):
    """
    post_save handler for nutrition.IntakeLog.

    Increments progress on active nutrition/mixed ChallengeParticipant records,
    updates the user's streak, and awards badges on completion.
    """
    try:
        _update_challenge_progress(
            user=instance.user,
            calories=instance.calories,
            challenge_types=['nutrition', 'mixed'],
        )
        _update_streak(instance.user)
    except Exception:
        logger.error(
            "Error in handle_intake_log_saved for IntakeLog pk=%s",
            instance.pk,
            exc_info=True,
        )


def connect_signals():
    """Connect signal handlers to their respective senders."""
    from django.apps import apps

    WorkoutLog = apps.get_model('workouts', 'WorkoutLog')
    IntakeLog = apps.get_model('nutrition', 'IntakeLog')

    post_save.connect(handle_workout_log_saved, sender=WorkoutLog)
    post_save.connect(handle_intake_log_saved, sender=IntakeLog)
