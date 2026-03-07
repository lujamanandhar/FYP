# Nutrition Tracking Type Mismatch Fix

## Problem
The nutrition tracking page was showing `TypeError: "results": type 'String' is not a subtype of type 'int'` error when loading, and the backend was returning empty arrays instead of default goals.

## Root Causes

### 1. Type Mismatch
The backend's `NutritionGoalsViewSet.retrieve()` method was returning decimal values as **strings** (e.g., `'2000.00'`) instead of numbers when no goals existed. The Flutter frontend expected numeric values and failed when trying to cast strings as `num`.

### 2. Empty List Response
The backend's `list()` endpoint was returning an empty array `[]` when no goals existed, instead of returning default values. The frontend was calling the list endpoint, not the retrieve endpoint.

## Solution Applied

### 1. Backend Fix - Default Values (backend/nutrition/views.py)

**Added `list()` method override** to return default values when no goals exist:
```python
def list(self, request, *args, **kwargs):
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

**Fixed `retrieve()` method** to return numeric values instead of strings:
```python
# Before:
'daily_calories': '2000.00',
'daily_protein': '150.00',
# ...

# After:
'daily_calories': 2000.00,
'daily_protein': 150.00,
# ...
```

### 2. Frontend Robust Parsing (All Models)
Added a `_parseDouble()` helper method to all nutrition models to handle both string and numeric inputs gracefully:

**Files Updated:**
- `frontend/lib/NutritionTracking/models/nutrition_goals.dart`
- `frontend/lib/NutritionTracking/models/intake_log.dart`
- `frontend/lib/NutritionTracking/models/food_item.dart`
- `frontend/lib/NutritionTracking/models/nutrition_progress.dart`
- `frontend/lib/NutritionTracking/models/hydration_log.dart`

**Helper Method:**
```dart
static double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
```

This ensures the frontend can handle:
- Numeric values (expected case)
- String values (edge case from serialization)
- Null values (fallback to 0.0)

### 3. Debug Logging Cleanup
Removed all debug print statements from:
- `frontend/lib/NutritionTracking/services/nutrition_api_service.dart`
- `frontend/lib/NutritionTracking/repositories/nutrition_repository.dart`
- `frontend/lib/NutritionTracking/providers/nutrition_providers.dart`

## Testing Instructions

1. **Restart the Flutter app completely** (hot reload won't pick up all changes)
2. **Navigate to Nutrition Tracking page**
3. **Expected behavior:**
   - Page loads without errors
   - Default goals are displayed (2000 cal, 150g protein, etc.)
   - No type errors in console
   - All macro cards show correct values

## Next Steps

After verifying the fix works:
1. Complete Task 16 (Flutter integration tests) from the spec
2. Test all CRUD operations (create goals, log meals, etc.)
3. Verify data persists across app restarts

## Files Modified

**Backend:**
- `backend/nutrition/views.py` - Fixed default values to return numbers

**Frontend Models:**
- `frontend/lib/NutritionTracking/models/nutrition_goals.dart`
- `frontend/lib/NutritionTracking/models/intake_log.dart`
- `frontend/lib/NutritionTracking/models/food_item.dart`
- `frontend/lib/NutritionTracking/models/nutrition_progress.dart`
- `frontend/lib/NutritionTracking/models/hydration_log.dart`

**Frontend Services:**
- `frontend/lib/NutritionTracking/services/nutrition_api_service.dart`
- `frontend/lib/NutritionTracking/repositories/nutrition_repository.dart`
- `frontend/lib/NutritionTracking/providers/nutrition_providers.dart`

## Verification Status
✅ All files compile successfully (no diagnostics errors)
⏳ Awaiting runtime testing by user
