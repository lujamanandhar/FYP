"""
Management command: send_streak_reminders
Run daily (e.g. via cron or scheduler) to notify users whose streak is at risk.

Usage:
    python manage.py send_streak_reminders
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from challenges.models import Streak
from notifications.utils import notify_streak_at_risk


class Command(BaseCommand):
    help = 'Send streak-at-risk notifications to users who have not logged activity today.'

    def handle(self, *args, **options):
        today = timezone.now().date()
        yesterday = today - timezone.timedelta(days=1)

        # Users whose last active date was yesterday (streak will break if they don't log today)
        at_risk = Streak.objects.filter(
            last_active_date=yesterday,
            current_streak__gte=1,
        ).select_related('user')

        count = 0
        for streak in at_risk:
            notify_streak_at_risk(streak.user, streak.current_streak)
            count += 1

        self.stdout.write(self.style.SUCCESS(f'Sent {count} streak reminder(s).'))
