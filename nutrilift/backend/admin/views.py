from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.utils import timezone
from django.utils.dateparse import parse_date
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

        def _parse_date(value):
            """Parse date string to timezone-aware datetime."""
            if not value:
                return None
            d = parse_date(str(value)[:10])
            if d:
                return timezone.make_aware(timezone.datetime(d.year, d.month, d.day))
            return value

        try:
            challenge = Challenge.objects.create(
                name=request.data['name'],
                description=request.data['description'],
                challenge_type=request.data['challenge_type'],
                goal_value=float(request.data['goal_value']),
                unit=request.data['unit'],
                start_date=_parse_date(request.data['start_date']),
                end_date=_parse_date(request.data['end_date']),
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


class AdminChallengeLeaderboardView(APIView):
    """
    GET /api/admin/challenges/<challenge_id>/leaderboard/
    Returns top participants with rank, progress, and prize_paid status.
    """
    permission_classes = [IsAdminUser]

    def get(self, request, challenge_id):
        try:
            challenge = Challenge.objects.get(id=challenge_id)
        except Challenge.DoesNotExist:
            return Response({'detail': 'Challenge not found'}, status=status.HTTP_404_NOT_FOUND)

        from challenges.models import ChallengeParticipant
        participants = (
            ChallengeParticipant.objects
            .filter(challenge=challenge)
            .select_related('user')
            .order_by('-progress')[:10]
        )

        data = []
        for i, p in enumerate(participants, start=1):
            data.append({
                'rank': i,
                'user_id': str(p.user.id),
                'name': getattr(p.user, 'name', None) or p.user.email,
                'email': p.user.email,
                'avatar_url': getattr(p.user, 'avatar_url', None),
                'progress': p.progress,
                'goal_value': challenge.goal_value,
                'completed': p.completed,
                'prize_paid': p.prize_paid,
                'participant_id': str(p.id),
            })

        now = timezone.now()
        return Response({
            'challenge_id': str(challenge.id),
            'challenge_name': challenge.name,
            'is_paid': challenge.is_paid,
            'prize_description': challenge.prize_description,
            'end_date': challenge.end_date,
            'has_ended': challenge.end_date <= now,
            'leaderboard': data,
        })


class AdminAwardPrizeView(APIView):
    """
    POST /api/admin/challenges/<challenge_id>/award-prize/
    Body: { "participant_id": "<uuid>", "notes": "optional" }
    Marks the participant as prize_paid and sends them a notification.
    """
    permission_classes = [IsAdminUser]

    def post(self, request, challenge_id):
        try:
            challenge = Challenge.objects.get(id=challenge_id)
        except Challenge.DoesNotExist:
            return Response({'detail': 'Challenge not found'}, status=status.HTTP_404_NOT_FOUND)

        participant_id = request.data.get('participant_id')
        if not participant_id:
            return Response({'detail': 'participant_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        from challenges.models import ChallengeParticipant
        try:
            participant = ChallengeParticipant.objects.select_related('user').get(
                id=participant_id, challenge=challenge
            )
        except ChallengeParticipant.DoesNotExist:
            return Response({'detail': 'Participant not found'}, status=status.HTTP_404_NOT_FOUND)

        # Compute rank
        rank = ChallengeParticipant.objects.filter(
            challenge=challenge, progress__gt=participant.progress
        ).count() + 1

        # Persist prize_paid on the participant record
        participant.prize_paid = True
        participant.prize_paid_at = timezone.now()
        if request.data.get('notes'):
            participant.prize_notes = request.data['notes']
        participant.save(update_fields=['prize_paid', 'prize_paid_at', 'prize_notes'])

        # Notify the winner
        try:
            from notifications.utils import notify_prize_awarded
            notify_prize_awarded(
                participant.user,
                challenge.name,
                rank,
                challenge.prize_description or 'Prize',
            )
        except Exception:
            pass

        return Response({
            'detail': f'Prize awarded and notification sent to {participant.user.email}',
            'rank': rank,
            'user': participant.user.email,
            'prize_paid': True,
            'prize_paid_at': participant.prize_paid_at,
        })
