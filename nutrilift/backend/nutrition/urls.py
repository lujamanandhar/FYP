from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'nutrition'

router = DefaultRouter()
router.register(r'food-items', views.FoodItemViewSet, basename='food-item')
router.register(r'intake-logs', views.IntakeLogViewSet, basename='intake-log')
router.register(r'hydration-logs', views.HydrationLogViewSet, basename='hydration-log')

urlpatterns = [
    path('', include(router.urls)),
]
