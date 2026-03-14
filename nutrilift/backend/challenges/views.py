from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.pagination import PageNumberPagination

from .models import (
    Challenge, ChallengeParticipant, UserBadge, Streak,
    Post, Comment, Like, Report, Follow,
)
from .serializers import (
    ChallengeSerializer, LeaderboardSerializer, UserBadgeSerializer,
    StreakSerializer, PostSerializer, CommentSerializer,
    UserProfileSerializer,
)

User = get_user_model()


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
        )
        serializer = ChallengeSerializer(challenges, many=True, context={'request': request})
        return Response(serializer.data)


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
    Requirements: 4.2
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            streak = Streak.objects.get(user=request.user)
            serializer = StreakSerializer(streak)
            return Response(serializer.data)
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
            return Response({'liked': False}, status=status.HTTP_200_OK)
        else:
            Like.objects.create(post=post, user=request.user)
            Post.objects.filter(pk=pk).update(like_count=post.like_count + 1)
            return Response({'liked': True}, status=status.HTTP_201_CREATED)


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
    Returns user stats: id, username, avatar_url, follower_count, following_count,
    post_count, is_following_me.
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
        }
        serializer = UserProfileSerializer(data)
        return Response(serializer.data)


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
