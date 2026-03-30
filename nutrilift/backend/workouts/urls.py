from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    GymViewSet, ExerciseViewSet, CustomWorkoutViewSet,
    WorkoutLogViewSet, PersonalRecordViewSet
)
from .rep_counting_views import RepSessionViewSet, RepEventViewSet

app_name = 'workouts'

router = DefaultRouter()
router.register(r'gyms', GymViewSet, basename='gym')
router.register(r'exercises', ExerciseViewSet, basename='exercise')
router.register(r'custom-workouts', CustomWorkoutViewSet, basename='custom-workout')
router.register(r'logs', WorkoutLogViewSet, basename='workout-log')
router.register(r'personal-records', PersonalRecordViewSet, basename='personal-record')
router.register(r'rep-sessions', RepSessionViewSet, basename='rep-session')
router.register(r'rep-events', RepEventViewSet, basename='rep-event')

urlpatterns = [
    path('', include(router.urls)),
]
