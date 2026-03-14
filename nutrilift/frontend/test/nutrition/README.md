# Nutrition Tracking Tests

This directory contains all tests for the Nutrition Tracking module.

## Test Structure

```
frontend/test/nutrition/
├── models/                    # Model tests (fromJson, toJson, copyWith, equality)
│   └── nutrition_models_test.dart
├── services/                  # API service tests (mocked Dio responses)
│   └── (to be created)
├── repositories/              # Repository tests (business logic, caching)
│   └── (to be created)
├── widgets/                   # Widget tests (UI components)
│   └── (to be created)
└── integration/               # Integration tests (end-to-end flows)
    └── (to be created)
```

## Test Coverage

### ✅ Completed Tests

#### Models (nutrition_models_test.dart)
- **FoodItem**: 5 tests
  - fromJson deserialization
  - toJson serialization
  - copyWith immutable updates
  - Equality operators
  - Null field handling
  
- **IntakeLog**: 5 tests
  - fromJson with nested food_item_details
  - toJson serialization
  - copyWith updates
  - Equality operators
  - Null field handling
  
- **HydrationLog**: 5 tests
  - fromJson deserialization
  - toJson serialization
  - copyWith updates
  - Equality operators
  - Null field handling
  
- **NutritionGoals**: 6 tests
  - fromJson deserialization
  - toJson serialization
  - copyWith updates
  - Equality operators
  - defaults() factory constructor
  - Null field handling
  
- **NutritionProgress**: 4 tests
  - fromJson deserialization
  - toJson serialization
  - copyWith updates
  - Equality operators
  
- **QuickLog**: 4 tests
  - fromJson deserialization
  - toJson serialization
  - copyWith updates
  - Equality operators
  
- **FrequentMealEntry**: 4 tests
  - fromJson deserialization
  - toJson serialization
  - copyWith updates
  - Equality operators

**Total Model Tests**: 33 tests

### ⏳ Pending Tests

#### Services (Task 16.2)
- Mock Dio responses for all API methods
- Test successful responses
- Test error responses (400, 401, 403, 404, 500)
- Test request parameters

#### Repositories (Task 16.3)
- Mock API service for all repository methods
- Test business logic
- Test error handling
- Test caching behavior

#### Widgets (Task 16.4)
- Test nutrition tracking screen with mock providers
- Test add meal screen with mock providers
- Test custom food form with mock providers
- Test loading and error states

#### Integration (Task 16.5 - Optional)
- Test end-to-end meal logging flow
- Test end-to-end food search flow
- Test end-to-end goals update flow

## Running Tests

### Run all nutrition tests
```bash
flutter test test/nutrition/
```

### Run specific test category
```bash
flutter test test/nutrition/models/
flutter test test/nutrition/services/
flutter test test/nutrition/repositories/
flutter test test/nutrition/widgets/
flutter test test/nutrition/integration/
```

### Run with coverage
```bash
flutter test --coverage test/nutrition/
```

### View coverage report
```bash
genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html in browser
```

## Test Guidelines

1. **Models**: Test serialization, deserialization, immutability, and equality
2. **Services**: Mock HTTP responses, test error handling
3. **Repositories**: Mock services, test business logic and caching
4. **Widgets**: Use mock providers, test UI states (loading, data, error)
5. **Integration**: Test complete user flows end-to-end

## Related Files

- Spec: `.kiro/specs/nutrition-tracking-system/tasks.md`
- Models: `frontend/lib/NutritionTracking/models/`
- Services: `frontend/lib/NutritionTracking/services/`
- Repositories: `frontend/lib/NutritionTracking/repositories/`
- Providers: `frontend/lib/NutritionTracking/providers/`
- Main UI: `frontend/lib/NutritionTracking/nutrition_tracking.dart`
