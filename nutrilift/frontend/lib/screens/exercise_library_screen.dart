import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/exercise_library_provider.dart';
import '../providers/new_workout_provider.dart';
import '../widgets/exercise_card.dart';
import '../widgets/nutrilift_header.dart';
import 'new_workout_screen.dart';

/// Exercise Library Screen
/// 
/// Displays all available exercises with filtering and search capabilities.
/// Users can filter by category, muscle group, equipment, and difficulty,
/// and search by exercise name.
/// 
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filter state
  String? _selectedCategory;
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    // Load exercises on initialization
    Future.microtask(() {
      ref.read(exerciseLibraryProvider.notifier).loadExercises();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(exerciseLibraryProvider.notifier).search(value);
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    ref.read(exerciseLibraryProvider.notifier).filterByCategory(category);
  }

  void _onMuscleGroupSelected(String? muscleGroup) {
    setState(() {
      _selectedMuscleGroup = muscleGroup;
    });
    ref.read(exerciseLibraryProvider.notifier).filterByMuscleGroup(muscleGroup);
  }

  void _onEquipmentSelected(String? equipment) {
    setState(() {
      _selectedEquipment = equipment;
    });
    ref.read(exerciseLibraryProvider.notifier).filterByEquipment(equipment);
  }

  void _onDifficultySelected(String? difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });
    ref.read(exerciseLibraryProvider.notifier).filterByDifficulty(difficulty);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _selectedDifficulty = null;
      _searchController.clear();
    });
    ref.read(exerciseLibraryProvider.notifier).clearAllFilters();
  }

  void _showExerciseDetails(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildExerciseDetailSheet(exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseLibraryProvider);
    final hasActiveFilters = _selectedCategory != null ||
        _selectedMuscleGroup != null ||
        _selectedEquipment != null ||
        _selectedDifficulty != null ||
        _searchController.text.isNotEmpty;

    return NutriLiftScaffold(
      title: 'Exercise Library',
      showBackButton: true,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE53935)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: _selectedCategory ?? 'Category',
                  isSelected: _selectedCategory != null,
                  onTap: () => _showCategoryFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _selectedMuscleGroup ?? 'Muscle',
                  isSelected: _selectedMuscleGroup != null,
                  onTap: () => _showMuscleGroupFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _selectedEquipment ?? 'Equipment',
                  isSelected: _selectedEquipment != null,
                  onTap: () => _showEquipmentFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _selectedDifficulty ?? 'Difficulty',
                  isSelected: _selectedDifficulty != null,
                  onTap: () => _showDifficultyFilter(),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Clear All'),
                    onPressed: _clearAllFilters,
                    backgroundColor: Colors.grey[200],
                    side: BorderSide.none,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Exercise grid
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) => _buildExerciseGrid(exercises),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE53935),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFFE53935) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildExerciseGrid(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ExerciseCard(
          exercise: exercise,
          onTap: () => _showExerciseDetails(exercise),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load exercises',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(exerciseLibraryProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetailSheet(Exercise exercise) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Exercise image
                    if (exercise.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          exercise.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.fitness_center,
                                size: 64,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Exercise name
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Exercise metadata
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMetadataChip(
                          icon: Icons.category,
                          label: exercise.category,
                        ),
                        _buildMetadataChip(
                          icon: Icons.fitness_center,
                          label: exercise.muscleGroup,
                        ),
                        _buildMetadataChip(
                          icon: Icons.build,
                          label: exercise.equipment,
                        ),
                        _buildMetadataChip(
                          icon: Icons.signal_cellular_alt,
                          label: exercise.difficulty,
                          color: _getDifficultyColor(exercise.difficulty),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Instructions
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.instructions,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    // Video link
                    if (exercise.videoUrl != null) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Open video URL
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Video link: Coming soon'),
                              backgroundColor: Color(0xFFE53935),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Watch Video'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                          side: const BorderSide(color: Color(0xFFE53935)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Add to Workout button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Add exercise to new workout and navigate
                        ref.read(newWorkoutProvider.notifier).addExercise(exercise);
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewWorkoutScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color ?? const Color(0xFFE53935)),
      label: Text(label),
      backgroundColor: Colors.grey[100],
      side: BorderSide.none,
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return const Color(0xFFE53935);
    }
  }

  void _showCategoryFilter() {
    _showFilterDialog(
      title: 'Select Category',
      options: ['Strength', 'Cardio', 'Bodyweight'],
      currentValue: _selectedCategory,
      onSelected: _onCategorySelected,
    );
  }

  void _showMuscleGroupFilter() {
    _showFilterDialog(
      title: 'Select Muscle Group',
      options: ['Chest', 'Back', 'Legs', 'Core', 'Arms', 'Shoulders', 'Full Body'],
      currentValue: _selectedMuscleGroup,
      onSelected: _onMuscleGroupSelected,
    );
  }

  void _showEquipmentFilter() {
    _showFilterDialog(
      title: 'Select Equipment',
      options: ['Free Weights', 'Machines', 'Bodyweight', 'Resistance Bands', 'Cardio Equipment'],
      currentValue: _selectedEquipment,
      onSelected: _onEquipmentSelected,
    );
  }

  void _showDifficultyFilter() {
    _showFilterDialog(
      title: 'Select Difficulty',
      options: ['Beginner', 'Intermediate', 'Advanced'],
      currentValue: _selectedDifficulty,
      onSelected: _onDifficultySelected,
    );
  }

  void _showFilterDialog({
    required String title,
    required List<String> options,
    required String? currentValue,
    required Function(String?) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...options.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: currentValue,
                  activeColor: const Color(0xFFE53935),
                  onChanged: (value) {
                    onSelected(value);
                    Navigator.pop(context);
                  },
                );
              }),
              const Divider(),
              ListTile(
                title: const Text('Clear Filter'),
                leading: const Icon(Icons.clear),
                onTap: () {
                  onSelected(null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
