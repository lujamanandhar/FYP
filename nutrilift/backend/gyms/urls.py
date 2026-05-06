from django.urls import path, re_path
from . import views

app_name = 'gyms'

urlpatterns = [
    path('nearby/', views.NearbyGymsView.as_view(), name='nearby'),
    # re_path needed because place_id contains slashes (e.g. node/123456)
    re_path(r'^details/(?P<place_id>.+)/$', views.GymDetailsView.as_view(), name='details'),
    path('favorites/', views.FavoriteGymsView.as_view(), name='favorites'),
    re_path(r'^favorites/(?P<place_id>.+)/$', views.FavoriteGymDetailView.as_view(), name='favorite-detail'),
    path('compare/', views.CompareGymsView.as_view(), name='compare'),
]
