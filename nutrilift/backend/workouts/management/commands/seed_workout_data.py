from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from workouts.models import Exercise, WorkoutLog, WorkoutExercise, PersonalRecord

User = get_user_model()


class Command(BaseCommand):
    help = 'Seeds dummy workout history and personal records for the first user (for UI preview)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            type=str,
            help='Email of the user to seed data for (defaults to first user)',
        )
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing workout logs and PRs before seeding',
        )

    def handle(self, *args, **options):
        # Resolve user
        email = options.get('email')
        if email:
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                self.stderr.write(self.style.ERROR(f'User with email "{email}" not found.'))
                return
        else:
            user = User.objects.first()
            if not user:
                self.stderr.write(self.style.ERROR('No users found. Please create a user first.'))
                return

        self.stdout.write(f'Seeding workout data for: {user.email}')

        if options.get('clear'):
            WorkoutLog.objects.filter(user=user).hard_delete() if hasattr(WorkoutLog, 'hard_delete') else WorkoutLog.objects.filter(user=user).delete()
            PersonalRecord.objects.filter(user=user).delete()
            self.stdout.write('Cleared existing data.')

        # Grab exercises we'll use (must already be seeded)
        exercise_names = [
            'Barbell Bench Press',
            'Barbell Squat',
            'Barbell Deadlift',
            'Overhead Press',
            'Barbell Row',
            'Dumbbell Curl',
            'Treadmill Running',
            'Pull-ups',
        ]
        exercises = {e.name: e for e in Exercise.objects.filter(name__in=exercise_names)}

        if not exercises:
            self.stderr.write(self.style.ERROR(
                'No exercises found. Run "python manage.py seed_exercises" first.'
            ))
            return

        now = timezone.now()

        # ── Workout definitions ──────────────────────────────────────────────
        # Each entry: (days_ago, workout_name, notes, duration_min, calories, has_pr, exercises_list)
        # exercises_list: list of (exercise_name, sets, reps, weight_kg)
        workouts_data = [
            {
                'days_ago': 1,
                'name': 'Push Day A',
                'notes': 'Felt strong today, hit a new bench PR!',
                'duration': 65,
                'calories': Decimal('520.00'),
                'exercises': [
                    ('Barbell Bench Press', 4, 8, Decimal('102.5')),
                    ('Overhead Press', 3, 10, Decimal('65.0')),
                ],
            },
            {
                'days_ago': 3,
                'name': 'Pull Day',
                'notes': 'Good back session, rows felt heavy.',
                'duration': 55,
                'calories': Decimal('480.00'),
                'exercises': [
                    ('Barbell Row', 4, 8, Decimal('90.0')),
                    ('Pull-ups', 3, 8, Decimal('0.5')),
                    ('Dumbbell Curl', 3, 12, Decimal('20.0')),
                ],
            },
            {
                'days_ago': 5,
                'name': 'Leg Day',
                'notes': 'Squats were tough but got through it.',
                'duration': 70,
                'calories': Decimal('610.00'),
                'exercises': [
                    ('Barbell Squat', 5, 5, Decimal('120.0')),
                    ('Barbell Deadlift', 3, 5, Decimal('140.0')),
                ],
            },
            {
                'days_ago': 8,
                'name': 'Push Day B',
                'notes': None,
                'duration': 60,
                'calories': Decimal('490.00'),
                'exercises': [
                    ('Barbell Bench Press', 4, 8, Decimal('97.5')),
                    ('Overhead Press', 3, 10, Decimal('62.5')),
                ],
            },
            {
                'days_ago': 10,
                'name': 'Cardio Session',
                'notes': '5km easy run on treadmill.',
                'duration': 35,
                'calories': Decimal('350.00'),
                'exercises': [
                    ('Treadmill Running', 1, 1, Decimal('0.5')),
                ],
            },
            {
                'days_ago': 12,
                'name': 'Full Body',
                'notes': 'Light session, focusing on form.',
                'duration': 50,
                'calories': Decimal('420.00'),
                'exercises': [
                    ('Barbell Squat', 3, 10, Decimal('100.0')),
                    ('Barbell Row', 3, 10, Decimal('80.0')),
                    ('Dumbbell Curl', 3, 12, Decimal('18.0')),
                ],
            },
            {
                'days_ago': 15,
                'name': 'Leg Day',
                'notes': 'Deadlift PR attempt — got it!',
                'duration': 75,
                'calories': Decimal('640.00'),
                'exercises': [
                    ('Barbell Squat', 5, 5, Decimal('115.0')),
                    ('Barbell Deadlift', 3, 3, Decimal('150.0')),
                ],
            },
            {
                'days_ago': 18,
                'name': 'Push Day A',
                'notes': None,
                'duration': 60,
                'calories': Decimal('500.00'),
                'exercises': [
                    ('Barbell Bench Press', 4, 8, Decimal('95.0')),
                    ('Overhead Press', 3, 10, Decimal('60.0')),
                ],
            },
        ]

        created_logs = []
        for w in workouts_data:
            log_time = now - timedelta(days=w['days_ago'])

            log = WorkoutLog(
                user=user,
                workout_name=w['name'],
                duration_minutes=w['duration'],
                calories_burned=w['calories'],
                notes=w['notes'],
            )
            # bypass auto_now_add so we can set logged_at manually
            log.save()
            WorkoutLog.objects.filter(pk=log.pk).update(logged_at=log_time)
            log.refresh_from_db()

            for order, (ex_name, sets, reps, weight) in enumerate(w['exercises']):
                exercise = exercises.get(ex_name)
                if exercise:
                    WorkoutExercise.objects.create(
                        workout_log=log,
                        exercise=exercise,
                        sets=sets,
                        reps=reps,
                        weight=weight,
                        order=order,
                    )

            created_logs.append(log)
            self.stdout.write(f'  Created: {w["name"]} ({log.logged_at.date()})')

        # ── Personal Records ─────────────────────────────────────────────────
        pr_data = [
            {
                'exercise': 'Barbell Bench Press',
                'max_weight': Decimal('102.5'),
                'max_reps': 8,
                'max_volume': Decimal('3280.0'),
                'prev_weight': Decimal('95.0'),
                'prev_reps': 8,
                'prev_volume': Decimal('3040.0'),
                'days_ago': 1,
            },
            {
                'exercise': 'Barbell Squat',
                'max_weight': Decimal('120.0'),
                'max_reps': 5,
                'max_volume': Decimal('3000.0'),
                'prev_weight': Decimal('115.0'),
                'prev_reps': 5,
                'prev_volume': Decimal('2875.0'),
                'days_ago': 5,
            },
            {
                'exercise': 'Barbell Deadlift',
                'max_weight': Decimal('150.0'),
                'max_reps': 3,
                'max_volume': Decimal('2250.0'),
                'prev_weight': Decimal('140.0'),
                'prev_reps': 5,
                'prev_volume': Decimal('2100.0'),
                'days_ago': 15,
            },
            {
                'exercise': 'Overhead Press',
                'max_weight': Decimal('65.0'),
                'max_reps': 10,
                'max_volume': Decimal('1950.0'),
                'prev_weight': Decimal('62.5'),
                'prev_reps': 10,
                'prev_volume': Decimal('1875.0'),
                'days_ago': 1,
            },
            {
                'exercise': 'Barbell Row',
                'max_weight': Decimal('90.0'),
                'max_reps': 8,
                'max_volume': Decimal('2880.0'),
                'prev_weight': Decimal('80.0'),
                'prev_reps': 10,
                'prev_volume': Decimal('2400.0'),
                'days_ago': 3,
            },
            {
                'exercise': 'Pull-ups',
                'max_weight': Decimal('0.5'),
                'max_reps': 8,
                'max_volume': Decimal('12.0'),
                'prev_weight': None,
                'prev_reps': None,
                'prev_volume': None,
                'days_ago': 3,
            },
            {
                'exercise': 'Dumbbell Curl',
                'max_weight': Decimal('20.0'),
                'max_reps': 12,
                'max_volume': Decimal('720.0'),
                'prev_weight': Decimal('18.0'),
                'prev_reps': 12,
                'prev_volume': Decimal('648.0'),
                'days_ago': 3,
            },
        ]

        for pr in pr_data:
            exercise = exercises.get(pr['exercise'])
            if not exercise:
                continue

            achieved = now - timedelta(days=pr['days_ago'])
            # Find the matching workout log for the FK
            matching_log = next(
                (l for l in created_logs if (now - timedelta(days=pr['days_ago'])).date() == l.logged_at.date()),
                created_logs[0],
            )

            PersonalRecord.objects.update_or_create(
                user=user,
                exercise=exercise,
                defaults={
                    'max_weight': pr['max_weight'],
                    'max_reps': pr['max_reps'],
                    'max_volume': pr['max_volume'],
                    'achieved_date': achieved,
                    'workout_log': matching_log,
                    'previous_max_weight': pr['prev_weight'],
                    'previous_max_reps': pr['prev_reps'],
                    'previous_max_volume': pr['prev_volume'],
                },
            )
            self.stdout.write(f'  PR: {pr["exercise"]} — {pr["max_weight"]}kg')

        self.stdout.write(self.style.SUCCESS(
            f'\nDone! Created {len(created_logs)} workouts and {len(pr_data)} PRs for {user.email}.'
        ))
