import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import 'guided_workout_plans.dart';
import 'guided_workout_player_screen.dart';

const Color _kRed = Color(0xFFE53935);

class GuidedWorkoutSelectScreen extends StatefulWidget {
  const GuidedWorkoutSelectScreen({super.key});

  @override
  State<GuidedWorkoutSelectScreen> createState() =>
      _GuidedWorkoutSelectScreenState();
}

class _GuidedWorkoutSelectScreenState
    extends State<GuidedWorkoutSelectScreen> {
  String _selectedCategory = 'All';

  static const _categories = [
    'All', 'Full Body', 'Core', 'Upper', 'Lower', 'Cardio'
  ];

  List<GuidedPlan> get _filtered => _selectedCategory == 'All'
      ? kGuidedPlans
      : kGuidedPlans.where((p) => p.category == _selectedCategory).toList();

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Beginner': return Colors.green;
      case 'Intermediate': return Colors.orange;
      default: return _kRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Guided Workouts',
      showBackButton: true,
      showDrawer: false,
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? _kRed : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? _kRed : Colors.grey[300]!),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ),
                );
              },
            ),
          ),

          // Plan cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _PlanCard(
                plan: _filtered[i],
                difficultyColor: _difficultyColor(_filtered[i].difficulty),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        GuidedWorkoutPlayerScreen(plan: _filtered[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final GuidedPlan plan;
  final Color difficultyColor;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.difficultyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header gradient
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kRed.withOpacity(0.85), const Color(0xFFFF7043)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(plan.emoji,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(plan.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(plan.description,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _InfoChip(
                      icon: Icons.timer_outlined,
                      label: '${plan.estimatedMinutes} min'),
                  const SizedBox(width: 8),
                  _InfoChip(
                      icon: Icons.fitness_center_rounded,
                      label: '${plan.totalExercises} exercises'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(plan.difficulty,
                        style: TextStyle(
                            color: difficultyColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.grey[500]),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
    ]);
  }
}
