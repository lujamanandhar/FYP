class Challenge {
  final String id;
  final String title;
  final String description;
  final int durationDays;
  final List<String> rules;
  final List<String> objectives;
  final String imageUrl;
  final bool isActive;
  final bool isCompleted;
  final int currentDay;
  final List<DailyTask> todaysTasks;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.rules,
    required this.objectives,
    this.imageUrl = '',
    this.isActive = false,
    this.isCompleted = false,
    this.currentDay = 0,
    this.todaysTasks = const [],
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    int? durationDays,
    List<String>? rules,
    List<String>? objectives,
    String? imageUrl,
    bool? isActive,
    bool? isCompleted,
    int? currentDay,
    List<DailyTask>? todaysTasks,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      rules: rules ?? this.rules,
      objectives: objectives ?? this.objectives,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      currentDay: currentDay ?? this.currentDay,
      todaysTasks: todaysTasks ?? this.todaysTasks,
    );
  }

  double get progressPercentage => currentDay / durationDays;
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final TaskType type;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.type = TaskType.general,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    TaskType? type,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
    );
  }
}

enum TaskType {
  workout,
  nutrition,
  hydration,
  general,
}