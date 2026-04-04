from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth import get_user_model
from datetime import timedelta

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed dummy paid challenges for eSewa payment testing'

    def handle(self, *args, **options):
        from challenges.models import Challenge

        admin, _ = User.objects.get_or_create(
            email='admin@nutrilift.com',
            defaults={'name': 'NutriLift Admin', 'is_staff': True, 'is_superuser': True},
        )
        if not admin.has_usable_password():
            admin.set_password('admin1234')
            admin.save()

        now = timezone.now()

        paid_challenges = [
            dict(
                name='🏆 Elite 30-Day Fat Burn',
                description='Burn 15,000 kcal in 30 days. Top 3 finishers win cash prizes. '
                            'Daily workout tasks + nutrition tracking required.',
                challenge_type='workout',
                goal_value=15000,
                unit='kcal',
                start_date=now,
                end_date=now + timedelta(days=30),
                created_by=admin,
                is_official=True,
                is_paid=True,
                price=99,
                currency='NPR',
                prize_description='🥇 1st: NPR 2,000 | 🥈 2nd: NPR 1,000 | 🥉 3rd: NPR 500',
            ),
            dict(
                name='💪 Premium Muscle Builder',
                description='Complete 1,000 reps across any strength exercises in 21 days. '
                            'Certificate + badge for all finishers.',
                challenge_type='workout',
                goal_value=1000,
                unit='reps',
                start_date=now,
                end_date=now + timedelta(days=21),
                created_by=admin,
                is_official=True,
                is_paid=True,
                price=49,
                currency='NPR',
                prize_description='🎖️ Certificate + exclusive badge for all finishers',
            ),
            dict(
                name='🥗 Clean Eating Challenge',
                description='Hit your daily nutrition goals for 14 consecutive days. '
                            'Macro tracking required. Winner gets featured on the app.',
                challenge_type='nutrition',
                goal_value=14,
                unit='days',
                start_date=now,
                end_date=now + timedelta(days=14),
                created_by=admin,
                is_official=True,
                is_paid=True,
                price=29,
                currency='NPR',
                prize_description='🌟 Winner featured on NutriLift homepage + NPR 500',
            ),
            dict(
                name='🚀 7-Day Transformation',
                description='Quick 7-day challenge — 500 kcal burn per day minimum. '
                            'Perfect for beginners. Low entry fee.',
                challenge_type='workout',
                goal_value=3500,
                unit='kcal',
                start_date=now,
                end_date=now + timedelta(days=7),
                created_by=admin,
                is_official=True,
                is_paid=True,
                price=19,
                currency='NPR',
                prize_description='🏅 Completion certificate for all finishers',
            ),
        ]

        created = 0
        for data in paid_challenges:
            obj, was_created = Challenge.objects.get_or_create(
                name=data['name'],
                defaults={**data, 'is_active': True},
            )
            if was_created:
                created += 1
                self.stdout.write(f'  ✅ Created: {obj.name} — NPR {obj.price}')
            else:
                self.stdout.write(f'  ⏭️  Exists:  {obj.name}')

        self.stdout.write(self.style.SUCCESS(
            f'\nDone. {created} new paid challenges created.'
        ))
