from django.urls import path
from . import views

app_name = 'gyms'

urlpatterns = [
    path('nearby/', views.NearbyGymsView.as_view(), name='nearby'),
    path('details/<str:place_id>/', views.GymDetailsView.as_view(), name='details'),
    path('favorites/', views.FavoriteGymsView.as_view(), name='favorites'),
    path('favorites/<str:place_id>/', views.FavoriteGymDetailView.as_view(), name='favorite-detail'),
    path('compare/', views.CompareGymsView.as_view(), name='compare'),
]
