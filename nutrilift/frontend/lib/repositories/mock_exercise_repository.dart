import 'exercise_repository.dart';
import '../models/exercise.dart';

/// Mock implementation of [ExerciseRepository] for testing and offline development.
/// 
/// This repository provides mock exercise data and implements filtering logic
/// without requiring a backend connection. It includes a comprehensive set of
/// exercises covering all categories, muscle groups, equipment types, and
/// difficulty levels.
/// 
/// Validates: Requirements 7.9
class MockExerciseRepository implements ExerciseRepository {
  final List<Exercise> _exercises = [];

  /// Creates a mock repository with pre-populated exercise data.
  MockExerciseRepository() {
    _exercises.addAll(_generateMockExercises());
  }

  @override
  Future<List<Exercise>> getExercises({
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    var filtered = List<Exercise>.from(_exercises);

    // Apply category filter
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((e) => 
        e.category.toLowerCase() == category.toLowerCase()
      ).toList();
    }

    // Apply muscle group filter
    if (muscleGroup != null && muscleGroup.isNotEmpty) {
      filtered = filtered.where((e) => 
        e.muscleGroup.toLowerCase() == muscleGroup.toLowerCase()
      ).toList();
    }

    // Apply equipment filter
    if (equipment != null && equipment.isNotEmpty) {
      filtered = filtered.where((e) => 
        e.equipment.toLowerCase() == equipment.toLowerCase()
      ).toList();
    }

    // Apply difficulty filter
    if (difficulty != null && difficulty.isNotEmpty) {
      filtered = filtered.where((e) => 
        e.difficulty.toLowerCase() == difficulty.toLowerCase()
      ).toList();
    }

    // Apply search filter (case-insensitive name search)
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      filtered = filtered.where((e) => 
        e.name.toLowerCase().contains(searchLower)
      ).toList();
    }

    return filtered;
  }

  @override
  Future<Exercise> getExerciseById(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    final exerciseId = int.tryParse(id);
    if (exerciseId == null) {
      throw Exception('Invalid exercise ID: $id');
    }

    final exercise = _exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => throw Exception('Exercise not found with ID: $id'),
    );

    return exercise;
  }

  /// Adds a custom exercise to the mock repository (for testing).
  void addExercise(Exercise exercise) {
    _exercises.add(exercise);
  }

  /// Clears all exercises and resets to default mock data.
  void reset() {
    _exercises.clear();
    _exercises.addAll(_generateMockExercises());
  }

  /// Generates comprehensive mock exercise data.
  List<Exercise> _generateMockExercises() {
    final now = DateTime.now();
    return [
      // Strength - Chest
      Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'A compound upper body exercise targeting the chest',
        instructions: 'Lie on bench, lower bar to chest, press up explosively',
        imageUrl: 'https://example.com/bench-press.jpg',
        videoUrl: 'https://youtube.com/watch?v=bench-press',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 2,
        name: 'Incline Dumbbell Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Targets upper chest with incline angle',
        instructions: 'Set bench to 30-45 degrees, press dumbbells up',
        imageUrl: 'https://example.com/incline-press.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 3,
        name: 'Push-ups',
        category: 'Bodyweight',
        muscleGroup: 'Chest',
        equipment: 'Bodyweight',
        difficulty: 'Beginner',
        description: 'Classic bodyweight chest exercise',
        instructions: 'Lower body until chest nearly touches floor, push back up',
        imageUrl: 'https://example.com/pushups.jpg',
        videoUrl: 'https://youtube.com/watch?v=pushups',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 4,
        name: 'Cable Flyes',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Machines',
        difficulty: 'Intermediate',
        description: 'Isolation exercise for chest using cables',
        instructions: 'Stand between cables, bring handles together in front',
        imageUrl: null,
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),

      // Strength - Back
      Exercise(
        id: 5,
        name: 'Deadlift',
        category: 'Strength',
        muscleGroup: 'Back',
        equipment: 'Free Weights',
        difficulty: 'Advanced',
        description: 'Compound exercise targeting entire posterior chain',
        instructions: 'Lift bar from ground to standing position, keep back straight',
        imageUrl: 'https://example.com/deadlift.jpg',
        videoUrl: 'https://youtube.com/watch?v=deadlift',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 6,
        name: 'Pull-ups',
        category: 'Bodyweight',
        muscleGroup: 'Back',
        equipment: 'Bodyweight',
        difficulty: 'Intermediate',
        description: 'Bodyweight exercise for back and biceps',
        instructions: 'Hang from bar, pull body up until chin over bar',
        imageUrl: 'https://example.com/pullups.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 7,
        name: 'Barbell Row',
        category: 'Strength',
        muscleGroup: 'Back',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Compound rowing movement for back thickness',
        instructions: 'Bend at hips, pull bar to lower chest',
        imageUrl: null,
        videoUrl: 'https://youtube.com/watch?v=barbell-row',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 8,
        name: 'Lat Pulldown',
        category: 'Strength',
        muscleGroup: 'Back',
        equipment: 'Machines',
        difficulty: 'Beginner',
        description: 'Machine exercise for lat development',
        instructions: 'Pull bar down to upper chest, control the return',
        imageUrl: 'https://example.com/lat-pulldown.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),

      // Strength - Legs
      Exercise(
        id: 9,
        name: 'Squats',
        category: 'Strength',
        muscleGroup: 'Legs',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'King of leg exercises, targets entire lower body',
        instructions: 'Lower hips until thighs parallel to ground, drive back up',
        imageUrl: 'https://example.com/squats.jpg',
        videoUrl: 'https://youtube.com/watch?v=squats',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 10,
        name: 'Leg Press',
        category: 'Strength',
        muscleGroup: 'Legs',
        equipment: 'Machines',
        difficulty: 'Beginner',
        description: 'Machine-based leg exercise',
        instructions: 'Push platform away with feet, control the return',
        imageUrl: 'https://example.com/leg-press.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 11,
        name: 'Lunges',
        category: 'Bodyweight',
        muscleGroup: 'Legs',
        equipment: 'Bodyweight',
        difficulty: 'Beginner',
        description: 'Unilateral leg exercise',
        instructions: 'Step forward, lower back knee toward ground',
        imageUrl: null,
        videoUrl: 'https://youtube.com/watch?v=lunges',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 12,
        name: 'Romanian Deadlift',
        category: 'Strength',
        muscleGroup: 'Legs',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Targets hamstrings and glutes',
        instructions: 'Hinge at hips, lower bar along legs, feel hamstring stretch',
        imageUrl: 'https://example.com/rdl.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),

      // Strength - Arms
      Exercise(
        id: 13,
        name: 'Barbell Curl',
        category: 'Strength',
        muscleGroup: 'Arms',
        equipment: 'Free Weights',
        difficulty: 'Beginner',
        description: 'Classic bicep exercise',
        instructions: 'Curl bar up to shoulders, control the descent',
        imageUrl: 'https://example.com/barbell-curl.jpg',
        videoUrl: 'https://youtube.com/watch?v=barbell-curl',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 14,
        name: 'Tricep Dips',
        category: 'Bodyweight',
        muscleGroup: 'Arms',
        equipment: 'Bodyweight',
        difficulty: 'Intermediate',
        description: 'Bodyweight tricep exercise',
        instructions: 'Lower body by bending elbows, push back up',
        imageUrl: null,
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 15,
        name: 'Hammer Curl',
        category: 'Strength',
        muscleGroup: 'Arms',
        equipment: 'Free Weights',
        difficulty: 'Beginner',
        description: 'Targets biceps and forearms',
        instructions: 'Curl dumbbells with neutral grip',
        imageUrl: 'https://example.com/hammer-curl.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 16,
        name: 'Cable Tricep Extension',
        category: 'Strength',
        muscleGroup: 'Arms',
        equipment: 'Machines',
        difficulty: 'Beginner',
        description: 'Isolation exercise for triceps',
        instructions: 'Push cable down, extend elbows fully',
        imageUrl: null,
        videoUrl: 'https://youtube.com/watch?v=tricep-extension',
        createdAt: now,
        updatedAt: now,
      ),

      // Strength - Shoulders
      Exercise(
        id: 17,
        name: 'Shoulder Press',
        category: 'Strength',
        muscleGroup: 'Shoulders',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Compound shoulder exercise',
        instructions: 'Press dumbbells or bar overhead',
        imageUrl: 'https://example.com/shoulder-press.jpg',
        videoUrl: 'https://youtube.com/watch?v=shoulder-press',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 18,
        name: 'Lateral Raise',
        category: 'Strength',
        muscleGroup: 'Shoulders',
        equipment: 'Free Weights',
        difficulty: 'Beginner',
        description: 'Isolation exercise for side delts',
        instructions: 'Raise dumbbells to sides until parallel to ground',
        imageUrl: 'https://example.com/lateral-raise.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 19,
        name: 'Face Pulls',
        category: 'Strength',
        muscleGroup: 'Shoulders',
        equipment: 'Resistance Bands',
        difficulty: 'Beginner',
        description: 'Targets rear delts and upper back',
        instructions: 'Pull rope to face, separate handles at end',
        imageUrl: null,
        videoUrl: 'https://youtube.com/watch?v=face-pulls',
        createdAt: now,
        updatedAt: now,
      ),

      // Strength - Core
      Exercise(
        id: 20,
        name: 'Plank',
        category: 'Bodyweight',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        difficulty: 'Beginner',
        description: 'Isometric core exercise',
        instructions: 'Hold body in straight line on forearms',
        imageUrl: 'https://example.com/plank.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 21,
        name: 'Russian Twist',
        category: 'Bodyweight',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        difficulty: 'Intermediate',
        description: 'Rotational core exercise',
        instructions: 'Sit with feet elevated, rotate torso side to side',
        imageUrl: null,
        videoUrl: 'https://youtube.com/watch?v=russian-twist',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 22,
        name: 'Cable Crunch',
        category: 'Strength',
        muscleGroup: 'Core',
        equipment: 'Machines',
        difficulty: 'Beginner',
        description: 'Weighted ab exercise',
        instructions: 'Kneel and crunch down, pulling cable',
        imageUrl: 'https://example.com/cable-crunch.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),

      // Cardio
      Exercise(
        id: 23,
        name: 'Running',
        category: 'Cardio',
        muscleGroup: 'Full Body',
        equipment: 'Cardio Equipment',
        difficulty: 'Beginner',
        description: 'Classic cardiovascular exercise',
        instructions: 'Run at steady pace or intervals',
        imageUrl: 'https://example.com/running.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 24,
        name: 'Cycling',
        category: 'Cardio',
        muscleGroup: 'Legs',
        equipment: 'Cardio Equipment',
        difficulty: 'Beginner',
        description: 'Low-impact cardio exercise',
        instructions: 'Pedal at consistent pace',
        imageUrl: 'https://example.com/cycling.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 25,
        name: 'Rowing Machine',
        category: 'Cardio',
        muscleGroup: 'Full Body',
        equipment: 'Cardio Equipment',
        difficulty: 'Intermediate',
        description: 'Full body cardio workout',
        instructions: 'Pull handle to chest, extend legs and arms',
        imageUrl: null,
        videoUrl: 'https://youtube.com/watch?v=rowing',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 26,
        name: 'Jump Rope',
        category: 'Cardio',
        muscleGroup: 'Full Body',
        equipment: 'Bodyweight',
        difficulty: 'Intermediate',
        description: 'High-intensity cardio',
        instructions: 'Jump over rope continuously',
        imageUrl: 'https://example.com/jump-rope.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 27,
        name: 'Burpees',
        category: 'Cardio',
        muscleGroup: 'Full Body',
        equipment: 'Bodyweight',
        difficulty: 'Advanced',
        description: 'High-intensity full body exercise',
        instructions: 'Drop to plank, push-up, jump up',
        imageUrl: null,
        videoUrl: 'https://youtube.com/watch?v=burpees',
        createdAt: now,
        updatedAt: now,
      ),

      // Additional exercises for comprehensive coverage
      Exercise(
        id: 28,
        name: 'Mountain Climbers',
        category: 'Cardio',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        difficulty: 'Intermediate',
        description: 'Dynamic core and cardio exercise',
        instructions: 'In plank position, alternate bringing knees to chest',
        imageUrl: 'https://example.com/mountain-climbers.jpg',
        videoUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 29,
        name: 'Box Jumps',
        category: 'Strength',
        muscleGroup: 'Legs',
        equipment: 'Bodyweight',
        difficulty: 'Advanced',
        description: 'Explosive leg power exercise',
        instructions: 'Jump onto elevated platform, step down',
        imageUrl: null,
        videoUrl: 'https://youtube.com/watch?v=box-jumps',
        createdAt: now,
        updatedAt: now,
      ),
      Exercise(
        id: 30,
        name: 'Kettlebell Swing',
        category: 'Strength',
        muscleGroup: 'Full Body',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Dynamic full body exercise',
        instructions: 'Swing kettlebell between legs and up to shoulder height',
        imageUrl: 'https://example.com/kettlebell-swing.jpg',
        videoUrl: 'https://youtube.com/watch?v=kettlebell-swing',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
