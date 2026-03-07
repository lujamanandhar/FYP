# Requirements Document: Nutrition Tracking System

## Introduction

The Nutrition Tracking System implements a complete full-stack solution for the NutriLift app's nutrition tracking functionality. The system consists of two major components:

1. **Backend Integration**: Django REST Framework API with 6 core entities (FOOD_ITEM, INTAKE_LOG, HYDRATION_LOG, NUTRITION_GOALS, QUICK_LOG, NUTRITION_PROGRESS)
2. **Frontend Integration**: Flutter data layer connecting the existing UI to the backend API

The backend follows the same architectural patterns as the existing workout tracking module, ensuring consistency in authentication, error handling, and API design. The frontend follows the workout module's pattern of models → services → repositories → state management.

## Glossary

### Backend Components

- **Nutrition_System**: The complete backend subsystem handling nutrition tracking, including all models, serializers, views, and API endpoints
- **Food_Database**: The FOOD_ITEM table storing nutritional attributes per 100g for both system and custom foods
- **Intake_Logger**: The component responsible for recording meal/snack/drink entries in INTAKE_LOG
- **Progress_Aggregator**: The component that calculates daily totals and adherence percentages for NUTRITION_PROGRESS
- **Hydration_Tracker**: The component managing water intake logging in HYDRATION_LOG
- **Goal_Manager**: The component handling NUTRITION_GOALS CRUD operations
- **Quick_Access_Manager**: The component maintaining frequent meals in QUICK_LOG
- **Nutrient_Calculator**: The calculation engine using formula: (nutrient_per_100g ÷ 100) × quantity
- **Adherence_Calculator**: The calculation engine computing: (actual ÷ target) × 100
- **API_Endpoint**: A RESTful HTTP endpoint following Django REST Framework conventions
- **JWT_Token**: JSON Web Token used for authentication (already implemented)
- **PostgreSQL_Database**: The relational database storing all nutrition data
- **Serializer**: Django REST Framework component for data validation and transformation
- **Migration**: Django database schema change script
- **Signal**: Django event handler for post-save operations

### Frontend Components

- **Frontend_Client**: The existing Flutter application with completed nutrition tracking UI
- **Nutrition_Model**: Dart data classes representing nutrition entities (FoodItem, IntakeLog, etc.)
- **Nutrition_Service**: API client classes for HTTP communication with backend
- **Nutrition_Repository**: Data access layer abstracting API calls and providing business logic
- **Nutrition_Provider**: State management using Riverpod for reactive UI updates
- **DioClient**: Shared HTTP client with JWT authentication and error handling
- **Workout_Module**: The existing Flutter workout module serving as architectural reference

### System Integration

- **Challenge_System**: The existing gamification system requiring nutrition progress updates
- **Streak_System**: The existing streak tracking system requiring date-based updates
- **Wellness_System**: The existing wellness score system requiring nutrition adherence data
- **Round_Trip_Property**: A correctness property where parse(print(x)) == x

## Part 1: Backend Requirements

### Requirement 1: Food Item Management

**User Story:** As a user, I want to search for foods and create custom foods, so that I can log accurate nutritional information for my meals.

#### Acceptance Criteria

1. THE Food_Database SHALL store nutritional attributes per 100g including calories_per_100g, protein_per_100g, carbs_per_100g, fats_per_100g, fiber_per_100g, and sugar_per_100g
2. THE Food_Database SHALL support custom foods with an is_custom flag to distinguish user-created foods from system foods
3. WHEN a user searches for foods, THE Nutrition_System SHALL return matching FOOD_ITEM records ordered by relevance
4. WHEN a user creates a custom food, THE Nutrition_System SHALL validate all nutritional values are non-negative numbers
5. WHEN a user creates a custom food, THE Nutrition_System SHALL associate the food with the user_id for ownership tracking
6. THE Nutrition_System SHALL provide an API_Endpoint for retrieving food details by food_item_id
7. THE Nutrition_System SHALL provide an API_Endpoint for listing recent foods based on QUICK_LOG frequency data
8. WHEN retrieving food items, THE Nutrition_System SHALL include all nutritional attributes in the response payload

### Requirement 2: Meal Intake Logging

**User Story:** As a user, I want to log meals with specific quantities, so that the system can calculate my actual nutrient intake.

#### Acceptance Criteria

1. WHEN a user logs a meal, THE Intake_Logger SHALL retrieve the food_item_id from Food_Database
2. WHEN a user logs a meal, THE Nutrient_Calculator SHALL compute calories using formula: (calories_per_100g ÷ 100) × quantity
3. WHEN a user logs a meal, THE Nutrient_Calculator SHALL compute protein using formula: (protein_per_100g ÷ 100) × quantity
4. WHEN a user logs a meal, THE Nutrient_Calculator SHALL compute carbs using formula: (carbs_per_100g ÷ 100) × quantity
5. WHEN a user logs a meal, THE Nutrient_Calculator SHALL compute fats using formula: (fats_per_100g ÷ 100) × quantity
6. THE Intake_Logger SHALL store user_id, entry_type, food_item_id, description, quantity, unit, logged_at, and calculated macros in INTAKE_LOG
7. THE Intake_Logger SHALL support entry_type values of meal, snack, and drink
8. WHEN a user logs a meal, THE Nutrition_System SHALL record the logged_at timestamp in UTC format
9. THE Nutrition_System SHALL provide an API_Endpoint for creating INTAKE_LOG entries with JSON request body
10. THE Nutrition_System SHALL provide an API_Endpoint for retrieving INTAKE_LOG entries filtered by user_id and date range
11. THE Nutrition_System SHALL provide an API_Endpoint for updating existing INTAKE_LOG entries
12. THE Nutrition_System SHALL provide an API_Endpoint for deleting INTAKE_LOG entries by log_id

### Requirement 3: Daily Progress Aggregation

**User Story:** As a user, I want to see my daily nutrition totals and adherence percentage, so that I can track my progress toward my goals.

#### Acceptance Criteria

1. WHEN a meal is saved, THE Progress_Aggregator SHALL aggregate all INTAKE_LOG records for the current date filtered by user_id
2. WHEN a meal is saved, THE Progress_Aggregator SHALL sum total_calories from all INTAKE_LOG entries for the date
3. WHEN a meal is saved, THE Progress_Aggregator SHALL sum total_protein from all INTAKE_LOG entries for the date
4. WHEN a meal is saved, THE Progress_Aggregator SHALL sum total_carbs from all INTAKE_LOG entries for the date
5. WHEN a meal is saved, THE Progress_Aggregator SHALL sum total_fats from all INTAKE_LOG entries for the date
6. WHEN a meal is saved, THE Progress_Aggregator SHALL retrieve NUTRITION_GOALS for the user_id
7. WHEN a meal is saved, THE Adherence_Calculator SHALL compute adherence_percentage using formula: (actual ÷ target) × 100 for each macro
8. WHEN a meal is saved, THE Progress_Aggregator SHALL store progress_date, total_calories, total_protein, total_carbs, total_fats, and adherence_percentage in NUTRITION_PROGRESS
9. THE Nutrition_System SHALL provide an API_Endpoint for retrieving NUTRITION_PROGRESS by user_id and date
10. WHEN an INTAKE_LOG entry is deleted, THE Progress_Aggregator SHALL recalculate NUTRITION_PROGRESS for the affected date
11. WHEN an INTAKE_LOG entry is updated, THE Progress_Aggregator SHALL recalculate NUTRITION_PROGRESS for the affected date

### Requirement 4: Hydration Tracking

**User Story:** As a user, I want to log water intake throughout the day, so that I can track my hydration progress.

#### Acceptance Criteria

1. THE Hydration_Tracker SHALL store user_id, amount, unit, and logged_at in HYDRATION_LOG
2. THE Nutrition_System SHALL provide an API_Endpoint for creating HYDRATION_LOG entries
3. THE Nutrition_System SHALL provide an API_Endpoint for retrieving daily HYDRATION_LOG entries filtered by user_id and date
4. WHEN retrieving daily hydration, THE Hydration_Tracker SHALL sum all HYDRATION_LOG.amount values for the date
5. WHEN retrieving daily hydration, THE Hydration_Tracker SHALL compare the sum to NUTRITION_GOALS.daily_water
6. THE Hydration_Tracker SHALL compute hydration_percentage using formula: (actual_water ÷ daily_water) × 100
7. THE Nutrition_System SHALL provide an API_Endpoint for deleting HYDRATION_LOG entries by log_id

### Requirement 5: Nutrition Goals Management

**User Story:** As a user, I want to set and update my daily nutrition targets, so that the system can calculate my adherence accurately.

#### Acceptance Criteria

1. THE Goal_Manager SHALL store daily_calories, daily_protein, daily_carbs, daily_fats, and daily_water in NUTRITION_GOALS
2. THE Goal_Manager SHALL associate NUTRITION_GOALS with user_id for per-user targets
3. THE Nutrition_System SHALL provide an API_Endpoint for creating NUTRITION_GOALS for a user_id
4. THE Nutrition_System SHALL provide an API_Endpoint for retrieving NUTRITION_GOALS by user_id
5. THE Nutrition_System SHALL provide an API_Endpoint for updating NUTRITION_GOALS by user_id
6. WHEN NUTRITION_GOALS are updated, THE Progress_Aggregator SHALL recalculate adherence_percentage for all existing NUTRITION_PROGRESS records
7. WHEN a user has no NUTRITION_GOALS, THE Nutrition_System SHALL return default values of 2000 calories, 150g protein, 200g carbs, 65g fats, 2000ml water

### Requirement 6: Quick Access to Frequent Foods

**User Story:** As a user, I want to see my recent and frequent foods, so that I can quickly log meals I eat regularly.

#### Acceptance Criteria

1. THE Quick_Access_Manager SHALL maintain a frequent_meals JSON field in QUICK_LOG
2. WHEN a user logs a meal, THE Quick_Access_Manager SHALL increment the usage count for the food_item_id in frequent_meals
3. WHEN a user logs a meal, THE Quick_Access_Manager SHALL update the last_used timestamp for the food_item_id in frequent_meals
4. THE Nutrition_System SHALL provide an API_Endpoint for retrieving frequent foods ordered by usage count descending
5. THE Nutrition_System SHALL provide an API_Endpoint for retrieving recent foods ordered by last_used descending
6. THE Quick_Access_Manager SHALL limit frequent_meals to the top 20 most used foods per user

### Requirement 7-16: Backend System Requirements

(Requirements 7-16 cover Challenge System Integration, Streak System Integration, Wellness Score Integration, Authentication and Authorization, Data Validation and Error Handling, Database Schema and Migrations, API Serialization and Deserialization, Performance and Optimization, Testing and Quality Assurance, and Frontend Integration - see backend spec for full details)

## Part 2: Frontend Requirements

### Requirement 17: Flutter Data Models

**User Story:** As a frontend developer, I want Dart data classes for all nutrition entities, so that I can work with type-safe nutrition data in Flutter.

#### Acceptance Criteria

1. THE Frontend_Client SHALL provide a FoodItem model with all nutritional fields matching the backend schema
2. THE Frontend_Client SHALL provide an IntakeLog model with calculated macro fields
3. THE Frontend_Client SHALL provide a HydrationLog model with amount and unit fields
4. THE Frontend_Client SHALL provide a NutritionGoals model with daily target fields
5. THE Frontend_Client SHALL provide a NutritionProgress model with aggregated totals and adherence fields
6. THE Frontend_Client SHALL provide a QuickLog model with frequent meals list
7. ALL models SHALL include fromJson and toJson methods for API serialization
8. ALL models SHALL include copyWith methods for immutable updates
9. ALL models SHALL include equality operators for state comparison

### Requirement 18: API Service Layer

**User Story:** As a frontend developer, I want API service classes for nutrition endpoints, so that I can make HTTP requests to the backend.

#### Acceptance Criteria

1. THE Frontend_Client SHALL provide a NutritionApiService class with methods for all nutrition endpoints
2. THE NutritionApiService SHALL use the shared DioClient for HTTP requests with JWT authentication
3. THE NutritionApiService SHALL provide searchFoods method with query parameter
4. THE NutritionApiService SHALL provide createCustomFood method with FoodItem data
5. THE NutritionApiService SHALL provide logMeal method with IntakeLog data
6. THE NutritionApiService SHALL provide getIntakeLogs method with date range filtering
7. THE NutritionApiService SHALL provide logHydration method with HydrationLog data
8. THE NutritionApiService SHALL provide getProgress method with date parameter
9. THE NutritionApiService SHALL provide getGoals and updateGoals methods
10. THE NutritionApiService SHALL handle API errors and throw typed exceptions

### Requirement 19: Repository Layer

**User Story:** As a frontend developer, I want repository classes that abstract API calls, so that I can separate business logic from API implementation.

#### Acceptance Criteria

1. THE Frontend_Client SHALL provide a NutritionRepository class with business logic methods
2. THE NutritionRepository SHALL use NutritionApiService for API communication
3. THE NutritionRepository SHALL provide searchFoods method with caching for recent searches
4. THE NutritionRepository SHALL provide logMeal method that returns updated progress
5. THE NutritionRepository SHALL provide getDailyProgress method with date parameter
6. THE NutritionRepository SHALL provide getFrequentFoods method for quick access
7. THE NutritionRepository SHALL handle errors and provide user-friendly error messages
8. THE NutritionRepository SHALL cache nutrition goals to minimize API calls

### Requirement 20: State Management

**User Story:** As a frontend developer, I want Riverpod providers for nutrition state, so that the UI can reactively update when nutrition data changes.

#### Acceptance Criteria

1. THE Frontend_Client SHALL provide nutritionRepositoryProvider for dependency injection
2. THE Frontend_Client SHALL provide dailyProgressProvider with date parameter
3. THE Frontend_Client SHALL provide intakeLogsProvider with date parameter
4. THE Frontend_Client SHALL provide nutritionGoalsProvider for user goals
5. THE Frontend_Client SHALL provide frequentFoodsProvider for quick access
6. ALL providers SHALL automatically refresh when related data changes
7. ALL providers SHALL handle loading and error states
8. THE Frontend_Client SHALL provide logMealProvider for meal logging actions

### Requirement 21: UI Integration

**User Story:** As a user, I want the existing nutrition tracking UI to connect to the backend, so that my nutrition data is persisted and synced.

#### Acceptance Criteria

1. THE Frontend_Client SHALL replace hardcoded nutrition data with API calls
2. THE nutrition_tracking.dart screen SHALL use dailyProgressProvider for macro cards
3. THE add meal screen SHALL use logMealProvider to save meals
4. THE food search SHALL use searchFoods from repository
5. THE custom food form SHALL use createCustomFood from repository
6. THE hydration section SHALL use logHydration from repository
7. THE goals screen SHALL use nutritionGoalsProvider for display and updates
8. ALL UI components SHALL show loading indicators during API calls
9. ALL UI components SHALL display error messages on API failures

### Requirement 22: Error Handling and Offline Support

**User Story:** As a user, I want clear error messages and graceful degradation when offline, so that I understand what's happening with my nutrition data.

#### Acceptance Criteria

1. THE Frontend_Client SHALL display user-friendly error messages for API failures
2. THE Frontend_Client SHALL show network error messages when offline
3. THE Frontend_Client SHALL show authentication error messages for 401 responses
4. THE Frontend_Client SHALL show validation error messages for 400 responses
5. THE Frontend_Client SHALL retry failed requests with exponential backoff
6. THE Frontend_Client SHALL cache recent nutrition data for offline viewing
7. THE Frontend_Client SHALL queue nutrition logs when offline and sync when online

### Requirement 23: Testing

**User Story:** As a developer, I want comprehensive tests for the Flutter nutrition integration, so that I can confidently deploy changes.

#### Acceptance Criteria

1. THE Frontend_Client SHALL include unit tests for all nutrition models
2. THE Frontend_Client SHALL include unit tests for NutritionApiService methods
3. THE Frontend_Client SHALL include unit tests for NutritionRepository methods
4. THE Frontend_Client SHALL include widget tests for nutrition UI components
5. THE Frontend_Client SHALL include integration tests for end-to-end nutrition flows
6. THE Frontend_Client SHALL achieve minimum 80% code coverage for nutrition module
