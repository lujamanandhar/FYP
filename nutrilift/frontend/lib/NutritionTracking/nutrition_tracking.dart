import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/nutrilift_header.dart';
import '../services/dashboard_service.dart';
import '../services/dashboard_refresh_service.dart';
import 'providers/nutrition_providers.dart';
import 'models/nutrition_progress.dart';
import 'models/intake_log.dart';
import 'models/food_item.dart';
import 'widgets/error_retry_widget.dart';

class NutritionTracking extends StatelessWidget {
  const NutritionTracking({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const NutritionTrackerHome();
  }
}

class NutritionTrackerHome extends ConsumerStatefulWidget {
  const NutritionTrackerHome({Key? key}) : super(key: key);

  @override
  ConsumerState<NutritionTrackerHome> createState() => _NutritionTrackerHomeState();
}

class _NutritionTrackerHomeState extends ConsumerState<NutritionTrackerHome> {
  int _selectedIndex = 0; 
  DateTime selectedDate = DateTime.now();
  bool _showAddMealScreen = false;
  String _selectedMealTypeForAdd = 'Breakfast';
  bool _isInMealSection = true; 
  String? _selectedMacro;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final dashboardService = DashboardService();
      final streak = await dashboardService.getCurrentStreak();
      if (mounted) {
        setState(() {
          _currentStreak = streak;
        });
      }
    } catch (e) {
      print('Error loading streak: $e');
    }
  } 

  Widget _getCurrentScreen() {
    if (_showAddMealScreen) {
      return AddMealScreen(
        onBack: () {
          setState(() {
            _showAddMealScreen = false;
          });
        },
        initialMealType: _selectedMealTypeForAdd,
      );
    }
    
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return const Center(child: Text('Workout Screen'));
      case 2:
        return _buildHomeScreen(); 
      case 3:
        return const Center(child: Text('Profile Screen'));
      default:
        return _buildHomeScreen();
    }
  }

  bool _isToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  bool _isPast() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isBefore(today);
  }

  bool _isFuture() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAfter(today);
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.subtract(const Duration(days: 1));
                    });
                    // Invalidate providers to refresh data for new date
                    ref.invalidate(dailyProgressProvider);
                    ref.invalidate(intakeLogsProvider);
                  },
                ),
                Text(
                  '${_getMonthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.add(const Duration(days: 1));
                    });
                    // Invalidate providers to refresh data for new date
                    ref.invalidate(dailyProgressProvider);
                    ref.invalidate(intakeLogsProvider);
                  },
                ),
              ],
            ),
          ),

          _buildMacroCards(),

          const SizedBox(height: 24),

          if (_isPast()) ..._buildPastMeals(),
          if (_isToday()) ..._buildTodayMeals(),
          if (_isFuture()) ..._buildFutureMeals(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMacroCards() {
    final progressAsync = ref.watch(dailyProgressProvider(selectedDate));
    final goalsAsync = ref.watch(nutritionGoalsProvider);

    return progressAsync.when(
      data: (progress) {
        return goalsAsync.when(
          data: (goals) {
            final protein = progress?.totalProtein.toStringAsFixed(0) ?? '0';
            final carbs = progress?.totalCarbs.toStringAsFixed(0) ?? '0';
            final fats = progress?.totalFats.toStringAsFixed(0) ?? '0';
            
            final proteinTarget = goals.dailyProtein.toStringAsFixed(0);
            final carbsTarget = goals.dailyCarbs.toStringAsFixed(0);
            final fatsTarget = goals.dailyFats.toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showMacroOverview('Protein'),
                      child: _buildMacroCard('Protein', '${protein}g', '/${proteinTarget}g'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showMacroOverview('Carbs'),
                      child: _buildMacroCard('Carbs', '${carbs}g', '/${carbsTarget}g'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showMacroOverview('Fats'),
                      child: _buildMacroCard('Fats', '${fats}g', '/${fatsTarget}g'),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildLoadingMacroCards(),
          error: (error, stack) => _buildErrorMacroCards(error.toString()),
        );
      },
      loading: () => _buildLoadingMacroCards(),
      error: (error, stack) => _buildErrorMacroCards(error.toString()),
    );
  }

  Widget _buildLoadingMacroCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildMacroCard('Protein', '...', '/...')),
          const SizedBox(width: 8),
          Expanded(child: _buildMacroCard('Carbs', '...', '/...')),
          const SizedBox(width: 8),
          Expanded(child: _buildMacroCard('Fats', '...', '/...')),
        ],
      ),
    );
  }

  Widget _buildErrorMacroCards(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ErrorRetryWidget(
        errorMessage: error,
        isCompact: true,
        onRetry: () {
          // Invalidate providers to retry loading
          ref.invalidate(dailyProgressProvider);
          ref.invalidate(nutritionGoalsProvider);
        },
      ),
    );
  }

  List<Widget> _buildPastMeals() {
    final intakeLogsAsync = ref.watch(intakeLogsProvider(selectedDate));
    
    return intakeLogsAsync.when(
      data: (logs) => _buildMealSectionsFromLogs(logs, false),
      loading: () => [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ],
      error: (error, stack) => [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ErrorRetryWidget(
            errorMessage: error.toString(),
            isCompact: true,
            onRetry: () {
              ref.invalidate(intakeLogsProvider);
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTodayMeals() {
    final intakeLogsAsync = ref.watch(intakeLogsProvider(selectedDate));
    
    return intakeLogsAsync.when(
      data: (logs) {
        print('📊 Building today meals with ${logs.length} logs');
        final sections = _buildMealSectionsFromLogs(logs, true);
        print('📊 Created ${sections.length} meal sections');
        return sections;
      },
      loading: () {
        print('⏳ Loading intake logs...');
        return [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ];
      },
      error: (error, stack) {
        print('❌ Error loading intake logs: $error');
        return [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ErrorRetryWidget(
              errorMessage: error.toString(),
              isCompact: true,
              onRetry: () {
                ref.invalidate(intakeLogsProvider);
              },
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _buildFutureMeals() {
    return [
      _buildMealSection('Breakfast', 0, [], true),
      _buildMealSection('Lunch', 0, [], true),
      _buildMealSection('Dinner', 0, [], true),
    ];
  }

  List<Widget> _buildMealSectionsFromLogs(List<IntakeLog> logs, bool showAddButton) {
    // Group logs by entry type
    final breakfastLogs = logs.where((log) => log.entryType == 'meal' && (log.description?.toLowerCase().contains('breakfast') ?? false)).toList();
    final lunchLogs = logs.where((log) => log.entryType == 'meal' && (log.description?.toLowerCase().contains('lunch') ?? false)).toList();
    final dinnerLogs = logs.where((log) => log.entryType == 'meal' && (log.description?.toLowerCase().contains('dinner') ?? false)).toList();
    final snackLogs = logs.where((log) => log.entryType == 'snack').toList();
    
    // Calculate calories for each meal type
    final breakfastCalories = breakfastLogs.fold<double>(0, (sum, log) => sum + log.calories).toInt();
    final lunchCalories = lunchLogs.fold<double>(0, (sum, log) => sum + log.calories).toInt();
    final dinnerCalories = dinnerLogs.fold<double>(0, (sum, log) => sum + log.calories).toInt();

    return [
      _buildMealSection('Breakfast', breakfastCalories, breakfastLogs, showAddButton),
      _buildMealSection('Lunch', lunchCalories, lunchLogs, showAddButton),
      _buildMealSection('Dinner', dinnerCalories, dinnerLogs, showAddButton),
      if (snackLogs.isNotEmpty)
        _buildMealSection(
          'Snacks',
          snackLogs.fold<double>(0, (sum, log) => sum + log.calories).toInt(),
          snackLogs,
          showAddButton,
        ),
    ];
  }

  Widget _buildMacroCard(String label, String value, String target) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            target,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String title, int calories, List<IntakeLog> logs, bool showAddButton) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$calories cal',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...logs.map((log) => _buildFoodItem(
            log.foodItemDetails?.name ?? 'Food Item',
            '${log.quantity.toStringAsFixed(0)}${log.unit}, ${log.calories.toStringAsFixed(0)} cal',
            log: log,
          )),
          if (showAddButton) 
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMealTypeForAdd = title == 'Snacks' ? 'Snack' : title;
                  _showAddMealScreen = true;
                });
              },
              child: _buildAddFoodButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildAddFoodButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE53935), style: BorderStyle.solid, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '+ Add Food',
          style: TextStyle(
            color: Color(0xFFE53935),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(String name, String details, {IntakeLog? log}) {
    // Check if the selected date is in the past (cannot edit past data)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isPastDate = selected.isBefore(today);

    // Get image URL from log's food item if available
    final imageUrl = log?.foodItemDetails?.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.fastfood, size: 24);
                      },
                    ),
                  )
                : const Icon(Icons.fastfood, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  details,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (log != null && !isPastDate)
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Color(0xFFE53935)),
              onPressed: () => _editLoggedFood(log),
            )
          else if (log != null && isPastDate)
            Icon(Icons.lock, size: 20, color: Colors.grey[400])
          else
            const Icon(Icons.open_in_new, size: 20),
        ],
      ),
    );
  }

  Future<void> _editLoggedFood(IntakeLog log) async {
    // Check if the selected date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    if (selected.isBefore(today)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot edit past data. Past entries are read-only.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show dialog to edit quantity
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildEditQuantityDialog(log),
    );

    if (result == null) return; // User cancelled

    // Check if user wants to delete
    if (result['delete'] == true) {
      if (log.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot delete: Invalid log ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      try {
        final repository = ref.read(nutritionRepositoryProvider);
        await repository.deleteIntakeLog(log.id!);

        // Invalidate providers to refresh data
        ref.invalidate(intakeLogsProvider);
        ref.invalidate(dailyProgressProvider);
        
        // Notify home page to refresh dashboard
        DashboardRefreshService().notifyRefresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Food deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting food: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Otherwise, update the log
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      
      // Update intake log with new values
      final updatedLog = log.copyWith(
        quantity: result['quantity'],
        unit: result['unit'],
        entryType: result['entryType'],
        description: result['description'],
      );

      await repository.updateIntakeLog(updatedLog);

      // Invalidate providers to refresh data
      ref.invalidate(intakeLogsProvider);
      ref.invalidate(dailyProgressProvider);
      
      // Notify home page to refresh dashboard
      DashboardRefreshService().notifyRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEditQuantityDialog(IntakeLog log) {
    final TextEditingController quantityController = TextEditingController(
      text: log.quantity.toStringAsFixed(0),
    );
    String selectedUnit = log.unit;
    String selectedMealType = log.description ?? 'Breakfast';
    String selectedEntryType = log.entryType;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with delete button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Food Entry',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.foodItemDetails?.name ?? 'Food Item',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('Delete Food Entry'),
                              content: const Text(
                                'Are you sure you want to delete this food entry?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    Navigator.of(context).pop({'delete': true});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Type Section
                      const Text(
                        'Meal Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedMealType,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                          items: [
                            {'value': 'Breakfast', 'icon': Icons.wb_sunny_outlined},
                            {'value': 'Lunch', 'icon': Icons.lunch_dining_outlined},
                            {'value': 'Dinner', 'icon': Icons.dinner_dining_outlined},
                            {'value': 'Snack', 'icon': Icons.cookie_outlined},
                          ].map((item) {
                            return DropdownMenuItem(
                              value: item['value'] as String,
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    size: 20,
                                    color: const Color(0xFFE53935),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item['value'] as String,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedMealType = value!;
                              selectedEntryType = value == 'Snack' ? 'snack' : 'meal';
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Quantity Section
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.scale_outlined,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedUnit,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                items: ['g', 'ml', 'oz', 'cup', 'piece']
                                    .map((unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(
                                            unit,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedUnit = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Nutritional values are calculated per 100g',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Footer Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final quantity = double.tryParse(quantityController.text);
                            if (quantity == null || quantity <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please enter a valid quantity'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).pop({
                              'quantity': quantity,
                              'unit': selectedUnit,
                              'entryType': selectedEntryType,
                              'description': selectedMealType,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showMacroOverview(String macro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MacroOverviewSheet(
        macro: macro,
        selectedDate: selectedDate,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      streakCount: _currentStreak,
      body: _getCurrentScreen(),
    );
  }
}

class MacroOverviewSheet extends ConsumerStatefulWidget {
  final String macro;
  final DateTime selectedDate;
  final VoidCallback onClose;

  const MacroOverviewSheet({
    Key? key,
    required this.macro,
    required this.selectedDate,
    required this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<MacroOverviewSheet> createState() => _MacroOverviewSheetState();
}

class _MacroOverviewSheetState extends ConsumerState<MacroOverviewSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _targetValue = 120.0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentGoal();
  }

  void _loadCurrentGoal() {
    final goalsAsync = ref.read(nutritionGoalsProvider);
    goalsAsync.whenData((goals) {
      setState(() {
        switch (widget.macro) {
          case 'Protein':
            _targetValue = goals.dailyProtein;
            break;
          case 'Carbs':
            _targetValue = goals.dailyCarbs;
            break;
          case 'Fats':
            _targetValue = goals.dailyFats;
            break;
        }
      });
    });
  }

  Future<void> _saveGoal() async {
    print('🎯 Starting _saveGoal for ${widget.macro}');
    print('   Target value: $_targetValue');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goalsAsync = ref.read(nutritionGoalsProvider);
      
      print('🎯 Goals async state: ${goalsAsync.runtimeType}');
      
      // Handle AsyncValue to get the actual goals
      final goals = goalsAsync.when(
        data: (data) {
          print('🎯 Goals data received: ${data.toJson()}');
          return data;
        },
        loading: () {
          print('❌ Goals are still loading');
          throw Exception('Goals are still loading');
        },
        error: (error, stack) {
          print('❌ Goals error: $error');
          throw error;
        },
      );
      
      print('🎯 Current goals:');
      print('   ID: ${goals.id}');
      print('   Protein: ${goals.dailyProtein}');
      print('   Carbs: ${goals.dailyCarbs}');
      print('   Fats: ${goals.dailyFats}');
      
      final repository = ref.read(nutritionRepositoryProvider);
      
      // Check if goals have an ID - if not, create new goals
      if (goals.id == null) {
        print('⚠️ Goals have no ID, creating new goals');
        
        // Create new goals with the target value
        final newGoals = goals.copyWith(
          dailyProtein: widget.macro == 'Protein' ? _targetValue : goals.dailyProtein,
          dailyCarbs: widget.macro == 'Carbs' ? _targetValue : goals.dailyCarbs,
          dailyFats: widget.macro == 'Fats' ? _targetValue : goals.dailyFats,
        );
        
        print('🚀 Calling repository.createGoals...');
        await repository.createGoals(newGoals);
        print('✅ Goals created successfully!');
      } else {
        // Update existing goals
        final updatedGoals = goals.copyWith(
          dailyProtein: widget.macro == 'Protein' ? _targetValue : goals.dailyProtein,
          dailyCarbs: widget.macro == 'Carbs' ? _targetValue : goals.dailyCarbs,
          dailyFats: widget.macro == 'Fats' ? _targetValue : goals.dailyFats,
        );

        print('🎯 Updated goals:');
        print('   Protein: ${updatedGoals.dailyProtein}');
        print('   Carbs: ${updatedGoals.dailyCarbs}');
        print('   Fats: ${updatedGoals.dailyFats}');

        print('🚀 Calling repository.updateGoals...');
        await repository.updateGoals(updatedGoals);
        print('✅ Goals updated successfully!');
      }

      // Invalidate providers to refresh data
      ref.invalidate(nutritionGoalsProvider);
      ref.invalidate(dailyProgressProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onClose();
      }
    } catch (e, stackTrace) {
      print('❌ Error in _saveGoal: $e');
      print('   Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.macro} Overview',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFE53935),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE53935),
            tabs: const [
              Tab(text: 'Adjust'),
              Tab(text: 'Overview'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdjustTab(),
                _buildOverviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustTab() {
    final goalsAsync = ref.watch(nutritionGoalsProvider);
    
    // Check if selected date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    final isPastDate = selected.isBefore(today);

    return goalsAsync.when(
      data: (goals) {
        double currentValue = 0;
        double recommendedMin = 0;
        double recommendedMax = 0;
        
        switch (widget.macro) {
          case 'Protein':
            currentValue = goals.dailyProtein;
            recommendedMin = 100;
            recommendedMax = 145;
            break;
          case 'Carbs':
            currentValue = goals.dailyCarbs;
            recommendedMin = 150;
            recommendedMax = 250;
            break;
          case 'Fats':
            currentValue = goals.dailyFats;
            recommendedMin = 50;
            recommendedMax = 80;
            break;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.macro} Sources',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (isPastDate)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Past goals cannot be changed',
                          style: TextStyle(color: Colors.orange[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ErrorRetryWidget(
                    errorMessage: _errorMessage!,
                    isCompact: true,
                    onRetry: _saveGoal,
                  ),
                ),

              const Text('Current Target', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currentValue.toStringAsFixed(0)}g',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Adjust Target',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isPastDate ? Colors.grey : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: isPastDate ? Colors.grey[400] : const Color(0xFFE53935),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: isPastDate ? Colors.grey[400] : const Color(0xFFE53935),
                  overlayColor: isPastDate ? Colors.grey[400]!.withOpacity(0.2) : const Color(0xFFE53935).withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  disabledActiveTrackColor: Colors.grey[400],
                  disabledInactiveTrackColor: Colors.grey[300],
                  disabledThumbColor: Colors.grey[400],
                ),
                child: Slider(
                  value: _targetValue,
                  min: 0,
                  max: 500,
                  divisions: 100,
                  label: '${_targetValue.round()}g',
                  onChanged: isPastDate ? null : (value) {
                    setState(() {
                      _targetValue = value;
                    });
                  },
                ),
              ),
              Center(
                child: Text(
                  '${_targetValue.round()}g',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isPastDate ? Colors.grey : Colors.black,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Recommended: ${recommendedMin.toStringAsFixed(0)}-${recommendedMax.toStringAsFixed(0)}g',
                  style: TextStyle(fontSize: 12, color: isPastDate ? Colors.grey[400] : Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : widget.onClose,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE53935)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFE53935)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || isPastDate) ? null : _saveGoal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: isPastDate ? Colors.grey[400] : const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorRetryWidget(
        errorMessage: error.toString(),
        onRetry: () {
          ref.invalidate(nutritionGoalsProvider);
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    final progressAsync = ref.watch(dailyProgressProvider(widget.selectedDate));
    final goalsAsync = ref.watch(nutritionGoalsProvider);
    final intakeLogsAsync = ref.watch(intakeLogsProvider(widget.selectedDate));

    return progressAsync.when(
      data: (progress) {
        return goalsAsync.when(
          data: (goals) {
            return intakeLogsAsync.when(
              data: (logs) {
                // Get current and target values based on macro
                double currentValue = 0;
                double targetValue = 0;
                
                switch (widget.macro) {
                  case 'Protein':
                    currentValue = progress?.totalProtein ?? 0;
                    targetValue = goals.dailyProtein;
                    break;
                  case 'Carbs':
                    currentValue = progress?.totalCarbs ?? 0;
                    targetValue = goals.dailyCarbs;
                    break;
                  case 'Fats':
                    currentValue = progress?.totalFats ?? 0;
                    targetValue = goals.dailyFats;
                    break;
                }

                // Calculate percentage
                final percentage = targetValue > 0 ? (currentValue / targetValue * 100).clamp(0.0, 100.0).toDouble() : 0.0;
                final remaining = (targetValue - currentValue).clamp(0.0, targetValue).toDouble();

                // Group foods by meal type and calculate macro totals
                final breakfastLogs = logs.where((log) => log.description?.toLowerCase().contains('breakfast') ?? false).toList();
                final lunchLogs = logs.where((log) => log.description?.toLowerCase().contains('lunch') ?? false).toList();
                final dinnerLogs = logs.where((log) => log.description?.toLowerCase().contains('dinner') ?? false).toList();
                final snackLogs = logs.where((log) => log.entryType == 'snack').toList();

                double getMacroTotal(List<IntakeLog> logs) {
                  switch (widget.macro) {
                    case 'Protein':
                      return logs.fold<double>(0, (sum, log) => sum + log.protein);
                    case 'Carbs':
                      return logs.fold<double>(0, (sum, log) => sum + log.carbs);
                    case 'Fats':
                      return logs.fold<double>(0, (sum, log) => sum + log.fats);
                    default:
                      return 0;
                  }
                }

                final breakfastMacro = getMacroTotal(breakfastLogs);
                final lunchMacro = getMacroTotal(lunchLogs);
                final dinnerMacro = getMacroTotal(dinnerLogs);
                final snackMacro = getMacroTotal(snackLogs);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Circular progress chart
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(200, 200),
                              painter: MacroDonutChartPainter(
                                percentage: percentage,
                                color: const Color(0xFFE53935),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${currentValue.toStringAsFixed(0)}g',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'of ${targetValue.toStringAsFixed(0)}g',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Remaining amount
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${remaining.toStringAsFixed(0)}g',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Breakdown by meal
                      if (logs.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Breakdown by Meal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (breakfastMacro > 0)
                          _buildMealBreakdownItem(
                            'Breakfast',
                            breakfastMacro,
                            currentValue,
                            const Color(0xFFE53935),
                          ),
                        if (lunchMacro > 0)
                          _buildMealBreakdownItem(
                            'Lunch',
                            lunchMacro,
                            currentValue,
                            const Color(0xFFFF7043),
                          ),
                        if (dinnerMacro > 0)
                          _buildMealBreakdownItem(
                            'Dinner',
                            dinnerMacro,
                            currentValue,
                            const Color(0xFFFFAB91),
                          ),
                        if (snackMacro > 0)
                          _buildMealBreakdownItem(
                            'Snacks',
                            snackMacro,
                            currentValue,
                            const Color(0xFFBCAAA4),
                          ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No meals logged today',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: ErrorRetryWidget(
                  errorMessage: error.toString(),
                  onRetry: () {
                    ref.invalidate(intakeLogsProvider);
                  },
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: ErrorRetryWidget(
              errorMessage: error.toString(),
              onRetry: () {
                ref.invalidate(nutritionGoalsProvider);
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: ErrorRetryWidget(
          errorMessage: error.toString(),
          onRetry: () {
            ref.invalidate(dailyProgressProvider);
          },
        ),
      ),
    );
  }

  Widget _buildMealBreakdownItem(String mealName, double amount, double total, Color color) {
    final percentage = total > 0 ? (amount / total * 100) : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mealName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount.toStringAsFixed(1)}g',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSourceItem(String name, String amount, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fastfood, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MacroDonutChartPainter extends CustomPainter {
  final double percentage;
  final Color color;

  MacroDonutChartPainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;

    // Background circle (gray)
    paint.color = Colors.grey[300]!;
    canvas.drawCircle(center, radius, paint);

    // Progress arc (colored)
    paint.color = color;
    final sweepAngle = (percentage / 100) * 2 * 3.14159; // Convert percentage to radians
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start at top (-90 degrees in radians)
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(MacroDonutChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 30) / 2;

    // Red arc (38%)
    paint.color = const Color(0xFFE53935);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // Start at top (-90 degrees in radians)
      2.37, // 38% of circle (0.38 * 2π)
      false,
      paint,
    );

    // Orange arc (62%)
    paint.color = const Color(0xFFFFA726);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.80, // Continue from red
      3.87, // 62% of circle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class AddMealScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final String initialMealType;
  
  const AddMealScreen({Key? key, required this.onBack, this.initialMealType = 'Breakfast'}) : super(key: key);

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showCustomFoodForm = false;
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isLoadingRecent = false;
  String? _errorMessage;
  List<dynamic> _searchResults = [];
  List<FoodItem> _recentFoods = [];
  
  // Track custom food that needs to be logged
  int? _pendingFoodIdToLog;
  String? _pendingFoodNameToLog;

  // Popular food suggestions
  final List<Map<String, dynamic>> _popularSuggestions = [
    {
      'name': 'Chicken breast',
      'calories': '165 cal per 100g',
      'imageUrl': 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=200'
    },
    {
      'name': 'Brown rice',
      'calories': '112 cal per 100g',
      'imageUrl': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=200'
    },
    {
      'name': 'Banana',
      'calories': '89 cal per 100g',
      'imageUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=200'
    },
    {
      'name': 'Egg',
      'calories': '155 cal per 100g',
      'imageUrl': 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=200'
    },
    {
      'name': 'Salmon',
      'calories': '208 cal per 100g',
      'imageUrl': 'https://images.unsplash.com/photo-1485921325833-c519f76c4927?w=200'
    },
    {
      'name': 'Broccoli',
      'calories': '34 cal per 100g',
      'imageUrl': 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=200'
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentFoods();
  }

  Future<void> _loadRecentFoods() async {
    setState(() {
      _isLoadingRecent = true;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final recentFoods = await repository.getRecentFoods();
      
      if (mounted) {
        setState(() {
          _recentFoods = recentFoods;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecent = false;
        });
      }
    }
  }

  // Helper method to set pending food from custom food form
  void _setPendingFoodToLog(int foodId, String foodName) {
    print('🎯 _setPendingFoodToLog called with ID: $foodId, Name: $foodName');
    if (mounted) {
      setState(() {
        _showCustomFoodForm = false;
        _pendingFoodIdToLog = foodId;
        _pendingFoodNameToLog = foodName;
      });
      print('🎯 Parent state updated successfully');
    } else {
      print('❌ Widget not mounted, cannot update state');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final results = await repository.searchFoods(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          // Only set error if there's an actual error, not for empty results
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _logMeal(int foodItemId, String foodName) async {
    // Show dialog to get quantity from user
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildQuantityDialog(foodName),
    );

    if (result == null) return; // User cancelled

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logMeal = ref.read(logMealProvider);
      
      // Create intake log with user-specified quantity
      final log = IntakeLog(
        id: 0,
        userId: null, // Will be set by backend
        foodItemId: foodItemId,
        entryType: result['entryType'] ?? 'meal',
        description: result['description'] ?? 'Meal',
        quantity: result['quantity'],
        unit: result['unit'],
        calories: 0, // Will be calculated by backend
        protein: 0,
        carbs: 0,
        fats: 0,
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await logMeal(log);

      // Notify home page to refresh dashboard
      DashboardRefreshService().notifyRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$foodName logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onBack();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildQuantityDialog(String foodName) {
    final TextEditingController quantityController = TextEditingController(text: '100');
    String selectedUnit = 'g';
    String selectedMealType = widget.initialMealType;
    String selectedEntryType = widget.initialMealType == 'Snack' ? 'snack' : 'meal';

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text('Log $foodName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meal Type', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: ['Breakfast', 'Lunch', 'Dinner']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMealType = value!;
                      selectedEntryType = 'meal';
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter quantity',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: ['g', 'ml', 'oz', 'cup', 'piece']
                            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedUnit = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: Nutritional values are calculated per 100g',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = double.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop({
                  'quantity': quantity,
                  'unit': selectedUnit,
                  'entryType': selectedEntryType,
                  'description': selectedMealType,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: const Text('Log Food', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if there's a pending food to log after custom food creation
    if (_pendingFoodIdToLog != null && _pendingFoodNameToLog != null) {
      print('🎯 BUILD: Detected pending food to log');
      print('   Food ID: $_pendingFoodIdToLog');
      print('   Food Name: $_pendingFoodNameToLog');
      
      // Schedule the dialog to show after this build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingFoodIdToLog != null && _pendingFoodNameToLog != null) {
          print('🎯 POST-FRAME: Calling _logMeal');
          final foodId = _pendingFoodIdToLog!;
          final foodName = _pendingFoodNameToLog!;
          
          // Clear the pending food before showing dialog
          setState(() {
            _pendingFoodIdToLog = null;
            _pendingFoodNameToLog = null;
          });
          
          // Show the quantity dialog
          _logMeal(foodId, foodName);
        }
      });
    }
    
    if (_showCustomFoodForm) {
      return _buildCustomFoodForm();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFE53935)),
          onPressed: widget.onBack,
        ),
        title: const Text('Add Food'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Food',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFF5F5),
                    ),
                  ),
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ErrorRetryWidget(
                      errorMessage: _errorMessage!,
                      isCompact: true,
                      onRetry: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                    ),
                  ),

                if (_searchResults.isNotEmpty)
                  ..._searchResults.map((food) => _buildFoodCard(
                    food.name,
                    '${food.caloriesPer100g.toStringAsFixed(0)} cal per 100g',
                    Icons.restaurant,
                    onTap: () => _logMeal(food.id, food.name),
                    imageUrl: food.imageUrl,
                  ))
                else if (_searchController.text.isNotEmpty && !_isSearching && _errorMessage == null)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No foods found for "${_searchController.text}"',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search or add custom food',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showCustomFoodForm = true;
                            });
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Custom Food', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_searchController.text.isEmpty)
                  ...[
                    // Popular Suggestions Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Popular Foods',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._popularSuggestions.map((food) => _buildFoodCard(
                            food['name'],
                            food['calories'],
                            Icons.restaurant,
                            onTap: () async {
                              // Search for this food and log it
                              try {
                                final repository = ref.read(nutritionRepositoryProvider);
                                final results = await repository.searchFoods(food['name']);
                                
                                if (results.isNotEmpty) {
                                  // Use the first result
                                  final foodItem = results.first;
                                  _logMeal(foodItem.id, foodItem.name);
                                } else {
                                  // Fallback: fill search box
                                  _searchController.text = food['name'];
                                }
                              } catch (e) {
                                // Fallback: fill search box
                                _searchController.text = food['name'];
                              }
                            },
                            imageUrl: food['imageUrl'],
                          )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Recent Foods Section
                    if (_recentFoods.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recently Logged',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._recentFoods.map((food) => _buildFoodCard(
                              food.name,
                              '${food.caloriesPer100g.toStringAsFixed(0)} cal per 100g',
                              Icons.history,
                              onTap: () => _logMeal(food.id, food.name),
                              imageUrl: food.imageUrl,
                            )),
                          ],
                        ),
                      )
                    else if (_isLoadingRecent)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Add Custom Food Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showCustomFoodForm = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE53935),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              '+ Add Custom Food',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomFoodForm() {
    final TextEditingController foodNameController = TextEditingController();
    final TextEditingController brandController = TextEditingController();
    final TextEditingController servingSizeController = TextEditingController();
    final TextEditingController caloriesController = TextEditingController();
    final TextEditingController proteinController = TextEditingController();
    final TextEditingController carbsController = TextEditingController();
    final TextEditingController fatsController = TextEditingController();
    
    // New controllers for quantity and meal type
    final TextEditingController quantityController = TextEditingController(text: '100');
    
    String selectedUnit = 'g';
    String selectedMealType = widget.initialMealType;
    String selectedEntryType = widget.initialMealType == 'Snack' ? 'snack' : 'meal';
    bool isLoading = false;
    String? errorMessage;

    return StatefulBuilder(
      builder: (context, setFormState) {
        Future<void> handleAddCustomFood() async {
          // Validate inputs
          if (foodNameController.text.isEmpty) {
            setFormState(() {
              errorMessage = 'Please enter a food name';
            });
            return;
          }

          if (caloriesController.text.isEmpty ||
              proteinController.text.isEmpty ||
              carbsController.text.isEmpty ||
              fatsController.text.isEmpty) {
            setFormState(() {
              errorMessage = 'Please fill in all nutrition fields';
            });
            return;
          }

          setFormState(() {
            isLoading = true;
            errorMessage = null;
          });

          try {
            final repository = ref.read(nutritionRepositoryProvider);
            
            // Parse nutrition values
            final calories = double.tryParse(caloriesController.text) ?? 0;
            final protein = double.tryParse(proteinController.text) ?? 0;
            final carbs = double.tryParse(carbsController.text) ?? 0;
            final fats = double.tryParse(fatsController.text) ?? 0;

            print('📝 Creating custom food:');
            print('   Name: ${foodNameController.text}');
            print('   Brand: ${brandController.text}');
            print('   Calories: $calories');
            print('   Protein: $protein');
            print('   Carbs: $carbs');
            print('   Fats: $fats');

            // Create custom food (values are per 100g)
            final customFood = FoodItem(
              id: 0,
              name: foodNameController.text,
              brand: brandController.text.isEmpty ? null : brandController.text,
              caloriesPer100g: calories,
              proteinPer100g: protein,
              carbsPer100g: carbs,
              fatsPer100g: fats,
              fiberPer100g: 0,
              sugarPer100g: 0,
              isCustom: true,
              createdBy: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            print('🚀 Calling repository.createCustomFood...');
            final createdFood = await repository.createCustomFood(customFood);
            
            print('✅ Custom food created successfully: ${createdFood.name} (ID: ${createdFood.id})');

            if (mounted) {
              print('🎯 Custom food created, now logging with quantity');
              print('   Food ID: ${createdFood.id}');
              print('   Food Name: ${createdFood.name}');
              print('   Quantity: ${quantityController.text}$selectedUnit');
              print('   Meal Type: $selectedMealType');
              
              // Parse quantity
              final quantity = double.tryParse(quantityController.text) ?? 100;
              
              // Create intake log directly with the quantity and meal type from the form
              final logMeal = ref.read(logMealProvider);
              final log = IntakeLog(
                id: 0,
                userId: null, // Will be set by backend
                foodItemId: createdFood.id,
                entryType: selectedEntryType,
                description: selectedMealType,
                quantity: quantity,
                unit: selectedUnit,
                calories: 0, // Will be calculated by backend
                protein: 0,
                carbs: 0,
                fats: 0,
                loggedAt: DateTime.now(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await logMeal(log);
              
              // Notify home page to refresh dashboard
              DashboardRefreshService().notifyRefresh();
              
              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${createdFood.name} logged successfully!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                // Close the form and return to main screen
                setFormState(() {
                  isLoading = false;
                });
                
                setState(() {
                  _showCustomFoodForm = false;
                });
                
                // Go back to main screen
                widget.onBack();
              }
            }
          } catch (e, stackTrace) {
            print('❌ Error in handleAddCustomFood: $e');
            print('   Stack trace: $stackTrace');
            if (mounted) {
              setFormState(() {
                isLoading = false;
                errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error creating custom food: ${e.toString().replaceAll('Exception: ', '')}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFE53935)),
              onPressed: () {
                setState(() {
                  _showCustomFoodForm = false;
                });
              },
            ),
            title: const Text('Add Custom Food'),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log your own food manually if not found in our database',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ErrorRetryWidget(
                            errorMessage: errorMessage!,
                            isCompact: true,
                            onRetry: handleAddCustomFood,
                          ),
                        ),

                      const Text('Food Name', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: foodNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. boil curry',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Brand Name (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: brandController,
                        decoration: InputDecoration(
                          hintText: 'Enter brand name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Nutrition Information (per 100g)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionField('Calories*', caloriesController, '0'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNutritionField('Protein (g)*', proteinController, '0'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionField('Carbs (g)*', carbsController, '0'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNutritionField('Fats (g)*', fatsController, '0'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Meal Type and Quantity Section
                      const Text('Meal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Meal Type', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedMealType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: ['Breakfast', 'Lunch', 'Dinner']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          setFormState(() {
                            selectedMealType = value!;
                            selectedEntryType = 'meal';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '100',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedUnit,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              items: ['g', 'ml', 'oz', 'cup', 'piece']
                                  .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                                  .toList(),
                              onChanged: (value) {
                                setFormState(() {
                                  selectedUnit = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading ? null : () {
                                setState(() {
                                  _showCustomFoodForm = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Color(0xFFE53935)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Color(0xFFE53935))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : handleAddCustomFood,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFFE53935),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Add', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildFoodCard(String name, String calories, IconData icon, {VoidCallback? onTap, String? imageUrl}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(icon, size: 28);
                      },
                    ),
                  )
                : Icon(icon, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  calories,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFFE53935)),
            onPressed: onTap ?? () {},
          ),
        ],
      ),
    );
  }
}