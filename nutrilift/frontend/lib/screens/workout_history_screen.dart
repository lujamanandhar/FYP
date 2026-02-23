import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../widgets/nutrilift_header.dart';
import '../widgets/workout_card.dart';
import '../widgets/date_range_filter_dialog.dart';
import '../providers/workout_history_provider.dart';
import '../models/workout_log.dart';

/// Workout History Screen
/// 
/// Displays a list of all logged workouts in reverse chronological order.
/// Features:
/// - Pull-to-refresh functionality
/// - Date range filtering
/// - PR badges on workouts with new personal records
/// - FAB to navigate to new workout screen
/// 
/// Validates: Requirements 1.1, 1.5, 1.6
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll events to detect when user reaches bottom
  /// 
  /// Triggers loadMore() when user scrolls to within 200 pixels of the bottom.
  /// Prevents multiple simultaneous load requests with _isLoadingMore flag.
  /// 
  /// Validates: Requirements 12.2
  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 200.0; // Load more when within 200 pixels of bottom

    if (currentScroll >= maxScroll - threshold) {
      _loadMoreWorkouts();
    }
  }

  /// Load more workouts for pagination
  /// 
  /// Called when user scrolls near the bottom of the list.
  /// Sets loading flag to prevent duplicate requests.
  /// 
  /// Validates: Requirements 12.2
  Future<void> _loadMoreWorkouts() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(workoutHistoryProvider.notifier).loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutHistoryState = ref.watch(workoutHistoryProvider);

    return NutriLiftScaffold(
      title: 'Workout History',
      showBackButton: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewWorkout,
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildDateFilterButton(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFFE53935),
              child: workoutHistoryState.when(
                data: (workouts) => _buildWorkoutList(workouts),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build date filter button
  Widget _buildDateFilterButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showDateRangeDialog,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_getFilterButtonText()),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFE53935)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          if (_selectedDateFrom != null || _selectedDateTo != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.clear),
              color: const Color(0xFFE53935),
              tooltip: 'Clear filter',
            ),
          ],
        ],
      ),
    );
  }

  /// Get the text for the filter button based on selected dates
  String _getFilterButtonText() {
    if (_selectedDateFrom != null && _selectedDateTo != null) {
      return '${DateFormat('MMM dd').format(_selectedDateFrom!)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateTo!)}';
    } else if (_selectedDateFrom != null) {
      return 'From: ${DateFormat('MMM dd, yyyy').format(_selectedDateFrom!)}';
    } else if (_selectedDateTo != null) {
      return 'To: ${DateFormat('MMM dd, yyyy').format(_selectedDateTo!)}';
    }
    return 'Filter by Date Range';
  }

  /// Build workout list
  Widget _buildWorkoutList(List<WorkoutLog> workouts) {
    if (workouts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: workouts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the bottom when loading more
        if (index == workouts.length) {
          return _buildLoadingMoreIndicator();
        }

        return WorkoutCard(
          workout: workouts[index],
          onTap: () => _navigateToWorkoutDetail(workouts[index]),
        );
      },
    );
  }

  /// Build loading indicator for pagination
  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your workouts to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToNewWorkout,
            icon: const Icon(Icons.add),
            label: const Text('Log Workout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
      ),
    );
  }

  /// Build error state
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
            'Failed to load workouts',
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
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    await ref.read(workoutHistoryProvider.notifier).refresh();
  }

  /// Show date range dialog
  Future<void> _showDateRangeDialog() async {
    final result = await showDialog<DateRangeFilterResult>(
      context: context,
      builder: (context) => DateRangeFilterDialog(
        initialDateFrom: _selectedDateFrom,
        initialDateTo: _selectedDateTo,
      ),
    );

    if (result != null) {
      if (result.cleared) {
        await _clearDateFilter();
      } else {
        setState(() {
          _selectedDateFrom = result.dateFrom;
          _selectedDateTo = result.dateTo;
        });
        // Use dateFrom for filtering (dateTo not yet supported by backend)
        if (result.dateFrom != null) {
          await ref.read(workoutHistoryProvider.notifier).filterByDateRange(result.dateFrom!);
        } else {
          await ref.read(workoutHistoryProvider.notifier).clearDateFilter();
        }
      }
    }
  }

  /// Clear date filter
  Future<void> _clearDateFilter() async {
    setState(() {
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    await ref.read(workoutHistoryProvider.notifier).clearDateFilter();
  }

  /// Navigate to new workout screen
  void _navigateToNewWorkout() {
    // TODO: Navigate to new workout screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New workout screen coming soon!'),
        backgroundColor: Color(0xFFE53935),
      ),
    );
  }

  /// Navigate to workout detail
  void _navigateToWorkoutDetail(WorkoutLog workout) {
    // TODO: Navigate to workout detail screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing workout: ${workout.workoutName ?? 'Workout'}'),
        backgroundColor: const Color(0xFFE53935),
      ),
    );
  }
}
