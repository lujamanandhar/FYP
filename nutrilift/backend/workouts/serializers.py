from rest_framework import serializers
from .models import (
    Gym, Exercise, CustomWorkout, CustomWorkoutExercise,
    WorkoutLog, WorkoutLogExercise, WorkoutSet, PersonalRecord
)


class GymSerializer(serializers.ModelSerializer):
    class Meta:
        model = Gym
        fields = ['id', 'name', 'location', 'address', 'rating', 'phone', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = [
            'id', 'name', 'description', 'category', 'difficulty',
            'instructions', 'video_url', 'image_url', 'calories_per_minute',
            'is_custom', 'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']


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
    exercises = WorkoutLogExerciseSerializer(many=True)
    gym = GymSerializer(read_only=True)
    gym_id = serializers.PrimaryKeyRelatedField(
        source='gym',
        queryset=Gym.objects.all(),
        write_only=True,
        required=False,
        allow_null=True
    )

    class Meta:
        model = WorkoutLog
        fields = [
            'id', 'workout_name', 'custom_workout', 'gym', 'gym_id',
            'duration_minutes', 'calories_burned', 'exercises', 'notes',
            'logged_at', 'updated_at'
        ]
        read_only_fields = ['id', 'logged_at', 'updated_at']

    def create(self, validated_data):
        exercises_data = validated_data.pop('exercises')
        workout_log = WorkoutLog.objects.create(**validated_data)

        for exercise_data in exercises_data:
            sets_data = exercise_data.pop('sets')
            workout_log_exercise = WorkoutLogExercise.objects.create(
                workout_log=workout_log,
                **exercise_data
            )
            for set_data in sets_data:
                WorkoutSet.objects.create(
                    workout_log_exercise=workout_log_exercise,
                    **set_data
                )

        return workout_log

    def update(self, instance, validated_data):
        exercises_data = validated_data.pop('exercises', None)
        
        # Update workout log fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # Update exercises if provided
        if exercises_data is not None:
            # Delete existing exercises and sets
            instance.exercises.all().delete()
            
            # Create new exercises and sets
            for exercise_data in exercises_data:
                sets_data = exercise_data.pop('sets')
                workout_log_exercise = WorkoutLogExercise.objects.create(
                    workout_log=instance,
                    **exercise_data
                )
                for set_data in sets_data:
                    WorkoutSet.objects.create(
                        workout_log_exercise=workout_log_exercise,
                        **set_data
                    )

        return instance


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
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)
    exercise_id = serializers.PrimaryKeyRelatedField(
        source='exercise',
        queryset=Exercise.objects.all(),
        write_only=True
    )

    class Meta:
        model = PersonalRecord
        fields = [
            'id', 'exercise_id', 'exercise_name', 'record_type',
            'value', 'unit', 'workout_log', 'achieved_at', 'notes'
        ]
        read_only_fields = ['id', 'achieved_at']
