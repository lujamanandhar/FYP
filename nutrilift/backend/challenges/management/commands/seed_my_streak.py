"""
Management command to inject 5 completed daily logs + streak for a given user.

Usage:
    python manage.py seed_my_streak --email your@email.com

This will:
  1. Find the first challenge the user has joined (or join the first active one).
  2. Backdate joined_at to 5 days ago.
  3. Create 5 completed daily logs (days 1–5).
  4. Set the user's Streak to current_streak=5, longest_streak=5.
"""

from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone
from django.contrib.auth import get_user_model
from datetime import timedelta, date

User = get_user_model()


class Command(BaseCommand):
    help = 'Inject 5-day streak data for a user (for demo/testing)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            type=str,
            required=True,
            help='Email of the user to seed streak data for',
        )
        parser.add_argument(
            '--days',
            type=int,
            default=5,
            help='Number of consecutive days to seed (default: 5)',
        )

    def handle(self, *args, **options):
        from challenges.models import (
            Challenge, ChallengeParticipant, ChallengeDailyLog, Streak
        )

        email = options['email']
        days = options['days']

        # --- Find user ---
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise CommandError(f'No user found with email: {email}')

        self.stdout.write(f'Found user: {user.name or user.email}')

        # --- Find or pick a challenge ---
        participant = ChallengeParticipant.objects.filter(user=user).select_related('challenge').first()

        if participant is None:
            # Auto-join the first active challenge
            challenge = Challenge.objects.filter(is_active=True, end_date__gt=timezone.now()).first()
            if challenge is None:
                raise CommandError('No active challenges found. Run seed_challenges first.')
            participant = ChallengeParticipant.objects.create(
                challenge=challenge,
                user=user,
                progress=0,
            )
            self.stdout.write(f'Auto-joined challenge: "{challenge.name}"')
        else:
            challenge = participant.challenge
            self.stdout.write(f'Using existing challenge: "{challenge.name}"')

        # --- Backdate joined_at so day_number math works ---
        now = timezone.now()
        joined_at = now - timedelta(days=days)
        ChallengeParticipant.objects.filter(pk=participant.pk).update(
            joined_at=joined_at,
            progress=days,
        )
        participant.refresh_from_db()

        # --- Create completed daily logs ---
        created_count = 0
        for day in range(1, days + 1):
            completed_at = joined_at + timedelta(days=day - 1)
            _, created = ChallengeDailyLog.objects.update_or_create(
                participant=participant,
                day_number=day,
                defaults={
                    'task_items': [{'label': 'Complete workout', 'completed': True}],
                    'media_urls': [],
                    'is_complete': True,
                    'completed_at': completed_at,
                },
            )
            if created:
                created_count += 1

        self.stdout.write(f'Created/updated {days} daily logs ({created_count} new).')

        # --- Set streak ---
        Streak.objects.update_or_create(
            user=user,
            defaults={
                'current_streak': days,
                'longest_streak': days,
                'last_active_date': date.today(),
            },
        )

        self.stdout.write(self.style.SUCCESS(
            f'Done! {user.name or user.email} now has a {days}-day streak '
            f'on "{challenge.name}".'
        ))
