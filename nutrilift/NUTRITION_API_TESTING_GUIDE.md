# Nutrition API Testing Guide

Complete guide for testing the nutrition tracking backend API endpoints.

## Prerequisites

1. **Backend Running**:
   ```bash
   cd backend
   python manage.py runserver
   ```

2. **Get JWT Token**:
   ```bash
   # Login to get token
   curl -X POST http://localhost:8000/api/auth/login/ \
     -H "Content-Type: application/json" \
     -d '{"email":"your@email.com","password":"yourpassword"}'
   
   # Save the token from response
   export TOKEN="your_jwt_token_here"
   ```

## API Endpoints Testing

### 1. Food Items API

**List all food items** (system + user's custom foods):
```bash
curl -X GET "http://localhost:8000/api/nutrition/food-items/" \
  -H "Authorization: Bearer $TOKEN"
```

**Search for foods**:
```bash
curl -X GET "http://localhost:8000/api/nutrition/food-items/?search=chicken" \
  -H "Authorization: Bearer $TOKEN"
```

**Create custom food**:
```bash
curl -X POST "http://localhost:8000/api/nutrition/food-items/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Protein Shake",
    "brand": "Homemade",
    "calories_per_100g": "120.00",
    "protein_per_100g": "25.00",
    "carbs_per_100g": "5.00",
    "fats_per_100g": "2.00",
    "fiber_per_100g": "1.00",
    "sugar_per_100g": "3.00"
  }'
```

**Get specific food item**:
```bash
curl -X GET "http://localhost:8000/api/nutrition/food-items/1/" \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Intake Logs API

**Create intake log** (meal/snack/drink):
```bash
curl -X POST "http://localhost:8000/api/nutrition/intake-logs/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "food_item": 1,
    "entry_type": "meal",
    "description": "Lunch",
    "quantity": "200.00",
    "unit": "g",
    "logged_at": "2024-01-15T12:30:00Z"
  }'
```

**List intake logs** (with date filtering):
```bash
# All logs
curl -X GET "http://localhost:8000/api/nutrition/intake-logs/" \
  -H "Authorization: Bearer $TOKEN"

# Filter by date range
curl -X GET "http://localhost:8000/api/nutrition/intake-logs/?date_from=2024-01-01&date_to=2024-01-31" \
  -H "Authorization: Bearer $TOKEN"
```

**Update intake log**:
```bash
curl -X PATCH "http://localhost:8000/api/nutrition/intake-logs/1/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": "250.00",
    "description": "Updated lunch portion"
  }'
```

**Delete intake log**:
```bash
curl -X DELETE "http://localhost:8000/api/nutrition/intake-logs/1/" \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Hydration Logs API

**Create hydration log**:
```bash
curl -X POST "http://localhost:8000/api/nutrition/hydration-logs/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": "500.00",
    "unit": "ml",
    "logged_at": "2024-01-15T10:00:00Z"
  }'
```

**List hydration logs** (with date filtering):
```bash
curl -X GET "http://localhost:8000/api/nutrition/hydration-logs/?date_from=2024-01-15" \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Nutrition Goals API

**Get nutrition goals** (returns defaults if none exist):
```bash
curl -X GET "http://localhost:8000/api/nutrition/nutrition-goals/" \
  -H "Authorization: Bearer $TOKEN"
```

**Create/Update nutrition goals**:
```bash
curl -X POST "http://localhost:8000/api/nutrition/nutrition-goals/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "daily_calories": "2500.00",
    "daily_protein": "180.00",
    "daily_carbs": "250.00",
    "daily_fats": "70.00",
    "daily_water": "3000.00"
  }'
```

### 5. Nutrition Progress API (Read-Only)

**Get daily progress** (automatically calculated):
```bash
# All progress records (paginated, 50 per page)
curl -X GET "http://localhost:8000/api/nutrition/nutrition-progress/" \
  -H "Authorization: Bearer $TOKEN"

# Filter by date range
curl -X GET "http://localhost:8000/api/nutrition/nutrition-progress/?date_from=2024-01-01&date_to=2024-01-31" \
  -H "Authorization: Bearer $TOKEN"

# Get specific date
curl -X GET "http://localhost:8000/api/nutrition/nutrition-progress/1/" \
  -H "Authorization: Bearer $TOKEN"
```

### 6. Quick Logs API (Frequent/Recent Foods)

**Get frequent foods** (ordered by usage count):
```bash
curl -X GET "http://localhost:8000/api/nutrition/quick-logs/frequent/" \
  -H "Authorization: Bearer $TOKEN"
```

**Get recent foods** (ordered by last used):
```bash
curl -X GET "http://localhost:8000/api/nutrition/quick-logs/recent/" \
  -H "Authorization: Bearer $TOKEN"
```

## Testing Signal Handlers

Run the automated signal test script:

```bash
cd backend
python test_nutrition_signals.py
```

This will verify:
- ✓ Intake logs trigger progress updates
- ✓ Multiple logs are aggregated correctly
- ✓ Hydration logs update water totals
- ✓ QuickLog tracks frequent foods
- ✓ Deletions trigger recalculation

## Expected Response Formats

### Successful Response (200/201):
```json
{
  "id": 1,
  "field1": "value1",
  "field2": "value2"
}
```

### Paginated Response:
```json
{
  "count": 100,
  "next": "http://localhost:8000/api/nutrition/endpoint/?page=2",
  "previous": null,
  "results": [...]
}
```

### Error Response (400/401/403/404):
```json
{
  "detail": "Error message here"
}
```

or

```json
{
  "field_name": ["Error message for this field"]
}
```

## Common Issues

### 401 Unauthorized
- Token expired or invalid
- Solution: Get a new token via `/api/auth/login/`

### 403 Forbidden
- Trying to access another user's data
- Solution: Ensure you're accessing your own resources

### 400 Bad Request
- Invalid data format
- Missing required fields
- Solution: Check request body matches expected format

### 404 Not Found
- Resource doesn't exist
- Trying to access another user's resource
- Solution: Verify resource ID and ownership

## Flutter Integration

Update your Flutter app's API service to use these endpoints:

```dart
// Example: Create intake log
Future<void> logMeal(IntakeLog log) async {
  final response = await dio.post(
    '/api/nutrition/intake-logs/',
    data: log.toJson(),
  );
  return response.data;
}

// Example: Get daily progress
Future<NutritionProgress> getDailyProgress(DateTime date) async {
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  final response = await dio.get(
    '/api/nutrition/nutrition-progress/',
    queryParameters: {
      'date_from': dateStr,
      'date_to': dateStr,
    },
  );
  return NutritionProgress.fromJson(response.data['results'][0]);
}
```

## Next Steps

1. ✅ Test all endpoints with cURL
2. ✅ Run signal handler tests
3. ✅ Integrate with Flutter frontend
4. ✅ Test end-to-end flow:
   - Create food item
   - Log meal
   - Verify progress updates automatically
   - Check quick log updates
   - View daily progress

## Support

If you encounter any issues:
1. Check Django logs: `python manage.py runserver` output
2. Verify migrations: `python manage.py migrate`
3. Check test coverage: `pytest backend/nutrition/ -v`
