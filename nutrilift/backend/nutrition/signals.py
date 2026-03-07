"""
Signal handlers for automatic nutrition progress updates.

This module implements Django signals that automatically update NutritionProgress
records when IntakeLog or HydrationLog entries are created, updated, or deleted.

Requirements: 3.1-3.8, 14.7
"""

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db.models import Sum
from decimal import Decimal


@receiver(post_save, sender='nutrition.IntakeLog')
def update_nutrition_progress_on_save(sender, instance, created, **kwargs):
    """
    Update NutritionProgress when IntakeLog is created or updated.
    
    This signal handler:
    1. Aggregates all IntakeLog entries for the date using Sum
    2. Retrieves or creates NutritionGoals with defaults
    3. Calculates adherence percentages using formula: (actual ÷ target) × 100
    4. Updates or creates NutritionProgress record
    
    Requirements: 3.1-3.8, 14.7
    """
    from .models import IntakeLog, HydrationLog, NutritionGoals, NutritionProgress
    
    user = instance.user
    date = instance.logged_at.date()
    
    # Aggregate all intake logs for this date
    daily_totals = IntakeLog.objects.filter(
        user=user,
        logged_at__date=date
    ).aggregate(
        total_calories=Sum('calories'),
        total_protein=Sum('protein'),
        total_carbs=Sum('carbs'),
        total_fats=Sum('fats')
    )
    
    # Aggregate hydration for this date
    daily_water = HydrationLog.objects.filter(
        user=user,
        logged_at__date=date
    ).aggregate(total_water=Sum('amount'))['total_water'] or Decimal('0.0')
    
    # Get user's goals or use defaults
    try:
        goals = user.nutrition_goals
    except NutritionGoals.DoesNotExist:
        # Use default goals (Requirements 5.7)
        goals = NutritionGoals(
            daily_calories=Decimal('2000'),
            daily_protein=Decimal('150'),
            daily_carbs=Decimal('200'),
            daily_fats=Decimal('65'),
            daily_water=Decimal('2000')
        )
    
    # Calculate adherence percentages: (actual ÷ target) × 100
    def calc_adherence(actual, target):
        """Calculate adherence percentage with zero-division protection."""
        if target == 0:
            return Decimal('0.0')
        return (actual / target) * Decimal('100')
    
    # Extract totals with default to 0.0
    total_calories = daily_totals['total_calories'] or Decimal('0.0')
    total_protein = daily_totals['total_protein'] or Decimal('0.0')
    total_carbs = daily_totals['total_carbs'] or Decimal('0.0')
    total_fats = daily_totals['total_fats'] or Decimal('0.0')
    
    # Update or create progress record
    progress, _ = NutritionProgress.objects.update_or_create(
        user=user,
        progress_date=date,
        defaults={
            'total_calories': total_calories,
            'total_protein': total_protein,
            'total_carbs': total_carbs,
            'total_fats': total_fats,
            'total_water': daily_water,
            'calories_adherence': calc_adherence(total_calories, goals.daily_calories),
            'protein_adherence': calc_adherence(total_protein, goals.daily_protein),
            'carbs_adherence': calc_adherence(total_carbs, goals.daily_carbs),
            'fats_adherence': calc_adherence(total_fats, goals.daily_fats),
            'water_adherence': calc_adherence(daily_water, goals.daily_water),
        }
    )


@receiver(post_delete, sender='nutrition.IntakeLog')
def update_nutrition_progress_on_delete(sender, instance, **kwargs):
    """
    Recalculate NutritionProgress when IntakeLog is deleted.
    
    This handler triggers the same aggregation logic as the save handler
    to ensure progress is accurate after deletions.
    
    Requirements: 3.10, 3.11
    """
    # Trigger the same update logic
    update_nutrition_progress_on_save(sender, instance, created=False, **kwargs)


@receiver(post_save, sender='nutrition.HydrationLog')
def update_hydration_progress(sender, instance, created, **kwargs):
    """
    Update water totals in NutritionProgress when HydrationLog is saved.
    
    This handler aggregates all hydration logs for the date and updates
    the total_water and water_adherence fields in NutritionProgress.
    
    Requirements: 4.4, 4.6
    """
    from .models import HydrationLog, NutritionGoals, NutritionProgress
    
    user = instance.user
    date = instance.logged_at.date()
    
    # Aggregate all hydration logs for this date
    daily_water = HydrationLog.objects.filter(
        user=user,
        logged_at__date=date
    ).aggregate(total_water=Sum('amount'))['total_water'] or Decimal('0.0')
    
    # Get user's goals or use defaults
    try:
        goals = user.nutrition_goals
    except NutritionGoals.DoesNotExist:
        goals = NutritionGoals(daily_water=Decimal('2000'))
    
    # Get or create progress record
    progress, _ = NutritionProgress.objects.get_or_create(
        user=user,
        progress_date=date
    )
    
    # Update water fields
    progress.total_water = daily_water
    progress.water_adherence = (
        (daily_water / goals.daily_water) * Decimal('100')
        if goals.daily_water > 0
        else Decimal('0.0')
    )
    progress.save()


@receiver(post_delete, sender='nutrition.HydrationLog')
def update_hydration_progress_on_delete(sender, instance, **kwargs):
    """
    Recalculate water totals when HydrationLog is deleted.
    
    Requirements: 4.4, 4.6
    """
    # Trigger the same update logic
    update_hydration_progress(sender, instance, created=False, **kwargs)


@receiver(post_save, sender='nutrition.IntakeLog')
def update_quick_log(sender, instance, created, **kwargs):
    """
    Update QuickLog when IntakeLog is saved.
    
    This handler:
    1. Gets or creates the user's QuickLog
    2. Increments usage_count for the food_item_id
    3. Updates last_used timestamp
    4. Limits frequent_meals to top 20 items by usage_count
    
    Requirements: 6.2, 6.3, 6.6
    """
    from .models import QuickLog
    from django.utils import timezone
    
    user = instance.user
    food_item_id = instance.food_item.id
    
    # Get or create QuickLog for user
    quick_log, _ = QuickLog.objects.get_or_create(user=user)
    
    # Get current frequent_meals list
    frequent_meals = quick_log.frequent_meals
    
    # Find existing entry for this food_item_id
    existing_entry = None
    for entry in frequent_meals:
        if entry.get('food_item_id') == food_item_id:
            existing_entry = entry
            break
    
    # Update or create entry
    if existing_entry:
        # Increment usage count and update timestamp
        existing_entry['usage_count'] = existing_entry.get('usage_count', 0) + 1
        existing_entry['last_used'] = timezone.now().isoformat()
    else:
        # Add new entry
        frequent_meals.append({
            'food_item_id': food_item_id,
            'usage_count': 1,
            'last_used': timezone.now().isoformat()
        })
    
    # Sort by usage_count descending and limit to top 20
    frequent_meals.sort(key=lambda x: x.get('usage_count', 0), reverse=True)
    frequent_meals = frequent_meals[:20]
    
    # Save updated frequent_meals
    quick_log.frequent_meals = frequent_meals
    quick_log.save()
