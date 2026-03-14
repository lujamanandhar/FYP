# Workout Logging Diagnostic Guide

## Current Status

The workout logging feature has been updated with the following fixes:

### ✅ Completed Fixes

1. **Added Workout Name Field**
   - Location: `frontend/lib/screens/new_workout_screen.dart`
   - Added `_workoutNameController` and `_buildWorkoutNameInput()` method
   - Field is marked as required with validation

2. **Updated Validation**
   - Location: `frontend/lib/providers/new_workout_provider.dart`
   - Added workout name validation in `_validateWorkout()`
   - Updated `isValid` getter to check workout name is not empty

3. **Fixed Request Format**
   - Location: `frontend/lib/services/workout_api_service.dart`
   - Correctly sends `workout_exercises` array (not `exercises`)
   - Each exercise has: `exercise` (id), `sets` (count), `reps`, `weight`, `order`
   - Fixed nullable notes field with `!` assertion

4. **Added Debug Logging**
   - Request data is logged before sending
   - Response data is logged on success
   - Errors are logged with status code and response data

## Backend Verification

The backend has been tested and validates correctly:

```python
# Test data format (VERIFIED WORKING):
{
    'workout_name': 'Test Workout',
    'duration_minutes': 60,
    'workout_exercises': [
        {
            'exercise': 4,  # Exercise ID
            'sets': 3,      # Number of sets
            'reps': 10,     # Reps per set
            'weight': 100.0,  # Weight in kg
            'order': 0      # Exercise order
        }
    ]
}
```

## Testing Steps

### 1. Check Flutter Console for Debug Logs

When you try to log a workout, look for these debug messages in the Flutter console:

```
DEBUG: Submitting workout: [workout_name], exercises: [count]
DEBUG: Sending workout log request: {data}
DEBUG: Workout log response: {response}
```

Or if there's an error:

```
DEBUG: Workout log error: {error}
DEBUG: Status code: {code}
DEBUG: Error submitting workout: {error}
```

### 2. Test Workout Logging

1. Open the app and navigate to "New Workout" screen
2. **IMPORTANT**: Enter a workout name (e.g., "Test Workout")
3. Set duration (e.g., 60 minutes)
4. Add at least one exercise
5. For each exercise, add at least one set with reps and weight
6. Tap "Save Workout"

### 3. Check for Validation Errors

The Save button should be:
- **DISABLED (gray)** if:
  - Workout name is empty
  - Duration is not set or invalid (< 1 or > 600)
  - No exercises added
  - Any set has invalid reps (< 1 or > 100) or weight (< 0.1 or > 1000)

- **ENABLED (red)** if:
  - Workout name is filled
  - Duration is valid (1-600 minutes)
  - At least one exercise with valid sets

### 4. Common Issues and Solutions

#### Issue: Save button is disabled
**Solution**: Check that:
- Workout name field is filled
- Duration is between 1-600 minutes
- At least one exercise is added
- All sets have valid reps and weight values

#### Issue: 400 Bad Request error
**Possible causes**:
1. **Missing workout name**: Make sure you entered a workout name
2. **Invalid exercise data**: Check that all sets have valid reps (1-100) and weight (0.1-1000)
3. **Authentication issue**: Make sure you're logged in

**Check the error details in Flutter console** - it will show the exact validation error from the backend.

#### Issue: 401 Unauthorized error
**Solution**: You need to log in again. The authentication token may have expired.

#### Issue: Network error
**Solution**: 
1. Make sure the backend is running on `http://127.0.0.1:8000`
2. Check that you can access `http://127.0.0.1:8000/api/workouts/exercises/` in your browser
3. Make sure your device/emulator can reach the backend

### 5. Backend Logs

Check the backend logs at `backend/logs/django.log` for the actual request:

```bash
# Look for lines like:
"POST /api/workouts/logs/log_workout/ HTTP/1.1" 201  # Success
"POST /api/workouts/logs/log_workout/ HTTP/1.1" 400  # Validation error
"POST /api/workouts/logs/log_workout/ HTTP/1.1" 401  # Authentication error
```

If you see a 400 error, the line above it should show the validation error details.

## Expected Behavior

When workout logging works correctly:

1. You fill in all required fields (workout name, duration, exercises)
2. Tap "Save Workout"
3. See a loading indicator briefly
4. See a green success message: "Workout logged successfully!"
5. If you achieved a PR, see a congratulations dialog
6. Navigate back to the previous screen
7. The workout appears in your workout history

## Request Format Reference

The frontend sends this format to the backend:

```json
{
  "workout_name": "Push Day",
  "duration_minutes": 60,
  "notes": "Great workout!",  // optional
  "gym_id": 1,  // optional
  "workout_exercises": [
    {
      "exercise": 4,  // Exercise ID (integer)
      "sets": 3,      // Number of sets (integer, 1-100)
      "reps": 10,     // Reps per set (integer, 1-100)
      "weight": 100.0,  // Weight in kg (decimal, 0.1-1000)
      "order": 0      // Exercise order (integer)
    }
  ]
}
```

## Next Steps

If workout logging still doesn't work after following this guide:

1. **Capture the debug logs** from Flutter console when you try to save
2. **Check the backend logs** for the exact error
3. **Share the error messages** so we can identify the specific issue

The code is correct and the backend validates successfully, so any remaining issues are likely:
- User input validation (missing required fields)
- Authentication (expired token)
- Network connectivity
- Backend not running
