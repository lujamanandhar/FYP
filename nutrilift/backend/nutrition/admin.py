from django.contrib import admin
from .models import (
    FoodItem, IntakeLog, HydrationLog, 
    NutritionGoals, NutritionProgress, QuickLog
)


@admin.register(FoodItem)
class FoodItemAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'brand', 'calories_per_100g', 'protein_per_100g', 
        'carbs_per_100g', 'fats_per_100g', 'is_custom', 'created_by', 'created_at'
    ]
    list_filter = ['is_custom', 'created_at']
    search_fields = ['name', 'brand', 'created_by__email']
    ordering = ['name']
    readonly_fields = ['created_at', 'updated_at']
    actions = ['mark_as_system', 'mark_as_custom']
    
    @admin.action(description='Mark selected foods as system foods')
    def mark_as_system(self, request, queryset):
        updated = queryset.update(is_custom=False, created_by=None)
        self.message_user(request, f'{updated} food(s) marked as system foods.')
    
    @admin.action(description='Mark selected foods as custom foods')
    def mark_as_custom(self, request, queryset):
        updated = queryset.update(is_custom=True)
        self.message_user(request, f'{updated} food(s) marked as custom foods.')


@admin.register(IntakeLog)
class IntakeLogAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'food_item', 'entry_type', 'quantity', 'unit',
        'calories', 'protein', 'carbs', 'fats', 'logged_at'
    ]
    list_filter = ['entry_type', 'logged_at', 'created_at']
    search_fields = ['user__email', 'food_item__name', 'description']
    ordering = ['-logged_at']
    readonly_fields = ['calories', 'protein', 'carbs', 'fats', 'created_at', 'updated_at']


@admin.register(HydrationLog)
class HydrationLogAdmin(admin.ModelAdmin):
    list_display = ['user', 'amount', 'unit', 'logged_at', 'created_at']
    list_filter = ['logged_at', 'created_at']
    search_fields = ['user__email']
    ordering = ['-logged_at']
    readonly_fields = ['created_at']


@admin.register(NutritionGoals)
class NutritionGoalsAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'daily_calories', 'daily_protein', 'daily_carbs', 
        'daily_fats', 'daily_water', 'updated_at'
    ]
    search_fields = ['user__email']
    ordering = ['user']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(NutritionProgress)
class NutritionProgressAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'progress_date', 'total_calories', 'total_protein', 
        'total_carbs', 'total_fats', 'total_water',
        'calories_adherence', 'protein_adherence', 'updated_at'
    ]
    list_filter = ['progress_date']
    search_fields = ['user__email']
    ordering = ['-progress_date']
    readonly_fields = ['updated_at']


@admin.register(QuickLog)
class QuickLogAdmin(admin.ModelAdmin):
    list_display = ['user', 'updated_at']
    search_fields = ['user__email']
    ordering = ['user']
    readonly_fields = ['updated_at']
