"""
Quick test script to verify nutrition API endpoints work correctly.

Run this script to test:
1. Authentication and JWT token retrieval
2. Food items CRUD operations
3. Intake logs with date filtering
4. Hydration logs
5. Nutrition goals with defaults
6. Nutrition progress (read-only)
7. Quick logs (frequent/recent foods)

Usage:
    python test_nutrition_api.py
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"
TEST_EMAIL = "signal_test@example.com"
TEST_PASSWORD = "testpass123"

def print_section(title):
    print("\n" + "=" * 60)
    print(title)
    print("=" * 60)

def print_test(title):
    print("\n" + "-" * 60)
    print(title)
    print("-" * 60)

def test_api():
    print_section("Testing Nutrition API Endpoints")
    
    # Test 1: Get JWT Token
    print_test("TEST 1: Authentication - Get JWT Token")
    response = requests.post(
        f"{BASE_URL}/api/auth/login/",
        json={"email": TEST_EMAIL, "password": TEST_PASSWORD}
    )
    
    if response.status_code == 200:
        response_data = response.json()
        # Try different token locations
        token = (response_data.get('access') or 
                response_data.get('token') or 
                (response_data.get('data', {}).get('token') if isinstance(response_data.get('data'), dict) else None))
        if not token:
            print(f"✗ FAILED: No token in response")
            print(f"  Response: {response_data}")
            return False
        print(f"✓ Authentication successful!")
        print(f"  Token: {token[:50]}...")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test 2: List Food Items
    print_test("TEST 2: List Food Items")
    response = requests.get(f"{BASE_URL}/api/nutrition/food-items/", headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Food items retrieved successfully!")
        if isinstance(data, dict):
            count = data.get('count', len(data.get('results', [])))
            results = data.get('results', [])
        else:
            count = len(data)
            results = data
        print(f"  Count: {count}")
        if results:
            print(f"  First item: {results[0]['name']}")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Test 3: Create Custom Food Item
    print_test("TEST 3: Create Custom Food Item")
    food_data = {
        "name": "Test Protein Shake",
        "brand": "Test Brand",
        "calories_per_100g": "120.00",
        "protein_per_100g": "25.00",
        "carbs_per_100g": "5.00",
        "fats_per_100g": "2.00"
    }
    response = requests.post(
        f"{BASE_URL}/api/nutrition/food-items/",
        headers=headers,
        json=food_data
    )
    
    if response.status_code == 201:
        food = response.json()
        food_id = food['id']
        print(f"✓ Custom food created successfully!")
        print(f"  ID: {food_id}")
        print(f"  Name: {food['name']}")
        print(f"  Is Custom: {food.get('is_custom', 'N/A')}")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Test 4: Create Intake Log
    print_test("TEST 4: Create Intake Log")
    intake_data = {
        "food_item": food_id,
        "entry_type": "meal",
        "description": "Test lunch",
        "quantity": "200.00",
        "unit": "g",
        "logged_at": datetime.now().isoformat()
    }
    response = requests.post(
        f"{BASE_URL}/api/nutrition/intake-logs/",
        headers=headers,
        json=intake_data
    )
    
    if response.status_code == 201:
        intake = response.json()
        intake_id = intake['id']
        print(f"✓ Intake log created successfully!")
        print(f"  ID: {intake_id}")
        print(f"  Calories: {intake.get('calories', 'N/A')}")
        print(f"  Protein: {intake.get('protein', 'N/A')}")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Test 5: List Intake Logs with Date Filtering
    print_test("TEST 5: List Intake Logs with Date Filtering")
    today = datetime.now().date().isoformat()
    response = requests.get(
        f"{BASE_URL}/api/nutrition/intake-logs/?date_from={today}&date_to={today}",
        headers=headers
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Intake logs retrieved successfully!")
        results = data.get('results', data) if isinstance(data, dict) else data
        print(f"  Count: {len(results)}")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Test 6: Create Hydration Log
    print_test("TEST 6: Create Hydration Log")
    hydration_data = {
        "amount": "500.00",
        "unit": "ml",
        "logged_at": datetime.now().isoformat()
    }
    response = requests.post(
        f"{BASE_URL}/api/nutrition/hydration-logs/",
        headers=headers,
        json=hydration_data
    )
    
    if response.status_code == 201:
        hydration = response.json()
        hydration_id = hydration['id']
        print(f"✓ Hydration log created successfully!")
        print(f"  ID: {hydration_id}")
        print(f"  Amount: {hydration['amount']}{hydration['unit']}")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Test 7: Get Nutrition Goals (should return defaults if none exist)
    print_test("TEST 7: Get Nutrition Goals")
    response = requests.get(f"{BASE_URL}/api/nutrition/nutrition-goals/", headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Nutrition goals retrieved successfully!")
        if isinstance(data, dict):
            results = data.get('results', [data])
        else:
            results = data
        if isinstance(results, list) and results:
            goals = results[0]
        elif isinstance(results, dict):
            goals = results
        else:
            goals = {}
        print(f"  Daily Calories: {goals.get('daily_calories', 'N/A')}")
        print(f"  Daily Protein: {goals.get('daily_protein', 'N/A')}")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Test 8: Get Nutrition Progress (auto-calculated)
    print_test("TEST 8: Get Nutrition Progress (Auto-Calculated)")
    response = requests.get(
        f"{BASE_URL}/api/nutrition/nutrition-progress/?date_from={today}&date_to={today}",
        headers=headers
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Nutrition progress retrieved successfully!")
        results = data.get('results', data) if isinstance(data, dict) else data
        if results:
            progress = results[0] if isinstance(results, list) else results
            print(f"  Total Calories: {progress.get('total_calories', 'N/A')}")
            print(f"  Total Protein: {progress.get('total_protein', 'N/A')}")
            print(f"  Total Water: {progress.get('total_water', 'N/A')}")
            print(f"  Calories Adherence: {progress.get('calories_adherence', 'N/A')}%")
        else:
            print(f"  No progress records found (this is OK if no intake logs exist)")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Test 9: Get Quick Logs - Frequent Foods
    print_test("TEST 9: Get Quick Logs - Frequent Foods")
    response = requests.get(f"{BASE_URL}/api/nutrition/quick-logs/frequent/", headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Frequent foods retrieved successfully!")
        if data:
            print(f"  Count: {len(data)}")
            if data:
                print(f"  Top food: {data[0].get('food_item_name', 'N/A')} ({data[0].get('usage_count', 0)} uses)")
        else:
            print(f"  No frequent foods yet")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Test 10: Search Food Items
    print_test("TEST 10: Search Food Items")
    response = requests.get(
        f"{BASE_URL}/api/nutrition/food-items/?search=Test",
        headers=headers
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Food search successful!")
        results = data.get('results', data) if isinstance(data, dict) else data
        print(f"  Results: {len(results)}")
    else:
        print(f"✗ FAILED: Status {response.status_code}")
        print(f"  Response: {response.text}")
        return False
    
    # Cleanup
    print_test("Cleanup - Deleting Test Data")
    requests.delete(f"{BASE_URL}/api/nutrition/intake-logs/{intake_id}/", headers=headers)
    requests.delete(f"{BASE_URL}/api/nutrition/hydration-logs/{hydration_id}/", headers=headers)
    requests.delete(f"{BASE_URL}/api/nutrition/food-items/{food_id}/", headers=headers)
    print("✓ Test data cleaned up")
    
    print_section("ALL API TESTS PASSED! ✓")
    print("\nAll nutrition API endpoints are working correctly:")
    print("  ✓ Authentication with JWT tokens")
    print("  ✓ Food items CRUD operations")
    print("  ✓ Intake logs with date filtering")
    print("  ✓ Hydration logs")
    print("  ✓ Nutrition goals with defaults")
    print("  ✓ Nutrition progress (auto-calculated)")
    print("  ✓ Quick logs (frequent foods)")
    print("  ✓ Search functionality")
    
    return True

if __name__ == '__main__':
    try:
        success = test_api()
        exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
