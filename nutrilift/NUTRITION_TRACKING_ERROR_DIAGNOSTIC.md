# Nutrition Tracking Error Diagnostic

## Error Message
"An unexpected error occurred. Please try again"

## Most Likely Causes

### 1. Backend Not Running ⚠️
The nutrition tracking system needs the Django backend to be running.

**Check if backend is running:**
```bash
# In a separate terminal
cd backend
python manage.py runserver
```

You should see:
```
Starting development server at http://127.0.0.1:8000/
```

### 2. Not Logged In 🔐
The nutrition API requires JWT authentication. You need to be logged in first.

**Steps:**
1. Make sure backend is running
2. In the Flutter app, go to the login screen
3. Log in with your test user credentials
4. Then navigate to the Nutrition tab

### 3. No Nutrition Data Yet 📊
If this is your first time using nutrition tracking, there's no data yet.

**Expected behavior:**
- The page should still load
- You'll see "0/2000" for macros (default goals)
- No meals logged yet
- You can start by clicking "Add Food" to log your first meal

## Debugging Steps

### Step 1: Check Backend Status
```bash
cd backend
python manage.py runserver
```

### Step 2: Check Backend Nutrition Endpoints
Open your browser and go to:
- http://127.0.0.1:8000/api/nutrition/food-items/
- http://127.0.0.1:8000/api/nutrition/nutrition-goals/
- http://127.0.0.1:8000/api/nutrition/nutrition-progress/

You should see the Django REST Framework browsable API.

### Step 3: Check Authentication
1. Log in to the Flutter app
2. Open browser DevTools (F12)
3. Go to Console tab
4. Look for any error messages
5. Check Network tab for failed API requests

### Step 4: Check Browser Console
Open DevTools Console and look for:
- Red error messages
- Failed network requests (status 401, 404, 500)
- CORS errors
- Connection refused errors

## Common Error Patterns

### "Connection refused" or "Network error"
**Cause**: Backend is not running
**Solution**: Start the backend with `python manage.py runserver`

### "401 Unauthorized"
**Cause**: Not logged in or token expired
**Solution**: Log in again through the app

### "404 Not Found"
**Cause**: API endpoint doesn't exist
**Solution**: Check that nutrition URLs are registered in backend/urls.py

### "500 Internal Server Error"
**Cause**: Backend error (database, code bug, etc.)
**Solution**: Check backend terminal for error traceback

## Quick Fix Checklist

- [ ] Backend is running (`python manage.py runserver`)
- [ ] You're logged in to the Flutter app
- [ ] Browser console shows no CORS errors
- [ ] Network tab shows API requests are being made
- [ ] Backend terminal shows no errors

## Testing Without Backend

If you want to test the UI without the backend, you can temporarily use mock data:

1. Open `frontend/lib/providers/repository_providers.dart`
2. Find `useMockDataProvider`
3. Change `return true;` (currently set to true for workout)
4. Create mock nutrition providers similar to workout

However, the nutrition tracking system is designed to work with the real backend, so this is not recommended.

## Next Steps

1. **Start the backend** if it's not running
2. **Log in** to the Flutter app
3. **Check browser console** for specific error messages
4. **Share the error details** if the problem persists:
   - Backend terminal output
   - Browser console errors
   - Network tab failed requests

## Expected First-Time Experience

When you first open nutrition tracking:
1. Loading spinner appears briefly
2. Macro cards show "0/2000" (default goals)
3. No meals are shown (empty state)
4. You can click "Add Food" to log your first meal
5. After logging a meal, progress updates automatically

If you see the error instead, follow the debugging steps above!
