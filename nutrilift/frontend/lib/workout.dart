import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final List<Map<String, dynamic>> workouts = [
    {
      'name': 'Push Ups',
      'reps': '3 x 15',
      'desc': 'Great for chest, shoulders, and triceps.',
      'icon': Icons.fitness_center,
      'completed': false,
      'category': 'Upper Body',
    },
    {
      'name': 'Pull Ups',
      'reps': '3 x 8',
      'desc': 'Back and biceps focus.',
      'icon': Icons.back_hand,
      'completed': false,
      'category': 'Upper Body',
    },
    {
      'name': 'Squats',
      'reps': '3 x 20',
      'desc': 'Strengthens legs and glutes.',
      'icon': Icons.directions_run,
      'completed': false,
      'category': 'Lower Body',
    },
    {
      'name': 'Lunges',
      'reps': '3 x 12 each leg',
      'desc': 'Works quads and glutes.',
      'icon': Icons.trending_down,
      'completed': false,
      'category': 'Lower Body',
    },
    {
      'name': 'Plank',
      'reps': '3 x 1 min',
      'desc': 'Core stability exercise.',
      'icon': Icons.accessibility_new,
      'completed': false,
      'category': 'Core',
    },
    {
      'name': 'Jumping Jacks',
      'reps': '3 x 30',
      'desc': 'Full body cardio move.',
      'icon': Icons.sports_handball,
      'completed': false,
      'category': 'Cardio',
    },
    {
      'name': 'Burpees',
      'reps': '3 x 12',
      'desc': 'Full body strength and cardio exercise.',
      'icon': Icons.whatshot,
      'completed': false,
      'category': 'Cardio',
    },
    {
      'name': 'Downward Dog',
      'reps': 'Hold 1 min',
      'desc': 'Yoga pose for shoulders and hamstrings.',
      'icon': Icons.self_improvement,
      'completed': false,
      'category': 'Yoga',
    },
    {
      'name': 'Child Pose',
      'reps': 'Hold 1-2 min',
      'desc': 'Relaxing yoga stretch.',
      'icon': Icons.airline_seat_recline_normal,
      'completed': false,
      'category': 'Yoga',
    },
  ];

  int? expandedIndex;

  // centralize animation settings
  static const Duration kAnimDuration = Duration(milliseconds: 360);
  static const Curve kAnimCurve = Curves.easeInOutCubic;

  void toggleCompleted(int index) {
    setState(() {
      workouts[index]['completed'] = !(workouts[index]['completed'] as bool);
    });
  }

  void showDetailsSheet(int index) {
    final workout = workouts[index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.36,
          minChildSize: 0.28,
          maxChildSize: 0.85,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: (workout['completed'] as bool)
                                ? [Colors.green.shade700, Colors.green.shade400]
                                : [Colors.green.shade300, Colors.green.shade100],
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          workout['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout['name'] as String,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              workout['reps'] as String,
                              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          toggleCompleted(index);
                        },
                        icon: Icon(
                          (workout['completed'] as bool) ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: (workout['completed'] as bool) ? Colors.green.shade700 : Colors.grey,
                          size: 28,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    workout['desc'] as String,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      toggleCompleted(index);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: Text((workout['completed'] as bool) ? 'Mark as not done' : 'Mark as completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int completedCount = workouts.where((w) => w['completed'] as bool).length;
    final double progress = workouts.isEmpty ? 0.0 : completedCount / workouts.length;

    // build ordered unique categories
    final List<String> categories = <String>[];
    for (var w in workouts) {
      final c = w['category'] as String? ?? 'General';
      if (!categories.contains(c)) categories.add(c);
    }

    Widget buildCategoryHeader(String category, int done, int total) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '$done/$total',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    List<Widget> buildItemsForCategory(String category) {
      final List<Widget> items = [];
      final indices = <int>[];
      for (var i = 0; i < workouts.length; i++) {
        if ((workouts[i]['category'] as String? ?? 'General') == category) {
          indices.add(i);
        }
      }

      final int catDone = indices.where((i) => workouts[i]['completed'] as bool).length;
      items.add(buildCategoryHeader(category, catDone, indices.length));

      for (final idx in indices) {
        final workout = workouts[idx];
        final completed = workout['completed'] as bool;
        final isExpanded = expandedIndex == idx;

        items.add(
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  expandedIndex = isExpanded ? null : idx;
                });
              },
              onLongPress: () => showDetailsSheet(idx),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: completed ? Colors.green.shade700 : Colors.green.shade50,
                      child: Icon(
                        workout['icon'] as IconData,
                        color: completed ? Colors.white : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout['name'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: completed ? Colors.grey.shade600 : Colors.black,
                              decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workout['reps'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: completed ? Colors.grey : Colors.green.shade700,
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 8),
                            Text(
                              workout['desc'] as String,
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => toggleCompleted(idx),
                                  icon: Icon(completed ? Icons.undo : Icons.check, size: 16),
                                  label: Text(completed ? 'Undo' : 'Complete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: completed ? Colors.white : Colors.green.shade700,
                                    foregroundColor: completed ? Colors.green.shade700 : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => showDetailsSheet(idx),
                                  icon: const Icon(Icons.info_outline, size: 16),
                                  label: const Text('Details'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => toggleCompleted(idx),
                      icon: Icon(
                        completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: completed ? Colors.green.shade700 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return items;
    }

    final List<Widget> children = <Widget>[];
    for (final category in categories) {
      children.addAll(buildItemsForCategory(category));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '$completedCount/${workouts.length} Done',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.green[50],
        child: Column(
          children: [
            // Animated progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 7,
                              color: Colors.green.shade700,
                              backgroundColor: Colors.green.shade100,
                            ),
                          ),
                          Text('${(value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Today\'s Routine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Complete the following exercises', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List of grouped items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}