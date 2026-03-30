from django.db import models
import uuid


class GymSearch(models.Model):
    """Store user gym searches for analytics"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey('authentications.User', on_delete=models.CASCADE, related_name='gym_searches')
    latitude = models.FloatField()
    longitude = models.FloatField()
    radius = models.IntegerField(default=5000)  # in meters
    search_query = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'gym_searches'
        ordering = ['-created_at']


class FavoriteGym(models.Model):
    """User's favorite gyms"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey('authentications.User', on_delete=models.CASCADE, related_name='favorite_gyms')
    place_id = models.CharField(max_length=255)  # Google Place ID
    name = models.CharField(max_length=255)
    address = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'favorite_gyms'
        unique_together = ['user', 'place_id']
        ordering = ['-created_at']
