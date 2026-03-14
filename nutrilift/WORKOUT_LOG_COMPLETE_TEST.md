# Complete Workout Logging Test

## Test the Complete Flow

Follow these exact steps to test workout logging:

### Step 1: Start the Backend

```bash
cd backend
python manage.py runserver
```

Verify it's running by visiting: http://127.0.0.1:8000/api/workouts/exercises/

### Step 2: Start the Flutter App

```bash
cd frontend
flutter run
```

### Step 3: Login

1. Open the app
2. Login with your credentials (e.g., rammanandhar14@gmail.com)
3. Wait for the home screen to load

### Step 4: Navigate to New Workout

1. Tap on "Workout Tracking" tab
2. Tap the "+" button or "New Workout" button

### Step 5: Fill in Workout Details

**CRITICAL - Follow this exact sequence:**

1. **Workout Name** (REQUIRED):
   - Tap the "Workout Name" field
   - Type: "Test Push Day"
   - Verify the text appears in the field

2. **Duration** (REQUIRED):
   - Tap the "Duration (minutes)" field
   - Type: "60"
   - Verify the number appears

3. **Add Exercise** (REQUIRED):
   - Tap "Add Exercise" button
   - Search for "Bench Press" or select any exercise
   - Tap on the exercise to add it

4. **Fill in Sets** (REQUIRED):
   - The exercise should appear with 3 default sets
   - For Set 1:
     - Reps: Should show "10" (default)
     - Weight: Should show "20.0" (default)
   - You can modify these values or leave them as is
   - Make sure at least one set has valid values (reps: 1-100, weight: 0.1-1000)

5. **Notes** (OPTIONAL):
   - You can add notes or leave blank

### Step 6: Verify Save Button State

Before tapping save, check:

- ✅ Save button should be RED (enabled) if:
  - Workout name is filled
  - Duration is filled (1-600)
  - At least one exercise with valid sets

- ❌ Save button should be GRAY (disabled) if:
  - Workout name is empty
  - Duration is empty or invalid
  - No exercises added

### Step 7: Save the Workout

1. Tap the RED "Save Workout" button
2. Watch for:
   - Loading indicator (spinning circle)
   - Success message (green snackbar): "Workout logged successfully!"
   - PR dialog (if you achieved a new personal record)
   - Navigation back to previous screen

### Step 8: Verify in Workout History

1. Go back to Workout Tracking main screen
2. Check "Workout History" section
3. Your "Test Push Day" workout should appear at the top

### Step 9: Check Debug Logs

Open the Flutter console/terminal and look for these messages:

**On Submit:**
```
DEBUG: Submitting workout: Test Push Day, exercises: 1
```

**On Send:**
```
DEBUG: Sending workout log request: {workout_name: Test Push Day, duration_minutes: 60, workout_exercises: [...]}
```

**On Success:**
```
DEBUG: Workout logged successfully: [workout_id]
```

**On Error:**
```
DEBUG: Workout log error: [error details]
DEBUG: Status code: [code]
```

### Step 10: Check Backend Logs

In the backend terminal, you should see:

**Success:**
```
"POST /api/workouts/logs/log_workout/ HTTP/1.1" 201
```

**Error:**
```
"POST /api/workouts/logs/log_workout/ HTTP/1.1" 400  # Validation error
"POST /api/workouts/logs/log_workout/ HTTP/1.1" 401  # Auth error
```

## Common Test Failures and Solutions

### Failure: Save button stays gray

**Cause**: Validation is failing

**Check**:
1. Is workout name filled? (Look at the text field)
2. Is duration filled with a valid number (1-600)?
3. Is at least one exercise added?
4. Do all sets have valid reps (1-100) and weight (0.1-1000)?

**Solution**: Fill in all required fields correctly

### Failure: 400 Bad Request

**Cause**: Backend validation is failing

**Check the Flutter console** for the exact error message. Common causes:
- Workout name is empty (even though UI validation passed)
- Exercise ID is invalid
- Sets/reps/weight are out of range

**Solution**: Check the debug logs for the exact validation error

### Failure: 401 Unauthorized

**Cause**: Not logged in or token expired

**Solution**: 
1. Log out and log back in
2. Check that you see your profile info in the app
3. Try again

### Failure: Network error

**Cause**: Can't reach backend

**Solution**:
1. Verify backend is running: http://127.0.0.1:8000/api/workouts/exercises/
2. Check that the app is using the correct base URL
3. If using an emulator, make sure it can reach localhost

### Failure: No error but workout doesn't save

**Cause**: Silent failure or navigation issue

**Check**:
1. Flutter console for any errors
2. Backend logs for the request
3. Whether the success message appeared briefly

**Solution**: Check all logs and share the output

## Expected Complete Flow

```
User fills form → Taps Save → 
  ↓
Validation passes → 
  ↓
Loading indicator shows → 
  ↓
Request sent to backend → 
  ↓
Backend validates → 
  ↓
Backend saves to database → 
  ↓
Backend returns 201 with workout data → 
  ↓
Success message shows → 
  ↓
PR dialog shows (if applicable) → 
  ↓
Navigate back → 
  ↓
Workout appears in history
```

## If All Else Fails

If you've followed all steps and it still doesn't work:

1. **Capture screenshots** of:
   - The filled workout form
   - The save button state
   - Any error messages

2. **Copy the debug logs** from Flutter console

3. **Copy the backend logs** showing the request

4. **Share all of the above** so we can diagnose the exact issue

The code has been verified to work correctly with the backend, so any remaining issues are likely environmental or user input related.
