from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator


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
        ('FULL_BODY', 'Full Body'),
        ('ARMS', 'Arms'),
        ('LEGS', 'Legs'),
        ('CORE', 'Core'),
        ('CARDIO', 'Cardio'),
        ('UPPER_BODY', 'Upper Body'),
        ('LOWER_BODY', 'Lower Body'),
    ]

    DIFFICULTY_CHOICES = [
        ('BEGINNER', 'Beginner'),
        ('INTERMEDIATE', 'Intermediate'),
        ('ADVANCED', 'Advanced'),
    ]

    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, default='BEGINNER')
    instructions = models.TextField(blank=True, null=True)
    video_url = models.URLField(blank=True, null=True)
    image_url = models.URLField(blank=True, null=True)
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
            models.Index(fields=['difficulty']),
        ]

    def __str__(self):
        return f"{self.name} ({self.category})"


class CustomWorkout(models.Model):
    """Custom workout templates created by users"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='custom_workouts'
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=20, choices=Exercise.CATEGORY_CHOICES)
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
