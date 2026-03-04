from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator
from django.utils import timezone


class FoodItem(models.Model):
    """
    Stores nutritional information per 100g for both system and custom foods.
    
    Requirements: 1.1, 1.2, 1.4, 1.5
    """
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, blank=True, null=True)
    
    # Nutritional values per 100g
    calories_per_100g = models.DecimalField(
        max_digits=7, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)]
    )
    protein_per_100g = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)]
    )
    carbs_per_100g = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)]
    )
    fats_per_100g = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)]
    )
    fiber_per_100g = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)], 
        default=0.0
    )
    sugar_per_100g = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)], 
        default=0.0
    )
    
    # Custom food tracking
    is_custom = models.BooleanField(default=False, db_index=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='custom_foods'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'food_items'
        ordering = ['name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['is_custom', 'created_by']),
        ]
    
    def __str__(self):
        brand_info = f" ({self.brand})" if self.brand else ""
        return f"{self.name}{brand_info}"


class IntakeLog(models.Model):
    """
    Records individual meal/snack/drink entries with calculated macros.
    
    Requirements: 2.1, 2.6, 2.7, 2.8, 12.7, 12.8, 12.9
    """
    ENTRY_TYPE_CHOICES = [
        ('meal', 'Meal'),
        ('snack', 'Snack'),
        ('drink', 'Drink'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='intake_logs'
    )
    food_item = models.ForeignKey(
        FoodItem, 
        on_delete=models.CASCADE, 
        related_name='intake_logs'
    )
    
    entry_type = models.CharField(max_length=10, choices=ENTRY_TYPE_CHOICES)
    description = models.CharField(max_length=500, blank=True, null=True)
    quantity = models.DecimalField(
        max_digits=8, 
        decimal_places=2, 
        validators=[MinValueValidator(0.01)]
    )
    unit = models.CharField(max_length=20)  # g, ml, oz, cup, etc.
    
    # Calculated macros (stored for performance)
    calories = models.DecimalField(max_digits=7, decimal_places=2)
    protein = models.DecimalField(max_digits=6, decimal_places=2)
    carbs = models.DecimalField(max_digits=6, decimal_places=2)
    fats = models.DecimalField(max_digits=6, decimal_places=2)
    
    logged_at = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'intake_logs'
        ordering = ['-logged_at']
        indexes = [
            models.Index(fields=['user', '-logged_at']),
            models.Index(fields=['user', 'logged_at']),  # For date range queries
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.food_item.name} ({self.entry_type}) at {self.logged_at}"


class HydrationLog(models.Model):
    """
    Tracks water intake throughout the day.
    
    Requirements: 4.1
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='hydration_logs'
    )
    amount = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.01)]
    )
    unit = models.CharField(max_length=10, default='ml')  # ml, oz, cup
    
    logged_at = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'hydration_logs'
        ordering = ['-logged_at']
        indexes = [
            models.Index(fields=['user', '-logged_at']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.amount}{self.unit} at {self.logged_at}"


class NutritionGoals(models.Model):
    """
    Stores daily nutrition targets per user (one record per user).
    
    Requirements: 5.1, 5.2, 12.10
    """
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='nutrition_goals'
    )
    
    daily_calories = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)], 
        default=2000
    )
    daily_protein = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)], 
        default=150
    )
    daily_carbs = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)], 
        default=200
    )
    daily_fats = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)], 
        default=65
    )
    daily_water = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0)], 
        default=2000
    )  # ml
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'nutrition_goals'
        indexes = [
            models.Index(fields=['user']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - Goals: {self.daily_calories}cal, {self.daily_protein}g protein"


class NutritionProgress(models.Model):
    """
    Pre-aggregated daily totals and adherence percentages.
    
    Requirements: 3.8, 12.8, 12.9
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='nutrition_progress'
    )
    progress_date = models.DateField()
    
    # Aggregated totals
    total_calories = models.DecimalField(
        max_digits=7, 
        decimal_places=2, 
        default=0.0
    )
    total_protein = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        default=0.0
    )
    total_carbs = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        default=0.0
    )
    total_fats = models.DecimalField(
        max_digits=6, 
        decimal_places=2, 
        default=0.0
    )
    total_water = models.DecimalField(
        max_digits=7, 
        decimal_places=2, 
        default=0.0
    )
    
    # Adherence percentages
    calories_adherence = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0.0
    )
    protein_adherence = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0.0
    )
    carbs_adherence = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0.0
    )
    fats_adherence = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0.0
    )
    water_adherence = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0.0
    )
    
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'nutrition_progress'
        ordering = ['-progress_date']
        unique_together = ['user', 'progress_date']
        indexes = [
            models.Index(fields=['user', '-progress_date']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.progress_date}: {self.total_calories}cal"


class QuickLog(models.Model):
    """
    Maintains frequent meals for quick access (JSON field for flexibility).
    
    Requirements: 6.1
    """
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='quick_log'
    )
    
    # JSON structure: [{"food_item_id": 123, "usage_count": 45, "last_used": "2024-01-15T10:30:00Z"}, ...]
    frequent_meals = models.JSONField(default=list)
    
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'quick_logs'
    
    def __str__(self):
        return f"{self.user.email} - {len(self.frequent_meals)} frequent meals"
