from decimal import Decimal
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.utils.html import escape
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

    def validate_name(self, value):
        """Sanitize exercise name"""
        return sanitize_text_input(value)

    def validate_description(self, value):
        """Sanitize exercise description"""
        return sanitize_text_input(value)

    def validate_instructions(self, value):
        """Sanitize exercise instructions"""
        return sanitize_text_input(value)


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

    def validate_notes(self, value):
        """
        Validate and sanitize notes field.
        
        Requirements: 9.10
        """
        if value:
            return sanitize_text_input(value)
        return value

    def validate_workout_name(self, value):
        """
        Validate and sanitize workout_name field.
        
        Requirements: 9.10
        """
        if value:
            return sanitize_text_input(value)
        return value

    def validate_duration_minutes(self, value):
        """
        Validate duration is within acceptable range (1-600 minutes).
        
        Requirements: 9.1, 9.9
        """
        if value is not None:
            if value < 1:
                raise serializers.ValidationError("Duration must be at least 1 minute.")
            if value > 600:
                raise serializers.ValidationError("Duration cannot exceed 600 minutes (10 hours).")
        return value

    def validate_workout_exercises(self, value):
        """
        Validate workout exercises list.
        
        Requirements: 9.4, 9.5, 9.7
        """
        if not value or len(value) == 0:
            raise serializers.ValidationError("At least one exercise is required.")
        
        # Validate each exercise
        for idx, exercise_data in enumerate(value):
            # Validate exercise exists
            exercise_id = exercise_data.get('exercise')
            if exercise_id:
                if isinstance(exercise_id, int):
                    if not Exercise.objects.filter(id=exercise_id).exists():
                        raise serializers.ValidationError(
                            f"Exercise with ID {exercise_id} does not exist."
                        )
                elif hasattr(exercise_id, 'id'):
                    # Already an Exercise object
                    pass
            
            # Validate sets range (1-100)
            sets = exercise_data.get('sets')
            if sets is not None:
                if sets < 1:
                    raise serializers.ValidationError(
                        f"Exercise {idx + 1}: Sets must be at least 1."
                    )
                if sets > 100:
                    raise serializers.ValidationError(
                        f"Exercise {idx + 1}: Sets cannot exceed 100."
                    )
            
            # Validate reps range (1-100)
            reps = exercise_data.get('reps')
            if reps is not None:
                if reps < 1:
                    raise serializers.ValidationError(
                        f"Exercise {idx + 1}: Reps must be at least 1."
                    )
                if reps > 100:
                    raise serializers.ValidationError(
                        f"Exercise {idx + 1}: Reps cannot exceed 100."
                    )
            
            # Validate weight range (0.1-1000 kg)
            weight = exercise_data.get('weight')
            if weight is not None:
                weight_decimal = Decimal(str(weight))
                if weight_decimal < Decimal('0.1'):
                    raise serializers.ValidationError(
                        f"Exercise {idx + 1}: Weight must be at least 0.1 kg."
                    )
                if weight_decimal > Decimal('1000'):
                    raise serializers.ValidationError(
                        f"Exercise {idx + 1}: Weight cannot exceed 1000 kg."
                    )
        
        return value

    def validate(self, data):
        """
        Object-level validation.
        
        Requirements: 9.4, 9.5, 9.8
        """
        # Validate that workout date is not in the future
        logged_at = data.get('logged_at')
        if logged_at and logged_at > timezone.now():
            raise serializers.ValidationError({
                'logged_at': 'Workout date cannot be in the future.'
            })
        
        # Validate that at least one exercise is provided
        workout_exercises = data.get('workout_exercises', [])
        exercises = data.get('exercises', [])
        
        if not workout_exercises and not exercises:
            raise serializers.ValidationError({
                'workout_exercises': 'At least one exercise is required.',
                'exercises': 'At least one exercise is required.'
            })
        
        return data

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

    def validate_name(self, value):
        """Sanitize workout name"""
        return sanitize_text_input(value)

    def validate_description(self, value):
        """Sanitize workout description"""
        return sanitize_text_input(value)

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


def sanitize_text_input(text):
    """
    Sanitize text input to prevent XSS and injection attacks.
    Escapes HTML special characters and strips dangerous content.
    
    Requirements: 9.10
    """
    if text is None:
        return None
    
    # Convert to string and strip whitespace
    text = str(text).strip()
    
    # Escape HTML special characters
    text = escape(text)
    
    # Remove null bytes
    text = text.replace('\x00', '')
    
    return text
