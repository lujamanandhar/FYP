import os
import uuid
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated


ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}
ALLOWED_VIDEO_TYPES = {'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm', 'video/x-matroska'}
ALLOWED_MEDIA_TYPES = ALLOWED_IMAGE_TYPES | ALLOWED_VIDEO_TYPES

MAX_IMAGE_SIZE = 10 * 1024 * 1024   # 10 MB
MAX_VIDEO_SIZE = 100 * 1024 * 1024  # 100 MB


class UploadMediaView(APIView):
    """
    POST /api/upload/
    Accepts multipart/form-data with an 'image' or 'file' field.
    Saves to media/uploads/ and returns the public URL and media type.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Accept 'image' (legacy) or 'file' field
        file = request.FILES.get('image') or request.FILES.get('file')
        if not file:
            return Response({'detail': 'No file provided.'}, status=status.HTTP_400_BAD_REQUEST)

        is_video = file.content_type in ALLOWED_VIDEO_TYPES

        if file.content_type not in ALLOWED_MEDIA_TYPES:
            return Response(
                {'detail': f'Unsupported file type: {file.content_type}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        max_size = MAX_VIDEO_SIZE if is_video else MAX_IMAGE_SIZE
        if file.size > max_size:
            limit_mb = max_size // (1024 * 1024)
            return Response(
                {'detail': f'File too large. Maximum size is {limit_mb} MB.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ext = os.path.splitext(file.name)[1] or ('.mp4' if is_video else '.jpg')
        filename = f'uploads/{uuid.uuid4().hex}{ext}'
        saved_path = default_storage.save(filename, ContentFile(file.read()))

        url = request.build_absolute_uri(settings.MEDIA_URL + saved_path)
        return Response({'url': url, 'is_video': is_video}, status=status.HTTP_201_CREATED)
