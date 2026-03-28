"""
Serializers for camera-based rep counting feature.
"""
from rest_framework import serializers
from .rep_counting_models import RepSession, RepEvent


class RepEventSerializer(serializers.ModelSerializer):
    """Serializer for individual rep events"""
    
    class Meta:
        model = RepEvent
        fields = [
            'id', 'rep_number', 'timestamp', 'confidence', 'angle_data'
        ]
        read_only_fields = ['id', 'timestamp']


class RepSessionSerializer(serializers.ModelSerializer):
    """Serializer for rep counting sessions"""
    rep_events = RepEventSerializer(many=True, read_only=True)
    duration_seconds = serializers.SerializerMethodField()
    
    class Meta:
        model = RepSession
        fields = [
            'id', 'exercise_type', 'exercise', 'start_time', 'end_time',
            'total_reps', 'confidence_avg', 'workout_log', 'is_converted',
            'rep_events', 'duration_seconds', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'start_time']
    
    def get_duration_seconds(self, obj):
        """Calculate session duration in seconds"""
        if obj.end_time and obj.start_time:
            delta = obj.end_time - obj.start_time
            return int(delta.total_seconds())
        return 0


class RepSessionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new rep sessions"""
    
    class Meta:
        model = RepSession
        fields = ['exercise_type', 'exercise']
    
    def validate_exercise_type(self, value):
        """Validate exercise type is supported"""
        valid_types = [choice[0] for choice in RepSession.EXERCISE_TYPE_CHOICES]
        if value not in valid_types:
            raise serializers.ValidationError(
                f"Invalid exercise type. Must be one of: {', '.join(valid_types)}"
            )
        return value


class RepSessionUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating rep session (end session, adjust reps)"""
    
    class Meta:
        model = RepSession
        fields = ['end_time', 'total_reps', 'confidence_avg']
    
    def validate_total_reps(self, value):
        """Validate total reps is non-negative"""
        if value < 0:
            raise serializers.ValidationError("Total reps cannot be negative")
        return value
