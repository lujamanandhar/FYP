"""
Management command: reseed_official_challenges
Deletes all existing official challenges and creates fresh ones
with structured (auto-verified) daily tasks.

Usage:
    python manage.py reseed_official_challenges
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth import get_user_model
from datetime import timedelta

User = get_user_model()


class Command(BaseCommand):
    help = 'Delete all official challenges and reseed with validated task-based ones'

    def handle(self, *args, **options):
        from challenges.models import Challenge

        # ── 1. Delete all existing official challenges ──────────────────────
        deleted_count, _ = Challenge.objects.filter(is_official=True).delete()
        self.stdout.write(self.style.WARNING(
            f'Deleted {deleted_count} existing official challenge(s).'
        ))

        # ── 2. Get or create admin user ─────────────────────────────────────
        admin, _ = User.objects.get_or_create(
            email='admin@nutrilift.com',
            defaults={'name': 'NutriLift Admin', 'is_staff': True, 'is_superuser': True},
        )
        if not admin.has_usable_password():
            admin.set_password('admin1234')
            admin.save()

        now = timezone.now()

        # ── 3. New official challenges with validated tasks ─────────────────
        #
        # Task types:
        #   'exercise' → auto-verified: checks if user logged a workout today
        #   'food'     → auto-verified: checks if user logged nutrition today
        #   'manual'   → self-reported checkbox (no auto-verify)
        #
        challenges_data = [
            # ── WORKOUT CHALLENGES ──────────────────────────────────────────
            {
                'name': '30-Day Fitness Kickstart',
                'description': (
                    'Build a daily workout habit over 30 days. '
                    'Log at least one workout every day to complete each day.'
                ),
                'challenge_type': 'workout',
                'goal_value': 30,
                'unit': 'days',
                'start_date': now,
                'end_date': now + timedelta(days=30),
                'default_tasks': [
                    {'label': 'Log a workout today', 'type': 'exercise'},
                    {'label': 'Complete at least 20 minutes of exercise', 'type': 'manual'},
                ],
            },
            {
                'name': '7-Day Strength Builder',
                'description': (
                    'One week of consistent strength training. '
                    'Log a workout each day to verify your progress.'
                ),
                'challenge_type': 'workout',
                'goal_value': 7,
                'unit': 'days',
                'start_date': now,
                'end_date': now + timedelta(days=7),
                'default_tasks': [
                    {'label': 'Log a strength workout today', 'type': 'exercise'},
                    {'label': 'Complete at least 3 exercises', 'type': 'manual'},
                    {'label': 'Rest 60 seconds between sets', 'type': 'manual'},
                ],
            },
            {
                'name': '14-Day Cardio Blast',
                'description': (
                    'Two weeks of daily cardio. Log any cardio workout '
                    '(running, cycling, HIIT) to complete each day.'
                ),
                'challenge_type': 'workout',
                'goal_value': 14,
                'unit': 'days',
                'start_date': now,
                'end_date': now + timedelta(days=14),
                'default_tasks': [
                    {'label': 'Log a cardio workout today', 'type': 'exercise'},
                    {'label': 'Minimum 15 minutes of cardio', 'type': 'manual'},
                ],
            },
            # ── NUTRITION CHALLENGES ────────────────────────────────────────
            {
                'name': '7-Day Clean Eating',
                'description': (
                    'Track every meal for 7 days straight. '
                    'Log your nutrition daily to complete each day.'
                ),
                'challenge_type': 'nutrition',
                'goal_value': 7,
                'unit': 'days',
                'start_date': now,
                'end_date': now + timedelta(days=7),
                'default_tasks': [
                    {'label': 'Log all meals today', 'type': 'food'},
                    {'label': 'Stay within your calorie goal', 'type': 'manual'},
                    {'label': 'Drink at least 2L of water', 'type': 'manual'},
                ],
            },
            {
                'name': '30-Day Nutrition Tracker',
                'description': (
                    'Build a consistent nutrition logging habit over 30 days. '
                    'Log your food intake every day.'
                ),
                'challenge_type': 'nutrition',
                'goal_value': 30,
                'unit': 'days',
                'start_date': now,
                'end_date': now + timedelta(days=30),
                'default_tasks': [
                    {'label': 'Log your meals today', 'type': 'food'},
                    {'label': 'Hit your protein target', 'type': 'manual'},
                    {'label': 'Avoid processed food', 'type': 'manual'},
                ],
            },
            {
                'name': '14-Day Protein Challenge',
                'description': (
                    'Hit your daily protein goal for 14 days. '
                    'Log your nutrition to track your protein intake.'
                ),
                'challenge_type': 'nutrition',
                'goal_value': 14,
                'unit': 'days',
                'start_date': now,
                'end_date': now + timedelta(days=14),
                'default_tasks': [
                    {'label': 'Log your food intake today', 'type': 'food'},
                    {'label': 'Eat at least 100g of protein', 'type': 'manual'},
                    {'label': 'Include a protein source in every meal', 'type': 'manual'},
                ],
            },
            # ── MIXED CHALLENGES ────────────────────────────────────────────
            {
                'name': '21-Day Total Wellness',
                'description': (
                    'Combine daily workouts and nutrition tracking for 21 days. '
                    'Both a workout log AND a nutrition log are required each day.'
                ),
                'challenge_type': 'mixed',
                'goal_value': 21,
                'unit': 'days',
                'start_date': now,
                'end_date': now + timedelta(days=21),
                'default_tasks': [
                    {'label': 'Log a workout today', 'type': 'exercise'},
                    {'label': 'Log your meals today', 'type': 'food'},
                    {'label': 'Get 7+ hours of sleep', 'type': 'manual'},
                ],
            },
            {
                'name': '7-Day Body Reset',
                'description': (
                    'One week of combined fitness and nutrition. '
                    'Log both a workout and your meals every day.'
                ),
                'challenge_type': 'mixed',
                'goal_value': 7,
                'unit': 'days',
                'start_date': now,
                'end_date': now + timedelta(days=7),
                'default_tasks': [
                    {'label': 'Log a workout today', 'type': 'exercise'},
                    {'label': 'Log your nutrition today', 'type': 'food'},
                    {'label': 'No junk food today', 'type': 'manual'},
                    {'label': 'Drink 8 glasses of water', 'type': 'manual'},
                ],
            },
        ]

        created = 0
        for data in challenges_data:
            Challenge.objects.create(
                name=data['name'],
                description=data['description'],
                challenge_type=data['challenge_type'],
                goal_value=data['goal_value'],
                unit=data['unit'],
                start_date=data['start_date'],
                end_date=data['end_date'],
                created_by=admin,
                is_official=True,
                is_active=True,
                default_tasks=data['default_tasks'],
            )
            created += 1
            self.stdout.write(f'  ✓ Created: {data["name"]}')

        self.stdout.write(self.style.SUCCESS(
            f'\nDone! Created {created} official challenges with validated tasks.'
        ))
        self.stdout.write(
            '\nTask types used:\n'
            '  exercise → auto-verified when user logs a workout\n'
            '  food     → auto-verified when user logs nutrition\n'
            '  manual   → self-reported checkbox\n'
        )
