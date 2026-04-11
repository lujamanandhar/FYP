from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .openstreetmap_service import OpenStreetMapService
from .models import GymSearch, FavoriteGym
from .serializers import GymSearchSerializer, FavoriteGymSerializer


class NearbyGymsView(APIView):
    """
    GET /api/gyms/nearby/
    Search for gyms near a location using Google Places API
    Query params: latitude, longitude, radius (optional, default 5000m)
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        latitude = request.query_params.get('latitude')
        longitude = request.query_params.get('longitude')
        radius = int(request.query_params.get('radius', 5000))
        
        if not latitude or not longitude:
            return Response(
                {'error': 'latitude and longitude are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            latitude = float(latitude)
            longitude = float(longitude)
        except ValueError:
            return Response(
                {'error': 'Invalid latitude or longitude'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Save search for analytics
        GymSearch.objects.create(
            user=request.user,
            latitude=latitude,
            longitude=longitude,
            radius=radius,
        )
        
        # Fetch gyms from OpenStreetMap Overpass API (100% FREE)
        osm_service = OpenStreetMapService()
        try:
            gyms = osm_service.search_nearby_gyms(latitude, longitude, radius)
            return Response({'gyms': gyms, 'count': len(gyms)})
        except Exception as e:
            return Response(
                {
                    'error': 'gym_fetch_failed',
                    'message': 'Could not load gyms right now. The map service is temporarily unavailable. Please try again.',
                    'gyms': [],
                    'count': 0,
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )


class GymDetailsView(APIView):
    """
    GET /api/gyms/details/<place_id>/
    Get detailed information about a specific gym
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, place_id):
        osm_service = OpenStreetMapService()
        details = osm_service.get_place_details(place_id)
        
        if not details:
            return Response(
                {'error': 'Gym not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if gym is in user's favorites
        is_favorite = FavoriteGym.objects.filter(
            user=request.user,
            place_id=place_id
        ).exists()
        
        details['is_favorite'] = is_favorite
        
        return Response(details)


class FavoriteGymsView(APIView):
    """
    GET /api/gyms/favorites/
    POST /api/gyms/favorites/
    Manage user's favorite gyms
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        favorites = FavoriteGym.objects.filter(user=request.user)
        serializer = FavoriteGymSerializer(favorites, many=True)
        return Response(serializer.data)
    
    def post(self, request):
        data = request.data.copy()
        data['user'] = request.user.id
        
        serializer = FavoriteGymSerializer(data=data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class FavoriteGymDetailView(APIView):
    """
    DELETE /api/gyms/favorites/<place_id>/
    Remove gym from favorites
    """
    permission_classes = [IsAuthenticated]
    
    def delete(self, request, place_id):
        try:
            favorite = FavoriteGym.objects.get(user=request.user, place_id=place_id)
            favorite.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except FavoriteGym.DoesNotExist:
            return Response(
                {'error': 'Favorite not found'},
                status=status.HTTP_404_NOT_FOUND
            )


class CompareGymsView(APIView):
    """
    POST /api/gyms/compare/
    Compare multiple gyms side by side
    Body: { "place_ids": ["id1", "id2", "id3"] }
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        place_ids = request.data.get('place_ids', [])
        
        if not place_ids or len(place_ids) < 2:
            return Response(
                {'error': 'At least 2 gym IDs required for comparison'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if len(place_ids) > 5:
            return Response(
                {'error': 'Maximum 5 gyms can be compared at once'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        osm_service = OpenStreetMapService()
        gyms = []
        
        for place_id in place_ids:
            details = osm_service.get_place_details(place_id)
            if details:
                gyms.append(details)
        
        return Response({'gyms': gyms, 'count': len(gyms)})
