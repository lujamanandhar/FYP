from decimal import Decimal
from django.contrib.auth import get_user_model
from rest_framework import serializers
from .models import (
    Gym, Exercise, CustomWorkout, CustomWorkoutExercise,
    WorkoutLog, WorkoutExercise, WorkoutLogExercise, WorkoutSet, PersonalRecord
)

User = get_user_model()


class GymSerializer(serializers.ModelSerializer):
    class Meta:
        model = Gym
        fields = ['id', 'name', 'location', 'address', 'rating', 'phone', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = [
            'id', 'name', 'description', 'category', 'muscle_group', 'equipment', 'difficulty',
            'instructions', 'video_url', 'image_url', 'calories_per_minute',
            'is_custom', 'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']


class WorkoutExerciseSerializer(serializers.ModelSerializer):
    """Serializer for WorkoutExercise model with calculated volume"""
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)
    volume = serializers.SerializerMethodField()

    class Meta:
        model = WorkoutExercise
        fields = ['id', 'exercise', 'exercise_name', 'sets', 'reps', 'weight', 'volume', 'order']
        read_only_fields = ['id', 'volume']

    def get_volume(self, obj):
        """Calculate and return the volume for this exercise"""
        return obj.calculate_volume()


class WorkoutSetSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkoutSet
        fields = ['id', 'set_number', 'reps', 'weight', 'duration_seconds', 'completed']
        read_only_fields = ['id']


class WorkoutLogExerciseSerializer(serializers.ModelSerializer):
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)
    exercise_id = serializers.PrimaryKeyRelatedField(
        source='exercise',
        queryset=Exercise.objects.all(),
        write_only=True
    )
    sets = WorkoutSetSerializer(many=True)

    class Meta:
        model = WorkoutLogExercise
        fields = ['id', 'exercise_id', 'exercise_name', 'order', 'sets', 'notes']
        read_only_fields = ['id']


class WorkoutLogSerializer(serializers.ModelSerializer):
    """Enhanced WorkoutLog serializer with nested exercises and PR detection"""
    workout_exercises = WorkoutExerciseSerializer(many=True)
    gym_name = serializers.CharField(source='gym.name', read_only=True)
    workout_name_display = serializers.CharField(source='custom_workout.name', read_only=True)
    has_new_prs = serializers.SerializerMethodField()
    
    # Keep backward compatibility with existing 'exercises' field
    exercises = WorkoutLogExerciseSerializer(many=True, required=False)
    gym = GymSerializer(read_only=True)
    gym_id = serializers.PrimaryKeyRelatedField(
        source='gym',
        queryset=Gym.objects.all(),
        write_only=True,
        required=False,
        allow_null=True
    )
    
    # Add user as PrimaryKeyRelatedField to handle UUID properly
    user = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        required=False  # Can be set from context in views
    )

    class Meta:
        model = WorkoutLog
        fields = [
            'id', 'user', 'workout_name', 'custom_workout', 'workout_name_display',
            'gym', 'gym_id', 'gym_name',
            'duration_minutes', 'calories_burned', 
            'workout_exercises', 'exercises', 'notes',
            'has_new_prs', 'logged_at', 'updated_at'
        ]
        read_only_fields = ['id', 'calories_burned', 'has_new_prs', 'logged_at', 'updated_at']

    def get_has_new_prs(self, obj):
        """Check if any exercises in this workout resulted in new PRs"""
        return PersonalRecord.objects.filter(
            user=obj.user,
            workout_log=obj,
            achieved_date=obj.logged_at
        ).exists()

    def calculate_calories(self, workout_log, exercises_data):
        """
        Calculate calories burned based on exercises and duration.
        Formula: Sum of (exercise.calories_per_minute * duration_minutes * intensity_factor)
        Intensity factor based on weight/reps: higher weight = higher intensity
        """
        total_calories = 0.0
        duration = workout_log.duration_minutes
        
        for exercise_data in exercises_data:
            exercise = exercise_data.get('exercise')
            if isinstance(exercise, Exercise):
                # Base calories from exercise
                base_calories = float(exercise.calories_per_minute) * duration
                
                # Intensity factor based on sets and weight
                sets = exercise_data.get('sets', 1)
                weight = float(exercise_data.get('weight', 0))
                
                # Higher sets and weight increase intensity
                intensity_factor = 1.0 + (sets * 0.1) + (weight * 0.01)
                intensity_factor = min(intensity_factor, 3.0)  # Cap at 3x
                
                total_calories += base_calories * intensity_factor
        
        # Ensure minimum calories
        return max(total_calories, duration * 3.0)

    def create(self, validated_data):
        """Create WorkoutLog with nested WorkoutExercise entries"""
        # Extract nested data
        workout_exercises_data = validated_data.pop('workout_exercises', [])
        exercises_data = validated_data.pop('exercises', [])
        
        # Ensure calories_burned has a default value if not provided
        if 'calories_burned' not in validated_data or validated_data['calories_burned'] is None:
            validated_data['calories_burned'] = Decimal('0.0')
        
        # Create the workout log
        workout_log = WorkoutLog.objects.create(**validated_data)
        
        # Create WorkoutExercise entries
        for exercise_data in workout_exercises_data:
            WorkoutExercise.objects.create(workout_log=workout_log, **exercise_data)
        
        # Create WorkoutLogExercise entries (backward compatibility)
        for exercise_data in exercises_data:
            sets_data = exercise_data.pop('sets', [])
            workout_log_exercise = WorkoutLogExercise.objects.create(
                workout_log=workout_log,
                **exercise_data
            )
            for set_data in sets_data:
                WorkoutSet.objects.create(
                    workout_log_exercise=workout_log_exercise,
                    **set_data
                )
        
        # Calculate and save calories
        if workout_exercises_data:
            workout_log.calories_burned = self.calculate_calories(workout_log, workout_exercises_data)
            workout_log.save()
        
        return workout_log


class CustomWorkoutExerciseSerializer(serializers.ModelSerializer):
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)
    exercise_id = serializers.PrimaryKeyRelatedField(
        source='exercise',
        queryset=Exercise.objects.all(),
        write_only=True
    )

    class Meta:
        model = CustomWorkoutExercise
        fields = [
            'id', 'exercise_id', 'exercise_name', 'order',
            'sets', 'reps', 'duration_seconds', 'rest_seconds'
        ]
        read_only_fields = ['id']


class CustomWorkoutSerializer(serializers.ModelSerializer):
    exercises = CustomWorkoutExerciseSerializer(
        source='customworkoutexercise_set',
        many=True
    )

    class Meta:
        model = CustomWorkout
        fields = [
            'id', 'name', 'description', 'category', 'exercises',
            'estimated_duration', 'is_public', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def create(self, validated_data):
        exercises_data = validated_data.pop('customworkoutexercise_set')
        custom_workout = CustomWorkout.objects.create(**validated_data)

        for exercise_data in exercises_data:
            CustomWorkoutExercise.objects.create(
                custom_workout=custom_workout,
                **exercise_data
            )

        return custom_workout

    def update(self, instance, validated_data):
        exercises_data = validated_data.pop('customworkoutexercise_set', None)
        
        # Update custom workout fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # Update exercises if provided
        if exercises_data is not None:
            # Delete existing exercises
            instance.customworkoutexercise_set.all().delete()
            
            # Create new exercises
            for exercise_data in exercises_data:
                CustomWorkoutExercise.objects.create(
                    custom_workout=instance,
                    **exercise_data
                )

        return instance


class PersonalRecordSerializer(serializers.ModelSerializer):
    """Enhanced PersonalRecord serializer with improvement tracking"""
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)
    improvement_percentage = serializers.SerializerMethodField()

    class Meta:
        model = PersonalRecord
        fields = [
            'id', 'exercise', 'exercise_name', 
            'max_weight', 'max_reps', 'max_volume',
            'achieved_date', 'workout_log',
            'improvement_percentage',
            'previous_max_weight', 'previous_max_reps', 'previous_max_volume'
        ]
        read_only_fields = ['id', 'achieved_date', 'improvement_percentage']

    def get_improvement_percentage(self, obj):
        """Get the improvement percentage from the model method"""
        return obj.get_improvement_percentage()
