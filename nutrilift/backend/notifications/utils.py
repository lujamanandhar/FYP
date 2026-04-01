"""
Utility functions to create notifications from anywhere in the backend.
Usage:
    from notifications.utils import notify
    notify(user, 'challenge', 'New Challenge!', 'A new challenge has been added.', '/challenges/uuid')
"""
from .models import Notification


def notify(user, ntype, title, message, action_url=''):
    """Create a notification for a user. Silently ignores errors."""
    try:
        Notification.objects.create(
            user=user,
            type=ntype,
            title=title,
            message=message,
            action_url=action_url,
        )
    except Exception:
        pass


def notify_streak_at_risk(user, streak_count):
    notify(
        user, 'streak',
        '🔥 Streak at Risk!',
        f"You have a {streak_count}-day streak. Log activity today to keep it alive!",
        '/workout',
    )


def notify_new_challenge(user, challenge_name, challenge_id):
    notify(
        user, 'challenge',
        '🏆 New Challenge Available',
        f'"{challenge_name}" has been added. Join now!',
        f'/challenges/{challenge_id}',
    )


def notify_challenge_expiring(user, challenge_name, days_left):
    notify(
        user, 'challenge',
        '⏰ Challenge Expiring Soon',
        f'"{challenge_name}" ends in {days_left} day(s). Keep going!',
        '/challenges',
    )


def notify_new_post(user, poster_name):
    notify(
        user, 'social',
        '📣 New Community Post',
        f'{poster_name} shared something new in the community.',
        '/community',
    )
