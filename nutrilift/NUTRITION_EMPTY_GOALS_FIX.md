# Nutrition Goals Empty List Fix

## Issue Found
From the backend logs, we can see:
```
INFO 2026-03-05 18:35:42,111 basehttp 29104 11856 "GET /api/nutrition/nutrition-goals/ HTTP/1.1" 200 2
```

The `200 2` means HTTP 200 OK with only **2 bytes** of content, which is an empty JSON array `[]`.

## Root Cause
The frontend calls `GET /api/nutrition/nutrition-goals/` (the **list** endpoint), but the backend was only handling default values in the **retrieve** endpoint. When no goals exist in the database, the list endpoint returned an empty array instead of default values.

## Fix Applied
Added a `list()` method override to `NutritionGoalsViewSet` in `backend/nutrition/views.py`:

```python
def list(self, request, *args, **kwargs):
    """
    Override list to return default values if user has no goals.
    Default values: 2000 calories, 150g protein, 200g carbs, 65g fats, 2000ml water
    """
    queryset = self.filter_queryset(self.get_queryset())
    
    if queryset.exists():
        # User has goals, return them normally
        serializer = self.get_serializer(queryset, many=True)
        return Response({'results': serializer.data})
    else:
        # No goals exist, return default values
        default_data = {
            'id': None,
            'user': request.user.id,
            'daily_calories': 2000.00,
            'daily_protein': 150.00,
            'daily_carbs': 200.00,
            'daily_fats': 65.00,
            'daily_water': 2000.00,
            'created_at': None,
            'updated_at': None
        }
        return Response({'results': [default_data]})
```

## Expected Behavior After Fix

**Before:**
```
GET /api/nutrition/nutrition-goals/ → 200 2 (empty array [])
```

**After:**
```
GET /api/nutrition/nutrition-goals/ → 200 ~200 (default goals object)
Response: {
  "results": [{
    "id": null,
    "user": <user_id>,
    "daily_calories": 2000.00,
    "daily_protein": 150.00,
    "daily_carbs": 200.00,
    "daily_fats": 65.00,
    "daily_water": 2000.00,
    "created_at": null,
    "updated_at": null
  }]
}
```

## Testing Instructions

1. **Restart the Django backend** (Ctrl+C, then `python manage.py runserver`)
2. **Refresh the Flutter app** in the browser (or hot restart with 'R')
3. **Navigate to Nutrition Tracking page**
4. **Check backend logs** - should now show larger response size (not just "200 2")
5. **Check frontend** - should display default goals without errors

## What to Look For

**Backend logs should show:**
```
"GET /api/nutrition/nutrition-goals/ HTTP/1.1" 200 <larger_number>
```
The number after 200 should be around 150-200 bytes instead of just 2.

**Frontend should show:**
- No errors in console
- Macro cards displaying: 0/2000 cal, 0/150g protein, etc.
- No "An unexpected error occurred" message
