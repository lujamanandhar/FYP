from django.contrib import admin
from .models import (
    Gym, Exercise, CustomWorkout, CustomWorkoutExercise,
    WorkoutLog, WorkoutLogExercise, WorkoutSet, PersonalRecord
)


@admin.register(Gym)
class GymAdmin(admin.ModelAdmin):
    list_display = ['name', 'location', 'rating', 'phone', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['name', 'location', 'address']
    ordering = ['-rating', 'name']


@admin.register(Exercise)
class ExerciseAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'difficulty', 'calories_per_minute', 'is_custom', 'created_at']
    list_filter = ['category', 'difficulty', 'is_custom']
    search_fields = ['name', 'description']
    ordering = ['category', 'name']


class CustomWorkoutExerciseInline(admin.TabularInline):
    model = CustomWorkoutExercise
    extra = 1
    fields = ['exercise', 'order', 'sets', 'reps', 'duration_seconds', 'rest_seconds']


@admin.register(CustomWorkout)
class CustomWorkoutAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'category', 'estimated_duration', 'is_public', 'created_at']
    list_filter = ['category', 'is_public', 'created_at']
    search_fields = ['name', 'description', 'user__email']
    inlines = [CustomWorkoutExerciseInline]
    ordering = ['-created_at']


class WorkoutSetInline(admin.TabularInline):
    model = WorkoutSet
    extra = 1
    fields = ['set_number', 'reps', 'weight', 'duration_seconds', 'completed']


class WorkoutLogExerciseInline(admin.TabularInline):
    model = WorkoutLogExercise
    extra = 1
    fields = ['exercise', 'order', 'notes']


@admin.register(WorkoutLog)
class WorkoutLogAdmin(admin.ModelAdmin):
    list_display = ['workout_name', 'user', 'duration_minutes', 'calories_burned', 'gym', 'logged_at']
    list_filter = ['logged_at', 'gym']
    search_fields = ['workout_name', 'user__email', 'notes']
    inlines = [WorkoutLogExerciseInline]
    ordering = ['-logged_at']


@admin.register(PersonalRecord)
class PersonalRecordAdmin(admin.ModelAdmin):
    list_display = ['user', 'exercise', 'record_type', 'value', 'unit', 'achieved_at']
    list_filter = ['record_type', 'achieved_at']
    search_fields = ['user__email', 'exercise__name', 'notes']
    ordering = ['-achieved_at']
