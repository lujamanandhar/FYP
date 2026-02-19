# Implementation Plan: NutriLift Workout Tracking System

## Overview

This implementation plan breaks down the NutriLift Workout Tracking System into discrete, manageable tasks. The plan follows an incremental approach, building backend APIs first, then frontend UI components, with testing integrated throughout. Each task builds on previous work, ensuring no orphaned code.

The implementation is organized into major phases:
1. Backend foundation (models, signals, serializers)
2. Backend API endpoints
3. Frontend data layer (models, repositories, services)
4. Frontend state management (Riverpod providers)
5. Frontend UI screens and widgets
6. Testing and quality assurance
7. Deployment setup

## Tasks

- [x] 1. Enhance Backend Exercise Model and Database
  - [x] 1.1 Update Exercise model with new fields (muscle_group, equipment, difficulty, instructions, image_url, video_url)
    - Modify `backend/workouts/models.py` to add new fields with choices
    - Create Django migration for model changes
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [x] 1.2 Add model validation for Exercise enum fields
    - Implement clean() method to validate category, muscle_group, equipment, difficulty
    - Add unique constraint for exercise names (case-insensitive)
    - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.8_
  
  - [x] 1.3 Write property tests for Exercise model validation
    - **Property 16: Exercise Category Validation**
    - **Property 17: Exercise Muscle Group Validation**
    - **Property 18: Exercise Equipment Validation**
    - **Property 19: Exercise Difficulty Validation**
    - **Property 21: Exercise Name Uniqueness**
    - **Validates: Requirements 6.2, 6.3, 6.4, 6.5, 6.8**
  
  - [x] 1.4 Create comprehensive exercise seeding command
    - Expand `backend/workouts/management/commands/seed_exercises.py` to seed 100+ exercises
    - Include exercises covering all categories, muscle groups, and difficulty levels
    - _Requirements: 6.6, 6.7, 3.10_
  
  - [x] 1.5 Write unit tests for exercise seeding
    - Test that seeding creates at least 100 exercises
    - Test coverage of all categories and difficulty levels
    - **Property 20: Exercise Seeding Coverage**
    - **Validates: Requirements 6.7, 3.10**


- [x] 2. Implement WorkoutExercise Model and Relationships
  - [x] 2.1 Create WorkoutExercise model
    - Create new model in `backend/workouts/models.py` with fields: workout_log, exercise, sets, reps, weight, order
    - Add validators for sets (1-100), reps (1-100), weight (0.1-1000)
    - Implement calculate_volume() method
    - _Requirements: 2.5, 2.6, 2.7_
  
  - [x] 2.2 Create migration for WorkoutExercise model
    - Generate and apply Django migration
    - _Requirements: 2.9_
  
  - [x] 2.3 Write property tests for WorkoutExercise validation
    - **Property 7: Input Validation Ranges**
    - Test that valid inputs (1-100 reps, 1-100 sets, 0.1-1000 weight) are accepted
    - Test that invalid inputs are rejected
    - **Validates: Requirements 2.5, 2.6, 2.7, 9.1, 9.2, 9.3, 9.9**
  
  - [x] 2.4 Write unit tests for calculate_volume method
    - Test volume calculation: sets * reps * weight
    - _Requirements: 2.10_

- [x] 3. Enhance PersonalRecord Model with Previous Values
  - [x] 3.1 Update PersonalRecord model
    - Add fields: previous_max_weight, previous_max_reps, previous_max_volume, workout_log FK
    - Implement get_improvement_percentage() method
    - _Requirements: 4.3, 4.7_
  
  - [x] 3.2 Create migration for PersonalRecord changes
    - Generate and apply Django migration
    - _Requirements: 4.7_
  
  - [x] 3.3 Write unit tests for improvement percentage calculation
    - Test percentage calculation with various previous/current values
    - _Requirements: 4.3_

- [x] 4. Implement Signal Handlers for Automatic PR Detection
  - [x] 4.1 Create signal handler for WorkoutLog post_save
    - Implement post_save signal in `backend/workouts/signals.py`
    - Create update_personal_record() function to check and update PRs
    - Compare max_weight, max_reps, max_volume against existing PRs
    - Store previous values when updating PRs
    - _Requirements: 2.11, 4.7, 5.6, 5.7, 5.8_
  
  - [x] 4.2 Register signal handlers in apps.py
    - Import signals in WorkoutsConfig.ready() method
    - _Requirements: 5.6_
  
  - [x] 4.3 Write property tests for PR detection logic
    - **Property 10: Personal Record Detection and Update**
    - Test that workouts exceeding PRs trigger updates
    - Test that previous values are stored correctly
    - Test that all three metrics (weight, reps, volume) are checked
    - **Validates: Requirements 2.11, 4.7, 5.6, 5.7, 5.8**
  
  - [x] 4.4 Write integration tests for signal triggering
    - Test that creating WorkoutLog triggers signal
    - Test that PR entries are created/updated correctly
    - _Requirements: 5.6, 5.8_

- [x] 5. Implement Enhanced Serializers
  - [x] 5.1 Create ExerciseSerializer
    - Implement serializer in `backend/workouts/serializers.py` with all fields
    - _Requirements: 5.3_
  
  - [x] 5.2 Create WorkoutExerciseSerializer
    - Include exercise_name (read-only), volume (calculated field)
    - _Requirements: 2.9_
  
  - [x] 5.3 Create/Update WorkoutLogSerializer
    - Include nested WorkoutExerciseSerializer
    - Add gym_name, workout_name (read-only fields)
    - Add has_new_prs calculated field
    - Implement create() method to handle nested exercises
    - Implement calories calculation
    - _Requirements: 1.8, 2.9, 2.10, 8.6_
  
  - [x] 5.4 Create PersonalRecordSerializer
    - Include exercise_name, improvement_percentage
    - _Requirements: 4.2, 4.3_
  
  - [x] 5.5 Write unit tests for serializer validation
    - Test WorkoutLogSerializer validation
    - Test nested exercise creation
    - **Property 29: Incomplete Workout Validation**
    - **Validates: Requirements 9.4, 9.5**
  
  - [x] 5.6 Write property tests for calories calculation
    - **Property 9: Calories Calculation**
    - Test that calculated calories are positive and reasonable
    - **Validates: Requirements 2.10**

- [x] 6. Checkpoint - Backend Models and Serializers Complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement Workout API Endpoints
  - [x] 7.1 Create WorkoutViewSet with log_workout action
    - Implement POST /api/workouts/log/ endpoint in `backend/workouts/views.py`
    - Validate workout data, create WorkoutLog and WorkoutExercises
    - Return 201 with complete workout object including PR flags
    - _Requirements: 2.8, 2.9, 5.1, 14.1, 14.2_
  
  - [x] 7.2 Implement get_history action
    - Implement GET /api/workouts/history/ endpoint
    - Add date_from and limit query parameters
    - Order by date descending
    - Include pagination support
    - _Requirements: 1.2, 1.7, 5.2_
  
  - [x] 7.3 Implement get_statistics action
    - Implement GET /api/workouts/statistics/ endpoint
    - Calculate total workouts, calories, duration, averages
    - Provide breakdowns by time period and category
    - Identify most frequent exercises
    - _Requirements: 5.5, 15.1, 15.2, 15.3, 15.4, 15.5_
  
  - [x] 7.4 Write integration tests for workout endpoints
    - Test POST /api/workouts/log/ with valid data returns 201
    - Test GET /api/workouts/history/ returns ordered workouts
    - Test date_from filtering works correctly
    - **Property 1: Workout History Ordering**
    - **Property 2: Date Range Filtering**
    - **Property 8: Workout Persistence and Response**
    - **Validates: Requirements 1.1, 1.2, 1.7, 2.9, 14.1, 14.2**
  
  - [x] 7.5 Write property tests for statistics calculation
    - **Property 41: Statistics Calculation Accuracy**
    - **Property 42: Time Period Aggregation**
    - **Property 43: Category Aggregation**
    - **Property 44: Exercise Frequency Ranking**
    - **Validates: Requirements 15.1, 15.2, 15.3, 15.4, 15.5**

- [x] 8. Implement Exercise API Endpoints
  - [x] 8.1 Create ExerciseViewSet with list and retrieve actions
    - Implement GET /api/exercises/ endpoint in `backend/workouts/views.py`
    - Add filtering by category, muscle, equipment, difficulty, search
    - Implement filter combination logic
    - _Requirements: 3.9, 5.3_
  
  - [x] 8.2 Write property tests for exercise filtering
    - **Property 11: Exercise Filter Combination**
    - Test that all filters work correctly in combination
    - Test that search filtering works
    - **Property 5: Exercise Search Filtering**
    - **Validates: Requirements 2.3, 3.2, 3.3, 3.4, 3.5, 3.6, 3.9**

- [x] 9. Implement PersonalRecord API Endpoints
  - [x] 9.1 Create PersonalRecordViewSet with list action
    - Implement GET /api/personal-records/ endpoint
    - Filter by authenticated user only
    - _Requirements: 4.6, 5.4_
  
  - [x] 9.2 Write property tests for user-scoped PRs
    - **Property 14: User-Scoped Personal Records**
    - Test that users only see their own PRs
    - **Validates: Requirements 4.6**

- [x] 10. Implement API Authentication and Error Handling
  - [x] 10.1 Add JWT authentication to all workout endpoints
    - Configure JWT authentication in settings
    - Add permission_classes to all ViewSets
    - _Requirements: 5.9, 7.5_
  
  - [x] 10.2 Implement comprehensive error handling
    - Add validation error responses (400)
    - Add authentication error responses (401)
    - Add not found error responses (404)
    - Implement input sanitization
    - _Requirements: 9.6, 9.10, 5.10_
  
  - [x] 10.3 Add validation for exercise references and dates
    - Validate that referenced exercises exist
    - Validate that workout dates are not in the future
    - _Requirements: 9.7, 9.8_
  
  - [x] 10.4 Write property tests for authentication and validation
    - **Property 22: JWT Authentication Enforcement**
    - **Property 30: Invalid Data Error Response**
    - **Property 31: Exercise Reference Validation**
    - **Property 32: Future Date Validation**
    - **Property 33: Input Sanitization**
    - **Validates: Requirements 5.9, 5.10, 7.5, 9.6, 9.7, 9.8, 9.10**

- [-] 11. Implement Database Optimizations
  - [x] 11.1 Add database indexes
    - Add indexes on WorkoutLog.user_id, WorkoutLog.date, PersonalRecord.user_id
    - Add composite indexes for common queries
    - _Requirements: 12.4_
  
  - [x] 11.2 Optimize queries with select_related and prefetch_related
    - Update ViewSets to use query optimization
    - _Requirements: 12.5_
  
  - [x] 11.3 Implement API response caching for exercises
    - Add caching decorator to exercise list endpoint
    - _Requirements: 12.6_
  
  - [x] 11.4 Write property tests for caching behavior
    - **Property 28: Data Caching** (backend portion)
    - Test that repeated requests return cached data
    - **Validates: Requirements 12.6**

- [x] 12. Implement Transaction Handling and Audit Logging
  - [x] 12.1 Add database transactions for workout logging
    - Wrap workout creation in atomic transaction
    - Implement rollback on failure
    - _Requirements: 14.3, 14.7_
  
  - [x] 12.2 Implement audit logging
    - Create AuditLog model
    - Log all workout create/update/delete operations
    - _Requirements: 14.8_
  
  - [x] 12.3 Implement soft deletes for workouts
    - Add is_deleted field to WorkoutLog
    - Override delete() method
    - _Requirements: 14.9_
  
  - [x] 12.4 Write property tests for transaction handling
    - **Property 36: Transaction Rollback on Failure**
    - Test that failures rollback all changes
    - **Property 39: Audit Log Creation**
    - **Property 40: Soft Delete Behavior**
    - **Validates: Requirements 14.3, 14.7, 14.8, 14.9**

- [x] 13. Implement Rate Limiting
  - [x] 13.1 Add rate limiting to API endpoints
    - Configure Django REST Framework throttling
    - Set appropriate rate limits per endpoint
    - _Requirements: 12.10_
  
  - [x] 13.2 Write property tests for rate limiting
    - **Property 35: Rate Limiting**
    - Test that excessive requests are throttled
    - **Validates: Requirements 12.10**

- [x] 14. Checkpoint - Backend API Complete
  - Ensure all backend tests pass, ask the user if questions arise.

- [x] 15. Create Frontend Data Models with Freezed
  - [x] 15.1 Create Exercise model
    - Create `frontend/lib/models/exercise.dart` with Freezed
    - Include all fields from backend Exercise model
    - Implement fromJson and toJson
    - _Requirements: 3.1_
  
  - [x] 15.2 Create WorkoutExercise model
    - Create model with exercise_id, exercise_name, sets, reps, weight, volume, order
    - _Requirements: 2.4_
  
  - [x] 15.3 Create WorkoutLog model
    - Create model with all workout fields including exercises list
    - _Requirements: 1.1, 2.8_
  
  - [x] 15.4 Create PersonalRecord model
    - Create model with PR fields including improvement_percentage
    - _Requirements: 4.1_
  
  - [x] 15.5 Write unit tests for model serialization
    - Test fromJson and toJson for all models
    - Test that models handle null values correctly

- [ ] 16. Implement Repository Interfaces
  - [ ] 16.1 Create WorkoutRepository interface
    - Create `frontend/lib/repositories/workout_repository.dart`
    - Define methods: getWorkoutHistory, logWorkout, getStatistics
    - _Requirements: 7.2_
  
  - [ ] 16.2 Create ExerciseRepository interface
    - Create interface with getExercises, getExerciseById methods
    - _Requirements: 7.2_
  
  - [ ] 16.3 Create PersonalRecordRepository interface
    - Create interface with getPersonalRecords, getPersonalRecordForExercise methods
    - _Requirements: 7.2_

- [ ] 17. Implement API Service with Dio
  - [ ] 17.1 Set up Dio client with JWT interceptor
    - Create `frontend/lib/services/dio_client.dart`
    - Add JWT token interceptor
    - Add error handling interceptor
    - _Requirements: 7.4, 7.5_
  
  - [ ] 17.2 Implement WorkoutApiService
    - Create `frontend/lib/services/workout_api_service.dart`
    - Implement WorkoutRepository interface
    - Implement getWorkoutHistory, logWorkout, getStatistics methods
    - _Requirements: 1.2, 2.8, 15.1_
  
  - [ ] 17.3 Implement ExerciseApiService
    - Create service implementing ExerciseRepository
    - Implement getExercises with all filters, getExerciseById
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6_
  
  - [ ] 17.4 Implement PersonalRecordApiService
    - Create service implementing PersonalRecordRepository
    - Implement getPersonalRecords method
    - _Requirements: 4.6_
  
  - [ ] 17.5 Write unit tests for API services
    - Mock Dio responses
    - Test that API calls are made correctly
    - Test error handling
    - **Property 23: Loading State Display** (service portion)
    - **Property 24: Error Message Display** (service portion)

- [ ] 18. Implement Mock Repositories for Testing
  - [ ] 18.1 Create MockWorkoutRepository
    - Implement in-memory workout storage
    - Return mock data for all methods
    - _Requirements: 7.9_
  
  - [ ] 18.2 Create MockExerciseRepository
    - Return mock exercise data
    - Implement filtering logic
    - _Requirements: 7.9_
  
  - [ ] 18.3 Create MockPersonalRecordRepository
    - Return mock PR data
    - _Requirements: 7.9_

- [ ] 19. Implement Riverpod State Management
  - [ ] 19.1 Create repository providers
    - Create `frontend/lib/providers/repository_providers.dart`
    - Define providers for WorkoutRepository, ExerciseRepository, PersonalRecordRepository
    - Support switching between API and Mock implementations
    - _Requirements: 7.3_
  
  - [ ] 19.2 Create WorkoutHistoryNotifier and provider
    - Create `frontend/lib/providers/workout_history_provider.dart`
    - Implement StateNotifier with AsyncValue<List<WorkoutLog>>
    - Implement loadWorkouts, refresh methods
    - _Requirements: 1.1, 1.5, 8.1_
  
  - [ ] 19.3 Create ExerciseLibraryNotifier and provider
    - Create provider for exercise library
    - Implement filtering logic
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_
  
  - [ ] 19.4 Create PersonalRecordsNotifier and provider
    - Create provider for personal records
    - _Requirements: 4.1_
  
  - [ ] 19.5 Create NewWorkoutNotifier and provider
    - Create provider for workout being created
    - Implement addExercise, removeExercise, updateExercise methods
    - Implement validation logic
    - _Requirements: 2.2, 2.4, 2.5, 2.6, 2.7_
  
  - [ ] 19.6 Write unit tests for state management
    - Test that state updates correctly
    - Test that errors are handled
    - **Property 26: Reactive State Updates**
    - **Validates: Requirements 8.1**

- [ ] 20. Implement Local Caching
  - [ ] 20.1 Set up shared_preferences for caching
    - Add shared_preferences dependency
    - Create cache service
    - _Requirements: 8.5, 14.4_
  
  - [ ] 20.2 Implement cache in repositories
    - Cache workout history locally
    - Cache exercises locally
    - Cache PRs locally
    - Implement cache synchronization on startup
    - _Requirements: 8.5, 14.4, 14.5_
  
  - [ ] 20.3 Write property tests for caching behavior
    - **Property 28: Data Caching** (frontend portion)
    - **Property 37: Cache Synchronization on Startup**
    - Test that data is cached and retrievable offline
    - **Validates: Requirements 8.5, 14.4, 14.5**

- [ ] 21. Implement Network Failure Handling
  - [ ] 21.1 Create retry queue for failed operations
    - Implement operation queue in cache service
    - Retry operations when network restored
    - _Requirements: 14.6_
  
  - [ ] 21.2 Write property tests for retry logic
    - **Property 38: Network Failure Retry Queue**
    - Test that failed operations are queued and retried
    - **Validates: Requirements 14.6**

- [ ] 22. Checkpoint - Frontend Data Layer Complete
  - Ensure all data layer tests pass, ask the user if questions arise.

- [ ] 23. Implement Workout History Screen
  - [ ] 23.1 Create WorkoutHistoryScreen widget
    - Create `frontend/lib/screens/workout_history_screen.dart`
    - Integrate NutriLiftHeader
    - Add RefreshIndicator for pull-to-refresh
    - Add date range filter button
    - Add FAB for new workout
    - _Requirements: 1.1, 1.5, 1.6_
  
  - [ ] 23.2 Create WorkoutCard widget
    - Create `frontend/lib/widgets/workout_card.dart`
    - Display workout name, date, duration, calories, gym
    - Show PR badge when has_new_prs is true
    - _Requirements: 1.3, 1.4_
  
  - [ ] 23.3 Implement date range filter dialog
    - Create dialog for selecting date range
    - Update workout list when filter applied
    - _Requirements: 1.2_
  
  - [ ] 23.4 Implement pagination for workout list
    - Add scroll listener
    - Load more workouts when scrolling to bottom
    - _Requirements: 12.2_
  
  - [ ] 23.5 Write widget tests for WorkoutHistoryScreen
    - Test that workouts are displayed
    - Test that PR badges show correctly
    - **Property 3: Workout Card Completeness**
    - **Property 4: Workout Card Completeness** (PR badge portion)
    - **Validates: Requirements 1.3, 1.4**
  
  - [ ] 23.6 Write property tests for pagination
    - **Property 34: Pagination Behavior**
    - **Validates: Requirements 12.2**

- [ ] 24. Implement New Workout Screen
  - [ ] 24.1 Create NewWorkoutScreen widget
    - Create `frontend/lib/screens/new_workout_screen.dart`
    - Add workout template dropdown
    - Add gym selection dropdown
    - Add duration input field with validation
    - Add notes text field
    - Add save button
    - _Requirements: 2.1, 2.5_
  
  - [ ] 24.2 Create ExerciseInputWidget
    - Create widget for inputting sets, reps, weight per exercise
    - Add validation for input ranges
    - Add remove button
    - _Requirements: 2.4, 2.5, 2.6, 2.7_
  
  - [ ] 24.3 Implement template selection logic
    - Load exercises when template selected
    - Pre-populate exercise list
    - _Requirements: 2.2_
  
  - [ ] 24.4 Implement exercise search and add
    - Add search bar
    - Show filtered exercises
    - Add exercise to workout on tap
    - _Requirements: 2.3, 2.4_
  
  - [ ] 24.5 Implement form validation
    - Validate duration (1-600)
    - Validate reps (1-100)
    - Validate weight (0.1-1000)
    - Validate at least one exercise
    - Show validation errors inline
    - _Requirements: 2.5, 2.6, 2.7, 9.4, 9.5_
  
  - [ ] 24.6 Implement workout submission
    - Call logWorkout API
    - Show loading indicator
    - Handle success: show PR notification if applicable, navigate back
    - Handle errors: show error message
    - _Requirements: 2.8, 8.2_
  
  - [ ] 24.7 Write widget tests for NewWorkoutScreen
    - Test form validation
    - Test exercise addition/removal
    - **Property 6: Exercise Addition to Workout**
    - **Property 29: Incomplete Workout Validation**
    - **Validates: Requirements 2.4, 2.5, 2.6, 2.7, 9.4, 9.5**
  
  - [ ] 24.8 Write property tests for template pre-population
    - **Property 4: Template Pre-population**
    - **Validates: Requirements 2.2**

- [ ] 25. Implement Exercise Library Screen
  - [ ] 25.1 Create ExerciseLibraryScreen widget
    - Create `frontend/lib/screens/exercise_library_screen.dart`
    - Add search bar
    - Add filter chips for category, muscle, equipment, difficulty
    - Display exercises in grid
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_
  
  - [ ] 25.2 Create ExerciseCard widget
    - Create `frontend/lib/widgets/exercise_card.dart`
    - Display exercise image, name, muscle group, difficulty
    - _Requirements: 3.1_
  
  - [ ] 25.3 Implement exercise filtering
    - Update exercise list when filters applied
    - Support multiple filters simultaneously
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.9_
  
  - [ ] 25.4 Implement exercise search
    - Filter exercises by name as user types
    - _Requirements: 3.6_
  
  - [ ] 25.5 Implement exercise detail bottom sheet
    - Show full exercise details on tap
    - Display image, instructions, video link
    - Add "Add to Workout" button
    - _Requirements: 3.7, 3.8_
  
  - [ ] 25.6 Write widget tests for ExerciseLibraryScreen
    - Test that exercises are displayed
    - Test that filters work
    - Test that search works
    - **Property 5: Exercise Search Filtering**
    - **Validates: Requirements 2.3, 3.6**

- [ ] 26. Implement Personal Records Screen
  - [ ] 26.1 Create PersonalRecordsScreen widget
    - Create `frontend/lib/screens/personal_records_screen.dart`
    - Display PRs in grid layout
    - _Requirements: 4.1_
  
  - [ ] 26.2 Create PRCard widget
    - Create `frontend/lib/widgets/pr_card.dart`
    - Display exercise name, max weight, max reps, max volume, date
    - Show progress indicator if improvement data exists
    - Add share button
    - _Requirements: 4.2, 4.3, 4.5_
  
  - [ ] 26.3 Implement PR tap navigation
    - Navigate to workout history filtered to exercise
    - _Requirements: 4.4_
  
  - [ ] 26.4 Implement PR sharing
    - Generate share message
    - Open share dialog
    - _Requirements: 4.5_
  
  - [ ] 26.5 Write widget tests for PersonalRecordsScreen
    - Test that PRs are displayed correctly
    - Test that progress indicators show
    - **Property 12: Personal Record Display Completeness**
    - **Property 13: PR Share Message Generation**
    - **Validates: Requirements 4.2, 4.3, 4.5**

- [ ] 27. Implement Navigation and Integration
  - [ ] 27.1 Integrate screens with existing navigation
    - Add workout screens to drawer navigation
    - Integrate with NutriLiftHeader
    - Set up routes
    - _Requirements: 7.10, 13.2, 13.3_
  
  - [ ] 27.2 Apply red theme consistently
    - Use #E53935 for primary color
    - Apply theme to all workout screens
    - _Requirements: 7.10, 13.1_
  
  - [ ] 27.3 Write integration tests for navigation flows
    - Test complete user flows
    - Test navigation between screens

- [ ] 28. Implement Loading and Error States
  - [ ] 28.1 Add loading indicators to all screens
    - Show CircularProgressIndicator during API calls
    - _Requirements: 7.6, 13.4_
  
  - [ ] 28.2 Add error handling to all screens
    - Display error messages when operations fail
    - Add retry buttons
    - _Requirements: 7.7, 13.5_
  
  - [ ] 28.3 Write property tests for loading and error states
    - **Property 23: Loading State Display**
    - **Property 24: Error Message Display**
    - **Validates: Requirements 7.6, 7.7, 13.4, 13.5**

- [ ] 29. Implement Optimistic UI Updates
  - [ ] 29.1 Add optimistic updates for workout logging
    - Update UI immediately when workout logged
    - Rollback if API call fails
    - _Requirements: 7.8_
  
  - [ ] 29.2 Write property tests for optimistic updates
    - **Property 25: Optimistic UI Updates**
    - **Validates: Requirements 7.8**

- [ ] 30. Implement PR Notifications
  - [ ] 30.1 Add notification display for new PRs
    - Show celebration notification when PR achieved
    - Display immediately after workout submission
    - _Requirements: 8.2, 4.8_
  
  - [ ] 30.2 Write property tests for PR notifications
    - **Property 15: PR Notification Creation**
    - **Validates: Requirements 4.8, 8.2, 8.6**

- [ ] 31. Checkpoint - Frontend UI Complete
  - Ensure all frontend tests pass, ask the user if questions arise.

- [ ] 32. Implement Backend Deployment Configuration
  - [ ] 32.1 Create Dockerfile for backend
    - Create multi-stage Dockerfile
    - Configure for production deployment
    - _Requirements: 11.1_
  
  - [ ] 32.2 Create docker-compose.yml for local development
    - Configure PostgreSQL service
    - Configure backend service
    - _Requirements: 11.2_
  
  - [ ] 32.3 Configure environment variables
    - Set up .env.example file
    - Document all required environment variables
    - _Requirements: 11.9_
  
  - [ ] 32.4 Create deployment documentation
    - Document Railway/Heroku deployment steps
    - Document database migration steps
    - _Requirements: 11.3_

- [ ] 33. Implement Frontend Deployment Configuration
  - [ ] 33.1 Create GitHub Actions workflow for Android build
    - Configure Flutter build action
    - Build release APK
    - Upload artifact
    - _Requirements: 11.4_
  
  - [ ] 33.2 Configure Firebase Hosting for web
    - Create firebase.json
    - Configure hosting settings
    - _Requirements: 11.5_
  
  - [ ] 33.3 Create environment configuration
    - Set up environment-specific API endpoints
    - _Requirements: 11.10_

- [ ] 34. Implement CI/CD Pipeline
  - [ ] 34.1 Create GitHub Actions workflow for backend tests
    - Run pytest on every PR
    - Upload coverage reports
    - _Requirements: 11.6_
  
  - [ ] 34.2 Create GitHub Actions workflow for frontend tests
    - Run Flutter tests on every PR
    - Upload coverage reports
    - _Requirements: 11.6_
  
  - [ ] 34.3 Configure deployment workflows
    - Deploy backend to Railway/Heroku on merge to main
    - Deploy frontend to Firebase on merge to main
    - _Requirements: 11.7, 11.8_

- [ ] 35. Final Integration Testing
  - [ ] 35.1 Run complete end-to-end tests
    - Test complete user flows from UI to database
    - Test all API endpoints with real database
    - Verify PR detection works end-to-end
  
  - [ ] 35.2 Run property-based test suite
    - Run all 47 property tests with 100+ iterations each
    - Verify all properties hold
  
  - [ ] 35.3 Verify test coverage goals
    - Backend: 90% coverage
    - Frontend: 85% coverage

- [ ] 36. Final Checkpoint - System Complete
  - Ensure all tests pass, verify deployment works, ask the user if questions arise.

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at major milestones
- Property tests validate universal correctness properties with minimum 100 iterations
- Unit tests validate specific examples, edge cases, and integration points
- Both testing approaches are complementary and necessary for comprehensive coverage
- Backend tasks should be completed before frontend tasks to ensure API availability
- Mock repositories enable frontend development without backend dependency
