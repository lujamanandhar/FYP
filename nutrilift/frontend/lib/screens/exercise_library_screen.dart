import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/nutrilift_header.dart';
import '../widgets/exercise_card.dart';
import '../providers/exercise_library_provider.dart';
import '../models/exercise.dart';

/// Exercise Library Screen
/// 
/// Displays a browsable and filterable library of exercises.
/// Features:
/// - Search by exercise name
/// - Filter by category, muscle group, equipment, difficulty
/// - Exercise detail view
/// - Selection mode for adding to workouts
/// 
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  final bool selectionMode;

  const ExerciseLibraryScreen({
    Key? key,
    this.selectionMode = false,
  }) : super(key: key);

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  String? _selectedDifficulty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exerciseLibraryProvider);

    return NutriLiftScaffold(
      title: widget.selectionMode ? 'Select Exercise' : 'Exercise Library',
      showBackButton: true,
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: exercisesState.when(
              data: (exercises) => _buildExerciseGrid(exercises),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
          ),
        ),
        onChanged: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Category',
            value: _selectedCategory,
            options: ['Strength', 'Cardio', 'Bodyweight'],
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Muscle',
            value: _selectedMuscleGroup,
            options: ['Chest', 'Back', 'Legs', 'Core', 'Arms', 'Shoulders', 'Full Body'],
            onSelected: (value) {
              setState(() {
                _selectedMuscleGroup = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Equipment',
            value: _selectedEquipment,
            options: ['Free Weights', 'Machines', 'Bodyweight', 'Resistance Bands', 'Cardio Equipment'],
            onSelected: (value) {
              setState(() {
                _selectedEquipment = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Difficulty',
            value: _selectedDifficulty,
            options: ['Beginner', 'Intermediate', 'Advanced'],
            onSelected: (value) {
              setState(() {
                _selectedDifficulty = value;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onSelected,
  }) {
    return FilterChip(
      label: Text(value ?? label),
      selected: value != null,
      onSelected: (_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Select $label'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null)
                  ListTile(
                    title: const Text('Clear'),
                    leading: const Icon(Icons.clear),
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(null);
                    },
                  ),
                ...options.map((option) => ListTile(
                  title: Text(option),
                  selected: value == option,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(option);
                  },
                )).toList(),
              ],
            ),
          ),
        );
      },
      selectedColor: const Color(0xFFE53935).withOpacity(0.2),
      checkmarkColor: const Color(0xFFE53935),
    );
  }

  Widget _buildExerciseGrid(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return _buildEmptyState();
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
        return ExerciseCard(
          exercise: exercises[index],
          onTap: () => _handleExerciseTap(exercises[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load exercises',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(exerciseLibraryProvider.notifier).loadExercises();
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
    );
  }

  void _applyFilters() {
    ref.read(exerciseLibraryProvider.notifier).loadExercises(
      category: _selectedCategory,
      muscleGroup: _selectedMuscleGroup,
      equipment: _selectedEquipment,
      difficulty: _selectedDifficulty,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );
  }

  void _handleExerciseTap(Exercise exercise) {
    if (widget.selectionMode) {
      Navigator.pop(context, exercise);
    } else {
      _showExerciseDetail(exercise);
    }
  }

  void _showExerciseDetail(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(exercise.category),
                    backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
                  ),
                  Chip(
                    label: Text(exercise.muscleGroup),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                  Chip(
                    label: Text(exercise.difficulty),
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                  Chip(
                    label: Text(exercise.equipment),
                    backgroundColor: Colors.orange.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
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
                style: const TextStyle(fontSize: 16),
              ),
              if (widget.selectionMode) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, exercise);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add to Workout'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
