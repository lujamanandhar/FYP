from django.core.management.base import BaseCommand
from django.utils import timezone


class Command(BaseCommand):
    help = 'Recalculate all active challenge progress from actual workout/nutrition logs'

    def handle(self, *args, **options):
        from challenges.signals import (
            _update_challenge_progress_from_nutrition,
            _update_challenge_progress_from_workout,
        )
        from challenges.models import ChallengeParticipant
        from django.contrib.auth import get_user_model

        User = get_user_model()
        now = timezone.now()

        # Get all users with active challenge participation
        user_ids = ChallengeParticipant.objects.filter(
            challenge__is_active=True,
            challenge__end_date__gt=now,
            completed=False,
        ).values_list('user_id', flat=True).distinct()

        users = User.objects.filter(id__in=user_ids)
        self.stdout.write(f'Recalculating progress for {users.count()} users...')

        for user in users:
            try:
                _update_challenge_progress_from_nutrition(user)
                _update_challenge_progress_from_workout(user)
                self.stdout.write(f'  ✅ {user.email}')
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'  ❌ {user.email}: {e}'))

        self.stdout.write(self.style.SUCCESS('Done.'))
