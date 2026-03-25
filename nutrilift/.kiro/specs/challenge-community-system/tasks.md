# Implementation Plan: Challenge & Community System

## Overview

Backend-first implementation: scaffold the `challenges` Django app, wire signals, then build Flutter API services, providers, and screens. Existing frontend scaffold files are enhanced — not replaced.

## Tasks

- [x] 1. Backend: scaffold `challenges` Django app and register it
  - Create `backend/challenges/__init__.py`, `apps.py`, `admin.py`, `migrations/__init__.py`
  - Write all models in `backend/challenges/models.py` (Challenge, ChallengeParticipant, Badge, UserBadge, Streak, Post, Comment, Like, Report, Follow) exactly as specified in the design
  - Register `'challenges'` in `INSTALLED_APPS` in `backend/backend/settings.py`
  - Run `python manage.py makemigrations challenges` to generate initial migration
  - Register all models in `backend/challenges/admin.py`
  - _Requirements: 1.1–1.6, 2.1–2.6, 15.1_

- [x] 2. Backend: serializers
  - Write `backend/challenges/serializers.py` with DRF serializers for all models
  - `ChallengeSerializer` must include computed `participant_progress` field (0 if not joined) using `context['request'].user`
  - `PostSerializer` must include computed `is_liked_by_me` boolean
  - `LeaderboardSerializer` must include `rank`, `user_id`, `username`, `avatar_url`, `progress`
  - _Requirements: 3.1, 3.4, 4.1, 4.2, 6.1, 7.1_

- [x] 3. Backend: views and URL routing
  - Write `backend/challenges/views.py` with all ViewSets and APIViews: `ChallengeViewSet` (list active, join, leave), `LeaderboardView`, `BadgeView`, `StreakView`, `PostViewSet` (feed, create, delete, like, comment, report), `UserProfileView`, `FollowView`, `UserPostsView`, `UserFollowersView`
  - Write `backend/challenges/urls.py` with URL patterns for both `api/challenges/` and `api/community/` namespaces
  - Add `path('api/challenges/', include('challenges.urls'))` and `path('api/community/', include('challenges.urls'))` in `backend/backend/urls.py`
  - All views must use `IsAuthenticated` permission class; return 401 for unauthenticated requests
  - Feed endpoint must paginate at page size 20, ordered by descending `created_at`, excluding `is_removed` posts
  - Leaderboard must return top 10 participants ordered by descending `progress`
  - _Requirements: 3.1–3.6, 4.1–4.3, 6.1–6.8, 7.1–7.5, 15.2, 15.3_

- [x] 4. Backend: signals
  - Write `backend/challenges/signals.py` with two handlers:
    - `handle_workout_log_saved`: post_save on `workouts.WorkoutLog` — increments progress on active workout/mixed `ChallengeParticipant` records, updates streak, checks completion, awards badges
    - `handle_intake_log_saved`: post_save on `nutrition.IntakeLog` — increments progress on active nutrition/mixed `ChallengeParticipant` records, updates streak, checks completion, awards badges
  - Wrap all signal logic in `try/except`; log errors at `ERROR` level — never let signal failure break the originating save
  - Connect signals in `backend/challenges/apps.py` `ready()` method
  - Streak logic: yesterday → increment; today → no-op; otherwise → reset to 1; update `longest_streak` if exceeded
  - Badge award: on completion, find active badges with `criteria={"type": "challenge_complete"}` not yet earned, create `UserBadge` records
  - _Requirements: 5.1–5.5_

- [x] 5. Backend: integration and property-based tests
  - Write `backend/challenges/tests.py` using Django `TestCase` and `hypothesis`
  - [x] 5.1 Write integration test TC-CG01: user joins workout challenge → save WorkoutLog with `calories_burned=500` → assert `ChallengeParticipant.progress == 500`
    - _Requirements: 16.1_
  - [x] 5.2 Write integration test TC-CM01: POST `/api/community/posts/` with content "hello" → GET `/api/community/feed/` → assert response contains post `id`
    - _Requirements: 16.2_
  - [x] 5.3 Write property test for Property 2: Active challenge filter — only `is_active=True` and `end_date` in future appear in `/api/challenges/active/`
    - **Property 2: Active Challenge Filter**
    - **Validates: Requirements 3.1**
  - [x] 5.4 Write property test for Property 4: Leaderboard ordering — result ≤ 10 entries, adjacent pairs satisfy `a.progress >= b.progress`
    - **Property 4: Leaderboard Ordering Invariant**
    - **Validates: Requirements 3.4**
  - [x] 5.5 Write property test for Property 5: Signal progress increment — WorkoutLog save increments `ChallengeParticipant.progress` by `calories_burned`
    - **Property 5: Signal Progress Increment**
    - **Validates: Requirements 5.1, 5.2**
  - [x] 5.6 Write property test for Property 9: Feed filter and ordering — no `is_removed` posts, descending `created_at`
    - **Property 9: Feed Filter and Ordering**
    - **Validates: Requirements 6.1**
  - [x] 5.7 Write property test for Property 10: Post content round-trip — created content equals fetched content
    - **Property 10: Post Content Round-Trip**
    - **Validates: Requirements 6.2, 16.3**
  - [x] 5.8 Write property test for Property 12: Like toggle round-trip — like then unlike returns `like_count` to original value
    - **Property 12: Like Toggle Round-Trip**
    - **Validates: Requirements 6.5**
  - [x] 5.9 Write property test for Property 16: Uniqueness constraints — duplicate Like for same (post, user) raises IntegrityError
    - **Property 16: Uniqueness Constraints**
    - **Validates: Requirements 1.4, 2.3, 2.5**

- [x] 6. Checkpoint — backend complete
  - Ensure `python manage.py check` reports no errors
  - Ensure all backend tests pass, ask the user if questions arise.

- [x] 7. Frontend: API services
  - Create `frontend/lib/Challenge_Community/challenge_api_service.dart` wrapping `DioClient` with methods: `fetchActiveChallenges()`, `joinChallenge(id)`, `leaveChallenge(id)`, `fetchLeaderboard(id)`, `fetchBadges()`, `fetchStreak()`
  - Create `frontend/lib/Challenge_Community/community_api_service.dart` wrapping `DioClient` with methods: `fetchFeed(page)`, `createPost(content, imageUrls)`, `deletePost(id)`, `toggleLike(id)`, `fetchComments(id)`, `addComment(id, content)`, `reportPost(id, reason)`, `fetchProfile(id)`, `toggleFollow(id)`, `fetchUserPosts(id)`, `fetchFollowers(id)`
  - Both services catch `DioException` and rethrow as typed errors
  - Include Dart model classes (`ChallengeModel`, `ChallengeParticipantModel`, `BadgeModel`, `StreakModel`, `PostModel`, `CommentModel`, `UserProfileModel`) with `fromJson` factories
  - _Requirements: 3.1–3.5, 4.1–4.2, 6.1–6.8, 7.1–7.4_

- [x] 8. Frontend: providers
  - Create `frontend/lib/Challenge_Community/challenge_provider.dart` as `ChangeNotifier` exposing: `List<ChallengeModel> challenges`, `bool isLoading`, `String? error`, `StreakModel? streak`, `List<BadgeModel> badges`; methods: `fetchChallenges()`, `joinChallenge(id)`, `leaveChallenge(id)`, `fetchStreak()`, `fetchBadges()`
  - `joinChallenge(id)` must update the matching challenge in `challenges` list in-place (set `isJoined=true`) without a full refresh
  - Create `frontend/lib/Challenge_Community/community_provider.dart` as `ChangeNotifier` exposing: `List<PostModel> posts`, `bool isLoading`, `String? error`, `int currentPage`, `bool hasMore`; methods: `fetchFeed()`, `loadMore()`, `createPost(content, imageUrls)`, `toggleLike(postId)`, `addComment(postId, content)`
  - `toggleLike(postId)` must optimistically update `like_count` and `isLikedByMe` before the API call; roll back on failure
  - _Requirements: 17.1–17.4_

- [x] 9. Frontend: enhance existing challenge screens
  - Enhance `challenge_community_wrapper.dart`: wire `_ChallengeTabContent` to `ChallengeProvider` via `Consumer`; replace any mock/static data
  - Enhance `challenge_overview_screen.dart`: add type badge `Chip`, `LinearProgressIndicator` for progress toward `goal_value`, remaining days countdown, green JOIN `ElevatedButton` wired to `provider.joinChallenge(id)`; show `CircularProgressIndicator` while loading; show error widget with retry on failure
  - Enhance `challenge_details_screen.dart`: add leaderboard `ListView` from `fetchLeaderboard(id)`, circular progress indicator showing progress %, red LEAVE `ElevatedButton` wired to `provider.leaveChallenge(id)`, countdown timer for days remaining
  - Enhance `active_challenge_screen.dart`: wire to real `ChallengeParticipant` data from `ChallengeProvider`
  - Enhance `challenge_progress_screen.dart`: wire `LinearProgressIndicator` to real participant progress from provider
  - _Requirements: 8.1–8.6, 9.1–9.5_

- [x] 10. Frontend: enhance existing community screens
  - Enhance `community_feed_screen.dart`: wire to `CommunityProvider`; implement infinite scroll (call `loadMore()` at bottom); render post cards with `CircleAvatar`, username, timeago timestamp, content, image carousel (if `imageUrls` non-empty), like/comment action bar; like button toggles heart icon and count optimistically; FAB navigates to `CreatePostScreen`; show `CircularProgressIndicator` on initial load
  - Enhance `comments_screen.dart`: fetch comments via `provider.fetchComments(id)`; display in ascending `createdAt` order; sticky bottom `TextField` + send button calls `provider.addComment`; 3-dot menu opens bottom sheet with Report option calling `communityApiService.reportPost(id, reason)`
  - _Requirements: 11.1–11.7, 12.1–12.5_

- [x] 11. Frontend: create new screens
  - Create `frontend/lib/Challenge_Community/create_post_screen.dart`: multi-line `TextField` (max 1000 chars) with character counter; image picker grid (up to 4 images via `image_picker`); green POST `ElevatedButton` disabled when content empty and no images; loading indicator on button while submitting; on success call `provider.createPost` then pop and prepend post to feed
  - Create `frontend/lib/Challenge_Community/user_profile_screen.dart`: avatar, username, follower/following/post counts from `fetchProfile(id)`; Follow/Unfollow `ElevatedButton` wired to `toggleFollow(id)`; two tabs — Posts (`fetchUserPosts(id)`) and Followers (`fetchFollowers(id)`); `CircularProgressIndicator` while loading
  - Create `frontend/lib/Challenge_Community/gamification_screen.dart`: streak card with large current streak number, flame icon, longest streak stat; badges `GridView` with circular icons, names, points from `fetchBadges()`; `CircularProgressIndicator` while loading; placeholder "Complete challenges to earn badges" when badge list is empty
  - _Requirements: 10.1–10.4, 13.1–13.5, 14.1–14.4_

- [x] 12. Frontend: wire providers into MultiProvider
  - In `frontend/lib/main.dart`, add `ChangeNotifierProvider(create: (_) => ChallengeProvider(ChallengeApiService()))` and `ChangeNotifierProvider(create: (_) => CommunityProvider(CommunityApiService()))` to the existing `MultiProvider`
  - _Requirements: 17.1, 17.2_

- [x] 13. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 14. Backend — Add `ChallengeDailyLog` model and `Challenge.default_tasks`
  - [x] 14.1 Add `default_tasks = models.JSONField(default=list)` to the existing `Challenge` model in `backend/challenges/models.py`
    - _Requirements: 18.1_
  - [x] 14.2 Add `ChallengeDailyLog` model to `backend/challenges/models.py` with fields: `id` (UUID PK), `participant` (FK to ChallengeParticipant, CASCADE, related_name='daily_logs'), `day_number` (PositiveIntegerField), `task_items` (JSONField default list), `media_urls` (JSONField default list), `is_complete` (BooleanField default False), `completed_at` (DateTimeField null/blank), `created_at` (auto_now_add), `updated_at` (auto_now), unique_together `('participant', 'day_number')`
    - _Requirements: 18.2, 18.3_
  - [x] 14.3 Run `python manage.py makemigrations challenges` to generate migration
    - _Requirements: 18.1, 18.2_
  - [x] 14.4 Register `ChallengeDailyLog` in `backend/challenges/admin.py`
    - _Requirements: 18.2_

- [x] 15. Backend — Daily log serializer
  - [x] 15.1 Add `ChallengeDailyLogSerializer` to `backend/challenges/serializers.py` with all fields including nested `task_items` and `media_urls` JSON arrays
    - _Requirements: 19.1–19.5_
  - [x] 15.2 Add `DailyLogCompleteResponseSerializer` that includes the log fields plus an optional `shared_post` field using the existing `PostSerializer`
    - _Requirements: 20.3_

- [x] 16. Backend — Daily log API views and URL routing
  - [x] 16.1 Add `DailyLogView` to `backend/challenges/views.py` handling `GET` (get_or_create today's log using `day_number = (today - participant.joined_at.date()).days + 1`; populate `task_items` from `challenge.default_tasks` adding `"completed": False` to each; return 404 if user not joined) and `PATCH` (update `task_items` and/or `media_urls` for today's log; return updated log)
    - _Requirements: 19.1–19.5_
  - [x] 16.2 Add `DailyLogCompleteView` to `backend/challenges/views.py` handling `POST`: set `is_complete=True`, `completed_at=now()`; if `share_to_community=true`, create a `Post` with content `"I completed Day {day_number} of {challenge_name}! 💪"` and `image_urls` from non-video media; return log + optional `shared_post`; return 400 if already complete
    - _Requirements: 20.1–20.4_
  - [x] 16.3 Add `DailyLogListView` to `backend/challenges/views.py` handling `GET`: return all logs for participant ordered by `day_number` ascending
    - _Requirements: 19.6, 19.7_
  - [x] 16.4 Add URL patterns to `backend/challenges/urls.py`: `GET/PATCH /api/challenges/<uuid:pk>/daily-log/` → `DailyLogView`; `POST /api/challenges/<uuid:pk>/daily-log/complete/` → `DailyLogCompleteView`; `GET /api/challenges/<uuid:pk>/daily-logs/` → `DailyLogListView`; all views use `IsAuthenticated`
    - _Requirements: 19.1–19.7, 20.1–20.4_

- [ ] 17. Backend — Daily log tests
  - [ ]* 17.1 Add unit test TC-DL01: join challenge → GET `/daily-log/` → `day_number=1`, `task_items` matches `challenge.default_tasks`
    - _Requirements: 19.1, 19.2_
  - [ ]* 17.2 Add unit test TC-DL02: PATCH `task_items` → GET → returned values match
    - _Requirements: 19.3_
  - [ ]* 17.3 Add unit test TC-DL03: POST `complete/` → `is_complete=True`, `completed_at` non-null
    - _Requirements: 20.1_
  - [ ]* 17.4 Add unit test TC-DL04: POST `complete/` twice → second returns HTTP 400
    - _Requirements: 20.2_
  - [ ]* 17.5 Add unit test TC-DL05: POST `complete/` with `share_to_community=true` → `Post` created, response has `shared_post`
    - _Requirements: 20.3, 20.4_
  - [ ]* 17.6 Add unit test TC-DL06: POST `complete/` with `share_to_community=false` → no `Post` created
    - _Requirements: 20.3_
  - [ ]* 17.7 Add unit test TC-DL07: request to `/daily-log/` for unjoined challenge → HTTP 404
    - _Requirements: 19.4_
  - [ ]* 17.8 Write property test for Property 17: daily log round-trip — PATCH then GET returns same values
    - **Property 17: Daily Log Round-Trip**
    - **Validates: Requirements 25.1**
  - [ ]* 17.9 Write property test for Property 18: idempotent PATCH — same payload N times yields same result
    - **Property 18: Idempotent PATCH**
    - **Validates: Requirements 25.2**
  - [ ]* 17.10 Write property test for Property 19: day number invariant — `day_number >= 1` for all `joined_at` in past/present
    - **Property 19: Day Number Invariant**
    - **Validates: Requirements 25.3**
  - [ ]* 17.11 Write property test for Property 20: completed log invariant — `is_complete=True` → `completed_at` non-null and `>= created_at`
    - **Property 20: Completed Log Invariant**
    - **Validates: Requirements 25.4**
  - [ ]* 17.12 Write property test for Property 21: no duplicate day numbers per participant
    - **Property 21: No Duplicate Day Numbers**
    - **Validates: Requirements 25.5**

- [x] 18. Frontend — Daily log Dart models and API service methods
  - [x] 18.1 Add `DailyTaskItem`, `DailyMediaItem`, `ChallengeDailyLogModel` classes to `frontend/lib/Challenge_Community/challenge_api_service.dart` with `fromJson`/`toJson` methods
    - _Requirements: 23.1–23.5_
  - [x] 18.2 Add `fetchTodayLog(challengeId)` → `ChallengeDailyLogModel` (GET `/api/challenges/{id}/daily-log/`) to `ChallengeApiService`
    - _Requirements: 23.1_
  - [x] 18.3 Add `updateDailyLog(challengeId, taskItems, mediaUrls)` → `ChallengeDailyLogModel` (PATCH `/api/challenges/{id}/daily-log/`) to `ChallengeApiService`
    - _Requirements: 23.3, 23.6_
  - [x] 18.4 Add `completeDailyLog(challengeId, {shareToCommmunity: false})` → `Map` with `log` and optional `sharedPost` (POST `/api/challenges/{id}/daily-log/complete/`) to `ChallengeApiService`
    - _Requirements: 24.1–24.7_
  - [x] 18.5 Add `fetchAllDailyLogs(challengeId)` → `List<ChallengeDailyLogModel>` (GET `/api/challenges/{id}/daily-logs/`) to `ChallengeApiService`
    - _Requirements: 23.9, 23.10_

- [x] 19. Frontend — ChallengeProvider daily log state and methods
  - [x] 19.1 Add `ChallengeDailyLogModel? todayLog` and `bool isDailyLogLoading` state fields to `frontend/lib/Challenge_Community/challenge_provider.dart`
    - _Requirements: 23.1_
  - [x] 19.2 Add `fetchTodayLog(challengeId)` — calls API, sets `todayLog`, notifies listeners
    - _Requirements: 23.1_
  - [x] 19.3 Add `toggleTask(challengeId, taskIndex)` — flips `task_items[index].completed`, calls `updateDailyLog`, notifies listeners
    - _Requirements: 23.3_
  - [x] 19.4 Add `attachMedia(challengeId, url, isVideo)` — appends to `todayLog.mediaUrls`, calls `updateDailyLog`, notifies listeners
    - _Requirements: 23.6_
  - [x] 19.5 Add `removeMedia(challengeId, index)` — removes from `todayLog.mediaUrls`, calls `updateDailyLog`, notifies listeners
    - _Requirements: 23.7_
  - [x] 19.6 Add `completeDailyLog(challengeId, {shareToCommmunity: false})` — calls complete endpoint, updates `todayLog`, notifies listeners
    - _Requirements: 24.1, 24.7_

- [x] 20. Frontend — Enhance ActiveChallengeScreen with daily log UI
  - [x] 20.1 On `initState`, call `provider.fetchTodayLog(challengeId)`; show `CircularProgressIndicator` while `isDailyLogLoading`
    - _Requirements: 23.1_
  - [x] 20.2 Show day heading `"Day X"` (large bold, from `todayLog.dayNumber`) and render `CheckboxListTile` for each `task_items` entry wired to `provider.toggleTask`
    - _Requirements: 23.2, 23.3_
  - [x] 20.3 Show media attachment button (camera icon) opening a bottom sheet with "Take Photo", "Choose from Gallery", "Record Video" options; on selection upload via `POST /api/upload/` then call `provider.attachMedia`
    - _Requirements: 23.5, 23.6_
  - [x] 20.4 Show horizontal scrollable row of media thumbnails with remove buttons wired to `provider.removeMedia`
    - _Requirements: 23.7_
  - [x] 20.5 Show `"Complete Day X"` `ElevatedButton` enabled only when all tasks are checked (or `task_items` is empty); on tap call `provider.completeDailyLog(challengeId)` and show `DayCompletionOverlay`
    - _Requirements: 23.8, 23.9_
  - [x] 20.6 Show error message with retry button on API failure
    - _Requirements: 23.10_
  - _Requirements: 23.1–23.10_

- [x] 21. Frontend — Create DayCompletionOverlay widget and share flow
  - [x] 21.1 Create `frontend/lib/Challenge_Community/day_completion_overlay.dart` as a full-screen overlay accepting `dayNumber`, `challengeName`, `firstMediaUrl` (nullable), `challengeId` as parameters; show success animation and `"Day X Complete!"` heading
    - _Requirements: 24.1, 24.2_
  - [x] 21.2 Show preview of auto-generated post content `"I completed Day X of [Challenge Name]! 💪"` and first media thumbnail if available
    - _Requirements: 24.3_
  - [x] 21.3 Add `"Share to Community"` `ElevatedButton` (green `#4CAF50`) — calls `provider.completeDailyLog(challengeId, shareToCommmunity: true)`, shows `SnackBar("Posted to community!")`, then pops overlay; show loading indicator while API call in progress; show error `SnackBar` on failure keeping overlay visible for retry
    - _Requirements: 24.4, 24.5, 24.6_
  - [x] 21.4 Add `"Skip"` `TextButton` — pops overlay without sharing
    - _Requirements: 24.7_

- [x] 22. Backend — Update create challenge to support default_tasks
  - [x] 22.1 Update `ChallengeSerializer` in `backend/challenges/serializers.py` to include `default_tasks` field
    - _Requirements: 18.1_
  - [x] 22.2 Update `CreateChallengeView` in `backend/challenges/views.py` to accept optional `default_tasks` list of `{"label": str}` objects; validate each item has a non-empty `label` string
    - _Requirements: 18.1_
  - [x] 22.3 Update the create challenge form in `frontend/lib/Challenge_Community/challenge_overview_screen.dart` (`_CreateChallengeSheet`) to allow adding/removing task items with a dynamic list of `TextField` inputs
    - _Requirements: 18.1, 23.2_

- [x] 23. Final checkpoint — daily log feature complete
  - Ensure `python manage.py check` reports no errors
  - Ensure all new backend tests pass
  - Verify the daily log UI works end-to-end: join challenge → see Day 1 → tick tasks → attach media → complete → share prompt → share to community

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Signal handlers must never propagate exceptions to the originating save
- JOIN/POST action buttons use green `#4CAF50`; all other buttons use red `#E53935`
- All new backend models use UUID primary keys
- Optimistic like updates must be rolled back on API failure
