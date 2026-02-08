from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    GymViewSet, ExerciseViewSet, CustomWorkoutViewSet,
    WorkoutLogViewSet, PersonalRecordViewSet
)

app_name = 'workouts'

router = DefaultRouter()
router.register(r'gyms', GymViewSet, basename='gym')
router.register(r'exercises', ExerciseViewSet, basename='exercise')
router.register(r'custom-workouts', CustomWorkoutViewSet, basename='custom-workout')
router.register(r'logs', WorkoutLogViewSet, basename='workout-log')
router.register(r'personal-records', PersonalRecordViewSet, basename='personal-record')

urlpatterns = [
    path('', include(router.urls)),
]
