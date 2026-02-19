from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Avg
from django.utils import timezone
from django.core.cache import cache
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
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
    
    GET /api/exercises/ - List all exercises with optional filtering
    GET /api/exercises/{id}/ - Retrieve a single exercise
    
    Query parameters for list:
    - category: Filter by exercise category (Strength, Cardio, Bodyweight)
    - muscle: Filter by muscle group (Chest, Back, Legs, Core, Arms, Shoulders, Full Body)
    - equipment: Filter by equipment type (Free Weights, Machines, Bodyweight, Resistance Bands, Cardio Equipment)
    - difficulty: Filter by difficulty level (Beginner, Intermediate, Advanced)
    - search: Search by exercise name (case-insensitive partial match)
    
    All filters can be combined to narrow down results.
    
    Requirements: 3.9, 5.3, 12.6
    """
    queryset = Exercise.objects.all()
    serializer_class = ExerciseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Filter exercises by category, muscle group, equipment, difficulty, and search term.
        All filters work in combination (AND logic).
        
        Requirements: 3.2, 3.3, 3.4, 3.5, 3.6, 3.9
        """
        queryset = Exercise.objects.all()
        
        # Filter by category
        category = self.request.query_params.get('category', None)
        if category:
            queryset = queryset.filter(category=category)
        
        # Filter by muscle group
        muscle = self.request.query_params.get('muscle', None)
        if muscle:
            queryset = queryset.filter(muscle_group=muscle)
        
        # Filter by equipment
        equipment = self.request.query_params.get('equipment', None)
        if equipment:
            queryset = queryset.filter(equipment=equipment)
        
        # Filter by difficulty
        difficulty = self.request.query_params.get('difficulty', None)
        if difficulty:
            queryset = queryset.filter(difficulty=difficulty)
        
        # Search by name (case-insensitive partial match)
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(name__icontains=search)
        
        return queryset

    def list(self, request, *args, **kwargs):
        """
        List exercises with caching support.
        Cache key is based on query parameters to ensure different filters get different cached results.
        
        Requirements: 12.6
        """
        # Build cache key from query parameters
        query_params = request.query_params.dict()
        cache_key_parts = ['exercise_list']
        for key in sorted(query_params.keys()):
            cache_key_parts.append(f'{key}_{query_params[key]}')
        cache_key = '_'.join(cache_key_parts)
        
        # Try to get from cache
        cached_data = cache.get(cache_key)
        if cached_data is not None:
            return Response(cached_data)
        
        # If not in cache, get from database
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response = self.get_paginated_response(serializer.data)
            # Cache paginated response data
            cache.set(cache_key, response.data, timeout=300)  # 5 minutes
            return response
        
        serializer = self.get_serializer(queryset, many=True)
        # Cache the response data
        cache.set(cache_key, serializer.data, timeout=300)  # 5 minutes
        return Response(serializer.data)

    def perform_create(self, serializer):
        """
        Clear exercise cache when new exercise is created.
        
        Requirements: 12.6
        """
        serializer.save(created_by=self.request.user, is_custom=True)
        # Clear cache by clearing all keys (simple approach for local memory cache)
        cache.clear()

    def perform_update(self, serializer):
        """
        Clear exercise cache when exercise is updated.
        
        Requirements: 12.6
        """
        serializer.save()
        # Clear cache
        cache.clear()

    def perform_destroy(self, instance):
        """
        Clear exercise cache when exercise is deleted.
        
        Requirements: 12.6
        """
        instance.delete()
        # Clear cache
        cache.clear()


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
        """
        Optimized queryset with select_related and prefetch_related.
        
        Requirements: 12.5
        """
        queryset = WorkoutLog.objects.filter(user=self.request.user)
        
        # Optimize queries with select_related for ForeignKey relationships
        queryset = queryset.select_related('user', 'custom_workout', 'gym')
        
        # Optimize queries with prefetch_related for reverse ForeignKey relationships
        queryset = queryset.prefetch_related(
            'workout_exercises',
            'workout_exercises__exercise',
            'personal_records',
            'personal_records__exercise'
        )
        
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

    @action(detail=False, methods=['post'])
    def log_workout(self, request):
        """
        Log a new workout with exercises.
        POST /api/workouts/log/
        
        Validates workout data, creates WorkoutLog and WorkoutExercises,
        returns 201 with complete workout object including PR flags.
        
        Requirements: 2.8, 2.9, 5.1, 14.1, 14.2
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Save with authenticated user
        workout_log = serializer.save(user=request.user)
        
        # Return complete workout object with PR flags
        response_serializer = self.get_serializer(workout_log)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def get_history(self, request):
        """
        Get workout history for the authenticated user.
        GET /api/workouts/history/
        
        Query parameters:
        - date_from: ISO datetime string to filter workouts from this date
        - limit: Maximum number of workouts to return
        
        Returns workouts ordered by date descending with pagination support.
        
        Requirements: 1.2, 1.7, 5.2, 12.5
        """
        # Use optimized queryset from get_queryset()
        queryset = self.get_queryset()
        
        # Order by date descending FIRST (before any slicing)
        queryset = queryset.order_by('-logged_at')
        
        # Apply date_from filter
        date_from = request.query_params.get('date_from', None)
        if date_from:
            try:
                # Handle both ISO format with and without timezone
                # Clean up the date string - handle various formats
                date_str = date_from.strip()
                # Replace 'Z' with '+00:00'
                date_str = date_str.replace('Z', '+00:00')
                # Fix space before timezone offset (e.g., "2026-02-14T06:00:43.208810 00:00" -> "2026-02-14T06:00:43.208810+00:00")
                if ' ' in date_str and date_str.count(':') >= 2:
                    # Check if there's a space before what looks like a timezone offset
                    parts = date_str.rsplit(' ', 1)
                    if len(parts) == 2 and ':' in parts[1]:
                        date_str = parts[0] + '+' + parts[1]
                
                # Try to parse as full datetime first
                try:
                    date_from_obj = datetime.fromisoformat(date_str)
                    # Ensure it's timezone-aware
                    if timezone.is_naive(date_from_obj):
                        date_from_obj = timezone.make_aware(date_from_obj)
                except ValueError:
                    # If that fails, try parsing as date only
                    from datetime import date as date_type
                    date_obj = date_type.fromisoformat(date_from)
                    date_from_obj = datetime.combine(date_obj, datetime.min.time())
                    date_from_obj = timezone.make_aware(date_from_obj)
                
                queryset = queryset.filter(logged_at__gte=date_from_obj)
            except (ValueError, TypeError) as e:
                return Response(
                    {'error': f'Invalid date_from format: {str(e)}. Use ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS).'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Apply limit LAST (after ordering and filtering)
        limit = request.query_params.get('limit', None)
        if limit:
            try:
                limit_int = int(limit)
                if limit_int > 0:
                    queryset = queryset[:limit_int]
                else:
                    return Response(
                        {'error': 'limit must be a positive integer'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            except ValueError:
                return Response(
                    {'error': 'limit must be an integer'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Serialize and return
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """
        Get workout statistics for the current user.
        GET /api/workouts/statistics/
        
        Query parameters:
        - start_date: ISO datetime string (optional)
        - end_date: ISO datetime string (optional)
        
        Returns:
        - Total workouts, calories, duration, averages
        - Breakdowns by time period and category
        - Most frequent exercises
        
        Requirements: 5.5, 15.1, 15.2, 15.3, 15.4, 15.5
        """
        queryset = self.get_queryset()
        
        # Apply date filters if provided
        start_date = request.query_params.get('start_date', None)
        end_date = request.query_params.get('end_date', None)
        
        if start_date:
            try:
                start_date_obj = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                queryset = queryset.filter(logged_at__gte=start_date_obj)
            except ValueError:
                return Response(
                    {'error': 'Invalid start_date format. Use ISO 8601 format.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        if end_date:
            try:
                end_date_obj = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                queryset = queryset.filter(logged_at__lte=end_date_obj)
            except ValueError:
                return Response(
                    {'error': 'Invalid end_date format. Use ISO 8601 format.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Calculate basic statistics
        total_workouts = queryset.count()
        total_duration = queryset.aggregate(Sum('duration_minutes'))['duration_minutes__sum'] or 0
        total_calories = queryset.aggregate(Sum('calories_burned'))['calories_burned__sum'] or 0
        avg_duration = queryset.aggregate(Avg('duration_minutes'))['duration_minutes__avg'] or 0
        avg_calories = queryset.aggregate(Avg('calories_burned'))['calories_burned__avg'] or 0
        
        # Get workout frequency by date (time period aggregation)
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
        
        # Get workout breakdown by category
        workouts_by_category = {}
        for log in queryset:
            # Get exercises for this workout
            exercises = log.workout_exercises.all()
            for workout_exercise in exercises:
                category = workout_exercise.exercise.category
                if category not in workouts_by_category:
                    workouts_by_category[category] = 0
                workouts_by_category[category] += 1
        
        # Get most frequent exercises
        exercise_frequency = {}
        for log in queryset:
            exercises = log.workout_exercises.all()
            for workout_exercise in exercises:
                exercise_name = workout_exercise.exercise.name
                if exercise_name not in exercise_frequency:
                    exercise_frequency[exercise_name] = 0
                exercise_frequency[exercise_name] += 1
        
        # Sort exercises by frequency and get top exercises
        most_frequent_exercises = [
            {'name': name, 'count': count}
            for name, count in sorted(
                exercise_frequency.items(),
                key=lambda x: x[1],
                reverse=True
            )
        ]
        
        return Response({
            'total_workouts': total_workouts,
            'total_duration_minutes': total_duration,
            'total_calories_burned': float(total_calories),
            'average_duration_minutes': float(avg_duration),
            'average_calories_burned': float(avg_calories),
            'workout_by_date': workout_by_date,
            'workouts_by_category': workouts_by_category,
            'most_frequent_exercises': most_frequent_exercises
        })


class PersonalRecordViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing personal records.
    Personal records are automatically created/updated when workout logs are saved.
    """
    serializer_class = PersonalRecordSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Optimized queryset with select_related for ForeignKey relationships.
        
        Requirements: 12.5
        """
        queryset = PersonalRecord.objects.filter(user=self.request.user)
        
        # Optimize queries with select_related for ForeignKey relationships
        queryset = queryset.select_related('user', 'exercise', 'workout_log')
        
        exercise_id = self.request.query_params.get('exercise_id', None)
        
        if exercise_id:
            queryset = queryset.filter(exercise_id=exercise_id)
        
        return queryset
