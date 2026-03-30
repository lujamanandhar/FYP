from django.core.management.base import BaseCommand
from challenges.reward_models import Achievement


class Command(BaseCommand):
    help = 'Seeds the database with achievements'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding achievements...')
        
        achievements = [
            # Workout Achievements
            {
                'name': 'First 10 Workouts',
                'description': 'Complete your first 10 workouts',
                'category': 'WORKOUT',
                'criteria': {'type': 'workout_count', 'value': 10},
                'points_reward': 50,
                'is_active': True,
            },
            {
                'name': '50 Workouts Strong',
                'description': 'Complete 50 workouts',
                'category': 'WORKOUT',
                'criteria': {'type': 'workout_count', 'value': 50},
                'points_reward': 200,
                'is_active': True,
            },
            {
                'name': 'Century Club',
                'description': 'Complete 100 workouts',
                'category': 'WORKOUT',
                'criteria': {'type': 'workout_count', 'value': 100},
                'points_reward': 500,
                'is_active': True,
            },
            {
                'name': 'Workout Warrior',
                'description': 'Complete 500 workouts',
                'category': 'WORKOUT',
                'criteria': {'type': 'workout_count', 'value': 500},
                'points_reward': 2000,
                'is_active': True,
            },
            
            # Streak Achievements
            {
                'name': '7 Day Streak',
                'description': 'Maintain a 7-day workout streak',
                'category': 'STREAK',
                'criteria': {'type': 'streak', 'value': 7},
                'points_reward': 100,
                'is_active': True,
            },
            {
                'name': '30 Day Streak',
                'description': 'Maintain a 30-day workout streak',
                'category': 'STREAK',
                'criteria': {'type': 'streak', 'value': 30},
                'points_reward': 500,
                'is_active': True,
            },
            {
                'name': '100 Day Streak',
                'description': 'Maintain a 100-day workout streak',
                'category': 'STREAK',
                'criteria': {'type': 'streak', 'value': 100},
                'points_reward': 2000,
                'is_active': True,
            },
            
            # Challenge Achievements
            {
                'name': 'Challenge Starter',
                'description': 'Complete your first challenge',
                'category': 'CHALLENGE',
                'criteria': {'type': 'challenge_complete', 'value': 1},
                'points_reward': 100,
                'is_active': True,
            },
            {
                'name': 'Challenge Master',
                'description': 'Complete 10 challenges',
                'category': 'CHALLENGE',
                'criteria': {'type': 'challenge_complete', 'value': 10},
                'points_reward': 1000,
                'is_active': True,
            },
            
            # Nutrition Achievements
            {
                'name': 'Nutrition Tracker',
                'description': 'Log nutrition for 7 consecutive days',
                'category': 'NUTRITION',
                'criteria': {'type': 'nutrition_streak', 'value': 7},
                'points_reward': 100,
                'is_active': True,
            },
            {
                'name': 'Nutrition Pro',
                'description': 'Log nutrition for 30 consecutive days',
                'category': 'NUTRITION',
                'criteria': {'type': 'nutrition_streak', 'value': 30},
                'points_reward': 500,
                'is_active': True,
            },
            
            # Social Achievements
            {
                'name': 'Social Butterfly',
                'description': 'Get 100 followers',
                'category': 'SOCIAL',
                'criteria': {'type': 'followers', 'value': 100},
                'points_reward': 200,
                'is_active': True,
            },
            {
                'name': 'Community Leader',
                'description': 'Get 1000 likes on your posts',
                'category': 'SOCIAL',
                'criteria': {'type': 'total_likes', 'value': 1000},
                'points_reward': 500,
                'is_active': True,
            },
        ]
        
        created_count = 0
        skipped_count = 0
        
        for achievement_data in achievements:
            if not Achievement.objects.filter(name=achievement_data['name']).exists():
                Achievement.objects.create(**achievement_data)
                created_count += 1
            else:
                skipped_count += 1
        
        self.stdout.write(self.style.SUCCESS(f'Successfully seeded {created_count} achievements'))
        if skipped_count > 0:
            self.stdout.write(self.style.WARNING(f'Skipped {skipped_count} existing achievements'))
