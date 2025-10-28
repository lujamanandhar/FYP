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
    },
    {
      'name': 'Squats',
      'reps': '3 x 20',
      'desc': 'Strengthens legs and glutes.',
      'icon': Icons.directions_run,
      'completed': false,
    },
    {
      'name': 'Plank',
      'reps': '3 x 1 min',
      'desc': 'Core stability exercise.',
      'icon': Icons.accessibility_new,
      'completed': false,
    },
    {
      'name': 'Jumping Jacks',
      'reps': '3 x 30',
      'desc': 'Full body cardio move.',
      'icon': Icons.sports_handball,
      'completed': false,
    },
  ];

  int? expandedIndex;

  void toggleCompleted(int index) {
    setState(() {
      workouts[index]['completed'] = !(workouts[index]['completed'] as bool);
    });
  }

  void showDetailsSheet(int index) {
    final workout = workouts[index];
    showModalBottomSheet(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
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
    int completedCount = workouts.where((w) => w['completed'] as bool).length;
    final progress = workouts.isEmpty ? 0.0 : completedCount / workouts.length;

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

            // Animated list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  final completed = workout['completed'] as bool;
                  final isExpanded = expandedIndex == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: completed
                          ? LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400])
                          : LinearGradient(colors: [Colors.white, Colors.white]),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // expand/collapse item
                          setState(() {
                            expandedIndex = isExpanded ? null : index;
                          });
                        },
                        onLongPress: () => showDetailsSheet(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: completed
                                      ? LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white24])
                                      : LinearGradient(colors: [Colors.green.shade100, Colors.green.shade50]),
                                ),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 300),
                                  scale: completed ? 1.06 : 1.0,
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.transparent,
                                    child: Icon(
                                      workout['icon'] as IconData,
                                      color: completed ? Colors.white : Colors.green.shade700,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 300),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: completed ? Colors.white : Colors.black,
                                        decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                                      ),
                                      child: Text(workout['name'] as String),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          workout['reps'] as String,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: completed ? Colors.white70 : Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // collapsed description preview
                                        Expanded(
                                          child: AnimatedOpacity(
                                            duration: const Duration(milliseconds: 300),
                                            opacity: completed ? 0.85 : 0.9,
                                            child: Text(
                                              workout['desc'] as String,
                                              maxLines: isExpanded ? 3 : 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: completed ? Colors.white70 : Colors.black54,
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    // Expanded extra actions
                                    AnimatedCrossFade(
                                      duration: const Duration(milliseconds: 300),
                                      firstChild: const SizedBox.shrink(),
                                      secondChild: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => toggleCompleted(index),
                                              icon: Icon(
                                                completed ? Icons.undo : Icons.check,
                                                size: 18,
                                              ),
                                              label: Text(completed ? 'Undo' : 'Complete'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: completed ? Colors.white : Colors.green.shade700,
                                                foregroundColor: completed ? Colors.green.shade700 : Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            OutlinedButton.icon(
                                              onPressed: () => showDetailsSheet(index),
                                              icon: const Icon(Icons.info_outline, size: 18),
                                              label: const Text('Details'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: completed ? Colors.white : Colors.green.shade700,
                                                side: BorderSide(color: completed ? Colors.white24 : Colors.green.shade200),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                    ),
                                  ],
                                ),
                              ),
                              // animated checkbox icon
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                                child: IconButton(
                                  key: ValueKey<bool>(completed),
                                  onPressed: () => toggleCompleted(index),
                                  icon: Icon(
                                    completed ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: completed ? Colors.white : Colors.green.shade700,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_right,
                                color: completed ? Colors.white70 : Colors.green.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}