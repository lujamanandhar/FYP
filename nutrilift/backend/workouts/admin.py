from django.contrib import admin
from .models import (
    Gym, Exercise, CustomWorkout, CustomWorkoutExercise,
    WorkoutLog, WorkoutLogExercise, WorkoutSet, PersonalRecord
)
from .rep_counting_models import RepSession, RepEvent


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
    list_display = ['user', 'exercise', 'max_weight', 'max_reps', 'max_volume', 'achieved_date']
    list_filter = ['achieved_date']
    search_fields = ['user__email', 'exercise__name']
    ordering = ['-achieved_date']



class RepEventInline(admin.TabularInline):
    model = RepEvent
    extra = 0
    fields = ['rep_number', 'timestamp', 'confidence', 'angle_data']
    readonly_fields = ['timestamp']


@admin.register(RepSession)
class RepSessionAdmin(admin.ModelAdmin):
    list_display = ['user', 'exercise_type', 'total_reps', 'confidence_avg', 'is_converted', 'start_time', 'end_time']
    list_filter = ['exercise_type', 'is_converted', 'start_time']
    search_fields = ['user__email', 'exercise_type']
    inlines = [RepEventInline]
    ordering = ['-start_time']
    readonly_fields = ['start_time', 'created_at', 'updated_at']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'exercise', 'workout_log')


@admin.register(RepEvent)
class RepEventAdmin(admin.ModelAdmin):
    list_display = ['session', 'rep_number', 'confidence', 'timestamp']
    list_filter = ['timestamp']
    search_fields = ['session__user__email']
    ordering = ['session', 'rep_number']
    readonly_fields = ['timestamp']
