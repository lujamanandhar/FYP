class OnboardingData {
  String? gender;
  String? ageGroup;
  String? fitnessLevel;
  double? height;
  double? weight;

  OnboardingData({
    this.gender,
    this.ageGroup,
    this.fitnessLevel,
    this.height,
    this.weight,
  });

  // Create a copy with updated values
  OnboardingData copyWith({
    String? gender,
    String? ageGroup,
    String? fitnessLevel,
    double? height,
    double? weight,
  }) {
    return OnboardingData(
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }

  // Convert to ProfileUpdateRequest for API call
  Map<String, dynamic> toProfileUpdateJson() {
    final json = <String, dynamic>{};
    
    if (gender != null) json['gender'] = gender;
    if (ageGroup != null) json['age_group'] = ageGroup;
    if (fitnessLevel != null) json['fitness_level'] = fitnessLevel;
    if (height != null) json['height'] = height;
    if (weight != null) json['weight'] = weight;
    
    return json;
  }

  // Validation methods
  String? validateGender() {
    if (gender == null || gender!.isEmpty) {
      return 'Please select your gender';
    }
    if (!['Male', 'Female'].contains(gender)) {
      return 'Invalid gender selection';
    }
    return null;
  }

  String? validateAgeGroup() {
    if (ageGroup == null || ageGroup!.isEmpty) {
      return 'Please select your age group';
    }
    if (!['Adult', 'Mid-Age Adult', 'Older Adult'].contains(ageGroup)) {
      return 'Invalid age group selection';
    }
    return null;
  }

  String? validateFitnessLevel() {
    if (fitnessLevel == null || fitnessLevel!.isEmpty) {
      return 'Please select your fitness level';
    }
    if (!['Beginner', 'Intermediate', 'Advance'].contains(fitnessLevel)) {
      return 'Invalid fitness level selection';
    }
    return null;
  }

  String? validateHeight() {
    if (height == null) {
      return 'Please set your height';
    }
    if (height! <= 0 || height! < 120 || height! > 220) {
      return 'Height must be between 120 and 220 cm';
    }
    return null;
  }

  String? validateWeight() {
    if (weight == null) {
      return 'Please set your weight';
    }
    if (weight! <= 0 || weight! < 30 || weight! > 200) {
      return 'Weight must be between 30 and 200 kg';
    }
    return null;
  }

  // Validate all fields and return list of errors
  List<String> validateAll() {
    final errors = <String>[];
    
    final genderError = validateGender();
    final ageGroupError = validateAgeGroup();
    final fitnessLevelError = validateFitnessLevel();
    final heightError = validateHeight();
    final weightError = validateWeight();
    
    if (genderError != null) errors.add(genderError);
    if (ageGroupError != null) errors.add(ageGroupError);
    if (fitnessLevelError != null) errors.add(fitnessLevelError);
    if (heightError != null) errors.add(heightError);
    if (weightError != null) errors.add(weightError);
    
    return errors;
  }

  // Check if all required fields are filled
  bool get isComplete {
    return gender != null &&
           ageGroup != null &&
           fitnessLevel != null &&
           height != null &&
           weight != null;
  }

  // Get completion percentage for progress tracking
  double get completionPercentage {
    int filledFields = 0;
    const int totalFields = 5;
    
    if (gender != null) filledFields++;
    if (ageGroup != null) filledFields++;
    if (fitnessLevel != null) filledFields++;
    if (height != null) filledFields++;
    if (weight != null) filledFields++;
    
    return filledFields / totalFields;
  }

  @override
  String toString() {
    return 'OnboardingData(gender: $gender, ageGroup: $ageGroup, fitnessLevel: $fitnessLevel, height: $height, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OnboardingData &&
           other.gender == gender &&
           other.ageGroup == ageGroup &&
           other.fitnessLevel == fitnessLevel &&
           other.height == height &&
           other.weight == weight;
  }

  @override
  int get hashCode {
    return gender.hashCode ^
           ageGroup.hashCode ^
           fitnessLevel.hashCode ^
           height.hashCode ^
           weight.hashCode;
  }
}