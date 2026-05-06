from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .openstreetmap_service import OpenStreetMapService
from .geoapify_service import GeoapifyService
from .models import GymSearch, FavoriteGym
from .serializers import GymSearchSerializer, FavoriteGymSerializer


class NearbyGymsView(APIView):
    """
    GET /api/gyms/nearby/
    Search for gyms near a location using OpenStreetMap (fast, free, unlimited).
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

        GymSearch.objects.create(
            user=request.user,
            latitude=latitude,
            longitude=longitude,
            radius=radius,
        )

        # Use OSM for nearby discovery — fast, unlimited, good Nepal coverage
        osm_service = OpenStreetMapService()
        try:
            gyms = osm_service.search_nearby_gyms(latitude, longitude, radius)
            return Response({'gyms': gyms, 'count': len(gyms)})
        except Exception as e:
            return Response(
                {
                    'error': 'gym_fetch_failed',
                    'message': 'Could not load gyms right now. Please try again.',
                    'gyms': [],
                    'count': 0,
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )


class GymDetailsView(APIView):
    """
    GET /api/gyms/details/<place_id>/
    Get detailed information about a specific gym.
    OSM place_ids (node/xxx, way/xxx) go directly to OSM.
    Geoapify place_ids go to Geoapify.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, place_id):
        # Decode URL-encoded slashes
        import urllib.parse
        decoded_id = urllib.parse.unquote(place_id)

        details = None

        # OSM IDs start with node/ or way/ — use OSM directly
        if decoded_id.startswith('node/') or decoded_id.startswith('way/') or decoded_id.startswith('relation/'):
            osm_service = OpenStreetMapService()
            details = osm_service.get_place_details(decoded_id)
        else:
            # Try Geoapify for non-OSM IDs
            geoapify = GeoapifyService()
            details = geoapify.get_place_details(decoded_id)
            if not details:
                osm_service = OpenStreetMapService()
                details = osm_service.get_place_details(decoded_id)

        if not details:
            return Response(
                {'error': 'Gym not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        is_favorite = FavoriteGym.objects.filter(
            user=request.user,
            place_id=decoded_id
        ).exists()
        details['is_favorite'] = is_favorite

        return Response(details)


class FavoriteGymsView(APIView):
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
    Compare multiple gyms. Uses Geoapify for enriched details.
    Body: { "place_ids": ["id1", "id2"] }
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

        geoapify = GeoapifyService()
        osm_service = OpenStreetMapService()
        gyms = []

        for place_id in place_ids:
            import urllib.parse
            decoded_id = urllib.parse.unquote(place_id)
            details = None
            # OSM IDs go directly to OSM
            if decoded_id.startswith('node/') or decoded_id.startswith('way/') or decoded_id.startswith('relation/'):
                details = osm_service.get_place_details(decoded_id)
            else:
                details = geoapify.get_place_details(decoded_id)
                if not details:
                    details = osm_service.get_place_details(decoded_id)
            if details:
                gyms.append(details)

        return Response({'gyms': gyms, 'count': len(gyms)})
