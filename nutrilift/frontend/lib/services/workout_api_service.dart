import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/workout_models.dart';
import 'token_service.dart';

class WorkoutApiService {
  final String baseUrl;
  final TokenService _tokenService = TokenService();

  WorkoutApiService({this.baseUrl = 'http://127.0.0.1:8000/api'});

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== EXERCISES ====================

  /// Get all exercises
  Future<List<Exercise>> getExercises({String? category, String? difficulty}) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (difficulty != null) queryParams['difficulty'] = difficulty;

    final uri = Uri.parse('$baseUrl/workouts/exercises/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Exercise.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exercises: ${response.body}');
    }
  }

  /// Get exercise by ID
  Future<Exercise> getExercise(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workouts/exercises/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Exercise.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load exercise: ${response.body}');
    }
  }

  // ==================== GYMS ====================

  /// Get all gyms
  Future<List<Gym>> getGyms({String? location}) async {
    final queryParams = <String, String>{};
    if (location != null) queryParams['location'] = location;

    final uri = Uri.parse('$baseUrl/workouts/gyms/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Gym.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load gyms: ${response.body}');
    }
  }

  /// Get gym by ID
  Future<Gym> getGym(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workouts/gyms/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Gym.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load gym: ${response.body}');
    }
  }

  // ==================== WORKOUT LOGS ====================

  /// Get all workout logs for the current user
  Future<List<WorkoutLog>> getWorkoutLogs({DateTime? startDate, DateTime? endDate}) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

    final uri = Uri.parse('$baseUrl/workouts/logs/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => WorkoutLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load workout logs: ${response.body}');
    }
  }

  /// Get workout log by ID
  Future<WorkoutLog> getWorkoutLog(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workouts/logs/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return WorkoutLog.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load workout log: ${response.body}');
    }
  }

  /// Create a new workout log
  Future<WorkoutLog> createWorkoutLog(CreateWorkoutLogRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workouts/logs/'),
      headers: await _getHeaders(),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return WorkoutLog.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create workout log: ${response.body}');
    }
  }

  /// Update a workout log
  Future<WorkoutLog> updateWorkoutLog(String id, CreateWorkoutLogRequest request) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workouts/logs/$id/'),
      headers: await _getHeaders(),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return WorkoutLog.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update workout log: ${response.body}');
    }
  }

  /// Delete a workout log
  Future<void> deleteWorkoutLog(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workouts/logs/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete workout log: ${response.body}');
    }
  }

  // ==================== CUSTOM WORKOUTS ====================

  /// Get all custom workouts for the current user
  Future<List<CustomWorkout>> getCustomWorkouts({bool? isPublic}) async {
    final queryParams = <String, String>{};
    if (isPublic != null) queryParams['is_public'] = isPublic.toString();

    final uri = Uri.parse('$baseUrl/workouts/custom-workouts/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CustomWorkout.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load custom workouts: ${response.body}');
    }
  }

  /// Get custom workout by ID
  Future<CustomWorkout> getCustomWorkout(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workouts/custom-workouts/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return CustomWorkout.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load custom workout: ${response.body}');
    }
  }

  /// Create a new custom workout
  Future<CustomWorkout> createCustomWorkout(CreateCustomWorkoutRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workouts/custom-workouts/'),
      headers: await _getHeaders(),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return CustomWorkout.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create custom workout: ${response.body}');
    }
  }

  /// Update a custom workout
  Future<CustomWorkout> updateCustomWorkout(String id, CreateCustomWorkoutRequest request) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workouts/custom-workouts/$id/'),
      headers: await _getHeaders(),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return CustomWorkout.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update custom workout: ${response.body}');
    }
  }

  /// Delete a custom workout
  Future<void> deleteCustomWorkout(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workouts/custom-workouts/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete custom workout: ${response.body}');
    }
  }

  // ==================== PERSONAL RECORDS ====================

  /// Get all personal records for the current user
  Future<List<PersonalRecord>> getPersonalRecords({String? exerciseId}) async {
    final queryParams = <String, String>{};
    if (exerciseId != null) queryParams['exercise_id'] = exerciseId;

    final uri = Uri.parse('$baseUrl/workouts/personal-records/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PersonalRecord.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load personal records: ${response.body}');
    }
  }

  /// Get personal record by ID
  Future<PersonalRecord> getPersonalRecord(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workouts/personal-records/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return PersonalRecord.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load personal record: ${response.body}');
    }
  }

  // ==================== STATISTICS ====================

  /// Get workout statistics for the current user
  Future<Map<String, dynamic>> getWorkoutStatistics({DateTime? startDate, DateTime? endDate}) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

    final uri = Uri.parse('$baseUrl/workouts/statistics/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workout statistics: ${response.body}');
    }
  }
}
