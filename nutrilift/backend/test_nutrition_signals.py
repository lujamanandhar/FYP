"""
Quick test script to verify nutrition signal handlers work correctly.

Run this script to test:
1. Creating an intake log triggers progress update
2. Deleting an intake log recalculates progress
3. Creating hydration log updates water totals
4. Quick log tracks frequent foods

Usage:
    python test_nutrition_signals.py
"""

import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from decimal import Decimal
from django.contrib.auth import get_user_model
from django.utils import timezone
from nutrition.models import (
    FoodItem, IntakeLog, HydrationLog, 
    NutritionGoals, NutritionProgress, QuickLog
)

User = get_user_model()

def test_signals():
    print("=" * 60)
    print("Testing Nutrition Signal Handlers")
    print("=" * 60)
    
    # Get or create test user
    user, created = User.objects.get_or_create(
        email='signal_test@example.com',
        defaults={'password': 'testpass123'}
    )
    if created:
        user.set_password('testpass123')
        user.save()
    print(f"\n✓ Using test user: {user.email}")
    
    # Create test food item
    food, _ = FoodItem.objects.get_or_create(
        name='Test Chicken Breast',
        defaults={
            'calories_per_100g': Decimal('165.00'),
            'protein_per_100g': Decimal('31.00'),
            'carbs_per_100g': Decimal('0.00'),
            'fats_per_100g': Decimal('3.60'),
            'is_custom': False
        }
    )
    print(f"✓ Using test food: {food.name}")
    
    # Test 1: Create intake log and verify progress update
    print("\n" + "-" * 60)
    print("TEST 1: Creating intake log should trigger progress update")
    print("-" * 60)
    
    intake = IntakeLog.objects.create(
        user=user,
        food_item=food,
        entry_type='meal',
        quantity=Decimal('200.00'),
        unit='g',
        calories=Decimal('330.00'),
        protein=Decimal('62.00'),
        carbs=Decimal('0.00'),
        fats=Decimal('7.20'),
        logged_at=timezone.now()
    )
    print(f"✓ Created intake log: {intake.quantity}g of {food.name}")
    
    # Check if progress was created
    progress = NutritionProgress.objects.filter(
        user=user,
        progress_date=intake.logged_at.date()
    ).first()
    
    if progress:
        print(f"✓ Progress record created automatically!")
        print(f"  - Total calories: {progress.total_calories}")
        print(f"  - Total protein: {progress.total_protein}")
        print(f"  - Calories adherence: {progress.calories_adherence}%")
    else:
        print("✗ FAILED: Progress record not created")
        return False
    
    # Test 2: Create another intake log and verify aggregation
    print("\n" + "-" * 60)
    print("TEST 2: Creating second intake log should aggregate totals")
    print("-" * 60)
    
    intake2 = IntakeLog.objects.create(
        user=user,
        food_item=food,
        entry_type='snack',
        quantity=Decimal('100.00'),
        unit='g',
        calories=Decimal('165.00'),
        protein=Decimal('31.00'),
        carbs=Decimal('0.00'),
        fats=Decimal('3.60'),
        logged_at=timezone.now()
    )
    print(f"✓ Created second intake log: {intake2.quantity}g of {food.name}")
    
    progress.refresh_from_db()
    expected_calories = Decimal('495.00')  # 330 + 165
    expected_protein = Decimal('93.00')    # 62 + 31
    
    if progress.total_calories == expected_calories:
        print(f"✓ Totals aggregated correctly!")
        print(f"  - Total calories: {progress.total_calories} (expected {expected_calories})")
        print(f"  - Total protein: {progress.total_protein} (expected {expected_protein})")
    else:
        print(f"✗ FAILED: Expected {expected_calories}, got {progress.total_calories}")
        return False
    
    # Test 3: Create hydration log and verify water tracking
    print("\n" + "-" * 60)
    print("TEST 3: Creating hydration log should update water totals")
    print("-" * 60)
    
    hydration = HydrationLog.objects.create(
        user=user,
        amount=Decimal('500.00'),
        unit='ml',
        logged_at=timezone.now()
    )
    print(f"✓ Created hydration log: {hydration.amount}{hydration.unit}")
    
    progress.refresh_from_db()
    if progress.total_water == Decimal('500.00'):
        print(f"✓ Water total updated correctly!")
        print(f"  - Total water: {progress.total_water}ml")
        print(f"  - Water adherence: {progress.water_adherence}%")
    else:
        print(f"✗ FAILED: Expected 500.00, got {progress.total_water}")
        return False
    
    # Test 4: Verify QuickLog tracking
    print("\n" + "-" * 60)
    print("TEST 4: Intake logs should update QuickLog")
    print("-" * 60)
    
    quick_log = QuickLog.objects.filter(user=user).first()
    if quick_log and len(quick_log.frequent_meals) > 0:
        print(f"✓ QuickLog created and updated!")
        print(f"  - Number of tracked foods: {len(quick_log.frequent_meals)}")
        for meal in quick_log.frequent_meals:
            print(f"  - Food ID {meal['food_item_id']}: {meal['usage_count']} uses")
    else:
        print("✗ FAILED: QuickLog not updated")
        return False
    
    # Test 5: Delete intake log and verify recalculation
    print("\n" + "-" * 60)
    print("TEST 5: Deleting intake log should recalculate progress")
    print("-" * 60)
    
    intake2.delete()
    print(f"✓ Deleted second intake log")
    
    progress.refresh_from_db()
    expected_calories_after_delete = Decimal('330.00')  # Only first intake remains
    
    if progress.total_calories == expected_calories_after_delete:
        print(f"✓ Progress recalculated correctly after deletion!")
        print(f"  - Total calories: {progress.total_calories} (expected {expected_calories_after_delete})")
    else:
        print(f"✗ FAILED: Expected {expected_calories_after_delete}, got {progress.total_calories}")
        return False
    
    # Cleanup
    print("\n" + "-" * 60)
    print("Cleaning up test data...")
    print("-" * 60)
    intake.delete()
    hydration.delete()
    progress.delete()
    quick_log.delete() if quick_log else None
    print("✓ Test data cleaned up")
    
    print("\n" + "=" * 60)
    print("ALL TESTS PASSED! ✓")
    print("=" * 60)
    print("\nSignal handlers are working correctly:")
    print("  ✓ Intake logs trigger progress updates")
    print("  ✓ Multiple logs are aggregated correctly")
    print("  ✓ Hydration logs update water totals")
    print("  ✓ QuickLog tracks frequent foods")
    print("  ✓ Deletions trigger recalculation")
    
    return True

if __name__ == '__main__':
    try:
        success = test_signals()
        exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
