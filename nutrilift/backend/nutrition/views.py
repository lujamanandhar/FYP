from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import action
from django.db.models import Q
from .models import FoodItem, IntakeLog, HydrationLog, NutritionGoals, NutritionProgress, QuickLog
from .serializers import (
    FoodItemSerializer, IntakeLogSerializer, HydrationLogSerializer,
    NutritionGoalsSerializer, NutritionProgressSerializer, QuickLogSerializer
)


class NutritionProgressPagination(PageNumberPagination):
    """
    Custom pagination class for NutritionProgress with 50 items per page.
    
    Requirements: 14.6, 16.7
    """
    page_size = 50
    page_size_query_param = 'page_size'
    max_page_size = 100


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
    
    @action(detail=False, methods=['get'])
    def recent_foods(self, request):
        """
        Get recently logged foods for the current user.
        Returns unique food items ordered by most recent usage.
        """
        user = request.user
        
        # Get distinct food items from recent logs (last 30 days)
        from datetime import timedelta
        from django.utils import timezone
        from django.db.models import Max
        
        thirty_days_ago = timezone.now() - timedelta(days=30)
        
        # Get recent food IDs with their last logged date
        recent_food_ids = (
            IntakeLog.objects
            .filter(user=user, logged_at__gte=thirty_days_ago)
            .values('food_item_id')
            .annotate(last_logged=Max('logged_at'))
            .order_by('-last_logged')[:10]
        )
        
        # Get the actual food items
        food_ids = [item['food_item_id'] for item in recent_food_ids]
        foods = FoodItem.objects.filter(id__in=food_ids)
        
        # Serialize and return
        serializer = FoodItemSerializer(foods, many=True)
        return Response(serializer.data)


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



class NutritionGoalsViewSet(viewsets.ModelViewSet):
    """
    ViewSet for NutritionGoals CRUD operations.
    Returns default values if user has no goals set.
    
    Requirements: 5.3-5.5, 5.7, 10.2
    """
    serializer_class = NutritionGoalsSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filter by authenticated user.
        
        Requirements: 5.4, 10.2
        """
        user = self.request.user
        return NutritionGoals.objects.filter(user=user)
    
    def list(self, request, *args, **kwargs):
        """
        Override list to return default values if user has no goals.
        Default values: 2000 calories, 150g protein, 200g carbs, 65g fats, 2000ml water
        
        Requirements: 5.4, 5.7
        """
        queryset = self.filter_queryset(self.get_queryset())
        
        if queryset.exists():
            # User has goals, return them normally
            serializer = self.get_serializer(queryset, many=True)
            return Response({'results': serializer.data})
        else:
            # No goals exist, return default values
            default_data = {
                'id': None,
                'user': request.user.id,
                'daily_calories': 2000.00,
                'daily_protein': 150.00,
                'daily_carbs': 200.00,
                'daily_fats': 65.00,
                'daily_water': 2000.00,
                'created_at': None,
                'updated_at': None
            }
            return Response({'results': [default_data]})
    
    def retrieve(self, request, *args, **kwargs):
        """
        Override retrieve to return default values if no goals exist.
        Default values: 2000 calories, 150g protein, 200g carbs, 65g fats, 2000ml water
        
        Requirements: 5.4, 5.7
        """
        user = request.user
        
        # Get the object using the standard method which checks permissions
        try:
            instance = self.get_object()
            serializer = self.get_serializer(instance)
            return Response(serializer.data)
        except NutritionGoals.DoesNotExist:
            # Return default values if no goals exist (as numbers, not strings)
            default_data = {
                'id': None,
                'user': user.id,
                'daily_calories': 2000.00,
                'daily_protein': 150.00,
                'daily_carbs': 200.00,
                'daily_fats': 65.00,
                'daily_water': 2000.00,
                'created_at': None,
                'updated_at': None
            }
            return Response(default_data)
    
    def perform_create(self, serializer):
        """
        Set user to current authenticated user from JWT token.
        
        Requirements: 5.3, 10.2
        """
        serializer.save(user=self.request.user)
    
    def perform_update(self, serializer):
        """
        Ensure user is set to current authenticated user.
        
        Requirements: 5.5, 10.2
        """
        serializer.save(user=self.request.user)


class NutritionProgressViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only ViewSet for NutritionProgress.
    Progress is automatically updated via signals when meals are logged.
    Users can only view progress records (no create/update/delete).
    
    Requirements: 3.9, 10.2, 14.1, 14.3, 14.6, 16.7
    """
    serializer_class = NutritionProgressSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = NutritionProgressPagination
    
    def get_queryset(self):
        """
        Filter by authenticated user and optional date range.
        
        Requirements: 3.9, 10.2, 16.7
        """
        user = self.request.user
        queryset = NutritionProgress.objects.filter(user=user)
        
        # Date filtering using query parameters
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        
        if date_from:
            queryset = queryset.filter(progress_date__gte=date_from)
        if date_to:
            queryset = queryset.filter(progress_date__lte=date_to)
        
        return queryset


class QuickLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only ViewSet for QuickLog.
    QuickLog is automatically updated via signals when meals are logged.
    Provides custom actions for retrieving frequent and recent foods.
    
    Requirements: 1.7, 6.4, 6.5, 10.2
    """
    serializer_class = QuickLogSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filter by authenticated user.
        
        Requirements: 10.2
        """
        user = self.request.user
        return QuickLog.objects.filter(user=user)
    
    @action(detail=False, methods=['get'])
    def frequent(self, request):
        """
        Custom action to retrieve frequent foods ordered by usage_count descending.
        Returns food items from the user's QuickLog sorted by how often they're used.
        
        Requirements: 6.4
        """
        user = request.user
        
        # Get or create QuickLog for user
        quick_log, _ = QuickLog.objects.get_or_create(user=user)
        
        # Sort frequent_meals by usage_count descending
        frequent_meals = sorted(
            quick_log.frequent_meals,
            key=lambda x: x.get('usage_count', 0),
            reverse=True
        )
        
        # Get food item IDs
        food_item_ids = [meal['food_item_id'] for meal in frequent_meals]
        
        # Fetch food items maintaining the order
        food_items = FoodItem.objects.filter(id__in=food_item_ids)
        food_items_dict = {item.id: item for item in food_items}
        
        # Build ordered list with food item details
        results = []
        for meal in frequent_meals:
            food_item_id = meal['food_item_id']
            if food_item_id in food_items_dict:
                food_item = food_items_dict[food_item_id]
                results.append({
                    'food_item_id': food_item_id,
                    'usage_count': meal.get('usage_count', 0),
                    'last_used': meal.get('last_used'),
                    'food_item': FoodItemSerializer(food_item).data
                })
        
        return Response(results)
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """
        Custom action to retrieve recent foods ordered by last_used descending.
        Returns food items from the user's QuickLog sorted by most recently used.
        
        Requirements: 6.5
        """
        user = request.user
        
        # Get or create QuickLog for user
        quick_log, _ = QuickLog.objects.get_or_create(user=user)
        
        # Sort frequent_meals by last_used descending
        recent_meals = sorted(
            quick_log.frequent_meals,
            key=lambda x: x.get('last_used', ''),
            reverse=True
        )
        
        # Get food item IDs
        food_item_ids = [meal['food_item_id'] for meal in recent_meals]
        
        # Fetch food items maintaining the order
        food_items = FoodItem.objects.filter(id__in=food_item_ids)
        food_items_dict = {item.id: item for item in food_items}
        
        # Build ordered list with food item details
        results = []
        for meal in recent_meals:
            food_item_id = meal['food_item_id']
            if food_item_id in food_items_dict:
                food_item = food_items_dict[food_item_id]
                results.append({
                    'food_item_id': food_item_id,
                    'usage_count': meal.get('usage_count', 0),
                    'last_used': meal.get('last_used'),
                    'food_item': FoodItemSerializer(food_item).data
                })
        
        return Response(results)
