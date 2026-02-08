# Requirements Document: Camera-Based Rep Counting

## Introduction

The Camera-Based Rep Counting feature enhances the existing NutriLift workout tracking system by providing an optional, automated way to count exercise repetitions using on-device machine learning. This feature uses Google ML Kit Pose Detection to analyze body movements in real-time through the device camera, automatically counting reps for common exercises. Users can choose between traditional manual logging or the new camera-based approach, with camera sessions seamlessly converting to workout logs.

## Glossary

- **Rep_Counter**: The system component responsible for detecting and counting exercise repetitions
- **Pose_Detector**: The ML Kit component that identifies 33 body landmarks from camera feed
- **RepSession**: A database record of a camera-based counting session
- **RepEvent**: A database record of a single detected repetition within a session
- **WorkoutLog**: The existing workout record in the manual tracking system
- **Landmark**: A specific body point detected by ML Kit (e.g., left elbow, right knee)
- **Confidence_Score**: A 0-1 value indicating ML detection accuracy
- **Rep_Cycle**: The complete movement pattern from starting position through full range of motion and back
- **Angle_Threshold**: The minimum angle change required to register a valid rep
- **Camera_Session**: An active period where the user is performing exercises with camera tracking
- **Exercise_Algorithm**: The specific angle-based logic for detecting reps for each exercise type
- **Form_Quality**: An assessment of whether the rep met proper form criteria

## Requirements

### Requirement 1: Camera Session Initialization

**User Story:** As a user, I want to start a camera-based rep counting session for my chosen exercise, so that I can automatically track my reps without manual input.

#### Acceptance Criteria

1. WHEN a user selects an exercise type from the supported list, THE Rep_Counter SHALL display the exercise-specific camera positioning guide
2. WHEN a user grants camera permission, THE Rep_Counter SHALL initialize the camera feed and Pose_Detector
3. WHEN camera permission is denied, THE Rep_Counter SHALL display an error message and provide instructions to enable permissions
4. WHEN the Pose_Detector initializes successfully, THE Rep_Counter SHALL display the live video feed with pose landmark overlay
5. WHERE the device camera is unavailable, THE Rep_Counter SHALL display an error message and fall back to manual logging option
6. THE Rep_Counter SHALL support these exercise types: push-ups, squats, pull-ups, bicep curls, shoulder press, lunges, sit-ups
7. WHEN the camera feed starts, THE Rep_Counter SHALL display a live rep counter initialized to zero
8. WHEN the camera feed starts, THE Rep_Counter SHALL display the current confidence score
9. WHEN the camera feed starts, THE Rep_Counter SHALL create a new RepSession record with start timestamp

### Requirement 2: Real-Time Rep Detection

**User Story:** As a user, I want the system to automatically detect and count my reps as I perform exercises, so that I can focus on my workout without manual tracking.

#### Acceptance Criteria

1. WHEN the Pose_Detector identifies body landmarks, THE Exercise_Algorithm SHALL calculate relevant joint angles for the selected exercise
2. WHEN a complete Rep_Cycle is detected, THE Rep_Counter SHALL increment the displayed rep count by one
3. WHEN a rep is detected, THE Rep_Counter SHALL create a RepEvent record with timestamp and confidence score
4. WHEN a rep is detected, THE Rep_Counter SHALL provide visual feedback (animation on screen)
5. WHEN a rep is detected, THE Rep_Counter SHALL provide audio feedback (sound effect)
6. WHEN a rep is detected, THE Rep_Counter SHALL provide haptic feedback (device vibration)
7. WHILE the confidence score is below 0.6, THE Rep_Counter SHALL display a warning indicator
8. WHEN the Pose_Detector loses tracking of required landmarks, THE Rep_Counter SHALL pause counting and display a repositioning message
9. THE Exercise_Algorithm SHALL filter false positives by requiring minimum angle change thresholds
10. THE Exercise_Algorithm SHALL filter false positives by enforcing minimum time between consecutive reps (0.5 seconds)

### Requirement 3: Exercise-Specific Detection Algorithms

**User Story:** As a user, I want accurate rep counting for different exercise types, so that the system correctly tracks various movements.

#### Acceptance Criteria

1. FOR push-ups, THE Exercise_Algorithm SHALL track elbow angle (landmarks: shoulder, elbow, wrist) with threshold 90° ± 15°
2. FOR squats, THE Exercise_Algorithm SHALL track knee angle (landmarks: hip, knee, ankle) with threshold 90° ± 15°
3. FOR pull-ups, THE Exercise_Algorithm SHALL track elbow angle and vertical shoulder displacement with threshold 120° ± 15°
4. FOR bicep curls, THE Exercise_Algorithm SHALL track elbow angle (landmarks: shoulder, elbow, wrist) with threshold 45° ± 10°
5. FOR shoulder press, THE Exercise_Algorithm SHALL track elbow angle and vertical wrist displacement with threshold 90° ± 15°
6. FOR lunges, THE Exercise_Algorithm SHALL track front knee angle (landmarks: hip, knee, ankle) with threshold 90° ± 15°
7. FOR sit-ups, THE Exercise_Algorithm SHALL track hip angle (landmarks: shoulder, hip, knee) with threshold 45° ± 10°
8. WHEN an Exercise_Algorithm detects a rep, THE Rep_Counter SHALL validate that the movement completed a full range of motion
9. WHEN an Exercise_Algorithm detects poor form (incomplete range of motion), THE Rep_Counter SHALL mark the rep with reduced confidence score

### Requirement 4: Session Control and Management

**User Story:** As a user, I want to control my camera session with pause, resume, and stop functions, so that I can manage my workout flow.

#### Acceptance Criteria

1. WHEN a user taps the pause button, THE Rep_Counter SHALL pause rep detection while maintaining the camera feed
2. WHEN a user taps the resume button, THE Rep_Counter SHALL resume rep detection from the current count
3. WHEN a user taps the stop button, THE Rep_Counter SHALL end the Camera_Session and save the RepSession with end timestamp
4. WHEN a Camera_Session is stopped, THE Rep_Counter SHALL navigate to the session review screen
5. WHEN a Camera_Session exceeds 60 minutes, THE Rep_Counter SHALL automatically stop and save the session
6. WHILE a Camera_Session is paused, THE Rep_Counter SHALL display a paused indicator overlay
7. WHEN a user exits the camera screen without stopping, THE Rep_Counter SHALL prompt for confirmation before discarding the session

### Requirement 5: Rep Session Review and Editing

**User Story:** As a user, I want to review and edit my camera session results before saving to my workout log, so that I can correct any counting errors.

#### Acceptance Criteria

1. WHEN a Camera_Session ends, THE Rep_Counter SHALL display a review screen showing total reps, duration, and average confidence
2. WHEN viewing the review screen, THE Rep_Counter SHALL allow the user to manually adjust the total rep count
3. WHEN viewing the review screen, THE Rep_Counter SHALL display a list of individual RepEvents with timestamps
4. WHEN viewing the review screen, THE Rep_Counter SHALL provide a "Convert to Workout" button
5. WHEN viewing the review screen, THE Rep_Counter SHALL provide a "Discard Session" button
6. WHEN a user adjusts the rep count, THE Rep_Counter SHALL update the RepSession record
7. WHEN a user discards a session, THE Rep_Counter SHALL delete the RepSession and all associated RepEvents

### Requirement 6: Integration with Workout Logging System

**User Story:** As a user, I want to convert my camera session into a workout log entry, so that it appears in my workout history alongside manual entries.

#### Acceptance Criteria

1. WHEN a user taps "Convert to Workout", THE Rep_Counter SHALL navigate to a pre-filled workout creation form
2. WHEN displaying the workout creation form, THE Rep_Counter SHALL auto-populate exercise type from the RepSession
3. WHEN displaying the workout creation form, THE Rep_Counter SHALL auto-populate reps from the RepSession total
4. WHEN displaying the workout creation form, THE Rep_Counter SHALL set sets to 1 by default
5. WHEN displaying the workout creation form, THE Rep_Counter SHALL allow the user to add weight value
6. WHEN displaying the workout creation form, THE Rep_Counter SHALL allow the user to add notes
7. WHEN a user saves the workout, THE Rep_Counter SHALL create a WorkoutLog record linked to the RepSession
8. WHEN a user saves the workout, THE Rep_Counter SHALL navigate to the workout history screen
9. THE Rep_Counter SHALL maintain the existing manual workout logging as an alternative option

### Requirement 7: Session History and Retrieval

**User Story:** As a user, I want to view my past camera sessions, so that I can track my progress and review previous workouts.

#### Acceptance Criteria

1. WHEN a user navigates to session history, THE Rep_Counter SHALL display a list of all RepSessions ordered by date (newest first)
2. WHEN displaying session history, THE Rep_Counter SHALL show exercise type, date, total reps, and duration for each session
3. WHEN displaying session history, THE Rep_Counter SHALL indicate which sessions have been converted to WorkoutLogs
4. WHEN a user taps a session in history, THE Rep_Counter SHALL display the detailed session review screen
5. WHEN viewing an unconverted session from history, THE Rep_Counter SHALL allow conversion to WorkoutLog
6. WHEN viewing a converted session from history, THE Rep_Counter SHALL provide a link to the associated WorkoutLog
7. THE Rep_Counter SHALL support pagination for session history (20 sessions per page)

### Requirement 8: Performance and Real-Time Processing

**User Story:** As a user, I want smooth, real-time rep counting without lag, so that my workout experience is not disrupted.

#### Acceptance Criteria

1. THE Pose_Detector SHALL process camera frames at a minimum rate of 30 frames per second
2. THE Exercise_Algorithm SHALL complete rep detection calculations within 33 milliseconds per frame
3. WHEN the device CPU usage exceeds 80%, THE Rep_Counter SHALL reduce frame processing rate to maintain responsiveness
4. THE Rep_Counter SHALL perform all ML processing on-device without network calls
5. WHEN the device battery level is below 15%, THE Rep_Counter SHALL display a low battery warning
6. THE Rep_Counter SHALL release camera resources when the app moves to background
7. WHEN the app returns to foreground during an active session, THE Rep_Counter SHALL resume camera feed and detection

### Requirement 9: Accuracy and Confidence Scoring

**User Story:** As a user, I want accurate rep counting with confidence indicators, so that I can trust the automated counts.

#### Acceptance Criteria

1. THE Pose_Detector SHALL provide a confidence score (0-1) for each detected landmark
2. THE Exercise_Algorithm SHALL calculate an overall confidence score for each rep based on landmark confidence
3. WHEN a rep has confidence below 0.6, THE Rep_Counter SHALL mark it as low confidence
4. WHEN displaying the live confidence score, THE Rep_Counter SHALL use color coding (green >0.8, yellow 0.6-0.8, red <0.6)
5. THE RepSession SHALL store the average confidence score across all reps
6. WHEN the average confidence for a session is below 0.7, THE Rep_Counter SHALL display a warning on the review screen
7. THE Rep_Counter SHALL achieve a minimum 85% accuracy rate for supported exercises under good conditions

### Requirement 10: Environmental Adaptability

**User Story:** As a user, I want the rep counter to work in various lighting conditions and camera angles, so that I can use it in different workout environments.

#### Acceptance Criteria

1. WHEN lighting conditions are poor (low brightness), THE Rep_Counter SHALL display a lighting warning message
2. WHEN the user is not fully visible in frame, THE Rep_Counter SHALL display a framing guidance message
3. WHEN the camera angle is suboptimal for the selected exercise, THE Rep_Counter SHALL display angle adjustment suggestions
4. THE Pose_Detector SHALL function in lighting conditions from 50 lux to 10,000 lux
5. THE Exercise_Algorithm SHALL adapt to different body types by using relative angle measurements
6. THE Exercise_Algorithm SHALL handle camera distances from 1.5 meters to 4 meters
7. WHEN the Pose_Detector cannot detect the required landmarks for 5 consecutive seconds, THE Rep_Counter SHALL pause and display troubleshooting tips

### Requirement 11: User Onboarding and Guidance

**User Story:** As a first-time user, I want clear instructions on how to use the camera rep counter, so that I can set up and use it correctly.

#### Acceptance Criteria

1. WHEN a user accesses camera rep counting for the first time, THE Rep_Counter SHALL display an onboarding tutorial
2. WHEN displaying the onboarding tutorial, THE Rep_Counter SHALL explain camera positioning for each exercise type
3. WHEN displaying the onboarding tutorial, THE Rep_Counter SHALL show example videos or animations of proper setup
4. WHEN displaying the onboarding tutorial, THE Rep_Counter SHALL explain the confidence score indicator
5. WHEN a user completes the tutorial, THE Rep_Counter SHALL mark the tutorial as completed and not show it again
6. WHERE a user wants to review the tutorial, THE Rep_Counter SHALL provide a "Help" button to access tutorial content
7. WHEN an error occurs during a session, THE Rep_Counter SHALL display contextual help messages with solutions

### Requirement 12: Backend API and Data Persistence

**User Story:** As a system, I need to store rep session data persistently, so that users can access their history across app sessions.

#### Acceptance Criteria

1. THE Rep_Counter SHALL create a RepSession record with fields: id, user_id, exercise_type, start_time, end_time, total_reps, confidence_avg
2. THE Rep_Counter SHALL create RepEvent records with fields: id, session_id, rep_number, timestamp, confidence, angle_data
3. WHEN a RepSession is created, THE Rep_Counter SHALL send a POST request to /api/rep-sessions/
4. WHEN retrieving session history, THE Rep_Counter SHALL send a GET request to /api/rep-sessions/?user_id={user_id}
5. WHEN retrieving a specific session, THE Rep_Counter SHALL send a GET request to /api/rep-sessions/{id}/
6. WHEN converting a session to workout, THE Rep_Counter SHALL send a POST request to /api/rep-sessions/{id}/convert-to-workout/
7. THE backend SHALL validate that RepSession.user_id matches the authenticated user
8. THE backend SHALL return RepSessions ordered by start_time descending
9. THE backend SHALL include associated RepEvents when retrieving a specific RepSession
10. WHEN a RepSession is converted to WorkoutLog, THE backend SHALL create the WorkoutLog record and link it to the RepSession

### Requirement 13: UI Consistency and Theme Integration

**User Story:** As a user, I want the camera rep counting interface to match the existing NutriLift design, so that the experience feels cohesive.

#### Acceptance Criteria

1. THE Rep_Counter SHALL use the primary red color (#E53935) for all primary action buttons
2. THE Rep_Counter SHALL use the existing NutriLiftHeader component for screen headers
3. THE Rep_Counter SHALL follow the existing app navigation patterns
4. THE Rep_Counter SHALL use consistent typography with the rest of the app
5. THE Rep_Counter SHALL use consistent spacing and padding with existing screens
6. WHEN displaying the rep counter, THE Rep_Counter SHALL use large, readable fonts (minimum 48sp for count)
7. THE Rep_Counter SHALL use the existing app's icon set for control buttons

### Requirement 14: Error Handling and Recovery

**User Story:** As a user, I want clear error messages and recovery options when something goes wrong, so that I can continue my workout.

#### Acceptance Criteria

1. WHEN the camera fails to initialize, THE Rep_Counter SHALL display an error message with troubleshooting steps
2. WHEN the Pose_Detector fails to load, THE Rep_Counter SHALL display an error message and offer to retry
3. WHEN network connectivity is lost during session save, THE Rep_Counter SHALL queue the session for upload when connectivity returns
4. WHEN the app crashes during a session, THE Rep_Counter SHALL attempt to recover the session data on restart
5. IF session recovery fails, THE Rep_Counter SHALL notify the user that the session was lost
6. WHEN an API request fails, THE Rep_Counter SHALL retry up to 3 times with exponential backoff
7. WHEN all retry attempts fail, THE Rep_Counter SHALL display an error message and save data locally for later sync

### Requirement 15: Offline Support and Data Synchronization

**User Story:** As a user, I want to use the camera rep counter without internet connection, so that I can work out anywhere.

#### Acceptance Criteria

1. THE Pose_Detector SHALL function entirely offline using on-device ML models
2. THE Rep_Counter SHALL function entirely offline for rep detection and counting
3. WHEN offline, THE Rep_Counter SHALL store RepSession and RepEvent data locally
4. WHEN connectivity is restored, THE Rep_Counter SHALL automatically sync local data to the backend
5. WHEN viewing session history offline, THE Rep_Counter SHALL display locally stored sessions
6. WHEN attempting to convert a session to workout offline, THE Rep_Counter SHALL queue the conversion for when online
7. THE Rep_Counter SHALL indicate sync status with a visual indicator (synced, pending, failed)
