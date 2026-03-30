/// Pre-built guided workout plans.
/// Each plan has a list of GuidedExercise steps with name, duration, and rest.

class GuidedExercise {
  final String name;
  final String muscleGroup;
  final int durationSeconds; // 0 = rep-based (show reps instead of timer)
  final int reps; // used when durationSeconds == 0
  final int restSeconds;
  final String instruction;

  const GuidedExercise({
    required this.name,
    required this.muscleGroup,
    this.durationSeconds = 40,
    this.reps = 0,
    this.restSeconds = 15,
    required this.instruction,
  });
}

class GuidedPlan {
  final String id;
  final String name;
  final String description;
  final String difficulty; // Beginner / Intermediate / Advanced
  final String category; // Full Body / Upper / Lower / Core / Cardio
  final int estimatedMinutes;
  final String emoji;
  final List<GuidedExercise> exercises;

  const GuidedPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.estimatedMinutes,
    required this.emoji,
    required this.exercises,
  });

  int get totalExercises => exercises.length;
}

const List<GuidedPlan> kGuidedPlans = [
  GuidedPlan(
    id: 'beginner_full_body',
    name: '10-Min Beginner Full Body',
    description: 'Perfect for beginners. No equipment needed.',
    difficulty: 'Beginner',
    category: 'Full Body',
    estimatedMinutes: 10,
    emoji: '',
    exercises: [
      GuidedExercise(name: 'Jumping Jacks', muscleGroup: 'Full Body', durationSeconds: 30, restSeconds: 10, instruction: 'Jump feet wide while raising arms overhead. Keep a steady rhythm.'),
      GuidedExercise(name: 'Push-ups', muscleGroup: 'Chest', durationSeconds: 0, reps: 10, restSeconds: 15, instruction: 'Keep body straight. Lower chest to ground, push back up.'),
      GuidedExercise(name: 'Bodyweight Squats', muscleGroup: 'Legs', durationSeconds: 0, reps: 15, restSeconds: 15, instruction: 'Feet shoulder-width apart. Squat down until thighs are parallel to floor.'),
      GuidedExercise(name: 'Plank Hold', muscleGroup: 'Core', durationSeconds: 30, restSeconds: 15, instruction: 'Hold a straight body position on forearms. Engage your core.'),
      GuidedExercise(name: 'Mountain Climbers', muscleGroup: 'Core', durationSeconds: 30, restSeconds: 15, instruction: 'In plank position, alternate driving knees to chest quickly.'),
      GuidedExercise(name: 'Glute Bridges', muscleGroup: 'Glutes', durationSeconds: 0, reps: 15, restSeconds: 15, instruction: 'Lie on back, feet flat. Push hips up, squeeze glutes at top.'),
      GuidedExercise(name: 'High Knees', muscleGroup: 'Cardio', durationSeconds: 30, restSeconds: 10, instruction: 'Run in place, driving knees up to hip height alternately.'),
    ],
  ),
  GuidedPlan(
    id: 'core_blast',
    name: '8-Min Core Blast',
    description: 'Intense core workout. Builds abs and stability.',
    difficulty: 'Intermediate',
    category: 'Core',
    estimatedMinutes: 8,
    emoji: '',
    exercises: [
      GuidedExercise(name: 'Crunches', muscleGroup: 'Abs', durationSeconds: 0, reps: 20, restSeconds: 10, instruction: 'Lie on back, hands behind head. Curl shoulders toward knees.'),
      GuidedExercise(name: 'Bicycle Crunches', muscleGroup: 'Abs', durationSeconds: 40, restSeconds: 15, instruction: 'Alternate elbow to opposite knee in a cycling motion.'),
      GuidedExercise(name: 'Plank Hold', muscleGroup: 'Core', durationSeconds: 45, restSeconds: 15, instruction: 'Hold straight body on forearms. Don\'t let hips sag.'),
      GuidedExercise(name: 'Leg Raises', muscleGroup: 'Lower Abs', durationSeconds: 0, reps: 15, restSeconds: 15, instruction: 'Lie flat, raise straight legs to 90°, lower slowly.'),
      GuidedExercise(name: 'Russian Twists', muscleGroup: 'Obliques', durationSeconds: 40, restSeconds: 15, instruction: 'Sit at 45°, rotate torso side to side. Keep feet off ground.'),
      GuidedExercise(name: 'Side Plank Left', muscleGroup: 'Obliques', durationSeconds: 30, restSeconds: 10, instruction: 'Balance on left forearm and feet. Keep body straight.'),
      GuidedExercise(name: 'Side Plank Right', muscleGroup: 'Obliques', durationSeconds: 30, restSeconds: 15, instruction: 'Balance on right forearm and feet. Keep body straight.'),
    ],
  ),
  GuidedPlan(
    id: 'upper_body_push',
    name: '15-Min Upper Body Push',
    description: 'Chest, shoulders and triceps. No equipment.',
    difficulty: 'Intermediate',
    category: 'Upper',
    estimatedMinutes: 15,
    emoji: '',
    exercises: [
      GuidedExercise(name: 'Push-ups', muscleGroup: 'Chest', durationSeconds: 0, reps: 15, restSeconds: 20, instruction: 'Standard push-up. Keep elbows at 45° from body.'),
      GuidedExercise(name: 'Wide Push-ups', muscleGroup: 'Chest', durationSeconds: 0, reps: 12, restSeconds: 20, instruction: 'Hands wider than shoulders. Targets outer chest.'),
      GuidedExercise(name: 'Diamond Push-ups', muscleGroup: 'Triceps', durationSeconds: 0, reps: 10, restSeconds: 20, instruction: 'Hands form diamond shape. Elbows stay close to body.'),
      GuidedExercise(name: 'Pike Push-ups', muscleGroup: 'Shoulders', durationSeconds: 0, reps: 10, restSeconds: 20, instruction: 'Hips high in inverted V. Lower head toward ground.'),
      GuidedExercise(name: 'Tricep Dips', muscleGroup: 'Triceps', durationSeconds: 0, reps: 12, restSeconds: 20, instruction: 'Use a chair. Lower body by bending elbows, push back up.'),
      GuidedExercise(name: 'Decline Push-ups', muscleGroup: 'Upper Chest', durationSeconds: 0, reps: 10, restSeconds: 20, instruction: 'Feet elevated on chair. Targets upper chest.'),
      GuidedExercise(name: 'Shoulder Taps', muscleGroup: 'Shoulders', durationSeconds: 30, restSeconds: 15, instruction: 'In push-up position, tap each shoulder alternately. Stay stable.'),
    ],
  ),
  GuidedPlan(
    id: 'leg_day',
    name: '12-Min Leg Burner',
    description: 'Quads, hamstrings and glutes. Feel the burn.',
    difficulty: 'Intermediate',
    category: 'Lower',
    estimatedMinutes: 12,
    emoji: '',
    exercises: [
      GuidedExercise(name: 'Bodyweight Squats', muscleGroup: 'Quads', durationSeconds: 0, reps: 20, restSeconds: 15, instruction: 'Feet shoulder-width. Squat deep, drive through heels.'),
      GuidedExercise(name: 'Jump Squats', muscleGroup: 'Quads', durationSeconds: 0, reps: 12, restSeconds: 20, instruction: 'Squat down then explode upward. Land softly.'),
      GuidedExercise(name: 'Reverse Lunges', muscleGroup: 'Legs', durationSeconds: 0, reps: 12, restSeconds: 15, instruction: 'Step back into lunge. Alternate legs. Keep front knee over ankle.'),
      GuidedExercise(name: 'Glute Bridges', muscleGroup: 'Glutes', durationSeconds: 0, reps: 20, restSeconds: 15, instruction: 'Lie on back. Push hips up, hold 1 second at top.'),
      GuidedExercise(name: 'Wall Sit', muscleGroup: 'Quads', durationSeconds: 45, restSeconds: 20, instruction: 'Back against wall, thighs parallel to floor. Hold position.'),
      GuidedExercise(name: 'Calf Raises', muscleGroup: 'Calves', durationSeconds: 0, reps: 25, restSeconds: 10, instruction: 'Rise onto toes, lower slowly. Use wall for balance.'),
      GuidedExercise(name: 'Sumo Squats', muscleGroup: 'Inner Thighs', durationSeconds: 0, reps: 15, restSeconds: 15, instruction: 'Wide stance, toes out. Squat deep, squeeze inner thighs.'),
    ],
  ),
  GuidedPlan(
    id: 'hiit_cardio',
    name: '20-Min HIIT Cardio',
    description: 'High intensity intervals. Maximum calorie burn.',
    difficulty: 'Advanced',
    category: 'Cardio',
    estimatedMinutes: 20,
    emoji: '',
    exercises: [
      GuidedExercise(name: 'Burpees', muscleGroup: 'Full Body', durationSeconds: 0, reps: 10, restSeconds: 20, instruction: 'Squat, jump back to plank, push-up, jump forward, jump up.'),
      GuidedExercise(name: 'High Knees', muscleGroup: 'Cardio', durationSeconds: 40, restSeconds: 20, instruction: 'Sprint in place, knees to hip height. Pump arms.'),
      GuidedExercise(name: 'Jump Squats', muscleGroup: 'Legs', durationSeconds: 0, reps: 15, restSeconds: 20, instruction: 'Explosive squat jumps. Land softly, immediately squat again.'),
      GuidedExercise(name: 'Mountain Climbers', muscleGroup: 'Core', durationSeconds: 40, restSeconds: 20, instruction: 'Fast alternating knee drives in plank position.'),
      GuidedExercise(name: 'Jumping Lunges', muscleGroup: 'Legs', durationSeconds: 0, reps: 12, restSeconds: 20, instruction: 'Lunge then jump, switching legs in air. Land in opposite lunge.'),
      GuidedExercise(name: 'Plank to Push-up', muscleGroup: 'Full Body', durationSeconds: 40, restSeconds: 20, instruction: 'Alternate between forearm plank and push-up position.'),
      GuidedExercise(name: 'Box Jumps (or Squat Jumps)', muscleGroup: 'Legs', durationSeconds: 0, reps: 10, restSeconds: 20, instruction: 'Jump onto box or do explosive squat jumps. Land with soft knees.'),
      GuidedExercise(name: 'Sprint in Place', muscleGroup: 'Cardio', durationSeconds: 30, restSeconds: 30, instruction: 'All-out sprint in place. Maximum effort for 30 seconds.'),
    ],
  ),
];
