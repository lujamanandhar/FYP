# Repository Pattern Implementation

This directory contains the repository interfaces and implementations for the NutriLift Workout Tracking System.

## Repository Interfaces

### WorkoutRepository
Interface for workout-related data operations:
- `getWorkoutHistory()` - Retrieve workout history with optional filtering
- `logWorkout()` - Log a new workout
- `getStatistics()` - Get aggregate workout statistics

### ExerciseRepository
Interface for exercise library data operations:
- `getExercises()` - Retrieve exercises with optional filtering by category, muscle group, equipment, difficulty, and search
- `getExerciseById()` - Get a single exercise by ID

### PersonalRecordRepository
Interface for personal record data operations:
- `getPersonalRecords()` - Retrieve all personal records for the user
- `getPersonalRecordForExercise()` - Get PR for a specific exercise

## Implementations

### API Implementations
- `WorkoutApiService` - Real API implementation using Dio HTTP client
- `ExerciseApiService` - Real API implementation for exercise data
- `PersonalRecordApiService` - Real API implementation for PR data

### Mock Implementations
- `MockWorkoutRepository` - In-memory mock for testing and offline development
- `MockExerciseRepository` - Mock with 30+ pre-populated exercises
- `MockPersonalRecordRepository` - Mock with 15+ sample personal records

## Usage

### Using API Implementations (Production)
```dart
final dioClient = DioClient(baseUrl: 'https://api.nutrilift.com');
final workoutRepo = WorkoutApiService(dioClient.dio, dioClient.baseUrl);
final exerciseRepo = ExerciseApiService(dioClient.dio, dioClient.baseUrl);
final prRepo = PersonalRecordApiService(dioClient.dio, dioClient.baseUrl);
```

### Using Mock Implementations (Testing/Development)
```dart
final workoutRepo = MockWorkoutRepository();
final exerciseRepo = MockExerciseRepository();
final prRepo = MockPersonalRecordRepository();
```

### With Riverpod Providers
```dart
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) {
    return MockWorkoutRepository();
  } else {
    final dioClient = ref.watch(dioClientProvider);
    return WorkoutApiService(dioClient.dio, dioClient.baseUrl);
  }
});
```

## Mock Data Features

### MockWorkoutRepository
- Pre-populated with 3 sample workouts
- Supports date filtering and pagination
- Calculates realistic statistics
- Simulates network delays (300-500ms)

### MockExerciseRepository
- 30+ exercises covering all categories:
  - Strength (Chest, Back, Legs, Arms, Shoulders, Core)
  - Cardio (Running, Cycling, Rowing, etc.)
  - Bodyweight exercises
- All difficulty levels (Beginner, Intermediate, Advanced)
- All equipment types (Free Weights, Machines, Bodyweight, etc.)
- Supports complex filtering and search

### MockPersonalRecordRepository
- 15+ sample personal records
- Realistic improvement percentages
- Covers various exercises and achievement dates
- Sorted by date (newest first)

## Testing

All mock repositories include comprehensive unit tests in `test/repositories/mock_repositories_test.dart`:
- Filtering logic validation
- Data ordering verification
- CRUD operations testing
- Edge case handling

Run tests with:
```bash
flutter test test/repositories/mock_repositories_test.dart
```

## Benefits of Repository Pattern

1. **Abstraction** - UI code doesn't know about data source details
2. **Testability** - Easy to swap real API with mocks for testing
3. **Flexibility** - Can switch between API, cache, or mock implementations
4. **Offline Support** - Mock repositories enable offline development
5. **Consistency** - Single interface for all data operations
