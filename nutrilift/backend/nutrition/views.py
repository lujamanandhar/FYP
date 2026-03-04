from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from .models import FoodItem, IntakeLog, HydrationLog, NutritionGoals, NutritionProgress, QuickLog
from .serializers import (
    FoodItemSerializer, IntakeLogSerializer, HydrationLogSerializer,
    NutritionGoalsSerializer, NutritionProgressSerializer, QuickLogSerializer
)


class FoodItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet for FoodItem CRUD operations.
    Supports search and filtering by custom/system foods.
    Users can view all system foods (is_custom=False) plus their own custom foods.
    
    Requirements: 1.3, 1.5, 1.6, 10.1, 10.2, 16.1, 16.2
    """
    serializer_class = FoodItemSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'brand']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']
    
    def get_queryset(self):
        """
        Return system foods (is_custom=False) + user's custom foods.
        
        Requirements: 1.3, 1.5
        """
        user = self.request.user
        return FoodItem.objects.filter(
            Q(is_custom=False) | Q(created_by=user)
        )
    
    def perform_create(self, serializer):
        """
        Set created_by to current user and mark as custom food.
        
        Requirements: 1.5, 1.6
        """
        serializer.save(created_by=self.request.user, is_custom=True)


class IntakeLogViewSet(viewsets.ModelViewSet):
    """
    ViewSet for IntakeLog CRUD operations.
    Supports date range filtering via query parameters.
    
    Requirements: 2.9-2.12, 10.2, 10.4, 14.5, 16.5
    """
    serializer_class = IntakeLogSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filter by authenticated user and optional date range.
        Uses select_related to minimize database queries.
        
        Requirements: 2.10, 10.2, 10.4, 14.5, 16.5
        """
        user = self.request.user
        queryset = IntakeLog.objects.filter(user=user).select_related('food_item')
        
        # Date filtering using query parameters
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        
        if date_from:
            queryset = queryset.filter(logged_at__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(logged_at__date__lte=date_to)
        
        return queryset
    
    def perform_create(self, serializer):
        """
        Set user to current authenticated user from JWT token.
        
        Requirements: 2.9, 10.2
        """
        serializer.save(user=self.request.user)


class HydrationLogViewSet(viewsets.ModelViewSet):
    """
    ViewSet for HydrationLog CRUD operations.
    Supports date range filtering via query parameters.
    
    Requirements: 4.2, 4.3, 4.7, 10.2
    """
    serializer_class = HydrationLogSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filter by authenticated user and optional date range.
        
        Requirements: 4.3, 10.2
        """
        user = self.request.user
        queryset = HydrationLog.objects.filter(user=user)
        
        # Date filtering using query parameters
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        
        if date_from:
            queryset = queryset.filter(logged_at__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(logged_at__date__lte=date_to)
        
        return queryset
    
    def perform_create(self, serializer):
        """
        Set user to current authenticated user from JWT token.
        
        Requirements: 4.2, 10.2
        """
        serializer.save(user=self.request.user)
