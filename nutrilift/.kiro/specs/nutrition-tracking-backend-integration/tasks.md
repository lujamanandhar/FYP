# Implementation Plan: Nutrition Tracking Backend Integration

## Overview

This plan implements a Django REST Framework backend for nutrition tracking, following the exact patterns from the existing workout module. The implementation prioritizes backend completion first (models → serializers → views → signals → routing), then testing. Tasks are grouped to minimize context switching and designed for 15-30 minute completion windows.

## Tasks

- [-] 1. Create Django app structure and initial models
  - [x] 1.1 Create nutrition app with apps.py configuration
    - Run `python manage.py startapp nutrition` in backend directory
    - Configure NutritionConfig in apps.py with signal registration
    - Add 'nutrition' to INSTALLED_APPS in settings.py
    - _Requirements: 12.1-12.6_

  - [x] 1.2 Implement FoodItem and IntakeLog models
    - Create FoodItem model with nutritional fields per 100g
    - Create IntakeLog model with calculated macro fields
    - Add validators for non-negative values and positive quantities
    - Define Meta classes with db_table, ordering, and indexes
    - _Requirements: 1.1, 1.2, 1.4, 1.5, 2.1, 2.6, 2.7, 2.8, 12.7, 12.8, 12.9_

  - [x] 1.3 Implement HydrationLog and NutritionGoals models
    - Create HydrationLog model with amount, unit, logged_at fields
    - Create NutritionGoals model with OneToOneField to User
    - Add unique constraint on NutritionGoals.user_id
    - Define indexes on user_id and date columns
    - _Requirements: 4.1, 5.1, 5.2, 12.10_

  - [x] 1.4 Implement NutritionProgress and QuickLog models
    - Create NutritionProgress model with aggregated totals and adherence fields
    - Create QuickLog model with JSONField for frequent_meals
    - Add unique_together constraint on user and progress_date
    - Define indexes for query optimization
    - _Requirements: 3.8, 6.1, 12.8, 12.9_

  - [x] 1.5 Create initial database migration
    - Run `python manage.py makemigrations nutrition`
    - Review migration file for correct field types and constraints
    - Run `python manage.py migrate` to apply schema
    - _Requirements: 12.1-12.10_

- [x] 2. Implement serializers with validation
  - [x] 2.1 Create FoodItemSerializer with field validation
    - Implement FoodItemSerializer with all nutritional fields
    - Add validate_name method using sanitize_text_input
    - Add validate method for non-negative nutritional values
    - Define read_only_fields for id, created_by, timestamps
    - _Requirements: 1.4, 11.1, 11.3, 13.1, 13.8, 13.10_

  - [x] 2.2 Create IntakeLogSerializer with macro calculation
    - Implement IntakeLogSerializer with nested food_item_details
    - Add validate_quantity method for positive values
    - Add validate_entry_type method for valid types
    - Implement create method with nutrient calculation formula
    - _Requirements: 2.2-2.5, 2.7, 11.2, 11.4, 13.2, 13.9_

  - [x] 2.3 Create remaining serializers
    - Implement HydrationLogSerializer with all required fields
    - Implement NutritionGoalsSerializer with target fields
    - Implement NutritionProgressSerializer with aggregated fields
    - Implement QuickLogSerializer with food_item details
    - _Requirements: 13.3-13.6, 13.8_

- [-] 3. Implement ViewSets for REST API
  - [x] 3.1 Create FoodItemViewSet with search and filtering
    - Implement ModelViewSet with IsAuthenticated permission
    - Add get_queryset to filter system + user's custom foods
    - Add perform_create to set created_by and is_custom
    - Configure SearchFilter for name and brand fields
    - _Requirements: 1.3, 1.5, 1.6, 10.1, 10.2, 16.1, 16.2_

  - [x] 3.2 Create IntakeLogViewSet with date filtering
    - Implement ModelViewSet with IsAuthenticated permission
    - Add get_queryset with user filtering and select_related
    - Add date_from and date_to query parameter filtering
    - Add perform_create to set user from JWT token
    - _Requirements: 2.9-2.12, 10.2, 10.4, 14.5, 16.5_

  - [-] 3.3 Create HydrationLogViewSet with date filtering
    - Implement ModelViewSet with IsAuthenticated permission
    - Add get_queryset with user and date filtering
    - Add perform_create to set user from JWT token
    - _Requirements: 4.2, 4.3, 4.7, 10.2_

  - [~] 3.4 Create NutritionGoalsViewSet with default handling
    - Implement ModelViewSet with IsAuthenticated permission
    - Add get_queryset to filter by user
    - Override retrieve to return defaults if no goals exist
    - Add perform_create and perform_update to set user
    - _Requirements: 5.3-5.5, 5.7, 10.2_

  - [~] 3.5 Create NutritionProgressViewSet (read-only)
    - Implement ReadOnlyModelViewSet with IsAuthenticated permission
    - Add get_queryset with user and date range filtering
    - Configure pagination to 50 items per page
    - _Requirements: 3.9, 10.2, 14.1, 14.3, 14.6, 16.7_

  - [~] 3.6 Create QuickLogViewSet with frequent/recent endpoints
    - Implement ReadOnlyModelViewSet with IsAuthenticated permission
    - Add custom action for frequent foods ordered by usage_count
    - Add custom action for recent foods ordered by last_used
    - _Requirements: 1.7, 6.4, 6.5_

- [~] 4. Implement signal handlers for auto-aggregation
  - [~] 4.1 Create signals.py with IntakeLog post-save handler
    - Implement update_nutrition_progress_on_save signal receiver
    - Aggregate all IntakeLog entries for the date using Sum
    - Retrieve or create NutritionGoals with defaults
    - Calculate adherence percentages using formula
    - Update or create NutritionProgress record
    - _Requirements: 3.1-3.8, 14.7_

  - [~] 4.2 Add IntakeLog post-delete handler
    - Implement update_nutrition_progress_on_delete signal receiver
    - Recalculate progress for affected date
    - _Requirements: 3.10, 3.11_

  - [~] 4.3 Add HydrationLog signal handlers
    - Implement post-save handler to update total_water
    - Aggregate HydrationLog entries for the date
    - Calculate water_adherence percentage
    - Update NutritionProgress record
    - _Requirements: 4.4, 4.6_

  - [~] 4.4 Add QuickLog update handler
    - Implement post-save handler for IntakeLog to update QuickLog
    - Increment usage_count for food_item_id
    - Update last_used timestamp
    - Limit frequent_meals to top 20 items
    - _Requirements: 6.2, 6.3, 6.6_

  - [~] 4.5 Register signals in apps.py ready method
    - Import nutrition.signals in NutritionConfig.ready()
    - Verify signals are registered on app startup
    - _Requirements: 3.1-3.11_

- [~] 5. Configure URL routing and app integration
  - [~] 5.1 Create urls.py with router configuration
    - Create DefaultRouter instance
    - Register all ViewSets with appropriate basenames
    - Define urlpatterns with router.urls
    - _Requirements: 16.1_

  - [~] 5.2 Add nutrition URLs to main project urls.py
    - Include nutrition.urls at /api/nutrition/ path
    - Verify URL patterns match workout module structure
    - _Requirements: 16.1_

  - [~] 5.3 Create admin.py for Django admin interface
    - Register all models with admin.site.register
    - Add list_display and search_fields for key models
    - _Requirements: 12.1-12.6_

- [~] 6. Checkpoint - Verify backend functionality
  - Run migrations and start development server
  - Test API endpoints with curl or Postman
  - Verify authentication with JWT tokens
  - Verify signal handlers trigger on meal logging
  - Ask user if questions arise

- [ ] 7. Write unit tests for models and serializers
  - [ ]* 7.1 Write unit tests for model methods
    - Test FoodItem creation with valid/invalid data
    - Test IntakeLog creation with calculated macros
    - Test NutritionProgress unique constraint
    - Test default values for NutritionGoals
    - _Requirements: 15.1, 15.2, 15.3, 15.8_

  - [ ]* 7.2 Write unit tests for serializer validation
    - Test FoodItemSerializer with negative values
    - Test IntakeLogSerializer quantity validation
    - Test IntakeLogSerializer entry_type validation
    - Test serializer round-trip for all models
    - _Requirements: 15.1, 15.5_

  - [ ]* 7.3 Write unit tests for API endpoints
    - Test food search with various queries
    - Test intake log CRUD operations
    - Test date range filtering
    - Test authentication and authorization
    - _Requirements: 15.4, 15.7_

  - [ ]* 7.4 Write unit tests for signal handlers
    - Test progress update on IntakeLog save
    - Test progress recalculation on delete
    - Test hydration aggregation
    - Test QuickLog updates
    - _Requirements: 15.9_

- [ ] 8. Write property-based tests for correctness properties
  - [ ]* 8.1 Write property test for nutrient calculation
    - **Property 1: Nutrient Calculation Accuracy**
    - **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
    - Use Hypothesis to generate random food items and quantities
    - Verify calculated macros match formula for all nutrients
    - _Requirements: 15.6_

  - [ ]* 8.2 Write property tests for aggregation
    - **Property 2: Daily Aggregation Completeness**
    - **Property 3: Progress Recalculation on Changes**
    - **Property 5: Hydration Aggregation**
    - **Validates: Requirements 3.1-3.5, 3.10, 3.11, 4.4**
    - Generate random intake logs and verify totals
    - Test CRUD operations trigger recalculation
    - _Requirements: 15.6_

  - [ ]* 8.3 Write property tests for adherence calculations
    - **Property 4: Adherence Percentage Calculation**
    - **Property 6: Hydration Adherence Calculation**
    - **Validates: Requirements 3.7, 4.6**
    - Generate random goals and actuals
    - Verify adherence formula for all macros
    - _Requirements: 15.6_

  - [ ]* 8.4 Write property tests for validation
    - **Property 10: Entry Type Validation**
    - **Property 11: Quantity Validation**
    - **Property 12: Non-Negative Nutritional Values**
    - **Property 22: Date Format Validation**
    - **Validates: Requirements 2.7, 11.2, 11.3, 11.4, 16.5**
    - Generate invalid inputs and verify HTTP 400 responses
    - _Requirements: 15.6_

  - [ ]* 8.5 Write property tests for authentication and authorization
    - **Property 13: Authentication Required**
    - **Property 14: Authorization Enforcement**
    - **Validates: Requirements 10.1, 10.3, 10.4**
    - Generate invalid tokens and cross-user access attempts
    - Verify HTTP 401 and 403 responses
    - _Requirements: 15.7_

  - [ ]* 8.6 Write property tests for filtering and pagination
    - **Property 15: Date Range Filtering**
    - **Property 21: Pagination Structure**
    - **Property 23: Meal Type Filtering**
    - **Validates: Requirements 2.10, 3.9, 14.6, 16.6, 16.7**
    - Generate random date ranges and verify results
    - Verify pagination structure with random result sets
    - _Requirements: 15.6_

  - [ ]* 8.7 Write property tests for QuickLog functionality
    - **Property 16: Quick Log Usage Counter**
    - **Property 17: Quick Log Timestamp Update**
    - **Property 18: Quick Log Size Limit**
    - **Property 19: Frequent Foods Ordering**
    - **Property 20: Recent Foods Ordering**
    - **Validates: Requirements 6.2, 6.3, 6.4, 6.5, 6.6**
    - Generate random meal sequences and verify QuickLog updates
    - _Requirements: 15.6_

  - [ ]* 8.8 Write property tests for serializer round-trip
    - **Property 9: Serializer Round-Trip Integrity**
    - **Validates: Requirements 13.7**
    - Generate random model instances for all models
    - Verify serialize → deserialize produces equivalent data
    - _Requirements: 15.5, 15.6_

  - [ ]* 8.9 Write property tests for data completeness and integrity
    - **Property 7: Custom Food Ownership**
    - **Property 8: Food Search Relevance**
    - **Property 26: Food Item Retrieval Completeness**
    - **Property 27: Food Item Reference Integrity**
    - **Validates: Requirements 1.3, 1.5, 1.8, 2.1**
    - Generate random users and food items
    - Verify ownership and search results
    - _Requirements: 15.6_

  - [ ]* 8.10 Write property tests for goals and timestamps
    - **Property 24: UTC Timestamp Storage**
    - **Property 25: ISO 8601 Datetime Format**
    - **Property 28: Goals Retrieval or Default**
    - **Property 29: Goals Update Triggers Recalculation**
    - **Validates: Requirements 2.8, 5.6, 5.7, 13.9**
    - Generate random timezones and verify UTC storage
    - Test goals updates trigger recalculation
    - _Requirements: 15.6_

  - [ ]* 8.11 Write property test for error format consistency
    - **Property 30: Error Response Format Consistency**
    - **Validates: Requirements 16.3**
    - Generate various error conditions
    - Verify error format matches workout module
    - _Requirements: 15.6_

- [~] 9. Final checkpoint and coverage verification
  - Run full test suite with `pytest backend/nutrition/tests/`
  - Verify minimum 90% code coverage
  - Run property tests with verbose output
  - Ensure all tests pass, ask user if questions arise

## Notes

- Tasks marked with `*` are optional testing tasks that can be skipped for faster MVP
- Backend implementation (tasks 1-6) should be completed before testing
- Signal handlers are critical for automatic progress updates
- Follow workout module patterns exactly for consistency
- Each task references specific requirements for traceability
- Property tests use Hypothesis with minimum 100 iterations per property
- All API endpoints require JWT authentication
