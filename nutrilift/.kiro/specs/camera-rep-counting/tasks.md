# Implementation Plan: Camera-Based Rep Counting

## Overview

This implementation plan breaks down the camera-based rep counting feature into discrete, incremental coding tasks. The approach follows a bottom-up strategy: first establishing backend data models and APIs, then building core ML and algorithm components, and finally integrating everything into the UI. Each task builds on previous work, with checkpoints to validate progress.

## Tasks

- [ ] 1. Set up backend data models and database migrations
  - Create RepSession and RepEvent Django models
  - Define model fields, relationships, and constraints
  - Create database migrations
  - Add model indexes for performance
  - _Requirements: 12.1, 12.2_

- [ ] 1.1 Write unit tests for RepSession and RepEvent models
  - Test model creation and validation
  - Test field constraints and defaults
  - Test relationships and cascade deletion
  - _Requirements: 12.1, 12.2_

- [ ] 2. Implement backend API endpoints
  - [ ] 2.1 Create RepSessionSerializer and RepEventSerializer
    - Implement serializer fields and validation
    - Handle nested RepEvent serialization
    - Add computed fields (duration_seconds)
    - _Requirements: 12.3, 12.9_
  
  - [ ] 2.2 Create RepSessionViewSet with CRUD operations
    - Implement list, create, retrieve, update, delete actions
    - Add user filtering in get_queryset
    - Implement permission checks
    - _Requirements: 12.3, 12.4, 12.5, 12.7_
  
  - [ ] 2.3 Implement convert_to_workout custom action
    - Create WorkoutLog from RepSession data
    - Link RepSession to WorkoutLog
    - Validate session not already converted
    - _Requirements: 6.1, 6.7, 12.6, 12.10_
  
  - [ ] 2.4 Configure URL routing for rep-sessions endpoints
    - Register RepSessionViewSet with router
    - Configure API URL patterns
    - _Requirements: 12.3, 12.4, 12.5, 12.6_

- [ ] 2.5 Write property test for user authorization validation
  - **Property 23: User Authorization Validation**
  - **Validates: Requirements 12.7**

- [ ] 2.6 Write property test for session ordering
  - **Property 11: Session History Ordering**
  - **Validates: Requirements 7.1, 12.8**

- [ ] 2.7 Write property test for session retrieval includes events
  - **Property 24: Session Retrieval Includes Events**
  - **Validates: Requirements 12.9**

- [ ] 2.8 Write property test for workout conversion
  - **Property 10: Workout Conversion Creates Linked Record**
  - **Validates: Requirements 6.7, 12.10**

- [ ] 2.9 Write unit tests for API endpoints
  - Test session creation, retrieval, update, delete
  - Test convert_to_workout action
  - Test error cases (unauthorized access, already converted)
  - _Requirements: 12.3, 12.4, 12.5, 12.6, 12.7, 12.10_

- [ ] 3. Checkpoint - Backend API validation
  - Run all backend tests and ensure they pass
  - Test API endpoints manually using Postman or curl
  - Verify database schema is correct
  - Ask the user if questions arise



- [ ] 4. Create frontend data models
  - [ ] 4.1 Implement RepSession Dart model
    - Define RepSession class with all fields
    - Implement fromJson and toJson methods
    - Add computed properties (duration)
    - _Requirements: 12.1_
  
  - [ ] 4.2 Implement RepEvent Dart model
    - Define RepEvent class with all fields
    - Implement fromJson and toJson methods
    - _Requirements: 12.2_

- [ ] 4.3 Write property test for data model completeness
  - **Property 22: Data Model Completeness**
  - **Validates: Requirements 12.1, 12.2**

- [ ] 4.4 Write unit tests for data models
  - Test JSON serialization/deserialization
  - Test computed properties
  - Test edge cases (empty sessions, null values)
  - _Requirements: 12.1, 12.2_

- [ ] 5. Implement RepApiService for backend communication
  - [ ] 5.1 Create RepApiService class with HTTP client
    - Implement createSession method (POST /api/rep-sessions/)
    - Implement listSessions method (GET /api/rep-sessions/)
    - Implement getSession method (GET /api/rep-sessions/{id}/)
    - Implement convertToWorkout method (POST /api/rep-sessions/{id}/convert-to-workout/)
    - Implement deleteSession method (DELETE /api/rep-sessions/{id}/)
    - _Requirements: 12.3, 12.4, 12.5, 12.6_
  
  - [ ] 5.2 Add error handling and retry logic
    - Implement exponential backoff retry (up to 3 attempts)
    - Handle network errors and timeouts
    - Handle authentication errors (401)
    - _Requirements: 14.6_

- [ ] 5.3 Write property test for API retry logic
  - **Property 26: API Retry with Exponential Backoff**
  - **Validates: Requirements 14.6**

- [ ] 5.4 Write unit tests for RepApiService
  - Test all API methods with mock responses
  - Test error handling and retry logic
  - Test authentication error handling
  - _Requirements: 12.3, 12.4, 12.5, 12.6, 14.6_

- [ ] 6. Implement angle calculation utility
  - [ ] 6.1 Create angle calculation function
    - Implement calculateAngle(a, b, c) using vector math
    - Calculate angle at point b using dot product and cross product
    - Return angle in degrees [0, 180]
    - _Requirements: 2.1_

- [ ] 6.2 Write property test for angle calculation
  - **Property 1: Angle Calculation from Landmarks**
  - **Validates: Requirements 2.1**

- [ ] 6.3 Write unit tests for angle calculation
  - Test known angle configurations (90°, 45°, 180°)
  - Test edge cases (collinear points, zero vectors)
  - _Requirements: 2.1_

- [ ] 7. Implement exercise-specific rep detection algorithms
  - [ ] 7.1 Create base ExerciseAlgorithm abstract class
    - Define interface: processFrame, reset, isValidRep
    - Implement common logic: temporal filtering, state tracking
    - _Requirements: 2.9, 2.10_
  
  - [ ] 7.2 Implement PushUpAlgorithm
    - Track elbow angle (shoulder-elbow-wrist)
    - Detect down position (angle < 90°) and up position (angle > 160°)
    - Validate full range of motion (70° change)
    - Check form: body alignment
    - _Requirements: 3.1, 3.8_
  
  - [ ] 7.3 Implement SquatAlgorithm
    - Track knee angle (hip-knee-ankle)
    - Detect down position (angle < 90°) and up position (angle > 160°)
    - Validate full range of motion (70° change)
    - Check form: knees not past toes
    - _Requirements: 3.2, 3.8_
  
  - [ ] 7.4 Implement PullUpAlgorithm
    - Track elbow angle and shoulder vertical displacement
    - Detect down (angle > 160°, shoulders low) and up (angle < 90°, shoulders high)
    - Validate vertical displacement (30% body height)
    - _Requirements: 3.3, 3.8_
  
  - [ ] 7.5 Implement BicepCurlAlgorithm
    - Track elbow angle (shoulder-elbow-wrist)
    - Detect start (angle > 160°) and curl (angle < 45°)
    - Validate full range of motion (115° change)
    - Check form: elbow stationary
    - _Requirements: 3.4, 3.8_
  
  - [ ] 7.6 Implement ShoulderPressAlgorithm
    - Track elbow angle and wrist vertical displacement
    - Detect down (angle < 90°, wrists at shoulder) and up (angle > 160°, wrists above head)
    - Validate vertical displacement (40cm)
    - Check form: minimal horizontal drift
    - _Requirements: 3.5, 3.8_
  
  - [ ] 7.7 Implement LungeAlgorithm
    - Track front knee angle (hip-knee-ankle)
    - Detect up (angle > 160°) and down (angle < 90°)
    - Validate full range of motion (70° change)
    - Check form: knee not past ankle
    - _Requirements: 3.6, 3.8_
  
  - [ ] 7.8 Implement SitUpAlgorithm
    - Track hip angle (shoulder-hip-knee)
    - Detect down (angle > 160°) and up (angle < 90°)
    - Validate full range of motion (70° change)
    - Check form: knees remain bent
    - _Requirements: 3.7, 3.8_

- [ ] 7.9 Write property test for angle threshold filtering
  - **Property 4: Angle Threshold Filtering**
  - **Validates: Requirements 2.9**

- [ ] 7.10 Write property test for temporal filtering
  - **Property 5: Temporal Filtering**
  - **Validates: Requirements 2.10**

- [ ] 7.11 Write property test for full range of motion validation
  - **Property 6: Full Range of Motion Validation**
  - **Validates: Requirements 3.8**

- [ ] 7.12 Write property test for form quality affects confidence
  - **Property 7: Form Quality Affects Confidence**
  - **Validates: Requirements 3.9**

- [ ] 7.13 Write unit tests for each exercise algorithm
  - Test rep detection for each exercise type
  - Test false positive filtering
  - Test form quality assessment
  - Test edge cases (partial reps, too fast reps)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9_

- [ ] 8. Checkpoint - Algorithm validation
  - Run all algorithm tests and ensure they pass
  - Manually test algorithms with sample landmark data
  - Verify rep detection accuracy
  - Ask the user if questions arise



- [ ] 9. Implement PoseDetectionService wrapper for ML Kit
  - [ ] 9.1 Add google_mlkit_pose_detection dependency
    - Add package to pubspec.yaml
    - Configure Android permissions in AndroidManifest.xml
    - _Requirements: 1.2_
  
  - [ ] 9.2 Create PoseDetectionService class
    - Initialize ML Kit PoseDetector with STREAM mode
    - Implement detectPose method to process InputImage
    - Return list of PoseLandmark with coordinates and confidence
    - Implement dispose method for cleanup
    - _Requirements: 1.4, 9.1_
  
  - [ ] 9.3 Add landmark confidence validation
    - Ensure all confidence scores are in range [0.0, 1.0]
    - Filter out landmarks with very low confidence
    - _Requirements: 9.1_

- [ ] 9.4 Write property test for landmark confidence range
  - **Property 15: Landmark Confidence Range**
  - **Validates: Requirements 9.1**

- [ ] 9.5 Write unit tests for PoseDetectionService
  - Test initialization and disposal
  - Test pose detection with mock images
  - Test error handling (ML Kit load failure)
  - _Requirements: 1.4, 9.1_

- [ ] 10. Implement RepSessionManager for state management
  - [ ] 10.1 Create RepSessionManager class with ChangeNotifier
    - Track current session state (idle, active, paused, stopped)
    - Maintain current rep count and events list
    - Implement startSession, addRep, pauseSession, resumeSession, stopSession
    - _Requirements: 2.2, 2.3, 4.1, 4.2, 4.3_
  
  - [ ] 10.2 Add local persistence with sqflite
    - Create local database schema for RepSession and RepEvent
    - Implement saveSessionLocally method
    - Implement loadLocalSessions method
    - _Requirements: 15.3_
  
  - [ ] 10.3 Implement sync queue for offline support
    - Track sessions pending sync
    - Implement syncToBackend method
    - Handle sync failures and retries
    - Update sync status indicators
    - _Requirements: 14.3, 15.4, 15.7_

- [ ] 10.4 Write property test for rep detection triggers state changes
  - **Property 2: Rep Detection Triggers State Changes**
  - **Validates: Requirements 2.2, 2.3**

- [ ] 10.5 Write property test for manual adjustment updates session
  - **Property 8: Manual Adjustment Updates Session**
  - **Validates: Requirements 5.6**

- [ ] 10.6 Write property test for sync status indication
  - **Property 27: Sync Status Indication**
  - **Validates: Requirements 15.7**

- [ ] 10.7 Write unit tests for RepSessionManager
  - Test session lifecycle (start, pause, resume, stop)
  - Test rep addition and counting
  - Test local persistence
  - Test sync queue and status
  - _Requirements: 2.2, 2.3, 4.1, 4.2, 4.3, 15.3, 15.4, 15.7_

- [ ] 11. Implement camera integration
  - [ ] 11.1 Add camera dependency
    - Add camera package to pubspec.yaml
    - Configure camera permissions in AndroidManifest.xml
    - _Requirements: 1.2_
  
  - [ ] 11.2 Create CameraController wrapper
    - Initialize camera with appropriate resolution
    - Handle camera permission requests
    - Implement startImageStream for frame processing
    - Implement dispose for cleanup
    - _Requirements: 1.2, 1.3, 8.6_
  
  - [ ] 11.3 Implement frame processing pipeline
    - Convert CameraImage to InputImage for ML Kit
    - Process frames at target rate (30 FPS)
    - Handle frame processing errors
    - _Requirements: 8.1, 8.2_

- [ ] 11.4 Write unit tests for camera integration
  - Test camera initialization
  - Test permission handling
  - Test frame processing pipeline
  - Test error handling (camera unavailable, permission denied)
  - _Requirements: 1.2, 1.3, 1.5, 8.6_

- [ ] 12. Implement CameraRepCountingScreen UI
  - [ ] 12.1 Create screen scaffold with camera preview
    - Display camera preview with CameraPreview widget
    - Overlay pose landmarks on camera feed
    - Add semi-transparent overlay for UI elements
    - _Requirements: 1.4, 1.7_
  
  - [ ] 12.2 Add rep counter display
    - Large text display for current rep count (48sp+)
    - Initialize to zero on session start
    - Update in real-time as reps are detected
    - _Requirements: 1.7, 2.2_
  
  - [ ] 12.3 Add confidence score indicator
    - Display current confidence score
    - Color code: green (>0.8), yellow (0.6-0.8), red (<0.6)
    - Show warning icon when confidence < 0.6
    - _Requirements: 1.8, 2.7, 9.4_
  
  - [ ] 12.4 Add session control buttons
    - Pause button (pause rep detection, maintain camera)
    - Resume button (resume rep detection)
    - Stop button (end session, navigate to review)
    - Style buttons with red theme (#E53935)
    - _Requirements: 4.1, 4.2, 4.3, 13.1_
  
  - [ ] 12.5 Add visual/audio/haptic feedback for rep detection
    - Animate rep counter on rep detection
    - Play sound effect on rep detection
    - Trigger haptic vibration on rep detection
    - _Requirements: 2.4, 2.5, 2.6_
  
  - [ ] 12.6 Add error and warning overlays
    - Display error messages (camera failure, ML Kit failure)
    - Display warnings (low confidence, poor lighting, bad framing)
    - Display repositioning guidance when tracking lost
    - _Requirements: 1.3, 1.5, 2.8, 10.1, 10.2, 10.3, 14.1, 14.2_
  
  - [ ] 12.7 Implement session lifecycle management
    - Create RepSession on session start
    - Create RepEvent on each rep detection
    - Handle pause/resume state
    - Save session on stop
    - _Requirements: 1.9, 2.3, 4.1, 4.2, 4.3_

- [ ] 12.8 Write property test for low confidence warning display
  - **Property 3: Low Confidence Warning Display**
  - **Validates: Requirements 2.7**

- [ ] 12.9 Write property test for confidence color coding
  - **Property 18: Confidence Color Coding**
  - **Validates: Requirements 9.4**

- [ ] 12.10 Write property test for primary button color consistency
  - **Property 25: Primary Button Color Consistency**
  - **Validates: Requirements 13.1**

- [ ] 12.11 Write widget tests for CameraRepCountingScreen
  - Test rep counter display and updates
  - Test confidence indicator color coding
  - Test control buttons (pause, resume, stop)
  - Test error and warning overlays
  - _Requirements: 1.7, 2.2, 2.7, 4.1, 4.2, 4.3, 9.4, 13.1_

- [ ] 13. Checkpoint - Camera screen validation
  - Run all frontend tests and ensure they pass
  - Manually test camera screen with device
  - Verify UI elements display correctly
  - Test rep detection with real exercises
  - Ask the user if questions arise



- [ ] 14. Implement exercise selection screen
  - [ ] 14.1 Create ExerciseSelectionScreen UI
    - Display list of supported exercises (push-ups, squats, pull-ups, bicep curls, shoulder press, lunges, sit-ups)
    - Show exercise icons and descriptions
    - Navigate to camera screen on selection
    - _Requirements: 1.1, 1.6_
  
  - [ ] 14.2 Add camera positioning guide for each exercise
    - Display exercise-specific positioning instructions
    - Show visual guide (image or animation)
    - Explain optimal camera distance and angle
    - _Requirements: 1.1, 4.1_

- [ ] 14.3 Write unit tests for ExerciseSelectionScreen
  - Test exercise list display
  - Test navigation on selection
  - Test positioning guide display
  - _Requirements: 1.1, 1.6_

- [ ] 15. Implement session review screen
  - [ ] 15.1 Create SessionReviewScreen UI
    - Display session summary (total reps, duration, average confidence)
    - Show list of individual RepEvents with timestamps
    - Add manual rep count adjustment input
    - Add "Convert to Workout" button
    - Add "Discard Session" button
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  
  - [ ] 15.2 Implement rep count adjustment
    - Allow user to edit total rep count
    - Update RepSession record on change
    - Validate input (positive integer)
    - _Requirements: 5.2, 5.6_
  
  - [ ] 15.3 Implement session discard
    - Show confirmation dialog
    - Delete RepSession and all RepEvents
    - Navigate back to home
    - _Requirements: 5.7_
  
  - [ ] 15.4 Add low confidence warning
    - Display warning when average confidence < 0.7
    - Suggest reviewing rep count
    - _Requirements: 9.6_

- [ ] 15.5 Write property test for session average confidence calculation
  - **Property 19: Session Average Confidence Calculation**
  - **Validates: Requirements 9.5**

- [ ] 15.6 Write property test for low average confidence warning
  - **Property 20: Low Average Confidence Warning**
  - **Validates: Requirements 9.6**

- [ ] 15.7 Write widget tests for SessionReviewScreen
  - Test session summary display
  - Test rep count adjustment
  - Test discard confirmation
  - Test low confidence warning
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 9.6_

- [ ] 16. Implement workout conversion flow
  - [ ] 16.1 Create WorkoutConversionScreen UI
    - Pre-fill exercise type from RepSession
    - Pre-fill reps from RepSession total
    - Set sets to 1 by default
    - Add weight input field
    - Add notes input field
    - Add save button
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_
  
  - [ ] 16.2 Implement workout save logic
    - Call RepApiService.convertToWorkout
    - Create WorkoutLog linked to RepSession
    - Navigate to workout history on success
    - Handle errors (network failure, already converted)
    - _Requirements: 6.7, 6.8, 12.6_

- [ ] 16.3 Write property test for workout form pre-population
  - **Property 9: Workout Form Pre-Population**
  - **Validates: Requirements 6.2, 6.3**

- [ ] 16.4 Write widget tests for WorkoutConversionScreen
  - Test form pre-population
  - Test weight and notes input
  - Test save button
  - Test error handling
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

- [ ] 17. Implement session history screen
  - [ ] 17.1 Create SessionHistoryScreen UI
    - Display list of RepSessions ordered by date (newest first)
    - Show exercise type, date, total reps, duration for each
    - Indicate converted sessions with icon/badge
    - Implement pagination (20 sessions per page)
    - _Requirements: 7.1, 7.2, 7.3, 7.7_
  
  - [ ] 17.2 Implement session detail navigation
    - Navigate to SessionReviewScreen on tap
    - Allow conversion for unconverted sessions
    - Provide link to WorkoutLog for converted sessions
    - _Requirements: 7.4, 7.5, 7.6_

- [ ] 17.3 Write property test for session history display completeness
  - **Property 12: Session History Display Completeness**
  - **Validates: Requirements 7.2**

- [ ] 17.4 Write property test for conversion status indication
  - **Property 13: Conversion Status Indication**
  - **Validates: Requirements 7.3**

- [ ] 17.5 Write property test for converted session links to workout
  - **Property 14: Converted Session Links to Workout**
  - **Validates: Requirements 7.6**

- [ ] 17.6 Write widget tests for SessionHistoryScreen
  - Test session list display
  - Test ordering (newest first)
  - Test conversion status indicators
  - Test navigation to detail
  - Test pagination
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [ ] 18. Implement onboarding tutorial
  - [ ] 18.1 Create OnboardingScreen UI
    - Create multi-page tutorial with PageView
    - Explain camera positioning for each exercise
    - Show example videos or animations
    - Explain confidence score indicator
    - Add "Skip" and "Next" buttons
    - _Requirements: 11.1, 11.2, 11.3, 11.4_
  
  - [ ] 18.2 Implement tutorial state management
    - Check if tutorial completed on first access
    - Mark tutorial as completed when finished
    - Don't show tutorial again after completion
    - Provide "Help" button to access tutorial anytime
    - _Requirements: 11.5, 11.6_

- [ ] 18.3 Write unit tests for onboarding
  - Test tutorial display on first access
  - Test tutorial completion state
  - Test help button access
  - _Requirements: 11.1, 11.5, 11.6_

- [ ] 19. Implement error handling and recovery
  - [ ] 19.1 Add camera error handling
    - Handle permission denied (show error, offer settings)
    - Handle camera initialization failure (show error, offer retry)
    - Handle camera unavailable (show error, redirect to manual)
    - _Requirements: 1.3, 1.5, 14.1_
  
  - [ ] 19.2 Add ML Kit error handling
    - Handle model loading failure (show error, offer retry)
    - Handle pose detection timeout (pause, show guidance)
    - _Requirements: 2.8, 14.2_
  
  - [ ] 19.3 Add network error handling
    - Handle session save failure (save locally, queue sync)
    - Handle API errors (retry with backoff, show error)
    - Handle authentication errors (redirect to login)
    - _Requirements: 14.3, 14.6, 14.7_
  
  - [ ] 19.4 Add session recovery
    - Attempt to recover session on app restart after crash
    - Notify user if recovery fails
    - _Requirements: 14.4, 14.5_

- [ ] 19.5 Write unit tests for error handling
  - Test all error scenarios
  - Test retry logic
  - Test fallback behaviors
  - Test session recovery
  - _Requirements: 1.3, 1.5, 2.8, 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7_

- [ ] 20. Implement offline support
  - [ ] 20.1 Add offline detection
    - Monitor network connectivity
    - Update UI to show offline status
    - _Requirements: 15.3, 15.4_
  
  - [ ] 20.2 Implement offline session storage
    - Store RepSession and RepEvents locally when offline
    - Display locally stored sessions in history
    - _Requirements: 15.3, 15.5_
  
  - [ ] 20.3 Implement auto-sync on connectivity restore
    - Detect when connectivity returns
    - Automatically sync queued sessions
    - Update sync status indicators
    - _Requirements: 15.4, 15.7_
  
  - [ ] 20.4 Handle offline workout conversion
    - Queue conversion requests when offline
    - Process queue when connectivity returns
    - _Requirements: 15.6_

- [ ] 20.5 Write unit tests for offline support
  - Test offline session storage
  - Test auto-sync on connectivity restore
  - Test offline conversion queueing
  - _Requirements: 15.3, 15.4, 15.5, 15.6, 15.7_

- [ ] 21. Checkpoint - Integration validation
  - Run all tests (unit, property, widget) and ensure they pass
  - Test complete user flows end-to-end
  - Test offline-to-online sync
  - Test error recovery scenarios
  - Ask the user if questions arise

- [ ] 22. Integrate with existing workout tracking system
  - [ ] 22.1 Add navigation from home screen to camera rep counting
    - Add "Camera Rep Counter" button/card on home screen
    - Navigate to ExerciseSelectionScreen on tap
    - Maintain existing manual logging option
    - _Requirements: 6.9_
  
  - [ ] 22.2 Link session history to workout history
    - Add "Rep Sessions" tab to workout history screen
    - Show both WorkoutLogs and RepSessions in unified view
    - Allow navigation between related records
    - _Requirements: 6.8, 7.6_
  
  - [ ] 22.3 Apply NutriLift theme consistently
    - Use NutriLiftHeader for all screen headers
    - Apply red theme (#E53935) to all primary buttons
    - Use consistent typography and spacing
    - Use existing icon set
    - _Requirements: 13.1, 13.2, 13.6, 13.7_

- [ ] 22.4 Write integration tests for workout system integration
  - Test navigation from home to camera
  - Test session-to-workout conversion flow
  - Test unified history display
  - _Requirements: 6.8, 6.9, 7.6_

- [ ] 23. Performance optimization
  - [ ] 23.1 Optimize frame processing
    - Ensure frame processing completes within 33ms
    - Reduce processing rate if CPU usage > 80%
    - Release camera resources on background
    - Resume camera on foreground return
    - _Requirements: 8.1, 8.2, 8.3, 8.6, 8.7_
  
  - [ ] 23.2 Add battery monitoring
    - Display warning when battery < 15%
    - Suggest manual logging to save battery
    - _Requirements: 8.5_
  
  - [ ] 23.3 Optimize ML Kit performance
    - Use STREAM mode for real-time processing
    - Configure appropriate detector settings
    - Ensure on-device processing (no network calls)
    - _Requirements: 8.4_

- [ ] 23.4 Write performance tests
  - Measure frame processing latency
  - Verify no network calls during ML processing
  - Test resource cleanup
  - _Requirements: 8.1, 8.2, 8.4, 8.6, 8.7_

- [ ] 24. Final testing and validation
  - [ ] 24.1 Run complete test suite
    - Execute all unit tests
    - Execute all property tests (100+ iterations each)
    - Execute all widget tests
    - Execute all integration tests
    - Verify test coverage meets goals (80%+ for business logic)
  
  - [ ] 24.2 Manual testing with real exercises
    - Test each supported exercise with real users
    - Verify accuracy across different body types
    - Test in various lighting conditions
    - Test at different camera distances and angles
    - Measure actual accuracy rate (target: 85%+)
    - _Requirements: 9.7_
  
  - [ ] 24.3 Performance testing
    - Measure FPS during active session (target: 30+)
    - Monitor CPU and memory usage
    - Test battery drain over 30-minute session
    - Verify frame processing latency < 33ms
    - _Requirements: 8.1, 8.2_
  
  - [ ] 24.4 Usability testing
    - Test first-time user onboarding flow
    - Verify error message clarity
    - Test recovery from common errors
    - Gather user feedback on overall experience

- [ ] 25. Final checkpoint - Production readiness
  - All tests passing
  - Manual testing complete with 85%+ accuracy
  - Performance metrics meet targets
  - Error handling validated
  - User experience polished
  - Ready for deployment

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (minimum 100 iterations each)
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end user flows
- Manual testing validates real-world accuracy and performance
