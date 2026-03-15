from django.urls import path
from .upload_views import UploadMediaView

urlpatterns = [
    path('upload/', UploadMediaView.as_view(), name='upload-media'),
]
