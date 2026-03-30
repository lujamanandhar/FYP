from rest_framework import serializers
from .models import GymSearch, FavoriteGym


class GymSearchSerializer(serializers.ModelSerializer):
    class Meta:
        model = GymSearch
        fields = ['id', 'latitude', 'longitude', 'radius', 'search_query', 'created_at']
        read_only_fields = ['id', 'created_at']


class FavoriteGymSerializer(serializers.ModelSerializer):
    class Meta:
        model = FavoriteGym
        fields = ['id', 'place_id', 'name', 'address', 'created_at']
        read_only_fields = ['id', 'created_at']
