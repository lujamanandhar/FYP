from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.pagination import PageNumberPagination

from .models import (
    Challenge, ChallengeParticipant, UserBadge, Streak,
    Post, Comment, Like, Report, Follow, ChallengeDailyLog,
)
from .serializers import (
    ChallengeSerializer, LeaderboardSerializer, UserBadgeSerializer,
    StreakSerializer, PostSerializer, CommentSerializer,
    UserProfileSerializer, ChallengeDailyLogSerializer,
)

User = get_user_model()


def _validated_default_tasks(raw):
    """Validate and normalise default_tasks list. Each item must have a non-empty 'label'."""
    if not isinstance(raw, list):
        return []
    result = []
    for item in raw:
        if isinstance(item, dict) and isinstance(item.get('label'), str) and item['label'].strip():
            result.append({'label': item['label'].strip()})
    return result


# ---------------------------------------------------------------------------
# Pagination
# ---------------------------------------------------------------------------

class FeedPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'


# ---------------------------------------------------------------------------
# Challenge views
# ---------------------------------------------------------------------------

class ActiveChallengeListView(APIView):
    """
    GET /api/challenges/active/
    Returns challenges where is_active=True AND end_date > now.
    Requirements: 3.1
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        challenges = Challenge.objects.filter(
            is_active=True,
            end_date__gt=timezone.now(),
        ).order_by('-is_official', '-created_at')
        serializer = ChallengeSerializer(challenges, many=True, context={'request': request})
        return Response(serializer.data)


class CreateChallengeView(APIView):
    """
    POST /api/challenges/create/
    Any authenticated user can create a challenge. is_official=False by default.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data
        required = ['name', 'description', 'challenge_type', 'goal_value', 'unit', 'start_date', 'end_date']
        for field in required:
            if not data.get(field):
                return Response({'detail': f'{field} is required.'}, status=status.HTTP_400_BAD_REQUEST)

        if data['challenge_type'] not in ['nutrition', 'workout', 'mixed']:
            return Response({'detail': 'Invalid challenge_type.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            challenge = Challenge.objects.create(
                name=data['name'],
                description=data['description'],
                challenge_type=data['challenge_type'],
                goal_value=float(data['goal_value']),
                unit=data['unit'],
                start_date=data['start_date'],
                end_date=data['end_date'],
                created_by=request.user,
                is_official=False,
                is_active=True,
                default_tasks=_validated_default_tasks(data.get('default_tasks', [])),
            )
        except Exception as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        serializer = ChallengeSerializer(challenge, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class JoinChallengeView(APIView):
    """
    POST /api/challenges/{id}/join/
    Creates a ChallengeParticipant. Returns 400 if already joined.
    Requirements: 3.2
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        challenge = Challenge.objects.filter(pk=pk).first()
        if challenge is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        if ChallengeParticipant.objects.filter(challenge=challenge, user=request.user).exists():
            return Response(
                {'detail': 'Already joined this challenge'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        ChallengeParticipant.objects.create(challenge=challenge, user=request.user)
        return Response({'detail': 'Joined successfully.'}, status=status.HTTP_201_CREATED)


class DeleteChallengeView(APIView):
    """
    DELETE /api/challenges/{id}/
    Owner-only delete. Returns 204.
    """
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        challenge = Challenge.objects.filter(pk=pk).first()
        if challenge is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        if challenge.created_by != request.user:
            return Response({'detail': 'You do not have permission.'}, status=status.HTTP_403_FORBIDDEN)
        challenge.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class LeaveChallengeView(APIView):
    """
    DELETE /api/challenges/{id}/leave/
    Deletes the ChallengeParticipant record. Returns 204.
    Requirements: 3.5
    """
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        participant = ChallengeParticipant.objects.filter(
            challenge_id=pk, user=request.user
        ).first()
        if participant is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        participant.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class LeaderboardView(APIView):
    """
    GET /api/challenges/{id}/leaderboard/
    Top 10 participants ordered by -progress.
    Requirements: 3.4
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        if not Challenge.objects.filter(pk=pk).exists():
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        participants = (
            ChallengeParticipant.objects
            .filter(challenge_id=pk)
            .select_related('user')
            .order_by('-progress')[:10]
        )
        # Annotate rank in Python (1-based)
        entries = []
        for i, p in enumerate(participants, start=1):
            p.rank = i
            entries.append(p)
        serializer = LeaderboardSerializer(entries, many=True)
        return Response(serializer.data)


# ---------------------------------------------------------------------------
# Badge & Streak views
# ---------------------------------------------------------------------------

class BadgeView(APIView):
    """
    GET /api/challenges/badges/
    Returns UserBadge records for the requesting user.
    Requirements: 4.1
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user_badges = UserBadge.objects.filter(user=request.user).select_related('badge')
        serializer = UserBadgeSerializer(user_badges, many=True)
        return Response(serializer.data)


class StreakView(APIView):
    """
    GET /api/challenges/streak/
    Returns the Streak for the requesting user, or zeros if none exists.
    If the user missed yesterday, returns 0 for current_streak.
    Requirements: 4.2
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from django.utils import timezone
        
        try:
            streak = Streak.objects.get(user=request.user)
            
            # Check if streak is still valid
            today = timezone.now().date()
            yesterday = today - timezone.timedelta(days=1)
            
            # If last active was today or yesterday, streak is valid
            if streak.last_active_date in (today, yesterday):
                current_streak = streak.current_streak
            else:
                # Missed a day - streak is broken, return 0
                current_streak = 0
            
            return Response({
                'current_streak': current_streak,
                'longest_streak': streak.longest_streak,
                'last_active_date': streak.last_active_date,
            })
        except Streak.DoesNotExist:
            return Response({
                'current_streak': 0,
                'longest_streak': 0,
                'last_active_date': None,
            })


# ---------------------------------------------------------------------------
# Community / Post views
# ---------------------------------------------------------------------------

class FeedView(APIView):
    """
    GET /api/community/feed/
    Paginated (page_size=20) posts where is_removed=False, ordered by -created_at.
    Requirements: 6.1
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        posts = Post.objects.filter(is_removed=False).order_by('-created_at')
        paginator = FeedPagination()
        page = paginator.paginate_queryset(posts, request)
        serializer = PostSerializer(page, many=True, context={'request': request})
        return paginator.get_paginated_response(serializer.data)


class CreatePostView(APIView):
    """
    POST /api/community/posts/
    Creates a new Post. Returns 201.
    Requirements: 6.2
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        content = request.data.get('content', '')
        image_urls = request.data.get('image_urls', [])
        if not content and not image_urls:
            return Response(
                {'detail': 'Content or image is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        post = Post.objects.create(
            user=request.user,
            content=content,
            image_urls=image_urls if isinstance(image_urls, list) else [],
        )
        serializer = PostSerializer(post, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class DeletePostView(APIView):
    """
    DELETE /api/community/posts/{id}/  — delete post (owner only, 204)
    PATCH  /api/community/posts/{id}/  — edit post content (owner only, 200)
    Requirements: 6.3, 6.4
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        post = Post.objects.filter(pk=pk).first()
        if post is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        if post.user != request.user:
            return Response(
                {'detail': 'You do not have permission to perform this action.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        content = request.data.get('content', '').strip()
        if not content:
            return Response({'detail': 'Content is required.'}, status=status.HTTP_400_BAD_REQUEST)
        post.content = content
        post.save(update_fields=['content'])
        serializer = PostSerializer(post, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

    def delete(self, request, pk):
        post = Post.objects.filter(pk=pk).first()
        if post is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        if post.user != request.user:
            return Response(
                {'detail': 'You do not have permission to perform this action.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        post.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class LikePostView(APIView):
    """
    POST /api/community/posts/{id}/like/
    Toggles Like: create if not exists (201), delete if exists (200 {"liked": false}).
    Updates Post.like_count.
    Requirements: 6.5
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        post = Post.objects.filter(pk=pk).first()
        if post is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        like = Like.objects.filter(post=post, user=request.user).first()
        if like:
            like.delete()
            Post.objects.filter(pk=pk).update(like_count=post.like_count - 1)
            return Response({'liked': False, 'like_count': max(0, post.like_count - 1)}, status=status.HTTP_200_OK)
        else:
            Like.objects.create(post=post, user=request.user)
            Post.objects.filter(pk=pk).update(like_count=post.like_count + 1)
            return Response({'liked': True, 'like_count': post.like_count + 1}, status=status.HTTP_201_CREATED)


class CommentPostView(APIView):
    """
    POST /api/community/posts/{id}/comment/
    Creates a Comment and increments Post.comment_count. Returns 201.
    Requirements: 6.6
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        post = Post.objects.filter(pk=pk).first()
        if post is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        content = request.data.get('content', '').strip()
        if not content:
            return Response({'detail': 'Content is required.'}, status=status.HTTP_400_BAD_REQUEST)
        comment = Comment.objects.create(post=post, user=request.user, content=content)
        Post.objects.filter(pk=pk).update(comment_count=post.comment_count + 1)
        serializer = CommentSerializer(comment)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class ListCommentsView(APIView):
    """
    GET /api/community/posts/{id}/comments/
    Lists Comments ordered by created_at ascending.
    Requirements: 6.7
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        if not Post.objects.filter(pk=pk).exists():
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        comments = Comment.objects.filter(post_id=pk).order_by('created_at')
        serializer = CommentSerializer(comments, many=True)
        return Response(serializer.data)


class ReportPostView(APIView):
    """
    POST /api/community/posts/{id}/report/
    Creates a Report with status=pending, sets Post.is_reported=True. Returns 201.
    Requirements: 6.8
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        post = Post.objects.filter(pk=pk).first()
        if post is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        reason = request.data.get('reason', '').strip()
        if not reason:
            return Response({'detail': 'Reason is required.'}, status=status.HTTP_400_BAD_REQUEST)
        Report.objects.create(post=post, reported_by=request.user, reason=reason, status='pending')
        Post.objects.filter(pk=pk).update(is_reported=True)
        return Response({'detail': 'Report submitted.'}, status=status.HTTP_201_CREATED)


# ---------------------------------------------------------------------------
# User / Social views
# ---------------------------------------------------------------------------

class UserProfileView(APIView):
    """
    GET /api/community/users/{id}/profile/
    Returns user stats + physical/fitness info.
    Requirements: 7.1
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        target = User.objects.filter(pk=pk).first()
        if target is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        follower_count = Follow.objects.filter(following=target).count()
        following_count = Follow.objects.filter(follower=target).count()
        post_count = Post.objects.filter(user=target, is_removed=False).count()
        is_following_me = Follow.objects.filter(
            follower=request.user, following=target
        ).exists()
        data = {
            'id': target.pk,
            'username': getattr(target, 'name', None) or target.email,
            'avatar_url': getattr(target, 'avatar_url', None),
            'follower_count': follower_count,
            'following_count': following_count,
            'post_count': post_count,
            'is_following_me': is_following_me,
            # Physical & fitness info
            'gender': getattr(target, 'gender', None) or None,
            'age_group': getattr(target, 'age_group', None) or None,
            'height': getattr(target, 'height', None),
            'weight': getattr(target, 'weight', None),
            'fitness_level': getattr(target, 'fitness_level', None) or None,
        }
        return Response(data)


class FollowView(APIView):
    """
    POST /api/community/users/{id}/follow/
    Toggles Follow: create if not exists (201), delete if exists (200 {"following": false}).
    Requirements: 7.2
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        target = User.objects.filter(pk=pk).first()
        if target is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        if target == request.user:
            return Response(
                {'detail': 'You cannot follow yourself.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        follow = Follow.objects.filter(follower=request.user, following=target).first()
        if follow:
            follow.delete()
            return Response({'following': False}, status=status.HTTP_200_OK)
        else:
            Follow.objects.create(follower=request.user, following=target)
            return Response({'following': True}, status=status.HTTP_201_CREATED)


class UserPostsView(APIView):
    """
    GET /api/community/users/{id}/posts/
    Non-removed Posts by the target user, ordered by -created_at.
    Requirements: 7.3
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        target = User.objects.filter(pk=pk).first()
        if target is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        posts = Post.objects.filter(user=target, is_removed=False).order_by('-created_at')
        serializer = PostSerializer(posts, many=True, context={'request': request})
        return Response(serializer.data)


class UserFollowersView(APIView):
    """
    GET /api/community/users/{id}/followers/
    Lists users who follow the target user.
    Requirements: 7.4
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        target = User.objects.filter(pk=pk).first()
        if target is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        followers = Follow.objects.filter(following=target).select_related('follower')
        data = []
        for f in followers:
            user = f.follower
            data.append({
                'id': user.pk,
                'username': getattr(user, 'name', None) or user.email,
                'avatar_url': getattr(user, 'avatar_url', None),
            })
        return Response(data)


class UserChallengeStatsView(APIView):
    """
    GET /api/community/users/{id}/challenge-stats/
    Returns challenge participation stats for a user's profile achievements tab.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        target = User.objects.filter(pk=pk).first()
        if target is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        participants = ChallengeParticipant.objects.filter(user=target).select_related('challenge')
        total_joined = participants.count()
        completed = participants.filter(completed=True).count()
        total_days_logged = 0
        challenge_list = []
        for p in participants:
            logs_done = ChallengeDailyLog.objects.filter(participant=p, is_complete=True).count()
            total_days_logged += logs_done
            challenge_list.append({
                'name': p.challenge.name,
                'challenge_type': p.challenge.challenge_type,
                'progress': p.progress,
                'goal_value': p.challenge.goal_value,
                'unit': p.challenge.unit,
                'completed': p.completed,
                'days_logged': logs_done,
            })

        # Streak
        streak_val = 0
        try:
            from .models import Streak
            streak_val = Streak.objects.get(user=target).current_streak
        except Exception:
            pass

        return Response({
            'total_joined': total_joined,
            'total_completed': completed,
            'total_days_logged': total_days_logged,
            'current_streak': streak_val,
            'challenges': challenge_list,
        })


class UserFollowingView(APIView):
    """
    GET /api/community/users/{id}/following/
    Lists users that the target user follows.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        target = User.objects.filter(pk=pk).first()
        if target is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        following = Follow.objects.filter(follower=target).select_related('following')
        data = []
        for f in following:
            user = f.following
            data.append({
                'id': user.pk,
                'username': getattr(user, 'name', None) or user.email,
                'avatar_url': getattr(user, 'avatar_url', None),
            })
        return Response(data)
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        target = User.objects.filter(pk=pk).first()
        if target is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        followers = Follow.objects.filter(following=target).select_related('follower')
        data = []
        for f in followers:
            user = f.follower
            data.append({
                'id': user.pk,
                'username': getattr(user, 'name', None) or user.email,
                'avatar_url': getattr(user, 'avatar_url', None),
            })
        return Response(data)


# ---------------------------------------------------------------------------
# Daily Log views
# ---------------------------------------------------------------------------

class DailyLogView(APIView):
    """
    GET  /api/challenges/<uuid:pk>/daily-log/
         get_or_create today's log; day_number = (today - joined_at.date()).days + 1
         Populates task_items from challenge.default_tasks on first creation.
         Returns 404 if user has not joined the challenge.

    PATCH /api/challenges/<uuid:pk>/daily-log/
         Update task_items and/or media_urls for today's log.

    Requirements: 19.1–19.5
    """
    permission_classes = [IsAuthenticated]

    def _get_participant(self, request, pk):
        return ChallengeParticipant.objects.filter(
            challenge_id=pk, user=request.user
        ).select_related('challenge').first()

    def get(self, request, pk):
        participant = self._get_participant(request, pk)
        if participant is None:
            return Response({'detail': 'Not joined this challenge.'}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()
        day_number = (today - participant.joined_at.date()).days + 1

        log, created = ChallengeDailyLog.objects.get_or_create(
            participant=participant,
            day_number=day_number,
            defaults={
                'task_items': [
                    {'label': t.get('label', ''), 'completed': False}
                    for t in (participant.challenge.default_tasks or [])
                ],
                'media_urls': [],
            },
        )
        serializer = ChallengeDailyLogSerializer(log)
        return Response(serializer.data)

    def patch(self, request, pk):
        participant = self._get_participant(request, pk)
        if participant is None:
            return Response({'detail': 'Not joined this challenge.'}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()
        day_number = (today - participant.joined_at.date()).days + 1

        log = ChallengeDailyLog.objects.filter(
            participant=participant, day_number=day_number
        ).first()
        if log is None:
            return Response({'detail': 'Log not found for today.'}, status=status.HTTP_404_NOT_FOUND)

        if 'task_items' in request.data:
            log.task_items = request.data['task_items']
        if 'media_urls' in request.data:
            log.media_urls = request.data['media_urls']
        log.save()
        serializer = ChallengeDailyLogSerializer(log)
        return Response(serializer.data)


class DailyLogCompleteView(APIView):
    """
    POST /api/challenges/<uuid:pk>/daily-log/complete/
    Marks today's log complete. Optionally shares to community feed.
    Returns 400 if already complete.
    Requirements: 20.1–20.4
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        participant = ChallengeParticipant.objects.filter(
            challenge_id=pk, user=request.user
        ).select_related('challenge').first()
        if participant is None:
            return Response({'detail': 'Not joined this challenge.'}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()
        day_number = (today - participant.joined_at.date()).days + 1

        log = ChallengeDailyLog.objects.filter(
            participant=participant, day_number=day_number
        ).first()
        if log is None:
            return Response({'detail': 'Log not found for today.'}, status=status.HTTP_404_NOT_FOUND)

        if log.is_complete:
            return Response({'detail': 'Day already completed.'}, status=status.HTTP_400_BAD_REQUEST)

        log.is_complete = True
        log.completed_at = timezone.now()
        log.save()

        # Increment participant progress by 1 completed day
        participant.progress = participant.progress + 1
        participant.save(update_fields=['progress'])

        # Update streak for this user
        from .signals import _update_streak, _award_badges
        _update_streak(request.user)
        _award_badges(request.user)

        shared_post = None
        share = request.data.get('share_to_community', False)
        if share:
            challenge_name = participant.challenge.name
            content = f"I completed Day {day_number} of {challenge_name}! 💪"
            # Only include non-video media as image_urls
            image_urls = [
                m['url'] for m in (log.media_urls or [])
                if not m.get('is_video', False)
            ]
            shared_post = Post.objects.create(
                user=request.user,
                content=content,
                image_urls=image_urls,
            )

        log_data = ChallengeDailyLogSerializer(log).data
        post_data = PostSerializer(shared_post, context={'request': request}).data if shared_post else None
        return Response({
            'log': log_data,
            'shared_post': post_data,
            'participant_progress': participant.progress,
        }, status=status.HTTP_200_OK)


class DailyLogListView(APIView):
    """
    GET /api/challenges/<uuid:pk>/daily-logs/
    Returns all logs for the participant ordered by day_number ascending.
    Requirements: 19.6, 19.7
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        participant = ChallengeParticipant.objects.filter(
            challenge_id=pk, user=request.user
        ).first()
        if participant is None:
            return Response({'detail': 'Not joined this challenge.'}, status=status.HTTP_404_NOT_FOUND)

        logs = ChallengeDailyLog.objects.filter(participant=participant).order_by('day_number')
        serializer = ChallengeDailyLogSerializer(logs, many=True)
        return Response(serializer.data)
