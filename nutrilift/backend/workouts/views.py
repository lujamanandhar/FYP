from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Avg
from datetime import datetime, timedelta
from .models import (
    Gym, Exercise, CustomWorkout, WorkoutLog, PersonalRecord
)
from .serializers import (
    GymSerializer, ExerciseSerializer, CustomWorkoutSerializer,
    WorkoutLogSerializer, PersonalRecordSerializer
)


class GymViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing gyms.
    Only read operations are allowed.
    """
    queryset = Gym.objects.all()
    serializer_class = GymSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Gym.objects.all()
        location = self.request.query_params.get('location', None)
        if location:
            queryset = queryset.filter(location__icontains=location)
        return queryset


class ExerciseViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing exercises.
    Users can view all exercises and create custom ones.
    """
    queryset = Exercise.objects.all()
    serializer_class = ExerciseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Exercise.objects.all()
        category = self.request.query_params.get('category', None)
        difficulty = self.request.query_params.get('difficulty', None)
        
        if category:
            queryset = queryset.filter(category=category)
        if difficulty:
            queryset = queryset.filter(difficulty=difficulty)
        
        return queryset

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user, is_custom=True)


class CustomWorkoutViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing custom workout templates.
    Users can only view and modify their own workouts.
    """
    serializer_class = CustomWorkoutSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = CustomWorkout.objects.filter(user=self.request.user)
        is_public = self.request.query_params.get('is_public', None)
        
        if is_public is not None:
            is_public_bool = is_public.lower() == 'true'
            queryset = queryset.filter(is_public=is_public_bool)
        
        return queryset

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class WorkoutLogViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing workout logs.
    Users can only view and modify their own workout logs.
    """
    serializer_class = WorkoutLogSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = WorkoutLog.objects.filter(user=self.request.user)
        start_date = self.request.query_params.get('start_date', None)
        end_date = self.request.query_params.get('end_date', None)
        
        if start_date:
            try:
                start_date_obj = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                queryset = queryset.filter(logged_at__gte=start_date_obj)
            except ValueError:
                pass
        
        if end_date:
            try:
                end_date_obj = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                queryset = queryset.filter(logged_at__lte=end_date_obj)
            except ValueError:
                pass
        
        return queryset

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """
        Get workout statistics for the current user.
        Optional query params: start_date, end_date
        """
        queryset = self.get_queryset()
        
        # Calculate statistics
        total_workouts = queryset.count()
        total_duration = queryset.aggregate(Sum('duration_minutes'))['duration_minutes__sum'] or 0
        total_calories = queryset.aggregate(Sum('calories_burned'))['calories_burned__sum'] or 0
        avg_duration = queryset.aggregate(Avg('duration_minutes'))['duration_minutes__avg'] or 0
        avg_calories = queryset.aggregate(Avg('calories_burned'))['calories_burned__avg'] or 0
        
        # Get workout frequency by date
        workout_by_date = {}
        for log in queryset:
            date_str = log.logged_at.date().isoformat()
            if date_str not in workout_by_date:
                workout_by_date[date_str] = {
                    'count': 0,
                    'duration': 0,
                    'calories': 0
                }
            workout_by_date[date_str]['count'] += 1
            workout_by_date[date_str]['duration'] += log.duration_minutes
            workout_by_date[date_str]['calories'] += float(log.calories_burned)
        
        return Response({
            'total_workouts': total_workouts,
            'total_duration_minutes': total_duration,
            'total_calories_burned': float(total_calories),
            'average_duration_minutes': float(avg_duration),
            'average_calories_burned': float(avg_calories),
            'workout_by_date': workout_by_date
        })


class PersonalRecordViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing personal records.
    Personal records are automatically created/updated when workout logs are saved.
    """
    serializer_class = PersonalRecordSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = PersonalRecord.objects.filter(user=self.request.user)
        exercise_id = self.request.query_params.get('exercise_id', None)
        
        if exercise_id:
            queryset = queryset.filter(exercise_id=exercise_id)
        
        return queryset
