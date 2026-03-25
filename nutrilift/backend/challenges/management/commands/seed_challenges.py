from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth import get_user_model
from datetime import timedelta, date

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed dummy challenge data (idempotent)'

    def handle(self, *args, **options):
        from challenges.models import Challenge, ChallengeParticipant, ChallengeDailyLog, Streak

        if Challenge.objects.exists():
            self.stdout.write(self.style.WARNING('Challenges already exist — skipping seed.'))
            return

        # --- Admin user (official challenges) ---
        admin, _ = User.objects.get_or_create(
            email='admin@nutrilift.com',
            defaults={'name': 'NutriLift Admin', 'is_staff': True, 'is_superuser': True},
        )
        if not admin.has_usable_password():
            admin.set_password('admin1234')
            admin.save()

        # --- Regular test users ---
        user1, _ = User.objects.get_or_create(
            email='alex@example.com',
            defaults={'name': 'Alex'},
        )
        if not user1.has_usable_password():
            user1.set_password('test1234')
            user1.save()

        user2, _ = User.objects.get_or_create(
            email='sam@example.com',
            defaults={'name': 'Sam'},
        )
        if not user2.has_usable_password():
            user2.set_password('test1234')
            user2.save()

        # --- Kamal Dhital (demo streak user) ---
        kamal, _ = User.objects.get_or_create(
            email='kamal@example.com',
            defaults={'name': 'kamal dhital'},
        )
        if not kamal.has_usable_password():
            kamal.set_password('test1234')
            kamal.save()

        now = timezone.now()

        official = [
            dict(
                name='30-Day Calorie Burn',
                description='Burn 10,000 kcal over 30 days through any activity.',
                challenge_type='workout',
                goal_value=10000,
                unit='kcal',
                start_date=now,
                end_date=now + timedelta(days=30),
                created_by=admin,
                is_official=True,
            ),
            dict(
                name='Clean Eating Week',
                description='Log at least 1,800 kcal of clean food every day for 7 days.',
                challenge_type='nutrition',
                goal_value=12600,
                unit='kcal',
                start_date=now,
                end_date=now + timedelta(days=7),
                created_by=admin,
                is_official=True,
            ),
            dict(
                name='100 Rep Challenge',
                description='Complete 100 reps of any exercise each day for 14 days.',
                challenge_type='workout',
                goal_value=1400,
                unit='reps',
                start_date=now,
                end_date=now + timedelta(days=14),
                created_by=admin,
                is_official=True,
            ),
        ]

        user_challenges = [
            dict(
                name="Alex's Push-Up Streak",
                description='50 push-ups every day for 10 days. Who is in?',
                challenge_type='workout',
                goal_value=500,
                unit='reps',
                start_date=now,
                end_date=now + timedelta(days=10),
                created_by=user1,
                is_official=False,
            ),
            dict(
                name='Protein Power Month',
                description='Hit your protein goal every single day for 30 days.',
                challenge_type='nutrition',
                goal_value=30,
                unit='days',
                start_date=now,
                end_date=now + timedelta(days=30),
                created_by=user2,
                is_official=False,
            ),
        ]

        challenges = []
        for data in official + user_challenges:
            challenges.append(Challenge.objects.create(is_active=True, **data))

        # --- Seed demo daily logs for kamal dhital on the first official challenge ---
        first_challenge = challenges[0]  # 30-Day Calorie Burn
        streak_days = 5

        # Join kamal to the challenge with a joined_at 5 days ago
        joined_at = now - timedelta(days=streak_days)
        participant = ChallengeParticipant.objects.filter(
            challenge=first_challenge, user=kamal
        ).first()
        if participant is None:
            participant = ChallengeParticipant.objects.create(
                challenge=first_challenge,
                user=kamal,
                progress=streak_days,
            )
            # Override auto_now_add joined_at
            ChallengeParticipant.objects.filter(pk=participant.pk).update(joined_at=joined_at)
            participant.refresh_from_db()

        # Create completed daily logs for each of the past 5 days
        for day in range(1, streak_days + 1):
            completed_at = joined_at + timedelta(days=day - 1)
            ChallengeDailyLog.objects.get_or_create(
                participant=participant,
                day_number=day,
                defaults={
                    'task_items': [{'label': 'Complete workout', 'completed': True}],
                    'media_urls': [],
                    'is_complete': True,
                    'completed_at': completed_at,
                },
            )

        # Set kamal's streak to 5
        Streak.objects.update_or_create(
            user=kamal,
            defaults={
                'current_streak': streak_days,
                'longest_streak': streak_days,
                'last_active_date': date.today(),
            },
        )

        self.stdout.write(self.style.SUCCESS(
            f'Seeded {len(official)} official + {len(user_challenges)} user challenges. '
            f'Added {streak_days}-day streak for kamal dhital.'
        ))
