"""
Management command to fast-complete a challenge for demo/presentation purposes.

Usage:
    python manage.py demo_complete_challenge --email user@example.com --challenge-name "Challenge Name"

What it does:
    1. Creates a 3-day challenge (goal_value=3, unit=days) if no challenge name given
    2. Joins the user to the challenge
    3. Creates 3 completed daily logs (backdated)
    4. Marks participant as completed
    5. Creates the ChallengeCompletion (certificate) record
    6. Awards any eligible badges
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta, date
import random
import string


class Command(BaseCommand):
    help = 'Fast-complete a challenge for demo purposes'

    def add_arguments(self, parser):
        parser.add_argument('--email', type=str, default='admin@nutrilift.com',
                            help='User email to complete the challenge for')
        parser.add_argument('--challenge-name', type=str, default=None,
                            help='Name of existing challenge to complete (optional)')
        parser.add_argument('--create-demo', action='store_true',
                            help='Create a fresh 3-day demo challenge and complete it')

    def handle(self, *args, **options):
        from django.contrib.auth import get_user_model
        from challenges.models import (
            Challenge, ChallengeParticipant, ChallengeDailyLog,
            ChallengeCompletion, Badge, UserBadge,
        )

        User = get_user_model()

        # Get user
        try:
            user = User.objects.get(email=options['email'])
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"User {options['email']} not found"))
            return

        now = timezone.now()

        # Get or create challenge
        if options['create_demo'] or options['challenge_name'] is None:
            # Create a fresh 3-day demo challenge
            challenge, created = Challenge.objects.get_or_create(
                name='Demo 3-Day Push-Up Challenge',
                defaults={
                    'description': 'Complete 10 push-ups every day for 3 days.',
                    'challenge_type': 'workout',
                    'goal_value': 3,
                    'unit': 'days',
                    'start_date': now - timedelta(days=4),
                    'end_date': now + timedelta(days=1),
                    'is_official': True,
                    'is_active': True,
                    'default_tasks': [
                        {'label': '10 Push-ups', 'type': 'exercise'},
                        {'label': 'Drink 2L water', 'type': 'manual'},
                    ],
                }
            )
            if created:
                self.stdout.write(f'Created demo challenge: {challenge.name}')
            else:
                self.stdout.write(f'Using existing challenge: {challenge.name}')
        else:
            try:
                challenge = Challenge.objects.get(name__icontains=options['challenge_name'])
                self.stdout.write(f'Found challenge: {challenge.name}')
            except Challenge.DoesNotExist:
                self.stdout.write(self.style.ERROR(f"Challenge '{options['challenge_name']}' not found"))
                return
            except Challenge.MultipleObjectsReturned:
                challenge = Challenge.objects.filter(name__icontains=options['challenge_name']).first()
                self.stdout.write(f'Multiple found, using: {challenge.name}')

        goal = int(challenge.goal_value)
        joined_at = now - timedelta(days=goal + 1)

        # Create or get participant
        participant, _ = ChallengeParticipant.objects.get_or_create(
            challenge=challenge,
            user=user,
        )

        # Backdate joined_at
        ChallengeParticipant.objects.filter(pk=participant.pk).update(
            joined_at=joined_at,
            progress=goal,
            completed=True,
            completed_at=now - timedelta(hours=1),
            rank=1,
        )
        participant.refresh_from_db()

        # Create completed daily logs for each day
        tasks = challenge.default_tasks or []
        for day in range(1, goal + 1):
            log_date = joined_at + timedelta(days=day - 1)
            task_items = [
                {**t, 'completed': True, 'verified': True,
                 'verification_message': '✓ Verified from logs'}
                for t in tasks
            ]
            log, created = ChallengeDailyLog.objects.get_or_create(
                participant=participant,
                day_number=day,
                defaults={
                    'task_items': task_items,
                    'media_urls': [],
                    'is_complete': True,
                    'completed_at': log_date,
                }
            )
            if not created and not log.is_complete:
                log.is_complete = True
                log.completed_at = log_date
                log.task_items = task_items
                log.save()

        self.stdout.write(f'Created {goal} completed daily logs')

        # Create certificate (ChallengeCompletion)
        total_participants = ChallengeParticipant.objects.filter(
            challenge=challenge, completed=True
        ).count()

        cert_number = 'NL-' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        completion, created = ChallengeCompletion.objects.get_or_create(
            user=user,
            challenge=challenge,
            defaults={
                'participant': participant,
                'certificate_number': cert_number,
                'days_taken': goal,
                'rank': 1,
                'total_participants': total_participants,
            }
        )
        if created:
            self.stdout.write(f'Certificate created: #{completion.certificate_number}')
        else:
            self.stdout.write(f'Certificate already exists: #{completion.certificate_number}')

        # Award badges
        try:
            from challenges.signals import _award_badges
            _award_badges(user)
            self.stdout.write('Badges checked and awarded')
        except Exception as e:
            self.stdout.write(f'Badge award skipped: {e}')

        # Update streak
        try:
            from challenges.signals import _update_streak
            _update_streak(user)
            self.stdout.write('Streak updated')
        except Exception as e:
            self.stdout.write(f'Streak update skipped: {e}')

        self.stdout.write(self.style.SUCCESS(
            f'\n✅ Done! {user.email} has completed "{challenge.name}"\n'
            f'   Certificate: #{completion.certificate_number}\n'
            f'   Days completed: {goal}\n'
            f'   Rank: #1 of {total_participants} participants\n'
            f'\nNow open the app → Challenges → Gamification tab to see the certificate and badges.'
        ))
