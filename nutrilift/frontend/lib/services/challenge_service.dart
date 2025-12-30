import '../models/challenge_models.dart';

class ChallengeService {
  static List<Challenge> _challenges = [
    Challenge(
      id: '1',
      title: '30 Days Fitness Challenge',
      description: 'Transform your lifestyle with our comprehensive 30-day challenge. Focus on nutrition, exercise, and mindful habits.',
      durationDays: 30,
      rules: [
        'Log meals daily',
        'Complete daily challenges',
        'Share progress weekly',
        'Stay hydrated (8 glasses/day)',
      ],
      objectives: [
        'Build healthy eating habits',
        'Establish workout routine',
        'Improve overall fitness',
        'Create lasting lifestyle changes',
      ],
    ),
    Challenge(
      id: '2',
      title: '7 Days Water Challenge',
      description: 'Stay hydrated and boost your energy with our 7-day water intake challenge.',
      durationDays: 7,
      rules: [
        'Drink 8 glasses of water daily',
        'Track your intake',
        'No sugary drinks',
      ],
      objectives: [
        'Improve hydration habits',
        'Boost energy levels',
        'Clear skin',
      ],
    ),
    Challenge(
      id: '3',
      title: '14 Days Mindful Eating',
      description: 'Learn to eat mindfully and develop a healthy relationship with food.',
      durationDays: 14,
      rules: [
        'Eat without distractions',
        'Chew slowly',
        'Log your meals',
        'Practice gratitude before meals',
      ],
      objectives: [
        'Develop mindful eating habits',
        'Improve digestion',
        'Better food awareness',
      ],
    ),
  ];

  static List<Challenge> getAvailableChallenges() {
    return _challenges.where((c) => !c.isActive && !c.isCompleted).toList();
  }

  static Challenge? getActiveChallenge() {
    try {
      return _challenges.firstWhere((c) => c.isActive);
    } catch (e) {
      return null;
    }
  }

  static void joinChallenge(String challengeId) {
    // Mark all other challenges as inactive
    _challenges = _challenges.map((c) => c.copyWith(isActive: false)).toList();
    
    // Mark the selected challenge as active and set up today's tasks
    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex != -1) {
      _challenges[challengeIndex] = _challenges[challengeIndex].copyWith(
        isActive: true,
        currentDay: 1,
        todaysTasks: _generateTodaysTasks(challengeId),
      );
    }
  }

  static void completeTask(String challengeId, String taskId) {
    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex != -1) {
      final challenge = _challenges[challengeIndex];
      final updatedTasks = challenge.todaysTasks.map((task) {
        if (task.id == taskId) {
          return task.copyWith(isCompleted: true);
        }
        return task;
      }).toList();

      _challenges[challengeIndex] = challenge.copyWith(todaysTasks: updatedTasks);

      // Check if all tasks are completed
      if (updatedTasks.every((task) => task.isCompleted)) {
        _advanceToNextDay(challengeId);
      }
    }
  }

  static void _advanceToNextDay(String challengeId) {
    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex != -1) {
      final challenge = _challenges[challengeIndex];
      final nextDay = challenge.currentDay + 1;

      if (nextDay > challenge.durationDays) {
        // Challenge completed
        _challenges[challengeIndex] = challenge.copyWith(
          isCompleted: true,
          isActive: false,
        );
      } else {
        // Move to next day
        _challenges[challengeIndex] = challenge.copyWith(
          currentDay: nextDay,
          todaysTasks: _generateTodaysTasks(challengeId),
        );
      }
    }
  }

  static List<DailyTask> _generateTodaysTasks(String challengeId) {
    switch (challengeId) {
      case '1': // 30 Days Fitness
        return [
          DailyTask(
            id: 'task1',
            title: 'Morning Workout',
            description: 'Complete 30 minutes of exercise',
            type: TaskType.workout,
          ),
          DailyTask(
            id: 'task2',
            title: 'Protein Intake',
            description: 'Consume adequate protein with meals',
            type: TaskType.nutrition,
          ),
          DailyTask(
            id: 'task3',
            title: 'Water Intake',
            description: 'Drink 8 glasses of water',
            type: TaskType.hydration,
          ),
          DailyTask(
            id: 'task4',
            title: 'Evening Walk',
            description: 'Take a 15-minute walk',
            type: TaskType.workout,
          ),
        ];
      case '2': // 7 Days Water
        return [
          DailyTask(
            id: 'water1',
            title: 'Morning Water',
            description: 'Drink 2 glasses upon waking',
            type: TaskType.hydration,
          ),
          DailyTask(
            id: 'water2',
            title: 'Midday Hydration',
            description: 'Drink 3 glasses before lunch',
            type: TaskType.hydration,
          ),
          DailyTask(
            id: 'water3',
            title: 'Evening Water',
            description: 'Drink 3 glasses in the evening',
            type: TaskType.hydration,
          ),
        ];
      case '3': // 14 Days Mindful Eating
        return [
          DailyTask(
            id: 'mindful1',
            title: 'Mindful Breakfast',
            description: 'Eat breakfast without distractions',
            type: TaskType.nutrition,
          ),
          DailyTask(
            id: 'mindful2',
            title: 'Gratitude Practice',
            description: 'Practice gratitude before each meal',
            type: TaskType.general,
          ),
          DailyTask(
            id: 'mindful3',
            title: 'Slow Eating',
            description: 'Chew each bite 20 times',
            type: TaskType.nutrition,
          ),
        ];
      default:
        return [];
    }
  }
}