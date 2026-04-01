from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(APIView):
    """GET /api/notifications/ — list all notifications for the user (latest first)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(user=request.user)
        serializer = NotificationSerializer(notifications, many=True)
        unread_count = notifications.filter(is_read=False).count()
        return Response({
            'notifications': serializer.data,
            'unread_count': unread_count,
        })


class NotificationMarkReadView(APIView):
    """PATCH /api/notifications/<id>/read/ — mark a single notification as read."""
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        try:
            notification = Notification.objects.get(pk=pk, user=request.user)
            notification.is_read = True
            notification.save(update_fields=['is_read'])
            return Response({'status': 'ok'})
        except Notification.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)


class NotificationMarkAllReadView(APIView):
    """PATCH /api/notifications/read-all/ — mark all notifications as read."""
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'status': 'ok'})


class UnreadCountView(APIView):
    """GET /api/notifications/unread-count/ — lightweight poll endpoint."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'unread_count': count})
