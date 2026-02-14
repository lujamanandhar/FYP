from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.core.exceptions import ValidationError


class Gym(models.Model):
    """Gym model for storing gym information"""
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=500)
    address = models.TextField(blank=True, null=True)
    rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)],
        default=0.0
    )
    phone = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'gyms'
        ordering = ['-rating', 'name']

    def __str__(self):
        return f"{self.name} - {self.location}"


class Exercise(models.Model):
    """Exercise model for storing exercise information"""
    CATEGORY_CHOICES = [
        ('STRENGTH', 'Strength'),
        ('CARDIO', 'Cardio'),
        ('BODYWEIGHT', 'Bodyweight'),
    ]

    MUSCLE_GROUP_CHOICES = [
        ('CHEST', 'Chest'),
        ('BACK', 'Back'),
        ('LEGS', 'Legs'),
        ('CORE', 'Core'),
        ('ARMS', 'Arms'),
        ('SHOULDERS', 'Shoulders'),
        ('FULL_BODY', 'Full Body'),
    ]

    EQUIPMENT_CHOICES = [
        ('FREE_WEIGHTS', 'Free Weights'),
        ('MACHINES', 'Machines'),
        ('BODYWEIGHT', 'Bodyweight'),
        ('RESISTANCE_BANDS', 'Resistance Bands'),
        ('CARDIO_EQUIPMENT', 'Cardio Equipment'),
    ]

    DIFFICULTY_CHOICES = [
        ('BEGINNER', 'Beginner'),
        ('INTERMEDIATE', 'Intermediate'),
        ('ADVANCED', 'Advanced'),
    ]

    name = models.CharField(max_length=200, unique=True)
    description = models.TextField(default='')
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    muscle_group = models.CharField(max_length=50, choices=MUSCLE_GROUP_CHOICES, default='FULL_BODY')
    equipment = models.CharField(max_length=50, choices=EQUIPMENT_CHOICES, default='BODYWEIGHT')
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, default='BEGINNER')
    instructions = models.TextField(default='')
    image_url = models.URLField(blank=True, null=True)
    video_url = models.URLField(blank=True, null=True)
    calories_per_minute = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=5.0,
        validators=[MinValueValidator(0.0)]
    )
    is_custom = models.BooleanField(default=False)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='created_exercises',
        null=True,
        blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'exercises'
        ordering = ['category', 'name']
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['muscle_group']),
            models.Index(fields=['equipment']),
            models.Index(fields=['difficulty']),
        ]
        constraints = [
            models.UniqueConstraint(
                models.functions.Lower('name'),
                name='unique_exercise_name_case_insensitive'
            )
        ]

    def clean(self):
        """Validate enum fields"""
        super().clean()
        
        # Validate category
        valid_categories = [choice[0] for choice in self.CATEGORY_CHOICES]
        if self.category not in valid_categories:
            raise ValidationError({
                'category': f'Invalid category. Must be one of: {", ".join(valid_categories)}'
            })
        
        # Validate muscle_group
        valid_muscle_groups = [choice[0] for choice in self.MUSCLE_GROUP_CHOICES]
        if self.muscle_group not in valid_muscle_groups:
            raise ValidationError({
                'muscle_group': f'Invalid muscle group. Must be one of: {", ".join(valid_muscle_groups)}'
            })
        
        # Validate equipment
        valid_equipment = [choice[0] for choice in self.EQUIPMENT_CHOICES]
        if self.equipment not in valid_equipment:
            raise ValidationError({
                'equipment': f'Invalid equipment. Must be one of: {", ".join(valid_equipment)}'
            })
        
        # Validate difficulty
        valid_difficulties = [choice[0] for choice in self.DIFFICULTY_CHOICES]
        if self.difficulty not in valid_difficulties:
            raise ValidationError({
                'difficulty': f'Invalid difficulty. Must be one of: {", ".join(valid_difficulties)}'
            })
        
        # Check for case-insensitive name uniqueness
        if self.pk:
            # Updating existing exercise
            existing = Exercise.objects.filter(
                name__iexact=self.name
            ).exclude(pk=self.pk)
        else:
            # Creating new exercise
            existing = Exercise.objects.filter(name__iexact=self.name)
        
        if existing.exists():
            raise ValidationError({
                'name': f'An exercise with the name "{self.name}" already exists (case-insensitive).'
            })

    def __str__(self):
        return f"{self.name} ({self.category})"


class CustomWorkout(models.Model):
    """Custom workout templates created by users"""
    CATEGORY_CHOICES = [
        ('STRENGTH', 'Strength'),
        ('CARDIO', 'Cardio'),
        ('BODYWEIGHT', 'Bodyweight'),
        ('MIXED', 'Mixed'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='custom_workouts'
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    exercises = models.ManyToManyField(Exercise, through='CustomWorkoutExercise')
    estimated_duration = models.IntegerField(
        help_text="Estimated duration in minutes",
        validators=[MinValueValidator(1)]
    )
    is_public = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'custom_workouts'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} by {self.user.email}"


class CustomWorkoutExercise(models.Model):
    """Through model for CustomWorkout and Exercise relationship"""
    custom_workout = models.ForeignKey(CustomWorkout, on_delete=models.CASCADE)
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE)
    order = models.IntegerField(default=0)
    sets = models.IntegerField(validators=[MinValueValidator(1)], default=3)
    reps = models.IntegerField(validators=[MinValueValidator(1)], default=10)
    duration_seconds = models.IntegerField(
        validators=[MinValueValidator(0)], 
        default=0,
        help_text="Duration for time-based exercises"
    )
    rest_seconds = models.IntegerField(
        validators=[MinValueValidator(0)], 
        default=60,
        help_text="Rest time between sets"
    )

    class Meta:
        db_table = 'custom_workout_exercises'
        ordering = ['order']
        unique_together = ['custom_workout', 'exercise', 'order']

    def __str__(self):
        return f"{self.exercise.name} in {self.custom_workout.name}"


class WorkoutLog(models.Model):
    """Workout log for tracking completed workouts"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='workout_logs'
    )
    workout_name = models.CharField(max_length=255)
    custom_workout = models.ForeignKey(
        CustomWorkout, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='logs'
    )
    gym = models.ForeignKey(
        Gym, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='workout_logs'
    )
    duration_minutes = models.IntegerField(validators=[MinValueValidator(1)])
    calories_burned = models.DecimalField(
        max_digits=7, 
        decimal_places=2,
        validators=[MinValueValidator(0.0)]
    )
    notes = models.TextField(blank=True, null=True)
    logged_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'workout_logs'
        ordering = ['-logged_at']
        indexes = [
            models.Index(fields=['user', '-logged_at']),
        ]

    def __str__(self):
        return f"{self.workout_name} - {self.user.email} ({self.logged_at.date()})"


class WorkoutLogExercise(models.Model):
    """Individual exercises within a workout log"""
    workout_log = models.ForeignKey(
        WorkoutLog, 
        on_delete=models.CASCADE, 
        related_name='exercises'
    )
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE)
    order = models.IntegerField(default=0)
    notes = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'workout_log_exercises'
        ordering = ['order']

    def __str__(self):
        return f"{self.exercise.name} in {self.workout_log.workout_name}"


class WorkoutSet(models.Model):
    """Individual sets within a workout log exercise"""
    workout_log_exercise = models.ForeignKey(
        WorkoutLogExercise, 
        on_delete=models.CASCADE, 
        related_name='sets'
    )
    set_number = models.IntegerField(validators=[MinValueValidator(1)])
    reps = models.IntegerField(
        validators=[MinValueValidator(0)], 
        null=True, 
        blank=True
    )
    weight = models.DecimalField(
        max_digits=6, 
        decimal_places=2,
        validators=[MinValueValidator(0.0)],
        null=True,
        blank=True,
        help_text="Weight in kg"
    )
    duration_seconds = models.IntegerField(
        validators=[MinValueValidator(0)],
        null=True,
        blank=True,
        help_text="Duration for time-based exercises"
    )
    completed = models.BooleanField(default=True)

    class Meta:
        db_table = 'workout_sets'
        ordering = ['set_number']
        unique_together = ['workout_log_exercise', 'set_number']

    def __str__(self):
        return f"Set {self.set_number} - {self.workout_log_exercise.exercise.name}"


class PersonalRecord(models.Model):
    """Personal records for tracking user's best performances"""
    RECORD_TYPE_CHOICES = [
        ('MAX_WEIGHT', 'Maximum Weight'),
        ('MAX_REPS', 'Maximum Reps'),
        ('MAX_DURATION', 'Maximum Duration'),
        ('FASTEST_TIME', 'Fastest Time'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='personal_records'
    )
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE)
    record_type = models.CharField(max_length=20, choices=RECORD_TYPE_CHOICES)
    value = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        validators=[MinValueValidator(0.0)]
    )
    unit = models.CharField(
        max_length=20, 
        help_text="kg, reps, seconds, etc."
    )
    workout_log = models.ForeignKey(
        WorkoutLog, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='personal_records'
    )
    achieved_at = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'personal_records'
        ordering = ['-achieved_at']
        indexes = [
            models.Index(fields=['user', 'exercise', 'record_type']),
        ]
        unique_together = ['user', 'exercise', 'record_type']

    def __str__(self):
        return f"{self.user.email} - {self.exercise.name}: {self.value} {self.unit}"
