"""
Management command to add more exercises for all muscle groups and difficulty levels.
Usage: python manage.py add_more_exercises
"""
from django.core.management.base import BaseCommand
from workouts.models import Exercise


EXERCISES = [
    # ── CORE (Abs) ──────────────────────────────────────────────────────────
    ('Plank', 'Hold a straight body position on forearms and toes.', 'CORE', 'Bodyweight', 'BEGINNER', 'Bodyweight', 5.0),
    ('Crunches', 'Lie on back, curl upper body toward knees.', 'CORE', 'Bodyweight', 'BEGINNER', 'Bodyweight', 5.5),
    ('Leg Raises', 'Lie flat, raise straight legs to 90 degrees.', 'CORE', 'Bodyweight', 'BEGINNER', 'Bodyweight', 5.0),
    ('Dead Bug', 'Lie on back, extend opposite arm and leg while keeping lower back flat.', 'CORE', 'Bodyweight', 'BEGINNER', 'Bodyweight', 4.5),
    ('Bicycle Crunches', 'Alternate elbow to opposite knee in cycling motion.', 'CORE', 'Bodyweight', 'INTERMEDIATE', 'Bodyweight', 7.0),
    ('Russian Twists', 'Sit at 45°, rotate torso side to side holding weight.', 'CORE', 'Bodyweight', 'INTERMEDIATE', 'Bodyweight', 6.5),
    ('Hanging Knee Raises', 'Hang from bar, raise knees to chest.', 'CORE', 'Bodyweight', 'INTERMEDIATE', 'Bodyweight', 7.5),
    ('Cable Crunches', 'Kneel at cable machine, crunch down with rope attachment.', 'CORE', 'Strength', 'INTERMEDIATE', 'Machines', 7.0),
    ('Dragon Flag', 'Lie on bench, raise entire body keeping it straight.', 'CORE', 'Bodyweight', 'ADVANCED', 'Bodyweight', 9.0),
    ('Ab Wheel Rollout', 'Roll wheel forward from knees, extend body, return.', 'CORE', 'Bodyweight', 'ADVANCED', 'Bodyweight', 8.5),
    ('Toes to Bar', 'Hang from bar, raise straight legs to touch bar.', 'CORE', 'Bodyweight', 'ADVANCED', 'Bodyweight', 9.5),

    # ── ARMS ────────────────────────────────────────────────────────────────
    ('Dumbbell Curl', 'Stand with dumbbells, curl up squeezing bicep.', 'ARMS', 'Strength', 'BEGINNER', 'Free Weights', 5.0),
    ('Tricep Dips', 'Hands on bench behind you, lower and raise body.', 'ARMS', 'Bodyweight', 'BEGINNER', 'Bodyweight', 5.5),
    ('Hammer Curl', 'Curl dumbbells with neutral grip (thumbs up).', 'ARMS', 'Strength', 'BEGINNER', 'Free Weights', 5.0),
    ('Overhead Tricep Extension', 'Hold dumbbell overhead, lower behind head, extend.', 'ARMS', 'Strength', 'INTERMEDIATE', 'Free Weights', 6.0),
    ('Preacher Curl', 'Rest arms on preacher bench, curl barbell up.', 'ARMS', 'Strength', 'INTERMEDIATE', 'Machines', 6.5),
    ('Skull Crushers', 'Lie on bench, lower barbell to forehead, extend.', 'ARMS', 'Strength', 'INTERMEDIATE', 'Barbell', 7.0),
    ('Cable Curl', 'Stand at cable machine, curl bar up.', 'ARMS', 'Strength', 'INTERMEDIATE', 'Machines', 6.0),
    ('Close Grip Bench Press', 'Bench press with narrow grip targeting triceps.', 'ARMS', 'Strength', 'ADVANCED', 'Barbell', 8.0),
    ('Chin Ups', 'Hang from bar with underhand grip, pull up.', 'ARMS', 'Bodyweight', 'ADVANCED', 'Bodyweight', 8.5),
    ('21s Curl', 'Do 7 half curls bottom, 7 half curls top, 7 full curls.', 'ARMS', 'Strength', 'ADVANCED', 'Barbell', 7.5),

    # ── CHEST ───────────────────────────────────────────────────────────────
    ('Push Ups', 'Standard push up, lower chest to floor, push up.', 'CHEST', 'Bodyweight', 'BEGINNER', 'Bodyweight', 7.0),
    ('Dumbbell Chest Press', 'Lie on bench, press dumbbells up from chest.', 'CHEST', 'Strength', 'BEGINNER', 'Free Weights', 7.5),
    ('Chest Fly', 'Lie on bench, open arms wide, bring together over chest.', 'CHEST', 'Strength', 'INTERMEDIATE', 'Free Weights', 6.5),
    ('Incline Push Ups', 'Push ups with hands elevated on bench.', 'CHEST', 'Bodyweight', 'BEGINNER', 'Bodyweight', 6.0),
    ('Incline Bench Press', 'Bench press on inclined bench targeting upper chest.', 'CHEST', 'Strength', 'INTERMEDIATE', 'Barbell', 8.5),
    ('Cable Crossover', 'Pull cables from high to low crossing in front.', 'CHEST', 'Strength', 'INTERMEDIATE', 'Machines', 7.0),
    ('Decline Push Ups', 'Push ups with feet elevated targeting lower chest.', 'CHEST', 'Bodyweight', 'INTERMEDIATE', 'Bodyweight', 7.5),
    ('Barbell Bench Press', 'Classic bench press with barbell.', 'CHEST', 'Strength', 'ADVANCED', 'Barbell', 9.0),
    ('Dips', 'On parallel bars, lower body by bending elbows.', 'CHEST', 'Bodyweight', 'ADVANCED', 'Bodyweight', 8.5),
    ('Plyometric Push Ups', 'Explosive push up, clap hands at top.', 'CHEST', 'Bodyweight', 'ADVANCED', 'Bodyweight', 10.0),

    # ── LEGS ────────────────────────────────────────────────────────────────
    ('Bodyweight Squat', 'Stand feet shoulder-width, lower until thighs parallel.', 'LEGS', 'Bodyweight', 'BEGINNER', 'Bodyweight', 6.0),
    ('Walking Lunges', 'Step forward into lunge, alternate legs walking forward.', 'LEGS', 'Bodyweight', 'BEGINNER', 'Bodyweight', 6.5),
    ('Calf Raises', 'Stand on edge of step, raise and lower on toes.', 'LEGS', 'Bodyweight', 'BEGINNER', 'Bodyweight', 4.5),
    ('Wall Sit', 'Back against wall, thighs parallel to floor, hold.', 'LEGS', 'Bodyweight', 'BEGINNER', 'Bodyweight', 5.0),
    ('Goblet Squat', 'Hold dumbbell at chest, squat deep.', 'LEGS', 'Strength', 'INTERMEDIATE', 'Free Weights', 7.5),
    ('Leg Press', 'Push platform away with feet on leg press machine.', 'LEGS', 'Strength', 'INTERMEDIATE', 'Machines', 8.0),
    ('Leg Curl', 'Lie face down, curl legs up on machine.', 'LEGS', 'Strength', 'INTERMEDIATE', 'Machines', 6.5),
    ('Barbell Squat', 'Squat with barbell on upper back.', 'LEGS', 'Strength', 'ADVANCED', 'Barbell', 10.0),
    ('Pistol Squat', 'Single leg squat, other leg extended forward.', 'LEGS', 'Bodyweight', 'ADVANCED', 'Bodyweight', 9.0),
    ('Jump Squats', 'Squat then explode upward into jump.', 'LEGS', 'Bodyweight', 'ADVANCED', 'Bodyweight', 10.5),

    # ── SHOULDERS ───────────────────────────────────────────────────────────
    ('Dumbbell Shoulder Press', 'Press dumbbells overhead from shoulder height.', 'SHOULDERS', 'Strength', 'BEGINNER', 'Free Weights', 7.0),
    ('Lateral Raises', 'Raise dumbbells out to sides to shoulder height.', 'SHOULDERS', 'Strength', 'BEGINNER', 'Free Weights', 5.5),
    ('Front Raises', 'Raise dumbbells forward to shoulder height.', 'SHOULDERS', 'Strength', 'BEGINNER', 'Free Weights', 5.5),
    ('Face Pulls', 'Pull rope attachment to face level, elbows high.', 'SHOULDERS', 'Strength', 'INTERMEDIATE', 'Machines', 6.0),
    ('Arnold Press', 'Rotate dumbbells from front to overhead press.', 'SHOULDERS', 'Strength', 'INTERMEDIATE', 'Free Weights', 7.5),
    ('Upright Row', 'Pull barbell up along body to chin level.', 'SHOULDERS', 'Strength', 'INTERMEDIATE', 'Barbell', 7.0),
    ('Barbell Overhead Press', 'Press barbell from shoulders to overhead.', 'SHOULDERS', 'Strength', 'ADVANCED', 'Barbell', 9.0),
    ('Pike Push Ups', 'In downward dog position, lower head toward floor.', 'SHOULDERS', 'Bodyweight', 'ADVANCED', 'Bodyweight', 8.0),
    ('Handstand Push Ups', 'In handstand against wall, lower and press up.', 'SHOULDERS', 'Bodyweight', 'ADVANCED', 'Bodyweight', 11.0),

    # ── BACK ────────────────────────────────────────────────────────────────
    ('Superman', 'Lie face down, raise arms and legs simultaneously.', 'BACK', 'Bodyweight', 'BEGINNER', 'Bodyweight', 4.5),
    ('Dumbbell Row', 'One hand on bench, row dumbbell to hip.', 'BACK', 'Strength', 'BEGINNER', 'Free Weights', 6.5),
    ('Lat Pulldown', 'Pull bar down to chest on lat pulldown machine.', 'BACK', 'Strength', 'BEGINNER', 'Machines', 7.0),
    ('Seated Cable Row', 'Pull cable handle to abdomen while seated.', 'BACK', 'Strength', 'INTERMEDIATE', 'Machines', 7.5),
    ('T-Bar Row', 'Straddle bar, row weight up to chest.', 'BACK', 'Strength', 'INTERMEDIATE', 'Barbell', 8.0),
    ('Bent Over Row', 'Hinge forward, row barbell to lower chest.', 'BACK', 'Strength', 'INTERMEDIATE', 'Barbell', 8.5),
    ('Pull Ups', 'Hang from bar, pull body up until chin over bar.', 'BACK', 'Bodyweight', 'ADVANCED', 'Bodyweight', 9.0),
    ('Deadlift', 'Lift barbell from floor to hip height.', 'BACK', 'Strength', 'ADVANCED', 'Barbell', 11.0),
    ('Rack Pull', 'Deadlift from elevated position targeting upper back.', 'BACK', 'Strength', 'ADVANCED', 'Barbell', 10.0),

    # ── GLUTES ──────────────────────────────────────────────────────────────
    ('Glute Bridge', 'Lie on back, drive hips up squeezing glutes.', 'GLUTES', 'Bodyweight', 'BEGINNER', 'Bodyweight', 5.0),
    ('Donkey Kicks', 'On all fours, kick one leg back and up.', 'GLUTES', 'Bodyweight', 'BEGINNER', 'Bodyweight', 4.5),
    ('Fire Hydrants', 'On all fours, lift knee out to side.', 'GLUTES', 'Bodyweight', 'BEGINNER', 'Bodyweight', 4.0),
    ('Sumo Squat', 'Wide stance squat targeting inner thighs and glutes.', 'GLUTES', 'Bodyweight', 'BEGINNER', 'Bodyweight', 6.0),
    ('Hip Thrust', 'Back on bench, barbell on hips, drive hips up.', 'GLUTES', 'Strength', 'INTERMEDIATE', 'Barbell', 7.5),
    ('Cable Kickback', 'Attach ankle to cable, kick leg back.', 'GLUTES', 'Strength', 'INTERMEDIATE', 'Machines', 5.5),
    ('Step Ups', 'Step onto elevated platform, drive through heel.', 'GLUTES', 'Bodyweight', 'INTERMEDIATE', 'Bodyweight', 7.0),
    ('Bulgarian Split Squat', 'Rear foot elevated, lower into deep lunge.', 'GLUTES', 'Strength', 'ADVANCED', 'Bodyweight', 9.0),
    ('Barbell Hip Thrust', 'Heavy barbell hip thrust for maximum glute activation.', 'GLUTES', 'Strength', 'ADVANCED', 'Barbell', 9.5),
    ('Single Leg Deadlift', 'Balance on one leg, hinge forward with weight.', 'GLUTES', 'Strength', 'ADVANCED', 'Free Weights', 8.5),

    # ── CARDIO ──────────────────────────────────────────────────────────────
    ('Jumping Jacks', 'Jump feet wide while raising arms overhead.', 'CARDIO', 'Cardio', 'BEGINNER', 'Bodyweight', 8.0),
    ('High Knees', 'Run in place driving knees up to hip height.', 'CARDIO', 'Cardio', 'BEGINNER', 'Bodyweight', 9.0),
    ('Jump Rope', 'Skip rope continuously.', 'CARDIO', 'Cardio', 'BEGINNER', 'Cardio Equipment', 11.0),
    ('Rowing Machine', 'Drive with legs, lean back, pull handle to chest.', 'CARDIO', 'Cardio', 'BEGINNER', 'Cardio Equipment', 9.0),
    ('Burpees', 'Squat, jump back to plank, push up, jump up.', 'CARDIO', 'Cardio', 'INTERMEDIATE', 'Bodyweight', 12.0),
    ('Box Jumps', 'Jump onto box with both feet, land softly.', 'CARDIO', 'Cardio', 'INTERMEDIATE', 'Bodyweight', 10.0),
    ('Mountain Climbers', 'In plank, drive knees alternately toward chest.', 'CARDIO', 'Cardio', 'INTERMEDIATE', 'Bodyweight', 10.5),
    ('Cycling', 'Pedal on stationary bike at moderate to high intensity.', 'CARDIO', 'Cardio', 'INTERMEDIATE', 'Cardio Equipment', 9.5),
    ('Sprint Intervals', 'Sprint at max effort 20s, rest 10s. Repeat 8 rounds.', 'CARDIO', 'Cardio', 'ADVANCED', 'Bodyweight', 14.0),
    ('Battle Ropes', 'Alternate arm waves with heavy ropes.', 'CARDIO', 'Cardio', 'ADVANCED', 'Resistance Bands', 13.0),
    ('Assault Bike', 'Full body cycling with arm handles at max effort.', 'CARDIO', 'Cardio', 'ADVANCED', 'Cardio Equipment', 15.0),

    # ── FULL BODY ────────────────────────────────────────────────────────────
    ('Kettlebell Swing', 'Hinge at hips, swing kettlebell to shoulder height.', 'FULL_BODY', 'Strength', 'BEGINNER', 'Free Weights', 9.0),
    ('Dumbbell Thruster', 'Front squat into overhead press in one movement.', 'FULL_BODY', 'Strength', 'INTERMEDIATE', 'Free Weights', 10.0),
    ('Clean and Press', 'Pull barbell from floor to shoulders, press overhead.', 'FULL_BODY', 'Strength', 'ADVANCED', 'Barbell', 12.0),
    ('Turkish Get Up', 'From lying to standing while holding weight overhead.', 'FULL_BODY', 'Strength', 'ADVANCED', 'Free Weights', 8.0),
    ('Man Makers', 'Push up, row each arm, squat, press overhead.', 'FULL_BODY', 'Strength', 'ADVANCED', 'Free Weights', 12.0),
]


class Command(BaseCommand):
    help = 'Add more exercises to the database'

    def handle(self, *args, **options):
        created = 0
        skipped = 0
        for name, desc, muscle, category, difficulty, equipment, cpm in EXERCISES:
            _, c = Exercise.objects.get_or_create(
                name=name,
                defaults={
                    'description': desc,
                    'muscle_group': muscle,
                    'category': category,
                    'difficulty': difficulty,
                    'equipment': equipment,
                    'calories_per_minute': cpm,
                }
            )
            if c:
                created += 1
            else:
                skipped += 1

        self.stdout.write(self.style.SUCCESS(
            f'Done! Created {created} new exercises, skipped {skipped} existing.'
        ))
        for mg in ['CORE', 'ARMS', 'CHEST', 'LEGS', 'SHOULDERS', 'BACK', 'GLUTES', 'CARDIO', 'FULL_BODY']:
            count = Exercise.objects.filter(muscle_group=mg).count()
            self.stdout.write(f'  {mg}: {count} exercises')
