# Nutrition Tracking Integration Tests

This directory contains integration tests for the nutrition tracking system that test complete end-to-end user flows.

## Test Coverage

### 1. End-to-End Meal Logging Flow

**Scenario**: Complete flow from searching for food to logging a meal and verifying progress updates

**Steps**:
1. Search for a food item (e.g., "chicken breast")
2. Select food from search results
3. Log a meal with specific quantity
4. Verify meal is saved with correct calculated macros
5. Verify daily progress is updated automatically
6. Verify meal appears in intake logs for the day

**Expected Behavior**:
- Food search returns relevant results
- Meal logging calculates macros correctly: `(nutrient_per_100g ÷ 100) × quantity`
- Progress aggregates all meals for the day
- Adherence percentages are calculated: `(actual ÷ target) × 100`

**Example**:
```dart
// Search for food
final searchResults = await repository.searchFoods('chicken breast');
expect(searchResults, isNotEmpty);

// Log meal with 200g chicken breast
final intakeLog = IntakeLog(
  foodItemId: searchResults.first.id,
  entryType: 'meal',
  quantity: 200.0,
  unit: 'g',
  calories: 330.0,  // (165 / 100) * 200
  protein: 62.0,    // (31 / 100) * 200
  loggedAt: DateTime.now(),
);

final result = await repository.logMeal(intakeLog);
expect(result.calories, equals(330.0));

// Verify progress updated
final progress = await repository.getDailyProgress(DateTime.now());
expect(progress.totalCalories, equals(330.0));
expect(progress.caloriesAdherence, closeTo(16.5, 0.1)); // 330/2000 * 100
```

### 2. Multiple Meal Logging and Aggregation

**Scenario**: Log multiple meals throughout the day and verify correct aggregation

**Steps**:
1. Log breakfast (e.g., oatmeal - 389 cal, 17g protein)
2. Log lunch (e.g., chicken salad - 450 cal, 45g protein)
3. Log snack (e.g., apple - 78 cal, 0.4g protein)
4. Verify progress aggregates all meals correctly
5. Verify all logs are retrievable

**Expected Behavior**:
- Total calories = sum of all meals (917 cal)
- Total protein = sum of all meals (62.4g)
- Adherence calculated against daily goals
- All logs retrievable by date

### 3. Food Search and Custom Food Creation

**Scenario**: Search for food, create custom food when not found, then use it

**Steps**:
1. Search for a food that doesn't exist (e.g., "homemade protein shake")
2. Verify search returns empty results
3. Create custom food with nutritional values
4. Search again and verify custom food appears
5. Log a meal using the custom food
6. Verify custom food appears in frequent foods

**Expected Behavior**:
- Custom food is created with `isCustom: true`
- Custom food is associated with user
- Custom food appears in search results
- Custom food can be used for meal logging
- Custom food appears in frequent foods after use

**Example**:
```dart
// Create custom food
final customFood = FoodItem(
  name: 'Homemade Protein Shake',
  caloriesPer100g: 120.0,
  proteinPer100g: 20.0,
  isCustom: true,
);

final created = await repository.createCustomFood(customFood);
expect(created.isCustom, isTrue);

// Use in meal log
final mealLog = IntakeLog(
  foodItemId: created.id,
  quantity: 250.0,
  unit: 'ml',
  calories: 300.0,  // (120 / 100) * 250
  loggedAt: DateTime.now(),
);

await repository.logMeal(mealLog);
```

### 4. Goals Update and Adherence Recalculation

**Scenario**: Update nutrition goals and verify adherence is recalculated

**Steps**:
1. Get current goals (or defaults if none exist)
2. Log some meals with current goals
3. Check progress and adherence percentages
4. Update goals to higher targets
5. Verify adherence is recalculated with new goals
6. Verify goals are cached for performance

**Expected Behavior**:
- Default goals are created if none exist (2000 cal, 150g protein, etc.)
- Adherence calculated with current goals
- When goals updated, adherence recalculated for same intake
- Higher goals result in lower adherence percentages
- Goals are cached for 5 minutes

**Example**:
```dart
// Initial goals: 2000 cal
final currentGoals = await repository.getGoals();
expect(currentGoals.dailyCalories, equals(2000.0));

// Log meal: 500 cal
await repository.logMeal(mealLog);

// Check adherence: 500/2000 = 25%
final progress1 = await repository.getDailyProgress(DateTime.now());
expect(progress1.caloriesAdherence, closeTo(25.0, 0.1));

// Update goals: 2500 cal
final updatedGoals = currentGoals.copyWith(dailyCalories: 2500.0);
await repository.updateGoals(updatedGoals);

// Check adherence: 500/2500 = 20% (lower)
final progress2 = await repository.getDailyProgress(DateTime.now());
expect(progress2.caloriesAdherence, closeTo(20.0, 0.1));
```

### 5. Hydration Tracking Flow

**Scenario**: Log water intake and verify progress updates

**Steps**:
1. Log water intake (e.g., 500ml)
2. Verify hydration log is saved
3. Log more water (e.g., 750ml)
4. Verify progress includes total water
5. Verify water adherence is calculated

**Expected Behavior**:
- Water logs are saved with amount and unit
- Progress aggregates all water logs for the day
- Water adherence calculated: `(total_water ÷ daily_water) × 100`

**Example**:
```dart
// Log water
final hydrationLog1 = HydrationLog(
  amount: 500.0,
  unit: 'ml',
  loggedAt: DateTime.now(),
);

await repository.logHydration(hydrationLog1);

// Log more water
final hydrationLog2 = HydrationLog(
  amount: 750.0,
  unit: 'ml',
  loggedAt: DateTime.now(),
);

await repository.logHydration(hydrationLog2);

// Check progress
final progress = await repository.getDailyProgress(DateTime.now());
expect(progress.totalWater, equals(1250.0));  // 500 + 750
expect(progress.waterAdherence, closeTo(62.5, 0.1));  // 1250/2000 * 100
```

### 6. Complete Daily Journey

**Scenario**: Full day of nutrition tracking from start to finish

**Steps**:
1. Set nutrition goals for the day
2. Log breakfast
3. Log water
4. Log lunch
5. Log more water
6. Log snack
7. Check final progress for the day

**Expected Behavior**:
- All meals and hydration logs are aggregated
- Progress shows correct totals for all macros and water
- Adherence percentages calculated for all nutrients
- All operations complete successfully

**Example**:
```dart
// Set goals
final goals = await repository.getGoals();
expect(goals.dailyCalories, equals(2200.0));

// Log breakfast (400 cal, 30g protein)
await repository.logMeal(breakfast);

// Log water (500ml)
await repository.logHydration(water1);

// Log lunch (600 cal, 50g protein)
await repository.logMeal(lunch);

// Log more water (750ml)
await repository.logHydration(water2);

// Log snack (150 cal, 10g protein)
await repository.logMeal(snack);

// Check final progress
final progress = await repository.getDailyProgress(DateTime.now());
expect(progress.totalCalories, equals(1150.0));  // 400 + 600 + 150
expect(progress.totalProtein, equals(90.0));     // 30 + 50 + 10
expect(progress.totalWater, equals(1250.0));     // 500 + 750
expect(progress.caloriesAdherence, closeTo(52.27, 0.1));  // 1150/2200 * 100
```

### 7. Error Handling and Recovery

**Scenario**: Handle network errors with retry logic

**Steps**:
1. Attempt to log meal with network error
2. Verify retry logic kicks in
3. Verify operation succeeds on retry
4. Verify authentication errors are not retried
5. Verify validation errors are handled gracefully

**Expected Behavior**:
- Network errors trigger retry with exponential backoff
- Maximum 3 retry attempts
- Authentication errors (401) are not retried
- Validation errors (400) are not retried
- User-friendly error messages are provided

**Example**:
```dart
// Network error on first attempt, success on retry
// Repository should retry automatically
final result = await repository.logMeal(mealLog);
expect(result.id, isNotNull);

// Authentication error should not retry
expect(
  () => repository.logMeal(mealLog),
  throwsA(isA<Exception>()),
);
```

### 8. Food Search Caching

**Scenario**: Verify search results are cached for performance

**Steps**:
1. Search for a food item
2. Verify API is called
3. Search for same item again immediately
4. Verify cached results are used (no API call)
5. Verify cache expires after 2 minutes

**Expected Behavior**:
- First search hits API
- Subsequent searches within 2 minutes use cache
- Cache expires after 2 minutes
- Different search queries have separate cache entries

## Running Integration Tests

To run all integration tests:

```bash
cd frontend
flutter test test/nutrition/integration/
```

To run a specific test file:

```bash
flutter test test/nutrition/integration/nutrition_integration_test.dart
```

## Test Data

Integration tests use mock data that matches the backend API structure:

- **FoodItem**: Nutritional values per 100g
- **IntakeLog**: Meal logs with calculated macros
- **HydrationLog**: Water intake logs
- **NutritionGoals**: Daily targets
- **NutritionProgress**: Aggregated daily totals and adherence

## Notes

- Integration tests use mocked API service to avoid network calls
- Tests verify the complete flow from repository through to UI
- Tests validate business logic, caching, and error handling
- Tests ensure data consistency across operations
- Tests verify automatic progress updates via provider invalidation

## Requirements Validated

These integration tests validate:
- **Requirement 23.5**: Integration tests for end-to-end nutrition flows
- **Requirement 19.4**: Meal logging with progress updates
- **Requirement 19.5**: Daily progress and goals management
- **Requirement 19.6**: Quick access to frequent foods
- **Requirement 22.5**: Retry logic for failed requests
- **Requirement 20.6**: Provider invalidation after mutations
