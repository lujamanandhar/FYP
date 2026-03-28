"""
Views for camera-based rep counting feature.
Requirements: 12.3-12.10
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .rep_counting_models import RepSession, RepEvent
from .rep_counting_serializers import (
    RepSessionSerializer, RepSessionCreateSerializer,
    RepSessionUpdateSerializer, RepEventSerializer
)
from .models import WorkoutLog, WorkoutLogExercise, WorkoutSet, Exercise


class RepSessionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing rep counting sessions.
    
    GET /api/rep-sessions/ - List user's sessions
    POST /api/rep-sessions/ - Create new session
    GET /api/rep-sessions/{id}/ - Get session details with events
    PATCH /api/rep-sessions/{id}/ - Update session (end, adjust reps)
    DELETE /api/rep-sessions/{id}/ - Delete session
    POST /api/rep-sessions/{id}/add-rep/ - Add a rep event
    POST /api/rep-sessions/{id}/convert-to-workout/ - Convert to workout log
    """
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return only user's own sessions"""
        return RepSession.objects.filter(user=self.request.user).prefetch_related('rep_events')
    
    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return RepSessionCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return RepSessionUpdateSerializer
        return RepSessionSerializer
    
    def perform_create(self, serializer):
        """Create session for authenticated user"""
        serializer.save(user=self.request.user)
    
    @action(detail=True, methods=['post'])
    def add_rep(self, request, pk=None):
        """
        Add a rep event to the session.
        POST /api/rep-sessions/{id}/add-rep/
        
        Body: {
            "confidence": 0.95,
            "angle_data": {"elbow_angle": 85, "knee_angle": 90}
        }
        
        Requirements: 2.3
        """
        session = self.get_object()
        
        if session.end_time is not None:
            return Response(
                {'error': 'Cannot add reps to ended session'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        confidence = request.data.get('confidence', 0.0)
        angle_data = request.data.get('angle_data', {})
        
        # Get next rep number
        last_rep = session.rep_events.order_by('-rep_number').first()
        rep_number = (last_rep.rep_number + 1) if last_rep else 1
        
        # Create rep event
        rep_event = RepEvent.objects.create(
            session=session,
            rep_number=rep_number,
            confidence=confidence,
            angle_data=angle_data
        )
        
        # Update session total reps and average confidence
        session.total_reps = rep_number
        
        # Recalculate average confidence
        all_events = session.rep_events.all()
        if all_events:
            avg_confidence = sum(float(e.confidence) for e in all_events) / len(all_events)
            session.confidence_avg = avg_confidence
        
        session.save(update_fields=['total_reps', 'confidence_avg'])
        
        serializer = RepEventSerializer(rep_event)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def end_session(self, request, pk=None):
        """
        End the rep counting session.
        POST /api/rep-sessions/{id}/end-session/
        
        Requirements: 4.3
        """
        session = self.get_object()
        
        if session.end_time is not None:
            return Response(
                {'error': 'Session already ended'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        session.end_time = timezone.now()
        session.save(update_fields=['end_time'])
        
        serializer = self.get_serializer(session)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def convert_to_workout(self, request, pk=None):
        """
        Convert rep session to workout log.
        POST /api/rep-sessions/{id}/convert-to-workout/
        
        Body: {
            "workout_name": "Morning Push-ups",
            "sets": 3,
            "weight": 0,
            "notes": "Felt strong today"
        }
        
        Requirements: 6.1-6.8, 12.10
        """
        session = self.get_object()
        
        if session.is_converted:
            return Response(
                {'error': 'Session already converted to workout'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if session.end_time is None:
            return Response(
                {'error': 'Session must be ended before conversion'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get workout details from request
        workout_name = request.data.get('workout_name', f'{session.get_exercise_type_display()} Session')
        sets = request.data.get('sets', 1)
        weight = request.data.get('weight', 0)
        notes = request.data.get('notes', '')
        
        # Calculate duration and calories
        duration_seconds = (session.end_time - session.start_time).total_seconds()
        duration_minutes = max(1, int(duration_seconds / 60))
        
        # Get exercise for calorie calculation
        exercise = session.exercise
        if not exercise:
            # Try to find matching exercise by type
            exercise_name_map = {
                'PUSH_UP': 'Push-up',
                'SQUAT': 'Squat',
                'PULL_UP': 'Pull-up',
                'BICEP_CURL': 'Bicep Curl',
                'SHOULDER_PRESS': 'Shoulder Press',
                'LUNGE': 'Lunge',
                'SIT_UP': 'Sit-up',
            }
            exercise_name = exercise_name_map.get(session.exercise_type)
            if exercise_name:
                exercise = Exercise.objects.filter(name__icontains=exercise_name).first()
        
        # Calculate calories (rough estimate)
        calories_per_minute = float(exercise.calories_per_minute) if exercise else 5.0
        calories_burned = calories_per_minute * duration_minutes
        
        # Create workout log
        workout_log = WorkoutLog.objects.create(
            user=session.user,
            workout_name=workout_name,
            duration_minutes=duration_minutes,
            calories_burned=calories_burned,
            notes=notes
        )
        
        # Create workout log exercise with sets
        if exercise:
            workout_log_exercise = WorkoutLogExercise.objects.create(
                workout_log=workout_log,
                exercise=exercise,
                order=1,
                notes=f'Camera session: {session.total_reps} total reps, avg confidence: {session.confidence_avg}'
            )
            
            # Create sets (distribute reps across sets)
            reps_per_set = session.total_reps // sets if sets > 0 else session.total_reps
            remainder = session.total_reps % sets if sets > 0 else 0
            
            for set_num in range(1, sets + 1):
                set_reps = reps_per_set + (1 if set_num <= remainder else 0)
                WorkoutSet.objects.create(
                    workout_log_exercise=workout_log_exercise,
                    set_number=set_num,
                    reps=set_reps,
                    weight=weight,
                    completed=True
                )
        
        # Link session to workout log
        session.workout_log = workout_log
        session.is_converted = True
        session.save(update_fields=['workout_log', 'is_converted'])
        
        return Response({
            'workout_log_id': workout_log.id,
            'message': 'Session converted to workout successfully'
        }, status=status.HTTP_201_CREATED)


class RepEventViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing rep events.
    Rep events are created via RepSessionViewSet.add_rep action.
    
    GET /api/rep-events/ - List all user's rep events
    GET /api/rep-events/{id}/ - Get specific rep event
    """
    serializer_class = RepEventSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return only events from user's sessions"""
        return RepEvent.objects.filter(
            session__user=self.request.user
        ).select_related('session')
