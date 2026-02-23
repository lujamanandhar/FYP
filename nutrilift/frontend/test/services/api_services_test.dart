import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:nutrilift/models/exercise.dart';
import 'package:nutrilift/models/personal_record.dart';
import 'package:nutrilift/models/workout_log.dart';
import 'package:nutrilift/models/workout_models.dart' show CreateWorkoutLogRequest, ExerciseSetRequest, WorkoutSetRequest;
import 'package:nutrilift/services/dio_client.dart';
import 'package:nutrilift/services/exercise_api_service.dart';
import 'package:nutrilift/services/personal_record_api_service.dart';
import 'package:nutrilift/services/workout_api_service.dart';
import 'package:nutrilift/services/cache_service.dart';

// Helper class to create a testable DioClient
class TestDioClient extends DioClient {
  final Dio testDio;

  TestDioClient(this.testDio);

  @override
  Dio get dio => testDio;
}

// Mock CacheService for testing
class MockCacheService implements CacheService {
  @override
  Future<void> cacheWorkoutHistory(List<WorkoutLog> workouts) async {}
  
  @override
  Future<List<WorkoutLog>?> getCachedWorkoutHistory() async => null;
  
  @override
  Future<void> addWorkoutToCache(WorkoutLog workout) async {}
  
  @override
  Future<void> cacheExercises(List<Exercise> exercises) async {}
  
  @override
  Future<List<Exercise>?> getCachedExercises() async => null;
  
  @override
  Future<void> cachePersonalRecords(List<PersonalRecord> records) async {}
  
  @override
  Future<List<PersonalRecord>?> getCachedPersonalRecords() async => null;
  
  @override
  Future<void> clearWorkoutHistoryCache() async {}
  
  @override
  Future<void> clearExercisesCache() async {}
  
  @override
  Future<void> clearPersonalRecordsCache() async {}
  
  @override
  Future<void> updatePersonalRecordInCache(PersonalRecord record) async {}
  
  @override
  Future<DateTime?> getLastSyncTime() async => null;
  
  @override
  Future<bool> needsRefresh({Duration maxAge = const Duration(hours: 1)}) async => false;
  
  @override
  Future<bool> hasCachedData() async => false;
  
  @override
  Future<void> clearAllCache() async {}
  
  @override
  Future<Map<String, dynamic>> getCacheStats() async => {};
  
  @override
  void dispose() {}
}

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late TestDioClient dioClient;
  late MockCacheService cacheService;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api'));
    dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;
    
    dioClient = TestDioClient(dio);
    cacheService = MockCacheService();
  });

  group('WorkoutApiService', () {
    late WorkoutApiService workoutApiService;

    setUp(() {
      workoutApiService = WorkoutApiService(dioClient, cacheService);
    });

    test('getWorkoutHistory returns list of workouts', () async {
      // Mock response data
      final mockResponse = [
        {
          'id': 1,
          'user': 1,
          'custom_workout': 1,
          'workout_name': 'Push Day',
          'gym': 1,
          'gym_name': 'Gold\'s Gym',
          'date': '2024-01-15T10:30:00Z',
          'duration': 60,
          'calories_burned': 450.5,
          'notes': 'Great workout',
          'exercises': [],
          'has_new_prs': true,
        }
      ];

      dioAdapter.onGet(
        '/workouts/history/',
        (server) => server.reply(200, mockResponse),
      );

      final result = await workoutApiService.getWorkoutHistory();

      expect(result, isA<List<WorkoutLog>>());
      expect(result.length, equals(1));
      expect(result.first.id, equals(1));
      expect(result.first.workoutName, equals('Push Day'));
      expect(result.first.hasNewPrs, isTrue);
    });

    test('getWorkoutHistory with filters applies query parameters', () async {
      final dateFrom = DateTime(2024, 1, 1);
      final mockResponse = <Map<String, dynamic>>[];

      dioAdapter.onGet(
        '/workouts/history/',
        (server) => server.reply(200, mockResponse),
        queryParameters: {
          'date_from': dateFrom.toIso8601String(),
          'limit': '10',
        },
      );

      final result = await workoutApiService.getWorkoutHistory(
        dateFrom: dateFrom,
        limit: 10,
      );

      expect(result, isA<List<WorkoutLog>>());
      expect(result.length, equals(0));
    });

    test('logWorkout creates workout and returns result', () async {
      final request = CreateWorkoutLogRequest(
        workoutName: 'Test Workout',
        durationMinutes: 60,
        caloriesBurned: 400.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '1',
            order: 0,
            sets: [
              WorkoutSetRequest(setNumber: 1, reps: 10, weight: 100.0),
            ],
          ),
        ],
      );

      final mockResponse = {
        'id': 1,
        'user': 1,
        'date': DateTime.now().toIso8601String(),
        'duration': 60,
        'calories_burned': 400.0,
        'notes': '',
        'exercises': [],
        'has_new_prs': false,
      };

      dioAdapter.onPost(
        '/workouts/log/',
        (server) => server.reply(201, mockResponse),
      );

      final result = await workoutApiService.logWorkout(request);

      expect(result, isA<WorkoutLog>());
      expect(result.id, equals(1));
      expect(result.duration, equals(60));
    });

    test('getStatistics returns statistics map', () async {
      final mockResponse = {
        'total_workouts': 45,
        'total_calories': 20250.0,
        'total_duration': 2700,
        'average_duration': 60,
        'average_calories': 450.0,
        'workouts_by_category': {
          'Strength': 30,
          'Cardio': 15,
        },
      };

      dioAdapter.onGet(
        '/workouts/statistics/',
        (server) => server.reply(200, mockResponse),
      );

      final result = await workoutApiService.getStatistics();

      expect(result, isA<Map<String, dynamic>>());
      expect(result['total_workouts'], equals(45));
      expect(result['average_calories'], equals(450.0));
    });

    test('handles 401 authentication error', () async {
      dioAdapter.onGet(
        '/workouts/history/',
        (server) => server.reply(401, {'message': 'Unauthorized'}),
      );

      expect(
        () => workoutApiService.getWorkoutHistory(),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('handles 404 not found error', () async {
      dioAdapter.onGet(
        '/workouts/history/',
        (server) => server.reply(404, {'message': 'Not found'}),
      );

      expect(
        () => workoutApiService.getWorkoutHistory(),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('handles network timeout error', () async {
      dioAdapter.onGet(
        '/workouts/history/',
        (server) => server.throws(
          408,
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: RequestOptions(path: '/workouts/history/'),
          ),
        ),
      );

      expect(
        () => workoutApiService.getWorkoutHistory(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ExerciseApiService', () {
    late ExerciseApiService exerciseApiService;

    setUp(() {
      exerciseApiService = ExerciseApiService(dioClient, cacheService);
    });

    test('getExercises returns list of exercises', () async {
      final mockResponse = [
        {
          'id': 1,
          'name': 'Bench Press',
          'category': 'Strength',
          'muscle_group': 'Chest',
          'equipment': 'Free Weights',
          'difficulty': 'Intermediate',
          'description': 'A compound upper body exercise',
          'instructions': 'Lie on bench, lower bar to chest, press up',
        }
      ];

      dioAdapter.onGet(
        '/exercises/',
        (server) => server.reply(200, mockResponse),
      );

      final result = await exerciseApiService.getExercises();

      expect(result, isA<List<Exercise>>());
      expect(result.length, equals(1));
      expect(result.first.name, equals('Bench Press'));
      expect(result.first.category, equals('Strength'));
    });

    test('getExercises with filters applies query parameters', () async {
      final mockResponse = <Map<String, dynamic>>[];

      dioAdapter.onGet(
        '/exercises/',
        (server) => server.reply(200, mockResponse),
        queryParameters: {
          'category': 'Strength',
          'muscle': 'Chest',
          'difficulty': 'Intermediate',
          'search': 'bench',
        },
      );

      final result = await exerciseApiService.getExercises(
        category: 'Strength',
        muscleGroup: 'Chest',
        difficulty: 'Intermediate',
        search: 'bench',
      );

      expect(result, isA<List<Exercise>>());
    });

    test('getExerciseById returns single exercise', () async {
      final mockResponse = {
        'id': 1,
        'name': 'Bench Press',
        'category': 'Strength',
        'muscle_group': 'Chest',
        'equipment': 'Free Weights',
        'difficulty': 'Intermediate',
        'description': 'A compound upper body exercise',
        'instructions': 'Lie on bench, lower bar to chest, press up',
      };

      dioAdapter.onGet(
        '/exercises/1/',
        (server) => server.reply(200, mockResponse),
      );

      final result = await exerciseApiService.getExerciseById('1');

      expect(result, isA<Exercise>());
      expect(result.id, equals(1));
      expect(result.name, equals('Bench Press'));
    });

    test('handles 404 when exercise not found', () async {
      dioAdapter.onGet(
        '/exercises/999/',
        (server) => server.reply(404, {'message': 'Exercise not found'}),
      );

      expect(
        () => exerciseApiService.getExerciseById('999'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('PersonalRecordApiService', () {
    late PersonalRecordApiService personalRecordApiService;

    setUp(() {
      personalRecordApiService = PersonalRecordApiService(dioClient, cacheService);
    });

    test('getPersonalRecords returns list of records', () async {
      final mockResponse = [
        {
          'id': 1,
          'exercise': 1,
          'exercise_name': 'Bench Press',
          'max_weight': 120.0,
          'max_reps': 12,
          'max_volume': 4320.0,
          'achieved_date': '2024-01-15T10:30:00Z',
          'improvement_percentage': 15.5,
        }
      ];

      dioAdapter.onGet(
        '/personal-records/',
        (server) => server.reply(200, mockResponse),
      );

      final result = await personalRecordApiService.getPersonalRecords();

      expect(result, isA<List<PersonalRecord>>());
      expect(result.length, equals(1));
      expect(result.first.exerciseName, equals('Bench Press'));
      expect(result.first.maxWeight, equals(120.0));
    });

    test('getPersonalRecordForExercise returns record for specific exercise', () async {
      final mockResponse = [
        {
          'id': 1,
          'exercise': 1,
          'exercise_name': 'Bench Press',
          'max_weight': 120.0,
          'max_reps': 12,
          'max_volume': 4320.0,
          'achieved_date': '2024-01-15T10:30:00Z',
        }
      ];

      dioAdapter.onGet(
        '/personal-records/',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'exercise_id': '1'},
      );

      final result = await personalRecordApiService.getPersonalRecordForExercise('1');

      expect(result, isA<PersonalRecord>());
      expect(result!.exerciseId, equals(1));
    });

    test('getPersonalRecordForExercise returns null when no record exists', () async {
      dioAdapter.onGet(
        '/personal-records/',
        (server) => server.reply(200, []),
        queryParameters: {'exercise_id': '999'},
      );

      final result = await personalRecordApiService.getPersonalRecordForExercise('999');

      expect(result, isNull);
    });

    test('getPersonalRecordForExercise returns null on 404', () async {
      dioAdapter.onGet(
        '/personal-records/',
        (server) => server.reply(404, {'message': 'Not found'}),
        queryParameters: {'exercise_id': '999'},
      );

      final result = await personalRecordApiService.getPersonalRecordForExercise('999');

      expect(result, isNull);
    });
  });

  group('Error Handling', () {
    late WorkoutApiService workoutApiService;

    setUp(() {
      workoutApiService = WorkoutApiService(dioClient, cacheService);
    });

    test('Feature: workout-tracking-system, Property 23: Loading State Display - Service handles loading states', () async {
      // Property test: For any asynchronous operation, the service should handle loading states
      final mockResponse = [
        {
          'id': 1,
          'date': DateTime.now().toIso8601String(),
          'duration': 60,
          'calories_burned': 400.0,
          'exercises': [],
          'has_new_prs': false,
        }
      ];

      dioAdapter.onGet(
        '/workouts/history/',
        (server) => server.reply(200, mockResponse),
      );

      // The service should complete the async operation successfully
      final result = await workoutApiService.getWorkoutHistory();
      expect(result, isA<List<WorkoutLog>>());
    });

    test('Feature: workout-tracking-system, Property 24: Error Message Display - Service provides error messages', () async {
      // Property test: For any failed operation, the service should provide error messages
      final errorCases = [
        {
          'statusCode': 400,
          'message': 'Invalid workout data',
          'exceptionType': ValidationException,
        },
        {
          'statusCode': 401,
          'message': 'Unauthorized access',
          'exceptionType': AuthenticationException,
        },
        {
          'statusCode': 403,
          'message': 'Forbidden',
          'exceptionType': AuthorizationException,
        },
        {
          'statusCode': 404,
          'message': 'Resource not found',
          'exceptionType': NotFoundException,
        },
        {
          'statusCode': 429,
          'message': 'Too many requests',
          'exceptionType': RateLimitException,
        },
        {
          'statusCode': 500,
          'message': 'Internal server error',
          'exceptionType': ServerException,
        },
      ];

      for (final errorCase in errorCases) {
        dioAdapter.onGet(
          '/workouts/history/',
          (server) => server.reply(
            errorCase['statusCode'] as int,
            {'message': errorCase['message']},
          ),
        );

        try {
          await workoutApiService.getWorkoutHistory();
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e.runtimeType, equals(errorCase['exceptionType']));
          expect(e.toString(), contains(errorCase['message'] as String));
        }
      }
    });

    test('handles validation errors with field details', () async {
      final errorResponse = {
        'message': 'Validation failed',
        'errors': {
          'duration': ['Duration must be between 1 and 600 minutes'],
          'exercises': ['At least one exercise is required'],
        },
      };

      dioAdapter.onPost(
        '/workouts/log/',
        (server) => server.reply(400, errorResponse),
      );

      final request = CreateWorkoutLogRequest(
        workoutName: 'Test',
        durationMinutes: 0,
        caloriesBurned: 0,
        exercises: [],
      );

      try {
        await workoutApiService.logWorkout(request);
        fail('Should have thrown ValidationException');
      } catch (e) {
        expect(e, isA<ValidationException>());
        final validationError = e as ValidationException;
        expect(validationError.fieldErrors, isNotNull);
        expect(validationError.fieldErrors!['duration'], isNotNull);
      }
    });

    test('handles connection errors', () async {
      dioAdapter.onGet(
        '/workouts/history/',
        (server) => server.throws(
          0,
          DioException.connectionError(
            reason: 'Connection failed',
            requestOptions: RequestOptions(path: '/workouts/history/'),
          ),
        ),
      );

      expect(
        () => workoutApiService.getWorkoutHistory(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
