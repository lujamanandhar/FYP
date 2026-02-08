from django.core.management.base import BaseCommand
from workouts.models import Exercise, Gym


class Command(BaseCommand):
    help = 'Seeds the database with initial exercise and gym data'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding exercises...')
        
        exercises_data = [
            # Full Body Exercises
            {
                'name': 'Burpees',
                'description': 'Full body exercise combining a squat, push-up, and jump',
                'category': 'FULL_BODY',
                'difficulty': 'INTERMEDIATE',
                'instructions': '1. Start in standing position\n2. Drop into squat\n3. Kick feet back to plank\n4. Do a push-up\n5. Jump feet back to squat\n6. Jump up with arms overhead',
                'calories_per_minute': 10.0,
            },
            {
                'name': 'Mountain Climbers',
                'description': 'Dynamic full body exercise in plank position',
                'category': 'FULL_BODY',
                'difficulty': 'BEGINNER',
                'instructions': '1. Start in plank position\n2. Bring one knee to chest\n3. Quickly switch legs\n4. Continue alternating',
                'calories_per_minute': 8.0,
            },
            
            # Arms Exercises
            {
                'name': 'Push-ups',
                'description': 'Classic upper body exercise',
                'category': 'ARMS',
                'difficulty': 'BEGINNER',
                'instructions': '1. Start in plank position\n2. Lower body until chest nearly touches floor\n3. Push back up\n4. Keep core tight',
                'calories_per_minute': 7.0,
            },
            {
                'name': 'Bicep Curls',
                'description': 'Isolation exercise for biceps',
                'category': 'ARMS',
                'difficulty': 'BEGINNER',
                'instructions': '1. Hold dumbbells at sides\n2. Curl weights up to shoulders\n3. Lower slowly\n4. Keep elbows stationary',
                'calories_per_minute': 4.0,
            },
            {
                'name': 'Tricep Dips',
                'description': 'Bodyweight exercise for triceps',
                'category': 'ARMS',
                'difficulty': 'INTERMEDIATE',
                'instructions': '1. Place hands on bench behind you\n2. Lower body by bending elbows\n3. Push back up\n4. Keep back close to bench',
                'calories_per_minute': 5.0,
            },
            
            # Legs Exercises
            {
                'name': 'Squats',
                'description': 'Fundamental lower body exercise',
                'category': 'LEGS',
                'difficulty': 'BEGINNER',
                'instructions': '1. Stand with feet shoulder-width apart\n2. Lower hips back and down\n3. Keep chest up\n4. Push through heels to stand',
                'calories_per_minute': 6.0,
            },
            {
                'name': 'Lunges',
                'description': 'Single-leg lower body exercise',
                'category': 'LEGS',
                'difficulty': 'BEGINNER',
                'instructions': '1. Step forward with one leg\n2. Lower hips until both knees bent at 90°\n3. Push back to start\n4. Alternate legs',
                'calories_per_minute': 6.0,
            },
            {
                'name': 'Deadlifts',
                'description': 'Compound exercise for posterior chain',
                'category': 'LEGS',
                'difficulty': 'ADVANCED',
                'instructions': '1. Stand with feet hip-width apart\n2. Bend at hips and knees to grip bar\n3. Lift by extending hips and knees\n4. Keep back straight',
                'calories_per_minute': 8.0,
            },
            
            # Core Exercises
            {
                'name': 'Plank',
                'description': 'Isometric core strengthening exercise',
                'category': 'CORE',
                'difficulty': 'BEGINNER',
                'instructions': '1. Start in forearm plank position\n2. Keep body in straight line\n3. Engage core\n4. Hold position',
                'calories_per_minute': 3.0,
            },
            {
                'name': 'Crunches',
                'description': 'Classic abdominal exercise',
                'category': 'CORE',
                'difficulty': 'BEGINNER',
                'instructions': '1. Lie on back with knees bent\n2. Place hands behind head\n3. Lift shoulders off ground\n4. Lower slowly',
                'calories_per_minute': 4.0,
            },
            {
                'name': 'Russian Twists',
                'description': 'Rotational core exercise',
                'category': 'CORE',
                'difficulty': 'INTERMEDIATE',
                'instructions': '1. Sit with knees bent, feet off ground\n2. Lean back slightly\n3. Rotate torso side to side\n4. Touch ground on each side',
                'calories_per_minute': 5.0,
            },
            
            # Cardio Exercises
            {
                'name': 'Running',
                'description': 'Cardiovascular endurance exercise',
                'category': 'CARDIO',
                'difficulty': 'BEGINNER',
                'instructions': '1. Maintain steady pace\n2. Land midfoot\n3. Keep arms at 90°\n4. Breathe rhythmically',
                'calories_per_minute': 10.0,
            },
            {
                'name': 'Jumping Jacks',
                'description': 'Full body cardio exercise',
                'category': 'CARDIO',
                'difficulty': 'BEGINNER',
                'instructions': '1. Start with feet together\n2. Jump feet apart while raising arms\n3. Jump back to start\n4. Maintain rhythm',
                'calories_per_minute': 8.0,
            },
            {
                'name': 'Jump Rope',
                'description': 'High-intensity cardio exercise',
                'category': 'CARDIO',
                'difficulty': 'INTERMEDIATE',
                'instructions': '1. Hold rope handles at sides\n2. Swing rope overhead\n3. Jump as rope passes under feet\n4. Land softly on balls of feet',
                'calories_per_minute': 12.0,
            },
            
            # Upper Body Exercises
            {
                'name': 'Bench Press',
                'description': 'Compound upper body pressing exercise',
                'category': 'UPPER_BODY',
                'difficulty': 'INTERMEDIATE',
                'instructions': '1. Lie on bench with feet flat\n2. Grip bar slightly wider than shoulders\n3. Lower bar to chest\n4. Press back up',
                'calories_per_minute': 6.0,
            },
            {
                'name': 'Pull-ups',
                'description': 'Bodyweight back and arm exercise',
                'category': 'UPPER_BODY',
                'difficulty': 'ADVANCED',
                'instructions': '1. Hang from bar with overhand grip\n2. Pull body up until chin over bar\n3. Lower with control\n4. Keep core engaged',
                'calories_per_minute': 8.0,
            },
            
            # Lower Body Exercises
            {
                'name': 'Leg Press',
                'description': 'Machine-based lower body exercise',
                'category': 'LOWER_BODY',
                'difficulty': 'BEGINNER',
                'instructions': '1. Sit in machine with feet on platform\n2. Push platform away by extending legs\n3. Lower with control\n4. Keep back against pad',
                'calories_per_minute': 5.0,
            },
            {
                'name': 'Calf Raises',
                'description': 'Isolation exercise for calves',
                'category': 'LOWER_BODY',
                'difficulty': 'BEGINNER',
                'instructions': '1. Stand with balls of feet on edge\n2. Raise heels as high as possible\n3. Lower slowly\n4. Keep legs straight',
                'calories_per_minute': 3.0,
            },
        ]
        
        created_count = 0
        for exercise_data in exercises_data:
            exercise, created = Exercise.objects.get_or_create(
                name=exercise_data['name'],
                defaults=exercise_data
            )
            if created:
                created_count += 1
                self.stdout.write(f'  Created: {exercise.name}')
        
        self.stdout.write(self.style.SUCCESS(f'Successfully created {created_count} exercises'))
        
        # Seed some gyms
        self.stdout.write('Seeding gyms...')
        
        gyms_data = [
            {
                'name': 'FitZone Gym',
                'location': 'Downtown',
                'address': '123 Main Street, City Center',
                'rating': 4.5,
                'phone': '+1234567890',
            },
            {
                'name': 'PowerHouse Fitness',
                'location': 'North District',
                'address': '456 Oak Avenue, North Side',
                'rating': 4.8,
                'phone': '+1234567891',
            },
            {
                'name': 'Elite Training Center',
                'location': 'East Side',
                'address': '789 Elm Road, East District',
                'rating': 4.3,
                'phone': '+1234567892',
            },
            {
                'name': '24/7 Fitness Hub',
                'location': 'West End',
                'address': '321 Pine Street, West Quarter',
                'rating': 4.6,
                'phone': '+1234567893',
            },
        ]
        
        gym_count = 0
        for gym_data in gyms_data:
            gym, created = Gym.objects.get_or_create(
                name=gym_data['name'],
                defaults=gym_data
            )
            if created:
                gym_count += 1
                self.stdout.write(f'  Created: {gym.name}')
        
        self.stdout.write(self.style.SUCCESS(f'Successfully created {gym_count} gyms'))
        self.stdout.write(self.style.SUCCESS('Database seeding completed!'))
