# Workout Tracking Subsystem

This is a self-contained subsystem for workout tracking functionality in the NutriLift app.

## Architecture

The subsystem follows clean architecture principles with clear separation of concerns:

```
WorkoutTracking/
├── workout_tracking.dart          # Main entry point / navigation hub
├── screens/                       # UI Layer
│   ├── new_workout_screen.dart
│   ├── workout_history_screen.dart
│   ├── exercise_library_screen.dart
│   └── personal_records_screen.dart
├── providers/                     # State Management (Riverpod)
│   ├── workout_history_provider.dart
│   ├── exercise_library_provider.dart
│   ├── personal_records_provider.dart
│   ├── new_workout_provider.dart
│   └── repository_providers.dart
├── repositories/                  # Data Access Interfaces
│   ├── workout_repository.dart
│   ├── exercise_repository.dart
│   ├── personal_record_repository.dart
│   └── mocks/                    # Mock implementations for testing
│       ├── mock_workout_repository.dart
│       ├── mock_exercise_repository.dart
│       └── mock_personal_record_repository.dart
├── services/                      # API Implementation
│   ├── workout_api_service.dart
│   ├── exercise_api_service.dart
│   └── personal_record_api_service.dart
├── models/                        # Data Models
│   └── workout_models.dart
└── widgets/                       # Reusable UI Components
    ├── workout_card.dart
    ├── exercise_card.dart
    ├── pr_card.dart
    ├── exercise_input_widget.dart
    └── date_range_filter_dialog.dart
```

## Features

1. **New Workout** - Log workouts with exercises, sets, reps, and weight
2. **Workout History** - View past workouts with date filtering
3. **Exercise Library** - Browse and search exercises with filters
4. **Personal Records** - Track personal bests for each exercise

## Data Flow

```
User Interaction
    ↓
Screen (UI Layer)
    ↓
Provider (State Management)
    ↓
Repository (Interface)
    ↓
Service (API Implementation)
    ↓
Backend API
```

## Dependencies

### Shared Services (from `lib/services/`)
These services are shared across all subsystems and remain in the global services folder:
- `dio_client.dart` - HTTP client with JWT authentication
- `cache_service.dart` - Offline caching for data persistence
- `token_service.dart` - JWT token management
- `error_handler.dart` - Global error handling

### Shared Widgets (from `lib/widgets/`)
- `nutrilift_header.dart` - App header/navigation scaffold

### External Dependencies
- `flutter_riverpod` - State management
- `dio` - HTTP client library

## Usage

Import the main entry point in your navigation:

```dart
import 'package:nutrilift/WorkoutTracking/workout_tracking.dart';

// Navigate to workout tracking
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const WorkoutTracking()),
);
```

## Testing

Tests are located in `frontend/test/` and mirror the subsystem structure:
- `test/widgets/` - Widget tests
- `test/providers/` - Provider tests
- `test/services/` - Service tests
- `test/repositories/` - Repository tests
- `test/integration/` - Integration tests

## Backend API

The subsystem communicates with the Django backend at:
- Base URL: `http://127.0.0.1:8000/api/workouts/`
- Endpoints:
  - `GET /exercises/` - List exercises
  - `GET /personal-records/` - List personal records
  - `GET /logs/` - List workout logs
  - `POST /logs/` - Create workout log
  - `GET /statistics/` - Get workout statistics

## Offline Support

The subsystem implements offline-first architecture:
- Data is cached locally using `CacheService`
- API calls fallback to cached data on network errors
- Changes are queued and synced when connection is restored
