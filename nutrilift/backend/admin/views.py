from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from django.contrib.auth import get_user_model
from django.db.models import Q
from .permissions import IsAdminUser
from .models import FAQ
from .serializers import FAQSerializer
from authentications.models import SupportTicket
from authentications.serializers import SupportTicketSerializer, UserProfileSerializer
from challenges.models import Challenge
from challenges.serializers import ChallengeSerializer

User = get_user_model()


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
        in_progress_tickets = SupportTicket.objects.filter(status='in_progress').count()
        
        return Response({
            'total_users': total_users,
            'active_users': active_users,
            'total_challenges': total_challenges,
            'official_challenges': official_challenges,
            'open_support_tickets': open_tickets,
            'in_progress_tickets': in_progress_tickets,
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
    Update challenge (mark as official, activate/deactivate, set payment fields)
    """
    permission_classes = [IsAdminUser]

    def put(self, request, challenge_id):
        try:
            challenge = Challenge.objects.get(id=challenge_id)

            updatable = ['is_official', 'is_active', 'is_paid', 'price', 'currency', 'prize_description']
            for field in updatable:
                if field in request.data:
                    setattr(challenge, field, request.data[field])

            challenge.save()
            serializer = ChallengeSerializer(challenge, context={'request': request})
            return Response(serializer.data)
        except Challenge.DoesNotExist:
            return Response({'detail': 'Challenge not found'}, status=status.HTTP_404_NOT_FOUND)


class AdminChallengeCreateView(APIView):
    """
    POST /api/admin/challenges/create/
    Create an official challenge with optional payment fields.
    """
    permission_classes = [IsAdminUser]

    def post(self, request):
        required = ['name', 'description', 'challenge_type', 'goal_value', 'unit', 'start_date', 'end_date']
        for field in required:
            if not request.data.get(field):
                return Response({'detail': f'{field} is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            challenge = Challenge.objects.create(
                name=request.data['name'],
                description=request.data['description'],
                challenge_type=request.data['challenge_type'],
                goal_value=float(request.data['goal_value']),
                unit=request.data['unit'],
                start_date=request.data['start_date'],
                end_date=request.data['end_date'],
                is_official=request.data.get('is_official', True),
                is_active=True,
                is_paid=request.data.get('is_paid', False),
                price=request.data.get('price', 0),
                currency=request.data.get('currency', 'NPR'),
                prize_description=request.data.get('prize_description', ''),
                default_tasks=[{'label': t} for t in request.data.get('tasks', []) if t],
            )
            serializer = ChallengeSerializer(challenge, context={'request': request})
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)


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



class FAQListView(APIView):
    """
    GET /api/admin/faqs/ - List all FAQs (admin)
    GET /api/faqs/ - List active FAQs (public)
    POST /api/admin/faqs/ - Create FAQ (admin only)
    """
    def get_permissions(self):
        if self.request.path.startswith('/api/admin/'):
            return [IsAdminUser()]
        return []

    def get(self, request):
        # Public endpoint shows only active FAQs
        if request.path.startswith('/api/admin/'):
            faqs = FAQ.objects.all()
        else:
            faqs = FAQ.objects.filter(is_active=True)
        
        category = request.query_params.get('category', '')
        if category:
            faqs = faqs.filter(category=category)
        
        serializer = FAQSerializer(faqs, many=True)
        return Response(serializer.data)

    def post(self, request):
        self.permission_classes = [IsAdminUser]
        self.check_permissions(request)
        
        serializer = FAQSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class FAQDetailView(APIView):
    """
    GET /api/admin/faqs/<faq_id>/ - Get FAQ details
    PUT /api/admin/faqs/<faq_id>/ - Update FAQ
    DELETE /api/admin/faqs/<faq_id>/ - Delete FAQ
    """
    permission_classes = [IsAdminUser]

    def get(self, request, faq_id):
        try:
            faq = FAQ.objects.get(id=faq_id)
            serializer = FAQSerializer(faq)
            return Response(serializer.data)
        except FAQ.DoesNotExist:
            return Response({'detail': 'FAQ not found'}, status=status.HTTP_404_NOT_FOUND)

    def put(self, request, faq_id):
        try:
            faq = FAQ.objects.get(id=faq_id)
            serializer = FAQSerializer(faq, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except FAQ.DoesNotExist:
            return Response({'detail': 'FAQ not found'}, status=status.HTTP_404_NOT_FOUND)

    def delete(self, request, faq_id):
        try:
            faq = FAQ.objects.get(id=faq_id)
            faq.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except FAQ.DoesNotExist:
            return Response({'detail': 'FAQ not found'}, status=status.HTTP_404_NOT_FOUND)
