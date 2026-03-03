import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/workout_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/personal_record_repository.dart';
import '../repositories/mock_workout_repository.dart';
import '../repositories/mock_exercise_repository.dart';
import '../repositories/mock_personal_record_repository.dart';
import '../services/workout_api_service.dart';
import '../services/exercise_api_service.dart';
import '../services/personal_record_api_service.dart';
import '../services/dio_client.dart';

/// Provider for DioClient instance
/// 
/// This provider creates and manages the Dio HTTP client with
/// JWT authentication and error handling interceptors.
/// 
/// Validates: Requirements 7.4, 7.5
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// Provider to control whether to use mock or API implementations
/// 
/// Set to true for offline development and testing with mock data.
/// Set to false for production use with real API calls.
/// 
/// Validates: Requirements 7.9
final useMockDataProvider = StateProvider<bool>((ref) {
  // Set to true to use mock data (for testing without backend)
  // Set to false to use real API (requires backend running)
  return true;  // Using mock data by default until backend is properly connected
});

/// Provider for WorkoutRepository
/// 
/// Returns either MockWorkoutRepository or WorkoutApiService
/// based on the useMockDataProvider state.
/// 
/// This allows seamless switching between mock and real data
/// for development, testing, and production.
/// 
/// Validates: Requirements 7.2, 7.3, 7.9
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final useMockData = ref.watch(useMockDataProvider);
  
  if (useMockData) {
    return MockWorkoutRepository();
  } else {
    final dioClient = ref.watch(dioClientProvider);
    return WorkoutApiService(dioClient);
  }
});

/// Provider for ExerciseRepository
/// 
/// Returns either MockExerciseRepository or ExerciseApiService
/// based on the useMockDataProvider state.
/// 
/// Validates: Requirements 7.2, 7.3, 7.9
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final useMockData = ref.watch(useMockDataProvider);
  
  if (useMockData) {
    return MockExerciseRepository();
  } else {
    final dioClient = ref.watch(dioClientProvider);
    return ExerciseApiService(dioClient);
  }
});

/// Provider for PersonalRecordRepository
/// 
/// Returns either MockPersonalRecordRepository or PersonalRecordApiService
/// based on the useMockDataProvider state.
/// 
/// Validates: Requirements 7.2, 7.3, 7.9
final personalRecordRepositoryProvider = Provider<PersonalRecordRepository>((ref) {
  final useMockData = ref.watch(useMockDataProvider);
  
  if (useMockData) {
    return MockPersonalRecordRepository();
  } else {
    final dioClient = ref.watch(dioClientProvider);
    return PersonalRecordApiService(dioClient);
  }
});
