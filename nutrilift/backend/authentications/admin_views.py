from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.pagination import PageNumberPagination
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from .models import SupportTicket
from .serializers import SupportTicketSerializer, UserProfileSerializer
from challenges.models import Challenge
from challenges.serializers import ChallengeSerializer

User = get_user_model()


class IsAdminUser(IsAuthenticated):
    """Permission class to check if user is admin/staff"""
    def has_permission(self, request, view):
        return super().has_permission(request, view) and request.user.is_staff


class AdminPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class AdminDashboardView(APIView):
    """
    GET /api/admin/dashboard/
    Returns admin dashboard statistics
    """
    permission_classes = [IsAdminUser]

    def get(self, request):
        total_users = User.objects.count()
        active_users = User.objects.filter(is_active=True).count()
        total_challenges = Challenge.objects.count()
        official_challenges = Challenge.objects.filter(is_official=True).count()
        open_tickets = SupportTicket.objects.filter(status='open').count()
        
        return Response({
            'total_users': total_users,
            'active_users': active_users,
            'total_challenges': total_challenges,
            'official_challenges': official_challenges,
            'open_support_tickets': open_tickets,
        })


class AdminUserListView(APIView):
    """
    GET /api/admin/users/
    Returns paginated list of all users with search
    """
    permission_classes = [IsAdminUser]
    pagination_class = AdminPagination

    def get(self, request):
        search = request.query_params.get('search', '')
        users = User.objects.all()
        
        if search:
            users = users.filter(
                Q(email__icontains=search) | 
                Q(name__icontains=search)
            )
        
        users = users.order_by('-created_at')
        
        paginator = self.pagination_class()
        page = paginator.paginate_queryset(users, request)
        
        serializer = UserProfileSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class AdminUserDetailView(APIView):
    """
    GET /api/admin/users/<user_id>/
    PUT /api/admin/users/<user_id>/
    Returns or updates user details
    """
    permission_classes = [IsAdminUser]

    def get(self, request, user_id):
        try:
            user = User.objects.get(id=user_id)
            serializer = UserProfileSerializer(user)
            return Response(serializer.data)
        except User.DoesNotExist:
            return Response({'detail': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    def put(self, request, user_id):
        try:
            user = User.objects.get(id=user_id)
            
            # Allow admin to update user status
            if 'is_active' in request.data:
                user.is_active = request.data['is_active']
            if 'is_staff' in request.data:
                user.is_staff = request.data['is_staff']
            
            user.save()
            serializer = UserProfileSerializer(user)
            return Response(serializer.data)
        except User.DoesNotExist:
            return Response({'detail': 'User not found'}, status=status.HTTP_404_NOT_FOUND)


class AdminChallengeListView(APIView):
    """
    GET /api/admin/challenges/
    Returns all challenges for admin management
    """
    permission_classes = [IsAdminUser]
    pagination_class = AdminPagination

    def get(self, request):
        challenges = Challenge.objects.all().order_by('-created_at')
        
        paginator = self.pagination_class()
        page = paginator.paginate_queryset(challenges, request)
        
        serializer = ChallengeSerializer(page, many=True, context={'request': request})
        return paginator.get_paginated_response(serializer.data)


class AdminChallengeUpdateView(APIView):
    """
    PUT /api/admin/challenges/<challenge_id>/
    Update challenge (mark as official, activate/deactivate)
    """
    permission_classes = [IsAdminUser]

    def put(self, request, challenge_id):
        try:
            challenge = Challenge.objects.get(id=challenge_id)
            
            if 'is_official' in request.data:
                challenge.is_official = request.data['is_official']
            if 'is_active' in request.data:
                challenge.is_active = request.data['is_active']
            
            challenge.save()
            serializer = ChallengeSerializer(challenge, context={'request': request})
            return Response(serializer.data)
        except Challenge.DoesNotExist:
            return Response({'detail': 'Challenge not found'}, status=status.HTTP_404_NOT_FOUND)


class AdminSupportTicketListView(APIView):
    """
    GET /api/admin/support-tickets/
    Returns all support tickets with filtering
    """
    permission_classes = [IsAdminUser]
    pagination_class = AdminPagination

    def get(self, request):
        status_filter = request.query_params.get('status', '')
        tickets = SupportTicket.objects.all()
        
        if status_filter:
            tickets = tickets.filter(status=status_filter)
        
        tickets = tickets.order_by('-created_at')
        
        paginator = self.pagination_class()
        page = paginator.paginate_queryset(tickets, request)
        
        serializer = SupportTicketSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class AdminSupportTicketUpdateView(APIView):
    """
    PUT /api/admin/support-tickets/<ticket_id>/
    Update support ticket status and admin notes
    """
    permission_classes = [IsAdminUser]

    def put(self, request, ticket_id):
        try:
            ticket = SupportTicket.objects.get(id=ticket_id)
            
            if 'status' in request.data:
                ticket.status = request.data['status']
            if 'admin_notes' in request.data:
                ticket.admin_notes = request.data['admin_notes']
            
            ticket.save()
            serializer = SupportTicketSerializer(ticket)
            return Response(serializer.data)
        except SupportTicket.DoesNotExist:
            return Response({'detail': 'Ticket not found'}, status=status.HTTP_404_NOT_FOUND)
