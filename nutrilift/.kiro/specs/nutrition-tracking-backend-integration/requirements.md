# Requirements Document

## Introduction

The Nutrition Tracking Backend Integration feature implements a complete backend system for the NutriLift app's nutrition tracking functionality. The system connects to an existing Flutter frontend that provides date navigation, macro tracking, meal logging, food search, custom food entry, and visualization features. The backend must implement six core entities (FOOD_ITEM, INTAKE_LOG, HYDRATION_LOG, NUTRITION_GOALS, QUICK_LOG, NUTRITION_PROGRESS) with Django REST Framework, following the same architectural patterns as the existing workout tracking module.

## Glossary

- **Nutrition_System**: The complete backend subsystem handling nutrition tracking, including all models, serializers, views, and API endpoints
- **Food_Database**: The FOOD_ITEM table storing nutritional attributes per 100g for both system and custom foods
- **Intake_Logger**: The component responsible for recording meal/snack/drink entries in INTAKE_LOG
- **Progress_Aggregator**: The component that calculates daily totals and adherence percentages for NUTRITION_PROGRESS
- **Hydration_Tracker**: The component managing water intake logging in HYDRATION_LOG
- **Goal_Manager**: The component handling NUTRITION_GOALS CRUD operations
- **Quick_Access_Manager**: The component maintaining frequent meals in QUICK_LOG
- **Nutrient_Calculator**: The calculation engine using formula: (nutrient_per_100g ÷ 100) × quantity
- **Adherence_Calculator**: The calculation engine computing: (actual ÷ target) × 100
- **Frontend_Client**: The existing Flutter application with completed nutrition tracking UI
- **Workout_Module**: The existing Django REST Framework module serving as architectural reference
- **Challenge_System**: The existing gamification system requiring nutrition progress updates
- **Streak_System**: The existing streak tracking system requiring date-based updates
- **Wellness_System**: The existing wellness score system requiring nutrition adherence data
- **API_Endpoint**: A RESTful HTTP endpoint following Django REST Framework conventions
- **JWT_Token**: JSON Web Token used for authentication (already implemented)
- **PostgreSQL_Database**: The relational database storing all nutrition data
- **Serializer**: Django REST Framework component for data validation and transformation
- **Migration**: Django database schema change script
- **Signal**: Django event handler for post-save operations
- **Round_Trip_Property**: A correctness property where parse(print(x)) == x

## Requirements

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

### Requirement 7: Challenge System Integration

**User Story:** As a user, I want my nutrition logging to count toward nutrition-related challenges, so that I can earn rewards for healthy eating.

#### Acceptance Criteria

1. WHEN a meal is logged, THE Nutrition_System SHALL check for active nutrition-related challenges for the user_id
2. WHEN a nutrition-related challenge is active, THE Nutrition_System SHALL update CHALLENGE_PARTICIPANT.progress for the user_id
3. THE Nutrition_System SHALL trigger challenge progress updates for daily calorie goals, protein targets, and meal logging streaks
4. WHEN a challenge milestone is reached, THE Nutrition_System SHALL emit a signal for the Challenge_System to process rewards

### Requirement 8: Streak System Integration

**User Story:** As a user, I want my nutrition logging to maintain my daily streak, so that I can track my consistency.

#### Acceptance Criteria

1. WHEN a user logs nutrition on a new date, THE Nutrition_System SHALL check the user's current streak in the Streak_System
2. WHEN a user logs nutrition on a new date, THE Nutrition_System SHALL update the STREAK entity with the new date
3. WHEN a user logs nutrition on consecutive dates, THE Nutrition_System SHALL increment the streak counter
4. WHEN a user breaks a streak, THE Nutrition_System SHALL reset the streak counter to 1

### Requirement 9: Wellness Score Integration

**User Story:** As a user, I want my nutrition adherence to contribute to my wellness score, so that I can see my overall health progress.

#### Acceptance Criteria

1. WHEN NUTRITION_PROGRESS is updated, THE Nutrition_System SHALL trigger a wellness score recalculation
2. THE Nutrition_System SHALL provide adherence_percentage data to the Wellness_System
3. THE Wellness_System SHALL incorporate nutrition adherence into the overall WELLNESS_SCORE calculation
4. WHEN nutrition adherence changes, THE Wellness_System SHALL update the WELLNESS_SCORE within 5 seconds

### Requirement 10: Authentication and Authorization

**User Story:** As a user, I want my nutrition data to be secure and private, so that only I can access my meal logs and goals.

#### Acceptance Criteria

1. THE Nutrition_System SHALL require a valid JWT_Token for all API_Endpoint requests
2. THE Nutrition_System SHALL extract user_id from the JWT_Token for data filtering
3. THE Nutrition_System SHALL return HTTP 401 Unauthorized when JWT_Token is missing or invalid
4. THE Nutrition_System SHALL return HTTP 403 Forbidden when a user attempts to access another user's nutrition data
5. THE Nutrition_System SHALL validate JWT_Token signature using the same secret key as the Workout_Module

### Requirement 11: Data Validation and Error Handling

**User Story:** As a user, I want clear error messages when I submit invalid data, so that I can correct my input and successfully log meals.

#### Acceptance Criteria

1. WHEN a user submits invalid nutritional values, THE Nutrition_System SHALL return HTTP 400 Bad Request with descriptive error messages
2. THE Nutrition_System SHALL validate that quantity values are positive numbers greater than zero
3. THE Nutrition_System SHALL validate that nutritional values are non-negative numbers
4. THE Nutrition_System SHALL validate that entry_type is one of meal, snack, or drink
5. THE Nutrition_System SHALL validate that unit is a recognized measurement unit
6. WHEN a database constraint is violated, THE Nutrition_System SHALL return HTTP 409 Conflict with the constraint name
7. WHEN a requested resource is not found, THE Nutrition_System SHALL return HTTP 404 Not Found
8. WHEN an internal error occurs, THE Nutrition_System SHALL return HTTP 500 Internal Server Error and log the error details

### Requirement 12: Database Schema and Migrations

**User Story:** As a developer, I want database migrations for all nutrition tables, so that the schema can be version controlled and deployed consistently.

#### Acceptance Criteria

1. THE Nutrition_System SHALL provide a Migration for creating the FOOD_ITEM table with all required columns
2. THE Nutrition_System SHALL provide a Migration for creating the INTAKE_LOG table with all required columns
3. THE Nutrition_System SHALL provide a Migration for creating the HYDRATION_LOG table with all required columns
4. THE Nutrition_System SHALL provide a Migration for creating the NUTRITION_GOALS table with all required columns
5. THE Nutrition_System SHALL provide a Migration for creating the QUICK_LOG table with all required columns
6. THE Nutrition_System SHALL provide a Migration for creating the NUTRITION_PROGRESS table with all required columns
7. THE Nutrition_System SHALL define foreign key constraints between INTAKE_LOG.food_item_id and FOOD_ITEM.id
8. THE Nutrition_System SHALL define indexes on user_id columns for query performance
9. THE Nutrition_System SHALL define indexes on date columns for query performance
10. THE Nutrition_System SHALL define a unique constraint on NUTRITION_GOALS.user_id to enforce one goal set per user

### Requirement 13: API Serialization and Deserialization

**User Story:** As a frontend developer, I want consistent JSON formats for all API responses, so that I can reliably parse nutrition data in the Flutter app.

#### Acceptance Criteria

1. THE Nutrition_System SHALL provide a Serializer for FOOD_ITEM with all nutritional fields
2. THE Nutrition_System SHALL provide a Serializer for INTAKE_LOG with nested food_item details
3. THE Nutrition_System SHALL provide a Serializer for HYDRATION_LOG with all required fields
4. THE Nutrition_System SHALL provide a Serializer for NUTRITION_GOALS with all target fields
5. THE Nutrition_System SHALL provide a Serializer for NUTRITION_PROGRESS with all aggregated fields
6. THE Nutrition_System SHALL provide a Serializer for QUICK_LOG with food_item details
7. FOR ALL Serializer implementations, THE Nutrition_System SHALL validate that serializing then deserializing produces equivalent data (Round_Trip_Property)
8. THE Nutrition_System SHALL use snake_case for JSON field names to match Python conventions
9. THE Nutrition_System SHALL format datetime fields as ISO 8601 strings with UTC timezone
10. THE Nutrition_System SHALL include field-level validation in Serializer classes

### Requirement 14: Performance and Optimization

**User Story:** As a user, I want fast API responses when logging meals and viewing progress, so that the app feels responsive.

#### Acceptance Criteria

1. WHEN retrieving daily progress, THE Nutrition_System SHALL use the pre-aggregated NUTRITION_PROGRESS table instead of computing on-demand
2. THE Nutrition_System SHALL complete INTAKE_LOG creation requests within 200ms for 95% of requests
3. THE Nutrition_System SHALL complete NUTRITION_PROGRESS retrieval requests within 100ms for 95% of requests
4. THE Nutrition_System SHALL use database indexes on user_id and date columns for query optimization
5. THE Nutrition_System SHALL use select_related for foreign key queries to minimize database round trips
6. THE Nutrition_System SHALL limit API response pagination to 50 items per page
7. WHEN aggregating daily totals, THE Progress_Aggregator SHALL use a single database query with SUM aggregation

### Requirement 15: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive tests for the nutrition system, so that I can confidently deploy changes without breaking functionality.

#### Acceptance Criteria

1. THE Nutrition_System SHALL include unit tests for all Serializer validation logic
2. THE Nutrition_System SHALL include unit tests for Nutrient_Calculator formulas
3. THE Nutrition_System SHALL include unit tests for Adherence_Calculator formulas
4. THE Nutrition_System SHALL include integration tests for all API_Endpoint operations
5. THE Nutrition_System SHALL include property-based tests for Round_Trip_Property on all Serializer classes
6. THE Nutrition_System SHALL include property-based tests for invariant properties on aggregation calculations
7. THE Nutrition_System SHALL include tests for authentication and authorization rules
8. THE Nutrition_System SHALL include tests for database constraint violations
9. THE Nutrition_System SHALL include tests for Signal handlers triggering Progress_Aggregator updates
10. THE Nutrition_System SHALL achieve minimum 90% code coverage for the nutrition module

### Requirement 16: Frontend Integration

**User Story:** As a frontend developer, I want clear API documentation and consistent patterns, so that I can integrate the Flutter app with the backend efficiently.

#### Acceptance Criteria

1. THE Nutrition_System SHALL follow the same URL patterns as the Workout_Module for consistency
2. THE Nutrition_System SHALL use the same authentication middleware as the Workout_Module
3. THE Nutrition_System SHALL use the same error response format as the Workout_Module
4. THE Nutrition_System SHALL provide API endpoints matching the Frontend_Client's existing data requirements
5. THE Nutrition_System SHALL support date filtering using query parameters in YYYY-MM-DD format
6. THE Nutrition_System SHALL support meal type filtering using query parameters
7. THE Nutrition_System SHALL return paginated responses with next, previous, count, and results fields
8. THE Nutrition_System SHALL include CORS headers for local development with Flutter web

