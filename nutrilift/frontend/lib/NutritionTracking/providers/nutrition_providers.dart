import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../models/intake_log.dart';
import '../models/hydration_log.dart';
import '../models/nutrition_goals.dart';
import '../models/nutrition_progress.dart';
import '../services/nutrition_api_service.dart';
import '../repositories/nutrition_repository.dart';
import '../../providers/repository_providers.dart';

/// Provider for NutritionApiService
/// 
/// Creates the API service with DioClient for HTTP communication.
/// 
/// Validates: Requirements 18.1, 18.2
final nutritionApiServiceProvider = Provider<NutritionApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NutritionApiService(dioClient);
});

/// Provider for NutritionRepository
/// 
/// Creates the repository with NutritionApiService for data access.
/// This is the main entry point for all nutrition data operations.
/// 
/// Validates: Requirements 19.1, 19.2, 20.1
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final apiService = ref.watch(nutritionApiServiceProvider);
  return NutritionRepository(apiService);
});

/// Provider for daily nutrition progress
/// 
/// Fetches nutrition progress for a specific date including:
/// - Total calories, protein, carbs, fats, water
/// - Adherence percentages for each macro
/// 
/// Usage: ref.watch(dailyProgressProvider(DateTime.now()))
/// 
/// Validates: Requirements 20.2, 20.7
final dailyProgressProvider = FutureProvider.family<NutritionProgress?, DateTime>((ref, date) async {
  final repository = ref.watch(nutritionRepositoryProvider);
  return await repository.getDailyProgress(date);
});

/// Provider for intake logs for a specific date
/// 
/// Fetches all meal/snack/drink logs for a given date.
/// 
/// Usage: ref.watch(intakeLogsProvider(DateTime.now()))
/// 
/// Validates: Requirements 20.3, 20.7
final intakeLogsProvider = FutureProvider.family<List<IntakeLog>, DateTime>((ref, date) async {
  final repository = ref.watch(nutritionRepositoryProvider);
  return await repository.getIntakeLogs(date);
});

/// Provider for nutrition goals
/// 
/// Fetches the user's daily nutrition targets.
/// Results are cached in the repository for 5 minutes.
/// 
/// Validates: Requirements 20.4, 20.7
final nutritionGoalsProvider = FutureProvider<NutritionGoals>((ref) async {
  final repository = ref.watch(nutritionRepositoryProvider);
  final goals = await repository.getGoals();
  return goals;
});

/// Provider for frequent foods
/// 
/// Fetches the user's most frequently logged foods for quick access.
/// 
/// Validates: Requirements 20.5, 20.7
final frequentFoodsProvider = FutureProvider<List<FoodItem>>((ref) async {
  final repository = ref.watch(nutritionRepositoryProvider);
  return await repository.getFrequentFoods();
});

/// Provider for logging a meal
/// 
/// Returns a function that logs a meal and automatically refreshes
/// related providers (progress and intake logs).
/// 
/// Usage:
/// ```dart
/// final logMeal = ref.read(logMealProvider);
/// await logMeal(intakeLog);
/// ```
/// 
/// Validates: Requirements 20.6, 20.8
final logMealProvider = Provider<Future<IntakeLog> Function(IntakeLog)>((ref) {
  return (IntakeLog log) async {
    final repository = ref.read(nutritionRepositoryProvider);
    final result = await repository.logMeal(log);
    
    // Invalidate related providers to trigger refresh
    ref.invalidate(dailyProgressProvider);
    ref.invalidate(intakeLogsProvider);
    
    return result;
  };
});

/// Provider for logging hydration
/// 
/// Returns a function that logs water intake and automatically refreshes
/// the daily progress provider.
/// 
/// Usage:
/// ```dart
/// final logHydration = ref.read(logHydrationProvider);
/// await logHydration(hydrationLog);
/// ```
/// 
/// Validates: Requirements 20.6, 20.8
final logHydrationProvider = Provider<Future<HydrationLog> Function(HydrationLog)>((ref) {
  return (HydrationLog log) async {
    final repository = ref.read(nutritionRepositoryProvider);
    final result = await repository.logHydration(log);
    
    // Invalidate progress to trigger refresh
    ref.invalidate(dailyProgressProvider);
    
    return result;
  };
});

/// Provider for updating nutrition goals
/// 
/// Returns a function that updates goals and automatically refreshes
/// related providers (goals and progress).
/// 
/// Usage:
/// ```dart
/// final updateGoals = ref.read(updateGoalsProvider);
/// await updateGoals(newGoals);
/// ```
/// 
/// Validates: Requirements 20.6, 20.8
final updateGoalsProvider = Provider<Future<NutritionGoals> Function(NutritionGoals)>((ref) {
  return (NutritionGoals goals) async {
    final repository = ref.read(nutritionRepositoryProvider);
    final result = await repository.updateGoals(goals);
    
    // Invalidate related providers to trigger refresh
    ref.invalidate(nutritionGoalsProvider);
    ref.invalidate(dailyProgressProvider);
    
    return result;
  };
});

/// Provider for deleting an intake log
/// 
/// Returns a function that deletes a meal log and automatically refreshes
/// related providers (progress and intake logs).
/// 
/// Usage:
/// ```dart
/// final deleteLog = ref.read(deleteIntakeLogProvider);
/// await deleteLog(logId);
/// ```
/// 
/// Validates: Requirements 20.6, 20.8
final deleteIntakeLogProvider = Provider<Future<void> Function(int)>((ref) {
  return (int id) async {
    final repository = ref.read(nutritionRepositoryProvider);
    await repository.deleteIntakeLog(id);
    
    // Invalidate related providers to trigger refresh
    ref.invalidate(dailyProgressProvider);
    ref.invalidate(intakeLogsProvider);
  };
});
