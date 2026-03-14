"""
Integration and property-based tests for the challenge-community-system.

Feature: challenge-community-system
"""
import uuid
from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.db import IntegrityError
from django.utils import timezone
from rest_framework.test import APIClient
from hypothesis import given, settings as h_settings
from hypothesis import strategies as st
from hypothesis.extra.django import TestCase as HypothesisTestCase

from challenges.models import (
    Challenge, ChallengeParticipant, Post, Like,
)

User = get_user_model()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_user(suffix=None):
    """Create a unique test user."""
    uid = suffix or uuid.uuid4().hex[:8]
    return User.objects.create_user(
        email=f'user_{uid}@test.com',
        password='testpass123',
        first_name='Test',
        last_name='User',
    )


def make_challenge(creator, challenge_type='workout', is_active=True, days_ahead=30):
    """Create a challenge ending in the future by default."""
    now = timezone.now()
    return Challenge.objects.create(
        name=f'Challenge {uuid.uuid4().hex[:6]}',
        description='Test challenge',
        challenge_type=challenge_type,
        goal_value=1000.0,
        unit='kcal',
        start_date=now,
        end_date=now + timezone.timedelta(days=days_ahead),
        created_by=creator,
        is_active=is_active,
    )


def make_workout_log(user, calories_burned):
    """Create a WorkoutLog directly to trigger the signal."""
    from workouts.models import WorkoutLog
    return WorkoutLog.objects.create(
        user=user,
        workout_name='Test Workout',
        duration_minutes=30,
        calories_burned=Decimal(str(calories_burned)),
    )


# ---------------------------------------------------------------------------
# 5.1  TC-CG01: WorkoutLog signal increments ChallengeParticipant.progress
# ---------------------------------------------------------------------------

class TCCG01IntegrationTest(TestCase):
    """
    TC-CG01: Create user → create workout challenge → join challenge →
    save WorkoutLog with calories_burned=500 → assert ChallengeParticipant.progress == 500

    Requirements: 16.1
    """

    def test_workout_log_increments_participant_progress(self):
        user = make_user()
        challenge = make_challenge(user, challenge_type='workout')
        ChallengeParticipant.objects.create(challenge=challenge, user=user)

        make_workout_log(user, 500)

        participant = ChallengeParticipant.objects.get(challenge=challenge, user=user)
        self.assertEqual(participant.progress, 500.0)


# ---------------------------------------------------------------------------
# 5.2  TC-CM01: POST /api/community/posts/ → GET /api/community/feed/ contains post id
# ---------------------------------------------------------------------------

class TCCM01IntegrationTest(TestCase):
    """
    TC-CM01: Create user → POST /api/community/posts/ with content "hello" →
    GET /api/community/feed/ → assert response contains post id

    Requirements: 16.2
    """

    def setUp(self):
        self.client = APIClient()
        self.user = make_user()
        self.client.force_authenticate(user=self.user)

    def test_created_post_appears_in_feed(self):
        create_resp = self.client.post(
            '/api/community/posts/',
            {'content': 'hello'},
            format='json',
        )
        self.assertEqual(create_resp.status_code, 201)
        post_id = str(create_resp.data['id'])

        feed_resp = self.client.get('/api/community/feed/')
        self.assertEqual(feed_resp.status_code, 200)

        # Feed is paginated — results are in 'results' key
        results = feed_resp.data.get('results', feed_resp.data)
        ids = [str(p['id']) for p in results]
        self.assertIn(post_id, ids)


# ---------------------------------------------------------------------------
# 5.3  Property 2: Active challenge filter
# ---------------------------------------------------------------------------

@st.composite
def challenge_params(draw):
    """Generate (is_active, days_ahead) pairs for challenge creation."""
    is_active = draw(st.booleans())
    # days_ahead > 0 means future, <= 0 means past/expired
    days_ahead = draw(st.integers(min_value=-10, max_value=60))
    return is_active, days_ahead


class ActiveChallengeFilterPropertyTest(HypothesisTestCase):
    """
    Feature: challenge-community-system, Property 2: Active challenge filter

    Only is_active=True and end_date in future appear in /api/challenges/active/

    Validates: Requirements 3.1
    """

    @given(params=st.lists(challenge_params(), min_size=1, max_size=10))
    @h_settings(max_examples=50, deadline=None)
    def test_active_challenge_filter(self, params):
        # Feature: challenge-community-system, Property 2: Active challenge filter
        user = make_user()
        client = APIClient()
        client.force_authenticate(user=user)

        created_ids = set()
        for is_active, days_ahead in params:
            c = Challenge.objects.create(
                name=f'C {uuid.uuid4().hex[:6]}',
                description='desc',
                challenge_type='workout',
                goal_value=100.0,
                unit='kcal',
                start_date=timezone.now(),
                end_date=timezone.now() + timezone.timedelta(days=days_ahead),
                created_by=user,
                is_active=is_active,
            )
            created_ids.add(str(c.id))

        resp = client.get('/api/challenges/active/')
        self.assertEqual(resp.status_code, 200)

        now = timezone.now()
        for item in resp.data:
            cid = str(item['id'])
            if cid not in created_ids:
                continue  # skip challenges from other hypothesis runs
            c = Challenge.objects.get(id=cid)
            # Property: every returned challenge must be active and in the future
            self.assertTrue(c.is_active, f"Inactive challenge {cid} appeared in active list")
            self.assertGreater(c.end_date, now, f"Expired challenge {cid} appeared in active list")


# ---------------------------------------------------------------------------
# 5.4  Property 4: Leaderboard ordering
# ---------------------------------------------------------------------------

class LeaderboardOrderingPropertyTest(HypothesisTestCase):
    """
    Feature: challenge-community-system, Property 4: Leaderboard ordering invariant

    Result ≤ 10 entries, adjacent pairs satisfy a.progress >= b.progress

    Validates: Requirements 3.4
    """

    @given(progress_values=st.lists(
        st.floats(min_value=0.0, max_value=10000.0, allow_nan=False, allow_infinity=False),
        min_size=1, max_size=50,
    ))
    @h_settings(max_examples=50, deadline=None)
    def test_leaderboard_ordering_and_limit(self, progress_values):
        # Feature: challenge-community-system, Property 4: Leaderboard ordering invariant
        creator = make_user()
        challenge = make_challenge(creator)
        client = APIClient()
        client.force_authenticate(user=creator)

        for progress in progress_values:
            participant_user = make_user()
            ChallengeParticipant.objects.create(
                challenge=challenge,
                user=participant_user,
                progress=progress,
            )

        resp = client.get(f'/api/challenges/{challenge.id}/leaderboard/')
        self.assertEqual(resp.status_code, 200)

        entries = resp.data
        # Property: at most 10 entries
        self.assertLessEqual(len(entries), 10)

        # Property: descending order
        for i in range(len(entries) - 1):
            self.assertGreaterEqual(
                entries[i]['progress'],
                entries[i + 1]['progress'],
                f"Leaderboard not sorted at positions {i} and {i+1}",
            )


# ---------------------------------------------------------------------------
# 5.5  Property 5: Signal progress increment
# ---------------------------------------------------------------------------

class SignalProgressIncrementPropertyTest(HypothesisTestCase):
    """
    Feature: challenge-community-system, Property 5: Signal progress increment

    WorkoutLog save increments ChallengeParticipant.progress by calories_burned

    Validates: Requirements 5.1, 5.2
    """

    @given(calories=st.floats(min_value=1.0, max_value=5000.0, allow_nan=False, allow_infinity=False))
    @h_settings(max_examples=50, deadline=None)
    def test_signal_increments_progress(self, calories):
        # Feature: challenge-community-system, Property 5: Signal progress increment
        user = make_user()
        challenge = make_challenge(user, challenge_type='workout')
        participant = ChallengeParticipant.objects.create(
            challenge=challenge, user=user, progress=0.0,
        )
        before = participant.progress

        make_workout_log(user, calories)

        participant.refresh_from_db()
        expected = before + calories
        self.assertAlmostEqual(
            participant.progress,
            expected,
            places=2,
            msg=f"Progress should have increased by {calories}",
        )


# ---------------------------------------------------------------------------
# 5.6  Property 9: Feed filter and ordering
# ---------------------------------------------------------------------------

@st.composite
def post_params(draw):
    """Generate is_removed booleans for post creation."""
    return draw(st.booleans())


class FeedFilterOrderingPropertyTest(HypothesisTestCase):
    """
    Feature: challenge-community-system, Property 9: Feed filter and ordering

    No is_removed posts in feed; adjacent pairs satisfy a.created_at >= b.created_at

    Validates: Requirements 6.1
    """

    @given(post_flags=st.lists(post_params(), min_size=2, max_size=8))
    @h_settings(max_examples=20, deadline=None)
    def test_feed_excludes_removed_and_is_ordered(self, post_flags):
        # Feature: challenge-community-system, Property 9: Feed filter and ordering
        user = make_user()
        client = APIClient()
        client.force_authenticate(user=user)

        created_ids = set()
        for is_removed in post_flags:
            p = Post.objects.create(
                user=user,
                content=f'Post {uuid.uuid4().hex[:6]}',
                is_removed=is_removed,
            )
            created_ids.add(str(p.id))

        resp = client.get('/api/community/feed/')
        self.assertEqual(resp.status_code, 200)

        results = resp.data.get('results', resp.data)
        # Filter to only posts created in this test run
        our_results = [r for r in results if str(r['id']) in created_ids]

        # Property: no is_removed posts
        for item in our_results:
            post = Post.objects.get(id=item['id'])
            self.assertFalse(post.is_removed, f"Removed post {item['id']} appeared in feed")

        # Property: descending created_at order
        for i in range(len(our_results) - 1):
            self.assertGreaterEqual(
                our_results[i]['created_at'],
                our_results[i + 1]['created_at'],
                f"Feed not sorted at positions {i} and {i+1}",
            )


# ---------------------------------------------------------------------------
# 5.7  Property 10: Post content round-trip
# ---------------------------------------------------------------------------

class PostContentRoundTripPropertyTest(HypothesisTestCase):
    """
    Feature: challenge-community-system, Property 10: Post content round-trip

    Created content equals fetched content

    Validates: Requirements 6.2, 16.3
    """

    @given(content=st.text(
        alphabet=st.characters(blacklist_characters='\x00'),
        min_size=1,
        max_size=1000,
    ).filter(lambda s: s.strip()))
    @h_settings(max_examples=20, deadline=None)
    def test_post_content_round_trip(self, content):
        # Feature: challenge-community-system, Property 10: Post content round-trip
        user = make_user()
        client = APIClient()
        client.force_authenticate(user=user)

        create_resp = client.post(
            '/api/community/posts/',
            {'content': content},
            format='json',
        )
        self.assertEqual(create_resp.status_code, 201)
        post_id = str(create_resp.data['id'])

        feed_resp = client.get('/api/community/feed/')
        self.assertEqual(feed_resp.status_code, 200)

        results = feed_resp.data.get('results', feed_resp.data)
        matching = [p for p in results if str(p['id']) == post_id]
        self.assertEqual(len(matching), 1, "Created post not found in feed")
        self.assertEqual(matching[0]['content'], content, "Content was mutated on round-trip")


# ---------------------------------------------------------------------------
# 5.8  Property 12: Like toggle round-trip
# ---------------------------------------------------------------------------

class LikeToggleRoundTripPropertyTest(HypothesisTestCase):
    """
    Feature: challenge-community-system, Property 12: Like toggle round-trip

    Like then unlike returns like_count to original value

    Validates: Requirements 6.5
    """

    @given(initial_likes=st.integers(min_value=0, max_value=100))
    @h_settings(max_examples=20, deadline=None)
    def test_like_toggle_round_trip(self, initial_likes):
        # Feature: challenge-community-system, Property 12: Like toggle round-trip
        owner = make_user()
        liker = make_user()
        post = Post.objects.create(
            user=owner,
            content='Like test post',
            like_count=initial_likes,
        )

        client = APIClient()
        client.force_authenticate(user=liker)

        # Like the post
        like_resp = client.post(f'/api/community/posts/{post.id}/like/')
        self.assertEqual(like_resp.status_code, 201)

        # Unlike the post (toggle off)
        unlike_resp = client.post(f'/api/community/posts/{post.id}/like/')
        self.assertEqual(unlike_resp.status_code, 200)
        self.assertFalse(unlike_resp.data.get('liked', True))

        # Property: like_count returns to original value
        post.refresh_from_db()
        self.assertEqual(
            post.like_count,
            initial_likes,
            f"like_count should be {initial_likes} after toggle, got {post.like_count}",
        )


# ---------------------------------------------------------------------------
# 5.9  Property 16: Uniqueness constraints — duplicate Like raises IntegrityError
# ---------------------------------------------------------------------------

class UniquenessConstraintsPropertyTest(TestCase):
    """
    Feature: challenge-community-system, Property 16: Uniqueness constraints

    Duplicate Like for same (post, user) raises IntegrityError

    Validates: Requirements 1.4, 2.3, 2.5
    """

    def test_duplicate_like_raises_integrity_error(self):
        # Feature: challenge-community-system, Property 16: Uniqueness constraints
        user = make_user()
        post = Post.objects.create(user=user, content='Unique like test')

        Like.objects.create(post=post, user=user)

        with self.assertRaises(IntegrityError):
            Like.objects.create(post=post, user=user)
