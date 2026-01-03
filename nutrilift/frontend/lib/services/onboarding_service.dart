import 'package:flutter/foundation.dart';
import '../models/onboarding_data.dart';
import 'auth_service.dart';
import 'api_client.dart';

class OnboardingService extends ChangeNotifier {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  OnboardingData _data = OnboardingData();
  bool _isLoading = false;
  String? _error;

  // Getters
  OnboardingData get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Update gender
  void updateGender(String gender) {
    _data = _data.copyWith(gender: gender);
    _clearError();
    notifyListeners();
  }

  // Update age group
  void updateAgeGroup(String ageGroup) {
    _data = _data.copyWith(ageGroup: ageGroup);
    _clearError();
    notifyListeners();
  }

  // Update fitness level
  void updateFitnessLevel(String fitnessLevel) {
    _data = _data.copyWith(fitnessLevel: fitnessLevel);
    _clearError();
    notifyListeners();
  }

  // Update height
  void updateHeight(double height) {
    _data = _data.copyWith(height: height);
    _clearError();
    notifyListeners();
  }

  // Update weight
  void updateWeight(double weight) {
    _data = _data.copyWith(weight: weight);
    _clearError();
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    if (_error != null) {
      _error = null;
    }
  }

  // Initialize onboarding for a new session
  void initializeOnboarding() {
    clearData();
  }

  // Clear all data (for new onboarding session)
  void clearData() {
    _data = OnboardingData();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Validate current step
  String? validateCurrentStep(int step) {
    switch (step) {
      case 1: // Gender screen
        return _data.validateGender();
      case 2: // Age group screen
        return _data.validateAgeGroup();
      case 3: // Fitness level screen
        return _data.validateFitnessLevel();
      case 4: // Height screen
        return _data.validateHeight();
      case 5: // Weight screen
        return _data.validateWeight();
      default:
        return null;
    }
  }

  // Check if current step is valid
  bool isStepValid(int step) {
    return validateCurrentStep(step) == null;
  }

  // Submit profile data to backend
  Future<bool> submitProfile() async {
    if (!_data.isComplete) {
      _error = 'Please complete all onboarding steps';
      notifyListeners();
      return false;
    }

    final validationErrors = _data.validateAll();
    if (validationErrors.isNotEmpty) {
      _error = validationErrors.first;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final profileRequest = ProfileUpdateRequest(
        gender: _data.gender,
        ageGroup: _data.ageGroup,
        fitnessLevel: _data.fitnessLevel,
        height: _data.height,
        weight: _data.weight,
      );

      await authService.updateProfile(profileRequest);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to save profile: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Get progress for current step
  double getProgressForStep(int step) {
    switch (step) {
      case 1:
        return 0.2; // 20% after gender
      case 2:
        return 0.4; // 40% after age group
      case 3:
        return 0.6; // 60% after fitness level
      case 4:
        return 0.8; // 80% after height
      case 5:
        return 1.0; // 100% after weight
      default:
        return 0.0;
    }
  }

  // Check if we can proceed to next step
  bool canProceedFromStep(int step) {
    return isStepValid(step);
  }

  // Get user-friendly error message for step
  String? getStepErrorMessage(int step) {
    final error = validateCurrentStep(step);
    if (error == null) return null;

    // Convert technical validation errors to user-friendly messages
    switch (step) {
      case 1:
        return 'Please select your gender to continue';
      case 2:
        return 'Please select your age group to continue';
      case 3:
        return 'Please select your fitness level to continue';
      case 4:
        return 'Please set your height to continue';
      case 5:
        return 'Please set your weight to continue';
      default:
        return error;
    }
  }

  // Reset error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get summary of collected data for review
  Map<String, String> getDataSummary() {
    return {
      'Gender': _data.gender ?? 'Not selected',
      'Age Group': _data.ageGroup ?? 'Not selected',
      'Fitness Level': _data.fitnessLevel ?? 'Not selected',
      'Height': _data.height != null ? '${_data.height!.toInt()} cm' : 'Not set',
      'Weight': _data.weight != null ? '${_data.weight!.toInt()} kg' : 'Not set',
    };
  }
}