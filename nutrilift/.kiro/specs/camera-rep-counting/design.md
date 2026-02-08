# Design Document: Camera-Based Rep Counting

## Overview

The Camera-Based Rep Counting feature is an optional enhancement to the NutriLift workout tracking system that leverages Google ML Kit Pose Detection to automatically count exercise repetitions in real-time. The system uses on-device machine learning to analyze body movements through the device camera, providing users with an automated alternative to manual rep logging.

### Key Design Principles

1. **On-Device Processing**: All ML inference runs locally using ML Kit, ensuring privacy and offline functionality
2. **Real-Time Performance**: Target 30+ FPS with sub-33ms processing latency per frame
3. **Accuracy First**: Prioritize accurate rep detection over speed, with confidence scoring for transparency
4. **Seamless Integration**: Camera sessions convert directly to WorkoutLog entries in the existing system
5. **Graceful Degradation**: Fall back to manual logging if camera/ML features unavailable
6. **User Control**: Users maintain full control with pause/resume/stop and manual editing capabilities

### System Context

This feature integrates with the existing workout-tracking-system spec:
- Reuses Exercise model for exercise type selection
- Converts RepSession to WorkoutLog for unified history
- Maintains existing authentication and user management
- Adds new RepSession and RepEvent models alongside existing models

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Frontend                         │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Camera     │  │  Pose        │  │  Rep         │     │
│  │   Screen     │→ │  Detection   │→ │  Counter     │     │
│  │   UI         │  │  Service     │  │  Algorithm   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         ↓                 ↓                  ↓              │
│  ┌──────────────────────────────────────────────────┐     │
│  │         Rep Session State Management             │     │
│  └──────────────────────────────────────────────────┘     │
│         ↓                                                   │
│  ┌──────────────────────────────────────────────────┐     │
│  │         Rep API Service (HTTP Client)            │     │
│  └──────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           ↓ HTTPS
┌─────────────────────────────────────────────────────────────┐
│                    Django Backend                            │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  RepSession  │  │  RepEvent    │  │  Workout     │     │
│  │  ViewSet     │  │  Model       │  │  Integration │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         ↓                 ↓                  ↓              │
│  ┌──────────────────────────────────────────────────┐     │
│  │              PostgreSQL Database                 │     │
│  │  (RepSession, RepEvent, WorkoutLog tables)       │     │
│  └──────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

**Frontend Components:**

1. **CameraRepCountingScreen**: Main UI for camera session
   - Displays camera feed with pose overlay
   - Shows live rep count and confidence score
   - Provides pause/resume/stop controls
   - Handles camera permissions

2. **PoseDetectionService**: Wrapper for ML Kit Pose Detection
   - Initializes ML Kit PoseDetector
   - Processes camera frames to extract 33 body landmarks
   - Returns landmark coordinates and confidence scores
   - Manages ML Kit lifecycle

3. **RepCounterAlgorithm**: Exercise-specific rep detection logic
   - Calculates joint angles from landmarks
   - Detects complete rep cycles based on angle thresholds
   - Filters false positives
   - Assesses form quality

4. **RepSessionManager**: State management for active sessions
   - Tracks current rep count
   - Stores RepEvents as they occur
   - Manages session start/pause/resume/stop
   - Handles local persistence

5. **RepApiService**: HTTP client for backend communication
   - POST /api/rep-sessions/ (create session)
   - GET /api/rep-sessions/ (list sessions)
   - GET /api/rep-sessions/{id}/ (retrieve session)
   - POST /api/rep-sessions/{id}/convert-to-workout/ (convert)

**Backend Components:**

1. **RepSession Model**: Database model for camera sessions
2. **RepEvent Model**: Database model for individual reps
3. **RepSessionViewSet**: REST API endpoints
4. **WorkoutConversionService**: Logic to convert RepSession → WorkoutLog



## Components and Interfaces

### Frontend Components

#### 1. CameraRepCountingScreen (Flutter Widget)

**Purpose**: Main UI screen for camera-based rep counting session

**State:**
```dart
class CameraRepCountingState {
  CameraController? cameraController;
  PoseDetector? poseDetector;
  String selectedExercise;
  int currentRepCount;
  double currentConfidence;
  SessionStatus status; // idle, active, paused, stopped
  String? errorMessage;
  List<RepEvent> detectedReps;
  DateTime? sessionStartTime;
}
```

**Methods:**
- `initializeCamera()`: Request permissions and initialize camera
- `startSession()`: Begin rep counting session
- `pauseSession()`: Pause rep detection
- `resumeSession()`: Resume rep detection
- `stopSession()`: End session and navigate to review
- `processCameraFrame(CameraImage frame)`: Process each camera frame
- `onRepDetected(RepEvent event)`: Handle detected rep
- `dispose()`: Clean up camera and ML Kit resources

**UI Elements:**
- Camera preview with pose landmark overlay
- Large rep counter display (48sp+)
- Confidence score indicator with color coding
- Pause/Resume/Stop control buttons
- Error/warning message overlay
- Exercise name header

#### 2. PoseDetectionService

**Purpose**: Wrapper service for Google ML Kit Pose Detection

**Interface:**
```dart
class PoseDetectionService {
  PoseDetector? _detector;
  
  Future<void> initialize();
  Future<List<PoseLandmark>> detectPose(InputImage image);
  Future<void> dispose();
}

class PoseLandmark {
  PoseLandmarkType type; // NOSE, LEFT_ELBOW, etc.
  Point<double> position; // x, y coordinates
  double confidence; // 0.0 to 1.0
}
```

**ML Kit Configuration:**
- Mode: STREAM (optimized for video)
- Detector: PoseDetector.vision
- Performance: FAST (prioritize speed over accuracy)

**Landmark Types Used:**
- Shoulders: LEFT_SHOULDER, RIGHT_SHOULDER
- Elbows: LEFT_ELBOW, RIGHT_ELBOW
- Wrists: LEFT_WRIST, RIGHT_WRIST
- Hips: LEFT_HIP, RIGHT_HIP
- Knees: LEFT_KNEE, RIGHT_KNEE
- Ankles: LEFT_ANKLE, RIGHT_ANKLE

#### 3. RepCounterAlgorithm

**Purpose**: Exercise-specific logic for detecting rep cycles

**Interface:**
```dart
abstract class ExerciseAlgorithm {
  RepDetectionResult processFrame(List<PoseLandmark> landmarks);
  void reset();
}

class RepDetectionResult {
  bool repDetected;
  double confidence;
  FormQuality formQuality; // GOOD, ACCEPTABLE, POOR
  Map<String, double> angleData;
}

enum FormQuality { GOOD, ACCEPTABLE, POOR }
```

**Exercise-Specific Algorithms:**

**PushUpAlgorithm:**
- Track: Elbow angle (shoulder-elbow-wrist)
- Down position: Elbow angle < 90°
- Up position: Elbow angle > 160°
- Rep cycle: Up → Down → Up
- Minimum angle change: 70°
- Form check: Body alignment (shoulder-hip-ankle should be straight)

**SquatAlgorithm:**
- Track: Knee angle (hip-knee-ankle)
- Down position: Knee angle < 90°
- Up position: Knee angle > 160°
- Rep cycle: Up → Down → Up
- Minimum angle change: 70°
- Form check: Knees should not extend past toes

**PullUpAlgorithm:**
- Track: Elbow angle + shoulder vertical displacement
- Down position: Elbow angle > 160° AND shoulders low
- Up position: Elbow angle < 90° AND shoulders high
- Rep cycle: Down → Up → Down
- Minimum vertical displacement: 30% of body height
- Form check: Chin above bar level

**BicepCurlAlgorithm:**
- Track: Elbow angle (shoulder-elbow-wrist)
- Start position: Elbow angle > 160°
- Curl position: Elbow angle < 45°
- Rep cycle: Start → Curl → Start
- Minimum angle change: 115°
- Form check: Elbow should remain stationary (shoulder-elbow distance constant)

**ShoulderPressAlgorithm:**
- Track: Elbow angle + wrist vertical displacement
- Down position: Elbow angle < 90° AND wrists at shoulder level
- Up position: Elbow angle > 160° AND wrists above head
- Rep cycle: Down → Up → Down
- Minimum vertical displacement: 40cm
- Form check: Wrists should move vertically (minimal horizontal drift)

**LungeAlgorithm:**
- Track: Front knee angle (hip-knee-ankle)
- Up position: Knee angle > 160°
- Down position: Knee angle < 90°
- Rep cycle: Up → Down → Up
- Minimum angle change: 70°
- Form check: Front knee should not extend past front ankle

**SitUpAlgorithm:**
- Track: Hip angle (shoulder-hip-knee)
- Down position: Hip angle > 160° (lying flat)
- Up position: Hip angle < 90° (sitting up)
- Rep cycle: Down → Up → Down
- Minimum angle change: 70°
- Form check: Knees should remain bent

**Common Algorithm Logic:**

```dart
class BaseRepAlgorithm {
  RepState currentState; // UP, DOWN, TRANSITIONING
  DateTime? lastRepTime;
  double minTimeBetweenReps = 0.5; // seconds
  
  bool isValidRep(double angleChange, DateTime timestamp) {
    if (lastRepTime != null) {
      double timeSinceLastRep = timestamp.difference(lastRepTime!).inMilliseconds / 1000.0;
      if (timeSinceLastRep < minTimeBetweenReps) {
        return false; // Too soon, likely false positive
      }
    }
    return angleChange >= minAngleThreshold;
  }
  
  double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // Calculate angle at point b using vectors ba and bc
    double ba_x = a.position.x - b.position.x;
    double ba_y = a.position.y - b.position.y;
    double bc_x = c.position.x - b.position.x;
    double bc_y = c.position.y - b.position.y;
    
    double dot = ba_x * bc_x + ba_y * bc_y;
    double cross = ba_x * bc_y - ba_y * bc_x;
    double angle = atan2(cross, dot) * 180 / pi;
    
    return angle.abs();
  }
}
```

#### 4. RepSessionManager

**Purpose**: State management for active rep counting sessions

**Interface:**
```dart
class RepSessionManager extends ChangeNotifier {
  RepSession? currentSession;
  List<RepEvent> currentEvents;
  
  void startSession(String exerciseType);
  void addRep(double confidence, Map<String, double> angleData);
  void pauseSession();
  void resumeSession();
  RepSession stopSession();
  void discardSession();
  
  // Persistence
  Future<void> saveSessionLocally();
  Future<void> syncToBackend();
}
```

**Local Storage:**
- Use `shared_preferences` for session metadata
- Use `sqflite` for RepEvent storage (local SQLite)
- Sync to backend when online

#### 5. RepApiService

**Purpose**: HTTP client for backend API communication

**Interface:**
```dart
class RepApiService {
  final String baseUrl;
  final http.Client client;
  
  Future<RepSession> createSession(RepSessionCreate data);
  Future<List<RepSession>> listSessions({int? userId, int page = 1});
  Future<RepSession> getSession(int sessionId);
  Future<WorkoutLog> convertToWorkout(int sessionId, WorkoutConversionData data);
  Future<void> deleteSession(int sessionId);
}
```

**API Request/Response Models:**

```dart
class RepSessionCreate {
  int userId;
  String exerciseType;
  DateTime startTime;
  DateTime endTime;
  int totalReps;
  double confidenceAvg;
  List<RepEventCreate> events;
}

class RepEventCreate {
  int repNumber;
  DateTime timestamp;
  double confidence;
  Map<String, double> angleData;
}

class WorkoutConversionData {
  int sets;
  double? weight;
  String? notes;
}
```



### Backend Components

#### 1. RepSession Model

**Purpose**: Database model for camera-based rep counting sessions

**Django Model:**
```python
from django.db import models
from django.contrib.auth.models import User
from workouts.models import WorkoutLog

class RepSession(models.Model):
    EXERCISE_CHOICES = [
        ('push_ups', 'Push-ups'),
        ('squats', 'Squats'),
        ('pull_ups', 'Pull-ups'),
        ('bicep_curls', 'Bicep Curls'),
        ('shoulder_press', 'Shoulder Press'),
        ('lunges', 'Lunges'),
        ('sit_ups', 'Sit-ups'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='rep_sessions')
    exercise_type = models.CharField(max_length=50, choices=EXERCISE_CHOICES)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    total_reps = models.IntegerField()
    confidence_avg = models.FloatField()
    converted_workout = models.ForeignKey(
        WorkoutLog, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='source_rep_session'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-start_time']
        indexes = [
            models.Index(fields=['user', '-start_time']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.exercise_type} - {self.total_reps} reps"
```

#### 2. RepEvent Model

**Purpose**: Database model for individual detected reps within a session

**Django Model:**
```python
class RepEvent(models.Model):
    session = models.ForeignKey(RepSession, on_delete=models.CASCADE, related_name='events')
    rep_number = models.IntegerField()
    timestamp = models.DateTimeField()
    confidence = models.FloatField()
    angle_data = models.JSONField(default=dict)  # Store angle measurements
    
    class Meta:
        ordering = ['rep_number']
        indexes = [
            models.Index(fields=['session', 'rep_number']),
        ]
    
    def __str__(self):
        return f"Rep {self.rep_number} - {self.confidence:.2f}"
```

#### 3. RepSessionViewSet

**Purpose**: REST API endpoints for rep session management

**Django REST Framework ViewSet:**
```python
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

class RepSessionViewSet(viewsets.ModelViewSet):
    serializer_class = RepSessionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Users can only access their own sessions
        return RepSession.objects.filter(user=self.request.user).prefetch_related('events')
    
    def perform_create(self, serializer):
        # Automatically set user from request
        serializer.save(user=self.request.user)
    
    @action(detail=True, methods=['post'])
    def convert_to_workout(self, request, pk=None):
        """
        Convert a RepSession to a WorkoutLog entry
        POST /api/rep-sessions/{id}/convert-to-workout/
        Body: { "sets": 1, "weight": 50.0, "notes": "Great session!" }
        """
        session = self.get_object()
        
        if session.converted_workout:
            return Response(
                {"error": "Session already converted to workout"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Extract data from request
        sets = request.data.get('sets', 1)
        weight = request.data.get('weight')
        notes = request.data.get('notes', '')
        
        # Create WorkoutLog
        workout = WorkoutLog.objects.create(
            user=session.user,
            exercise_name=session.exercise_type.replace('_', ' ').title(),
            sets=sets,
            reps=session.total_reps,
            weight=weight,
            notes=f"Camera session (avg confidence: {session.confidence_avg:.2f}). {notes}",
            date=session.start_time.date()
        )
        
        # Link session to workout
        session.converted_workout = workout
        session.save()
        
        return Response(
            WorkoutLogSerializer(workout).data,
            status=status.HTTP_201_CREATED
        )
```

#### 4. Serializers

**RepEventSerializer:**
```python
from rest_framework import serializers

class RepEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = RepEvent
        fields = ['id', 'rep_number', 'timestamp', 'confidence', 'angle_data']
```

**RepSessionSerializer:**
```python
class RepSessionSerializer(serializers.ModelSerializer):
    events = RepEventSerializer(many=True, read_only=False)
    converted_workout_id = serializers.IntegerField(source='converted_workout.id', read_only=True)
    duration_seconds = serializers.SerializerMethodField()
    
    class Meta:
        model = RepSession
        fields = [
            'id', 'user', 'exercise_type', 'start_time', 'end_time',
            'total_reps', 'confidence_avg', 'events', 'converted_workout_id',
            'duration_seconds', 'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']
    
    def get_duration_seconds(self, obj):
        return (obj.end_time - obj.start_time).total_seconds()
    
    def create(self, validated_data):
        events_data = validated_data.pop('events', [])
        session = RepSession.objects.create(**validated_data)
        
        for event_data in events_data:
            RepEvent.objects.create(session=session, **event_data)
        
        return session
```

#### 5. URL Configuration

**urls.py:**
```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RepSessionViewSet

router = DefaultRouter()
router.register(r'rep-sessions', RepSessionViewSet, basename='rep-session')

urlpatterns = [
    path('api/', include(router.urls)),
]
```

**API Endpoints:**
- `POST /api/rep-sessions/` - Create new session
- `GET /api/rep-sessions/` - List user's sessions (paginated)
- `GET /api/rep-sessions/{id}/` - Retrieve specific session with events
- `PUT /api/rep-sessions/{id}/` - Update session (e.g., adjust rep count)
- `DELETE /api/rep-sessions/{id}/` - Delete session
- `POST /api/rep-sessions/{id}/convert-to-workout/` - Convert to WorkoutLog

## Data Models

### Frontend Data Models

**RepSession (Dart):**
```dart
class RepSession {
  int? id;
  int userId;
  String exerciseType;
  DateTime startTime;
  DateTime endTime;
  int totalReps;
  double confidenceAvg;
  List<RepEvent> events;
  int? convertedWorkoutId;
  
  Duration get duration => endTime.difference(startTime);
  
  RepSession({
    this.id,
    required this.userId,
    required this.exerciseType,
    required this.startTime,
    required this.endTime,
    required this.totalReps,
    required this.confidenceAvg,
    this.events = const [],
    this.convertedWorkoutId,
  });
  
  factory RepSession.fromJson(Map<String, dynamic> json) {
    return RepSession(
      id: json['id'],
      userId: json['user'],
      exerciseType: json['exercise_type'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      totalReps: json['total_reps'],
      confidenceAvg: json['confidence_avg'].toDouble(),
      events: (json['events'] as List?)
          ?.map((e) => RepEvent.fromJson(e))
          .toList() ?? [],
      convertedWorkoutId: json['converted_workout_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'exercise_type': exerciseType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_reps': totalReps,
      'confidence_avg': confidenceAvg,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}
```

**RepEvent (Dart):**
```dart
class RepEvent {
  int? id;
  int repNumber;
  DateTime timestamp;
  double confidence;
  Map<String, double> angleData;
  
  RepEvent({
    this.id,
    required this.repNumber,
    required this.timestamp,
    required this.confidence,
    this.angleData = const {},
  });
  
  factory RepEvent.fromJson(Map<String, dynamic> json) {
    return RepEvent(
      id: json['id'],
      repNumber: json['rep_number'],
      timestamp: DateTime.parse(json['timestamp']),
      confidence: json['confidence'].toDouble(),
      angleData: Map<String, double>.from(json['angle_data'] ?? {}),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'rep_number': repNumber,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'angle_data': angleData,
    };
  }
}
```

### Database Schema

**rep_session table:**
```sql
CREATE TABLE rep_session (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES auth_user(id),
    exercise_type VARCHAR(50) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    total_reps INTEGER NOT NULL,
    confidence_avg FLOAT NOT NULL,
    converted_workout_id INTEGER REFERENCES workout_log(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rep_session_user_start ON rep_session(user_id, start_time DESC);
```

**rep_event table:**
```sql
CREATE TABLE rep_event (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES rep_session(id) ON DELETE CASCADE,
    rep_number INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    confidence FLOAT NOT NULL,
    angle_data JSONB NOT NULL DEFAULT '{}',
    UNIQUE(session_id, rep_number)
);

CREATE INDEX idx_rep_event_session ON rep_event(session_id, rep_number);
```

### Data Flow

**Session Creation Flow:**
1. User starts camera session → Frontend creates local RepSession
2. User performs reps → Frontend creates RepEvent records locally
3. User stops session → Frontend sends POST /api/rep-sessions/ with all data
4. Backend validates and stores RepSession + RepEvents
5. Backend returns saved session with IDs

**Session Conversion Flow:**
1. User reviews session → Taps "Convert to Workout"
2. Frontend shows workout form (pre-filled with session data)
3. User adds weight/notes → Taps save
4. Frontend sends POST /api/rep-sessions/{id}/convert-to-workout/
5. Backend creates WorkoutLog and links to RepSession
6. Frontend navigates to workout history



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Angle Calculation from Landmarks

*For any* set of three pose landmarks (forming a joint), the Exercise_Algorithm should calculate the angle at the middle landmark using vector mathematics, and the result should be in the range [0°, 180°].

**Validates: Requirements 2.1**

### Property 2: Rep Detection Triggers State Changes

*For any* complete rep cycle detected by the Exercise_Algorithm, the Rep_Counter should both increment the displayed count by exactly one AND create a new RepEvent record with timestamp and confidence score.

**Validates: Requirements 2.2, 2.3**

### Property 3: Low Confidence Warning Display

*For any* confidence score below 0.6, the Rep_Counter should display a warning indicator to the user.

**Validates: Requirements 2.7**

### Property 4: Angle Threshold Filtering

*For any* detected movement where the angle change is below the exercise-specific minimum threshold, the Exercise_Algorithm should reject it and not count it as a rep.

**Validates: Requirements 2.9**

### Property 5: Temporal Filtering

*For any* two consecutive rep detections where the time difference is less than 0.5 seconds, the Exercise_Algorithm should reject the second detection as a false positive.

**Validates: Requirements 2.10**

### Property 6: Full Range of Motion Validation

*For any* rep detected by the Exercise_Algorithm, the movement should have completed the full range of motion from starting position through the threshold position and back.

**Validates: Requirements 3.8**

### Property 7: Form Quality Affects Confidence

*For any* rep detected with incomplete range of motion or poor form, the confidence score assigned to that rep should be lower than the confidence score for a rep with good form (all else being equal).

**Validates: Requirements 3.9**

### Property 8: Manual Adjustment Updates Session

*For any* manual adjustment to the rep count on the review screen, the RepSession record should be updated to reflect the new total_reps value.

**Validates: Requirements 5.6**

### Property 9: Workout Form Pre-Population

*For any* RepSession being converted to a workout, the workout creation form should auto-populate with exercise_type and total_reps matching the RepSession values.

**Validates: Requirements 6.2, 6.3**

### Property 10: Workout Conversion Creates Linked Record

*For any* RepSession conversion to workout, the system should create a new WorkoutLog record and link it to the RepSession via the converted_workout foreign key.

**Validates: Requirements 6.7, 12.10**

### Property 11: Session History Ordering

*For any* list of RepSessions retrieved from the backend or displayed in the history screen, the sessions should be ordered by start_time in descending order (newest first).

**Validates: Requirements 7.1, 12.8**

### Property 12: Session History Display Completeness

*For any* RepSession displayed in the history list, the display should include exercise_type, date, total_reps, and duration.

**Validates: Requirements 7.2**

### Property 13: Conversion Status Indication

*For any* RepSession that has been converted to a WorkoutLog (converted_workout_id is not null), the history display should show a conversion indicator.

**Validates: Requirements 7.3**

### Property 14: Converted Session Links to Workout

*For any* RepSession that has been converted to a WorkoutLog, the session detail view should provide a clickable link to the associated WorkoutLog.

**Validates: Requirements 7.6**

### Property 15: Landmark Confidence Range

*For any* landmark detected by the Pose_Detector, the confidence score should be in the range [0.0, 1.0].

**Validates: Requirements 9.1**

### Property 16: Rep Confidence Derived from Landmarks

*For any* rep detected, the overall confidence score should be calculated as a function of the confidence scores of the landmarks used in that rep's detection (e.g., average or minimum of relevant landmark confidences).

**Validates: Requirements 9.2**

### Property 17: Low Confidence Rep Marking

*For any* rep with a confidence score below 0.6, the RepEvent should be marked or flagged as low confidence.

**Validates: Requirements 9.3**

### Property 18: Confidence Color Coding

*For any* confidence score displayed, the color should be: green if confidence > 0.8, yellow if 0.6 ≤ confidence ≤ 0.8, red if confidence < 0.6.

**Validates: Requirements 9.4**

### Property 19: Session Average Confidence Calculation

*For any* RepSession with N reps, the confidence_avg should equal the sum of all RepEvent confidence scores divided by N.

**Validates: Requirements 9.5**

### Property 20: Low Average Confidence Warning

*For any* RepSession with confidence_avg below 0.7, the review screen should display a warning message about low accuracy.

**Validates: Requirements 9.6**

### Property 21: Relative Angle Measurements

*For any* body type or size, the Exercise_Algorithm should use relative angle measurements (angles between joints) rather than absolute positions, ensuring the algorithm adapts to different body proportions.

**Validates: Requirements 10.5**

### Property 22: Data Model Completeness

*For any* RepSession created, it should contain all required fields: id, user_id, exercise_type, start_time, end_time, total_reps, confidence_avg. *For any* RepEvent created, it should contain all required fields: id, session_id, rep_number, timestamp, confidence, angle_data.

**Validates: Requirements 12.1, 12.2**

### Property 23: User Authorization Validation

*For any* API request to access or modify a RepSession, the backend should validate that the RepSession.user_id matches the authenticated user making the request.

**Validates: Requirements 12.7**

### Property 24: Session Retrieval Includes Events

*For any* GET request to /api/rep-sessions/{id}/, the response should include the RepSession data along with all associated RepEvent records.

**Validates: Requirements 12.9**

### Property 25: Primary Button Color Consistency

*For any* primary action button in the Rep_Counter UI, the button color should be #E53935 (the NutriLift primary red).

**Validates: Requirements 13.1**

### Property 26: API Retry with Exponential Backoff

*For any* failed API request, the Rep_Counter should retry the request up to 3 times with exponentially increasing delays between attempts.

**Validates: Requirements 14.6**

### Property 27: Sync Status Indication

*For any* RepSession stored locally, the UI should display the correct sync status indicator: "synced" if successfully uploaded, "pending" if queued for upload, "failed" if upload failed after retries.

**Validates: Requirements 15.7**



## Error Handling

### Camera and Permission Errors

**Camera Permission Denied:**
- Display error dialog: "Camera access is required for rep counting"
- Provide button to open app settings
- Offer fallback: "Use Manual Logging Instead"
- Log error for analytics

**Camera Initialization Failed:**
- Display error: "Unable to access camera. Please check if another app is using it."
- Provide retry button
- Offer fallback to manual logging
- Log error with device info

**Camera Unavailable (Hardware):**
- Display error: "No camera detected on this device"
- Automatically redirect to manual logging
- Disable camera option in settings

### ML Kit and Pose Detection Errors

**ML Kit Model Loading Failed:**
- Display error: "Unable to load pose detection model"
- Provide retry button
- Check device storage space
- Offer to download model on WiFi only
- Log error for debugging

**Pose Detection Timeout:**
- After 5 seconds of no landmark detection:
  - Pause rep counting
  - Display overlay: "Can't see you clearly. Please adjust your position."
  - Show positioning guide for selected exercise
  - Provide resume button

**Low Confidence Detection:**
- When confidence < 0.6 for extended period:
  - Display warning banner: "Low accuracy detected"
  - Suggest: "Try better lighting or adjust camera angle"
  - Continue counting but mark reps as low confidence

### Network and API Errors

**Session Save Failed (Network Error):**
- Store session locally in SQLite
- Display: "Session saved locally. Will sync when online."
- Add to sync queue
- Show sync status indicator

**API Request Failed (4xx/5xx):**
- Retry up to 3 times with exponential backoff (1s, 2s, 4s)
- After 3 failures:
  - Display error message with details
  - Save data locally
  - Provide manual retry button
- Log error for debugging

**Authentication Error (401):**
- Display: "Session expired. Please log in again."
- Redirect to login screen
- Preserve unsaved session data
- Restore session after re-authentication

**Conversion Failed:**
- Display: "Unable to convert session to workout"
- Keep session in history
- Allow retry later
- Log error details

### Resource and Performance Errors

**Low Memory Warning:**
- Reduce frame processing rate from 30 FPS to 15 FPS
- Display warning: "Device memory low. Performance may be affected."
- Offer to stop session and save

**CPU Overload:**
- Monitor CPU usage
- If > 80% for 10 seconds:
  - Reduce processing rate
  - Simplify pose overlay rendering
  - Display: "Reducing quality to maintain performance"

**Battery Low (<15%):**
- Display warning: "Battery low. Camera mode uses significant power."
- Suggest: "Consider using manual logging to save battery"
- Continue session if user chooses

### Session and Data Errors

**Session Recovery Failed:**
- On app restart after crash:
  - Attempt to load last session from local storage
  - If recovery fails:
    - Display: "Previous session could not be recovered"
    - Log error for investigation
  - If recovery succeeds:
    - Display: "Session recovered. Continue or save?"

**Data Validation Failed:**
- If RepSession data is invalid (e.g., negative reps):
  - Display: "Invalid session data detected"
  - Offer to discard or manually correct
  - Log validation error

**Sync Conflict:**
- If local and server data conflict:
  - Prefer server data (source of truth)
  - Display: "Session data updated from server"
  - Log conflict for analysis

### User Experience Error Handling

**Graceful Degradation:**
- If camera fails → Fall back to manual logging
- If ML Kit fails → Disable camera option
- If network fails → Queue for later sync
- Always provide alternative path forward

**Error Message Guidelines:**
- Clear, non-technical language
- Explain what happened
- Suggest actionable solution
- Provide fallback option
- Use consistent error styling (red theme)

**Error Logging:**
- Log all errors to analytics service
- Include: error type, timestamp, device info, user action
- Use for debugging and improving reliability
- Respect user privacy (no PII in logs)

## Testing Strategy

### Dual Testing Approach

This feature requires both **unit tests** and **property-based tests** for comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property-based tests**: Verify universal properties across all inputs
- Both are complementary and necessary for comprehensive coverage

### Property-Based Testing

**Library Selection:**
- **Flutter/Dart**: Use `test` package with custom property test helpers or `dartz` for functional testing
- **Python/Django**: Use `hypothesis` library for property-based testing

**Configuration:**
- Minimum 100 iterations per property test (due to randomization)
- Each property test must reference its design document property
- Tag format: `// Feature: camera-rep-counting, Property N: [property text]`

**Property Test Examples:**

```dart
// Feature: camera-rep-counting, Property 1: Angle Calculation from Landmarks
test('angle calculation produces valid range', () {
  for (int i = 0; i < 100; i++) {
    // Generate random landmarks
    final a = PoseLandmark(type: PoseLandmarkType.SHOULDER, 
                           position: Point(random.nextDouble() * 100, random.nextDouble() * 100),
                           confidence: 1.0);
    final b = PoseLandmark(type: PoseLandmarkType.ELBOW,
                           position: Point(random.nextDouble() * 100, random.nextDouble() * 100),
                           confidence: 1.0);
    final c = PoseLandmark(type: PoseLandmarkType.WRIST,
                           position: Point(random.nextDouble() * 100, random.nextDouble() * 100),
                           confidence: 1.0);
    
    final angle = algorithm.calculateAngle(a, b, c);
    
    expect(angle, greaterThanOrEqualTo(0.0));
    expect(angle, lessThanOrEqualTo(180.0));
  }
});

// Feature: camera-rep-counting, Property 4: Angle Threshold Filtering
test('movements below threshold are rejected', () {
  for (int i = 0; i < 100; i++) {
    // Generate random angle change below threshold
    final angleChange = random.nextDouble() * (minThreshold - 1);
    final result = algorithm.isValidRep(angleChange, DateTime.now());
    
    expect(result, isFalse);
  }
});
```

**Python Property Test Example:**

```python
from hypothesis import given, strategies as st

# Feature: camera-rep-counting, Property 19: Session Average Confidence Calculation
@given(st.lists(st.floats(min_value=0.0, max_value=1.0), min_size=1, max_size=100))
def test_session_average_confidence(confidences):
    """For any list of confidence scores, average should equal sum/count"""
    session = RepSession(total_reps=len(confidences))
    for i, conf in enumerate(confidences):
        RepEvent.objects.create(session=session, rep_number=i+1, confidence=conf)
    
    expected_avg = sum(confidences) / len(confidences)
    assert abs(session.confidence_avg - expected_avg) < 0.001

# Feature: camera-rep-counting, Property 23: User Authorization Validation
@given(st.integers(min_value=1, max_value=1000), st.integers(min_value=1, max_value=1000))
def test_user_authorization(session_user_id, request_user_id):
    """For any user IDs, access should only be granted when they match"""
    session = RepSession(user_id=session_user_id)
    request = MockRequest(user_id=request_user_id)
    
    if session_user_id == request_user_id:
        assert can_access_session(request, session) == True
    else:
        assert can_access_session(request, session) == False
```

### Unit Testing

**Focus Areas for Unit Tests:**
- Specific examples demonstrating correct behavior
- Edge cases (empty sessions, single rep, maximum reps)
- Error conditions (camera failure, network errors)
- Integration points between components
- UI interactions and state transitions

**Unit Test Examples:**

```dart
// Example: Camera permission denied
test('camera permission denied shows error and fallback', () async {
  when(mockCamera.requestPermission()).thenReturn(Future.value(false));
  
  await screen.initializeCamera();
  
  expect(screen.errorMessage, contains('Camera access is required'));
  expect(screen.showManualLoggingButton, isTrue);
});

// Example: Pause and resume maintains count
test('pause and resume maintains rep count', () {
  screen.startSession();
  screen.addRep(0.9, {});
  screen.addRep(0.85, {});
  expect(screen.currentRepCount, equals(2));
  
  screen.pauseSession();
  screen.resumeSession();
  
  expect(screen.currentRepCount, equals(2));
  screen.addRep(0.88, {});
  expect(screen.currentRepCount, equals(3));
});

// Edge case: Empty session
test('empty session can be saved', () {
  final session = RepSession(
    userId: 1,
    exerciseType: 'push_ups',
    startTime: DateTime.now(),
    endTime: DateTime.now(),
    totalReps: 0,
    confidenceAvg: 0.0,
  );
  
  expect(() => session.save(), returnsNormally);
});

// Edge case: Single rep session
test('single rep session calculates correct average', () {
  final session = RepSession(totalReps: 1);
  final event = RepEvent(repNumber: 1, confidence: 0.75);
  session.events.add(event);
  
  expect(session.confidenceAvg, equals(0.75));
});
```

**Backend Unit Tests:**

```python
# Example: Session creation
def test_create_rep_session(self):
    data = {
        'exercise_type': 'push_ups',
        'start_time': timezone.now(),
        'end_time': timezone.now() + timedelta(minutes=5),
        'total_reps': 20,
        'confidence_avg': 0.85,
        'events': []
    }
    response = self.client.post('/api/rep-sessions/', data, format='json')
    self.assertEqual(response.status_code, 201)
    self.assertEqual(RepSession.objects.count(), 1)

# Example: Conversion to workout
def test_convert_session_to_workout(self):
    session = RepSession.objects.create(
        user=self.user,
        exercise_type='squats',
        total_reps=30,
        confidence_avg=0.9
    )
    
    response = self.client.post(
        f'/api/rep-sessions/{session.id}/convert-to-workout/',
        {'sets': 3, 'weight': 50.0},
        format='json'
    )
    
    self.assertEqual(response.status_code, 201)
    session.refresh_from_db()
    self.assertIsNotNone(session.converted_workout)
    self.assertEqual(session.converted_workout.reps, 30)

# Edge case: Cannot convert already converted session
def test_cannot_convert_twice(self):
    session = RepSession.objects.create(user=self.user, ...)
    workout = WorkoutLog.objects.create(user=self.user, ...)
    session.converted_workout = workout
    session.save()
    
    response = self.client.post(
        f'/api/rep-sessions/{session.id}/convert-to-workout/',
        {'sets': 1},
        format='json'
    )
    
    self.assertEqual(response.status_code, 400)
    self.assertIn('already converted', response.data['error'])
```

### Integration Testing

**Test Scenarios:**
1. **End-to-End Session Flow:**
   - Start camera → Detect reps → Stop session → Review → Convert to workout
   - Verify data flows correctly through all layers

2. **Offline-to-Online Sync:**
   - Create session offline → Go online → Verify auto-sync
   - Test sync queue and retry logic

3. **Multi-Exercise Session:**
   - Test different exercise algorithms
   - Verify correct landmark tracking per exercise

4. **Error Recovery:**
   - Simulate camera failure mid-session
   - Simulate network failure during save
   - Verify graceful recovery

### Widget Testing (Flutter)

**UI Component Tests:**
```dart
testWidgets('rep counter displays and updates', (tester) async {
  await tester.pumpWidget(CameraRepCountingScreen());
  
  expect(find.text('0'), findsOneWidget);
  
  // Simulate rep detection
  screen.onRepDetected(RepEvent(repNumber: 1, confidence: 0.9));
  await tester.pump();
  
  expect(find.text('1'), findsOneWidget);
});

testWidgets('confidence color coding', (tester) async {
  await tester.pumpWidget(ConfidenceIndicator(confidence: 0.9));
  expect(find.byColor(Colors.green), findsOneWidget);
  
  await tester.pumpWidget(ConfidenceIndicator(confidence: 0.7));
  expect(find.byColor(Colors.yellow), findsOneWidget);
  
  await tester.pumpWidget(ConfidenceIndicator(confidence: 0.5));
  expect(find.byColor(Colors.red), findsOneWidget);
});
```

### Manual Testing Requirements

**Real-World Exercise Testing:**
- Test each supported exercise with real users
- Verify accuracy across different body types
- Test in various lighting conditions
- Test at different camera distances and angles
- Measure actual accuracy rate (target: 85%+)

**Performance Testing:**
- Measure FPS during active session
- Monitor CPU and memory usage
- Test battery drain over 30-minute session
- Verify frame processing latency < 33ms

**Usability Testing:**
- First-time user onboarding flow
- Error message clarity
- Recovery from common errors
- Overall user experience

### Test Coverage Goals

- **Unit Test Coverage**: 80%+ for business logic
- **Property Test Coverage**: All 27 correctness properties
- **Integration Test Coverage**: All critical user flows
- **Widget Test Coverage**: All UI components
- **Manual Test Coverage**: All supported exercises in real conditions

### Continuous Integration

**Automated Test Execution:**
- Run unit tests on every commit
- Run property tests on every PR
- Run integration tests nightly
- Generate coverage reports
- Block merges if tests fail or coverage drops

**Test Data Management:**
- Use factories for test data generation
- Mock ML Kit responses for consistent testing
- Use test database for backend tests
- Clean up test data after each test
