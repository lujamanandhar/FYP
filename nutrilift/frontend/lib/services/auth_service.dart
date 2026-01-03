import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();

  // Register a new user
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.post('/auth/register', body: request.toJson());
      
      final authResponse = AuthResponse.fromJson(response.getData<Map<String, dynamic>>() ?? {});
      
      // Set the auth token for future requests
      if (authResponse.token != null) {
        _apiClient.setAuthToken(authResponse.token);
      }
      
      return authResponse;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Registration failed: ${e.toString()}');
    }
  }

  // Login with email and password
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post('/auth/login', body: request.toJson());
      
      final authResponse = AuthResponse.fromJson(response.getData<Map<String, dynamic>>() ?? {});
      
      // Set the auth token for future requests
      if (authResponse.token != null) {
        _apiClient.setAuthToken(authResponse.token);
      }
      
      return authResponse;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Login failed: ${e.toString()}');
    }
  }

  // Get current user profile
  Future<UserProfile> getProfile() async {
    try {
      final response = await _apiClient.get('/auth/me');
      
      final profileData = response.getData<Map<String, dynamic>>();
      if (profileData == null || profileData['user'] == null) {
        throw ApiException('Invalid profile data received');
      }
      
      return UserProfile.fromJson(profileData['user'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to get profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<UserProfile> updateProfile(ProfileUpdateRequest request) async {
    try {
      final response = await _apiClient.put('/auth/profile', body: request.toJson());
      
      final profileData = response.getData<Map<String, dynamic>>();
      if (profileData == null || profileData['user'] == null) {
        throw ApiException('Invalid profile data received');
      }
      
      return UserProfile.fromJson(profileData['user'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update profile: ${e.toString()}');
    }
  }

  // Set authentication token (for when token is loaded from storage)
  void setAuthToken(String? token) {
    _apiClient.setAuthToken(token);
  }

  // Clear authentication token
  void clearAuthToken() {
    _apiClient.setAuthToken(null);
  }

  // Dispose resources
  void dispose() {
    _apiClient.dispose();
  }
}

// Request models
class RegisterRequest {
  final String email;
  final String password;
  final String name;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
    };
  }

  // Validation
  String? validateEmail() {
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword() {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters long';
    return null;
  }

  String? validateName() {
    if (name.isEmpty) return 'Name is required';
    if (name.length < 2) return 'Name must be at least 2 characters long';
    return null;
  }

  List<String> validate() {
    final errors = <String>[];
    final emailError = validateEmail();
    final passwordError = validatePassword();
    final nameError = validateName();
    
    if (emailError != null) errors.add(emailError);
    if (passwordError != null) errors.add(passwordError);
    if (nameError != null) errors.add(nameError);
    
    return errors;
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  // Validation
  String? validateEmail() {
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword() {
    if (password.isEmpty) return 'Password is required';
    return null;
  }

  List<String> validate() {
    final errors = <String>[];
    final emailError = validateEmail();
    final passwordError = validatePassword();
    
    if (emailError != null) errors.add(emailError);
    if (passwordError != null) errors.add(passwordError);
    
    return errors;
  }
}

class ProfileUpdateRequest {
  final String? name;
  final String? gender;
  final String? ageGroup;
  final double? height;
  final double? weight;
  final String? fitnessLevel;

  ProfileUpdateRequest({
    this.name,
    this.gender,
    this.ageGroup,
    this.height,
    this.weight,
    this.fitnessLevel,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (name != null) json['name'] = name;
    if (gender != null) json['gender'] = gender;
    if (ageGroup != null) json['age_group'] = ageGroup;
    if (height != null) json['height'] = height;
    if (weight != null) json['weight'] = weight;
    if (fitnessLevel != null) json['fitness_level'] = fitnessLevel;
    
    return json;
  }

  // Validation
  String? validateHeight() {
    if (height != null && height! <= 0) return 'Height must be a positive number';
    return null;
  }

  String? validateWeight() {
    if (weight != null && weight! <= 0) return 'Weight must be a positive number';
    return null;
  }

  String? validateGender() {
    if (gender != null && !['Male', 'Female'].contains(gender)) {
      return 'Gender must be Male or Female';
    }
    return null;
  }

  String? validateAgeGroup() {
    if (ageGroup != null && !['Adult', 'Mid-Age Adult', 'Older Adult'].contains(ageGroup)) {
      return 'Invalid age group';
    }
    return null;
  }

  String? validateFitnessLevel() {
    if (fitnessLevel != null && !['Beginner', 'Intermediate', 'Advance'].contains(fitnessLevel)) {
      return 'Invalid fitness level';
    }
    return null;
  }

  List<String> validate() {
    final errors = <String>[];
    final heightError = validateHeight();
    final weightError = validateWeight();
    final genderError = validateGender();
    final ageGroupError = validateAgeGroup();
    final fitnessLevelError = validateFitnessLevel();
    
    if (heightError != null) errors.add(heightError);
    if (weightError != null) errors.add(weightError);
    if (genderError != null) errors.add(genderError);
    if (ageGroupError != null) errors.add(ageGroupError);
    if (fitnessLevelError != null) errors.add(fitnessLevelError);
    
    return errors;
  }
}

// Response models
class AuthResponse {
  final UserProfile? user;
  final String? token;

  AuthResponse({
    this.user,
    this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] != null ? UserProfile.fromJson(json['user'] as Map<String, dynamic>) : null,
      token: json['token'] as String?,
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? gender;
  final String? ageGroup;
  final double? height;
  final double? weight;
  final String? fitnessLevel;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.gender,
    this.ageGroup,
    this.height,
    this.weight,
    this.fitnessLevel,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      ageGroup: json['age_group'] as String?,
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      fitnessLevel: json['fitness_level'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'gender': gender,
      'age_group': ageGroup,
      'height': height,
      'weight': weight,
      'fitness_level': fitnessLevel,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get hasCompleteProfile {
    return name != null &&
           gender != null &&
           ageGroup != null &&
           height != null &&
           weight != null &&
           fitnessLevel != null;
  }

  String get displayName => name ?? email.split('@').first;

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? gender,
    String? ageGroup,
    double? height,
    double? weight,
    String? fitnessLevel,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}