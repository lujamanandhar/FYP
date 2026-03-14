# Requirements Document

## Introduction

The NutriLift Challenge & Gamification and Community subsystems extend the existing NutriLift Flutter/Django application with two interconnected features:

1. **Challenge & Gamification**: Users can join time-boxed fitness/nutrition challenges, earn badges, maintain streaks, and compete on leaderboards. Progress is automatically updated from existing WorkoutLog and IntakeLog activity.

2. **Community**: A social feed where users can post workout summaries and nutrition updates, like/comment on posts, follow other users, and report inappropriate content.

The frontend builds on existing scaffold files in `frontend/lib/Challenge_Community/` and integrates with the existing bottom navigation, design system (red primary `#E53935`, card elevation 4dp, rounded 12px), and JWT-authenticated DioClient. The backend adds a new `challenges` Django app alongside the existing `workouts`, `nutrition`, and `authentications` apps.

---

## Glossary

- **Challenge_System**: The Django/Flutter subsystem managing challenges, participants, badges, and streaks.
- **Community_System**: The Django/Flutter subsystem managing posts, comments, likes, follows, and reports.
- **Challenge**: A time-boxed fitness or nutrition goal that users can join and track progress against.
- **Challenge_Participant**: A record linking a User to a Challenge, tracking their progress and rank.
- **Badge**: An achievement awarded to a User when specific criteria are met.
- **Streak**: A record of a User's consecutive daily activity count.
- **Post**: A community content item created by a User, optionally containing images or embedded workout summaries.
- **Comment**: A text reply attached to a Post by a User.
- **Like**: A single positive reaction from a User to a Post (unique per user/post pair).
- **Report**: A moderation flag raised by a User against a Post.
- **Follow**: A directional relationship where one User subscribes to another User's posts.
- **Feed**: The paginated list of Posts shown to a User, sourced from followed users and recent activity.
- **Leaderboard**: A ranked list of Challenge_Participants ordered by descending progress.
- **WorkoutLog**: The existing model in the `workouts` app recording completed workouts with `calories_burned`.
- **IntakeLog**: The existing model in the `nutrition` app recording food intake with `calories`.
- **DioClient**: The existing authenticated HTTP client used by all Flutter API services.
- **NutriLiftScaffold**: The existing Flutter scaffold widget providing the app bar, drawer, and consistent layout.
- **Provider**: The Flutter state management package used across the app.

---

## Requirements

### Requirement 1: Challenge Data Models (Backend)

**User Story:** As a backend developer, I want well-defined Django models for challenges and gamification, so that challenge data is stored consistently and can be queried efficiently.

#### Acceptance Criteria

1. THE Challenge_System SHALL define a `Challenge` model with fields: `id` (UUID primary key), `name` (CharField max 255), `description` (TextField), `challenge_type` (CharField choices: `nutrition`, `workout`, `mixed`), `goal_value` (FloatField), `unit` (CharField choices: `kcal`, `reps`, `days`), `start_date` (DateTimeField), `end_date` (DateTimeField), `created_by` (ForeignKey to AUTH_USER_MODEL), `is_active` (BooleanField default True), `created_at` (DateTimeField auto_now_add).
2. THE Challenge_System SHALL define a `ChallengeParticipant` model with fields: `id` (UUID primary key), `challenge` (ForeignKey to Challenge), `user` (ForeignKey to AUTH_USER_MODEL), `progress` (FloatField default 0), `completed` (BooleanField default False), `joined_at` (DateTimeField auto_now_add), `completed_at` (DateTimeField null/blank), `rank` (IntegerField null/blank).
3. THE Challenge_System SHALL define a `Badge` model with fields: `id` (UUID primary key), `name` (CharField max 255), `description` (TextField), `icon_url` (CharField), `criteria` (JSONField), `points_reward` (IntegerField), `is_active` (BooleanField default True), `created_at` (DateTimeField auto_now_add).
4. THE Challenge_System SHALL define a `UserBadge` model with fields: `id` (UUID primary key), `user` (ForeignKey to AUTH_USER_MODEL), `badge` (ForeignKey to Badge), `earned_at` (DateTimeField auto_now_add), with a unique constraint on `(user, badge)`.
5. THE Challenge_System SHALL define a `Streak` model with fields: `id` (UUID primary key), `user` (OneToOneField to AUTH_USER_MODEL), `current_streak` (IntegerField default 0), `longest_streak` (IntegerField default 0), `last_active_date` (DateField null/blank), `updated_at` (DateTimeField auto_now).
6. WHEN a Django migration is run, THE Challenge_System SHALL create all challenge-related database tables without errors.

### Requirement 2: Community Data Models (Backend)

**User Story:** As a backend developer, I want well-defined Django models for the community subsystem, so that social interactions are stored with referential integrity.

#### Acceptance Criteria

1. THE Community_System SHALL define a `Post` model with fields: `id` (UUID primary key), `user` (ForeignKey to AUTH_USER_MODEL), `content` (TextField max_length 1000), `image_urls` (JSONField default list), `like_count` (IntegerField default 0), `comment_count` (IntegerField default 0), `is_reported` (BooleanField default False), `is_removed` (BooleanField default False), `created_at` (DateTimeField auto_now_add), `updated_at` (DateTimeField auto_now).
2. THE Community_System SHALL define a `Comment` model with fields: `id` (UUID primary key), `post` (ForeignKey to Post on_delete CASCADE), `user` (ForeignKey to AUTH_USER_MODEL), `content` (TextField), `created_at` (DateTimeField auto_now_add).
3. THE Community_System SHALL define a `Like` model with fields: `id` (UUID primary key), `post` (ForeignKey to Post on_delete CASCADE), `user` (ForeignKey to AUTH_USER_MODEL), `created_at` (DateTimeField auto_now_add), with a unique constraint on `(post, user)`.
4. THE Community_System SHALL define a `Report` model with fields: `id` (UUID primary key), `post` (ForeignKey to Post), `reported_by` (ForeignKey to AUTH_USER_MODEL), `reason` (TextField), `status` (CharField choices: `pending`, `reviewed`, `dismissed`, default `pending`), `created_at` (DateTimeField auto_now_add), `reviewed_at` (DateTimeField null/blank).
5. THE Community_System SHALL define a `Follow` model with fields: `id` (UUID primary key), `follower` (ForeignKey to AUTH_USER_MODEL related_name `following`), `following` (ForeignKey to AUTH_USER_MODEL related_name `followers`), `created_at` (DateTimeField auto_now_add), with a unique constraint on `(follower, following)`.
6. WHEN a Django migration is run, THE Community_System SHALL create all community-related database tables without errors.

### Requirement 3: Challenge API Endpoints (Backend)

**User Story:** As a mobile developer, I want REST API endpoints for challenges, so that the Flutter app can list, join, and track challenge progress.

#### Acceptance Criteria

1. WHEN an authenticated user sends `GET /api/challenges/active/`, THE Challenge_System SHALL return a list of all `Challenge` records where `is_active=True` and `end_date` is in the future, serialized with `id`, `name`, `description`, `challenge_type`, `goal_value`, `unit`, `start_date`, `end_date`, and the requesting user's `participant_progress` (0 if not joined).
2. WHEN an authenticated user sends `POST /api/challenges/{id}/join/`, THE Challenge_System SHALL create a `ChallengeParticipant` record linking the user to the challenge and return HTTP 201 with the participant data.
3. IF an authenticated user sends `POST /api/challenges/{id}/join/` and a `ChallengeParticipant` already exists for that user and challenge, THEN THE Challenge_System SHALL return HTTP 400 with an error message indicating the user has already joined.
4. WHEN an authenticated user sends `GET /api/challenges/{id}/leaderboard/`, THE Challenge_System SHALL return the top 10 `ChallengeParticipant` records for that challenge ordered by descending `progress`, each serialized with `rank`, `user_id`, `username`, `avatar_url`, and `progress`.
5. WHEN an authenticated user sends `DELETE /api/challenges/{id}/leave/`, THE Challenge_System SHALL delete the `ChallengeParticipant` record for that user and challenge and return HTTP 204.
6. IF an unauthenticated request is made to any challenge endpoint, THEN THE Challenge_System SHALL return HTTP 401.

### Requirement 4: Gamification API Endpoints (Backend)

**User Story:** As a mobile developer, I want REST API endpoints for badges and streaks, so that the Flutter app can display a user's gamification progress.

#### Acceptance Criteria

1. WHEN an authenticated user sends `GET /api/challenges/badges/`, THE Challenge_System SHALL return all `UserBadge` records for that user, each serialized with `badge_id`, `name`, `description`, `icon_url`, `points_reward`, and `earned_at`.
2. WHEN an authenticated user sends `GET /api/challenges/streak/`, THE Challenge_System SHALL return the `Streak` record for that user serialized with `current_streak`, `longest_streak`, and `last_active_date`. IF no streak record exists, THE Challenge_System SHALL return `{"current_streak": 0, "longest_streak": 0, "last_active_date": null}`.
3. IF an unauthenticated request is made to any gamification endpoint, THEN THE Challenge_System SHALL return HTTP 401.

### Requirement 5: Automatic Progress Updates via Signals (Backend)

**User Story:** As a user, I want my challenge progress to update automatically when I log workouts or meals, so that I don't have to manually track my challenge activity.

#### Acceptance Criteria

1. WHEN a `WorkoutLog` record is saved (post_save signal), THE Challenge_System SHALL query all active `ChallengeParticipant` records for that user where the linked `Challenge.challenge_type` is `workout` or `mixed`, and increment each participant's `progress` by the `WorkoutLog.calories_burned` value.
2. WHEN an `IntakeLog` record is saved (post_save signal), THE Challenge_System SHALL query all active `ChallengeParticipant` records for that user where the linked `Challenge.challenge_type` is `nutrition` or `mixed`, and increment each participant's `progress` by the `IntakeLog.calories` value.
3. WHEN a `ChallengeParticipant.progress` reaches or exceeds the linked `Challenge.goal_value` after an update, THE Challenge_System SHALL set `ChallengeParticipant.completed = True` and `ChallengeParticipant.completed_at` to the current datetime.
4. WHEN a `WorkoutLog` or `IntakeLog` is saved for a user, THE Challenge_System SHALL update or create the user's `Streak` record: if `last_active_date` is yesterday, increment `current_streak` by 1; if `last_active_date` is today, leave `current_streak` unchanged; otherwise reset `current_streak` to 1. THE Challenge_System SHALL update `longest_streak` if `current_streak` exceeds it.
5. WHEN a `ChallengeParticipant` is marked completed, THE Challenge_System SHALL check all active `Badge` records whose `criteria` JSON contains `{"type": "challenge_complete"}` and award any matching `UserBadge` records not already earned by that user.

### Requirement 6: Community Feed API Endpoints (Backend)

**User Story:** As a mobile developer, I want REST API endpoints for the community feed, so that the Flutter app can display and create posts.

#### Acceptance Criteria

1. WHEN an authenticated user sends `GET /api/community/feed/`, THE Community_System SHALL return a paginated list (page size 20) of `Post` records that are not `is_removed`, ordered by descending `created_at`, serialized with `id`, `user_id`, `username`, `avatar_url`, `content`, `image_urls`, `like_count`, `comment_count`, `created_at`, and `is_liked_by_me` (boolean).
2. WHEN an authenticated user sends `POST /api/community/posts/`, THE Community_System SHALL create a `Post` record with the provided `content` and `image_urls`, set `user` to the requesting user, and return HTTP 201 with the serialized post.
3. IF `content` exceeds 1000 characters in a `POST /api/community/posts/` request, THEN THE Community_System SHALL return HTTP 400 with a validation error.
4. WHEN an authenticated user sends `DELETE /api/community/posts/{id}/`, THE Community_System SHALL verify the requesting user owns the post, delete the record, and return HTTP 204. IF the user does not own the post, THE Community_System SHALL return HTTP 403.
5. WHEN an authenticated user sends `POST /api/community/posts/{id}/like/`, THE Community_System SHALL create a `Like` record and increment `Post.like_count` by 1, returning HTTP 201. IF a `Like` already exists for that user/post pair, THE Community_System SHALL delete it and decrement `Post.like_count` by 1, returning HTTP 200 with `{"liked": false}`.
6. WHEN an authenticated user sends `POST /api/community/posts/{id}/comment/`, THE Community_System SHALL create a `Comment` record, increment `Post.comment_count` by 1, and return HTTP 201 with the serialized comment.
7. WHEN an authenticated user sends `GET /api/community/posts/{id}/comments/`, THE Community_System SHALL return all `Comment` records for that post ordered by ascending `created_at`.
8. WHEN an authenticated user sends `POST /api/community/posts/{id}/report/`, THE Community_System SHALL create a `Report` record with `status=pending` and set `Post.is_reported=True`, returning HTTP 201.

### Requirement 7: User Social API Endpoints (Backend)

**User Story:** As a mobile developer, I want REST API endpoints for user profiles and following, so that the Flutter app can display social connections.

#### Acceptance Criteria

1. WHEN an authenticated user sends `GET /api/community/users/{id}/profile/`, THE Community_System SHALL return the target user's `id`, `username`, `avatar_url`, follower count, following count, post count, and `is_following_me` (boolean indicating if the requesting user follows the target).
2. WHEN an authenticated user sends `POST /api/community/users/{id}/follow/`, THE Community_System SHALL create a `Follow` record with `follower` as the requesting user and `following` as the target user, returning HTTP 201. IF the follow already exists, THE Community_System SHALL delete it and return HTTP 200 with `{"following": false}`.
3. WHEN an authenticated user sends `GET /api/community/users/{id}/posts/`, THE Community_System SHALL return all non-removed `Post` records by that user ordered by descending `created_at`.
4. WHEN an authenticated user sends `GET /api/community/users/{id}/followers/`, THE Community_System SHALL return a list of users who follow the target user, each serialized with `id`, `username`, and `avatar_url`.
5. IF an unauthenticated request is made to any community endpoint, THEN THE Community_System SHALL return HTTP 401.

### Requirement 8: Challenge List Screen (Frontend)

**User Story:** As a user, I want to browse available challenges in the app, so that I can find and join challenges that match my fitness goals.

#### Acceptance Criteria

1. WHEN the Challenge tab is selected in `ChallengeCommunityWrapper`, THE Challenge_System SHALL display a `ListView` of challenge cards fetched from `GET /api/challenges/active/`.
2. THE Challenge_System SHALL render each challenge card with: challenge name (bold), a type badge chip (`nutrition`/`workout`/`mixed`), goal value and unit, a `LinearProgressIndicator` showing the user's current progress toward `goal_value`, remaining days countdown, and a green `JOIN` `ElevatedButton`.
3. WHEN the `JOIN` button is tapped on a challenge the user has not joined, THE Challenge_System SHALL call `POST /api/challenges/{id}/join/` and update the card to show current progress with a `LEAVE` option.
4. WHILE the challenge list is loading, THE Challenge_System SHALL display a `CircularProgressIndicator` centered in the list area.
5. IF the API call to fetch challenges fails, THE Challenge_System SHALL display an error message with a retry button.
6. THE Challenge_System SHALL use card elevation 4dp, rounded corners 12px, and the app's primary color for the JOIN button, consistent with existing NutriLift card styling.

### Requirement 9: Challenge Detail Screen (Frontend)

**User Story:** As a user, I want to view detailed challenge information and a leaderboard, so that I can track my rank against other participants.

#### Acceptance Criteria

1. WHEN a challenge card is tapped, THE Challenge_System SHALL navigate to a detail screen showing the challenge name, description, type, goal, start/end dates, and a countdown timer showing days remaining.
2. THE Challenge_System SHALL display a circular progress indicator (matching the workout progress style) showing the user's progress as a percentage of `goal_value`.
3. THE Challenge_System SHALL display a leaderboard `ListView` fetched from `GET /api/challenges/{id}/leaderboard/`, with each entry showing rank number, avatar, username, and progress value.
4. WHEN the user has joined the challenge, THE Challenge_System SHALL display a red `LEAVE` `ElevatedButton` that calls `DELETE /api/challenges/{id}/leave/` on tap.
5. WHILE the leaderboard is loading, THE Challenge_System SHALL display a `CircularProgressIndicator`.

### Requirement 10: Profile Gamification Tab (Frontend)

**User Story:** As a user, I want to see my badges and streak on my profile, so that I can track my gamification achievements.

#### Acceptance Criteria

1. THE Challenge_System SHALL add a `Gamification` tab to the user profile screen displaying a streak card with the current streak count as a large number, a flame icon, and the longest streak stat.
2. THE Challenge_System SHALL display earned badges in a `GridView` with circular badge icons, badge names, and points reward, fetched from `GET /api/challenges/badges/`.
3. WHILE gamification data is loading, THE Challenge_System SHALL display a `CircularProgressIndicator`.
4. IF the user has no badges, THE Challenge_System SHALL display a placeholder message: "Complete challenges to earn badges".

### Requirement 11: Community Feed Screen (Frontend)

**User Story:** As a user, I want to scroll through a community feed of posts, so that I can stay connected with other NutriLift users.

#### Acceptance Criteria

1. WHEN the Community tab is selected in `ChallengeCommunityWrapper`, THE Community_System SHALL display an infinite-scroll `ListView` of post cards fetched from `GET /api/community/feed/`.
2. THE Community_System SHALL render each post card with: a `CircleAvatar` with the poster's avatar, username (bold), timeago-formatted timestamp, post content text, an image carousel (if `image_urls` is non-empty), and a bottom action bar with like count, comment count, and share icon.
3. WHEN the like button is tapped, THE Community_System SHALL call `POST /api/community/posts/{id}/like/` and toggle the heart icon between filled (liked) and outlined (not liked), updating the count optimistically.
4. WHEN the comment icon is tapped, THE Community_System SHALL navigate to the Post Detail screen.
5. THE Community_System SHALL display a floating `+` `FloatingActionButton` that navigates to the Create Post screen.
6. WHEN the user scrolls to the bottom of the loaded posts, THE Community_System SHALL fetch the next page and append the results to the list.
7. WHILE the initial feed is loading, THE Community_System SHALL display a `CircularProgressIndicator`.

### Requirement 12: Post Detail Screen (Frontend)

**User Story:** As a user, I want to view a post's full comments and add my own, so that I can engage in community discussions.

#### Acceptance Criteria

1. WHEN the Post Detail screen opens, THE Community_System SHALL display the full post content and fetch comments from `GET /api/community/posts/{id}/comments/`.
2. THE Community_System SHALL display comments in a `ListView` ordered by ascending `created_at`, each showing the commenter's avatar, username, comment text, and timeago timestamp.
3. THE Community_System SHALL display a sticky bottom `TextField` with a send button for submitting new comments via `POST /api/community/posts/{id}/comment/`.
4. WHEN a new comment is submitted, THE Community_System SHALL append it to the comment list and clear the input field.
5. THE Community_System SHALL display a 3-dot menu icon on the post that opens a bottom sheet with a `Report` option, which calls `POST /api/community/posts/{id}/report/` with a reason.

### Requirement 13: Create Post Screen (Frontend)

**User Story:** As a user, I want to create a new community post with text and images, so that I can share my fitness progress.

#### Acceptance Criteria

1. WHEN the `+` FAB is tapped on the Community Feed, THE Community_System SHALL navigate to a Create Post screen with a multi-line `TextField` for content (max 1000 characters) and a character counter.
2. THE Community_System SHALL display an image picker grid allowing selection of up to 4 images using the `image_picker` package.
3. WHEN the green `POST` `ElevatedButton` is tapped, THE Community_System SHALL call `POST /api/community/posts/` with the content and image URLs, then navigate back to the feed and prepend the new post.
4. IF the content field is empty and no images are selected, THE Community_System SHALL disable the `POST` button.
5. WHILE the post is being submitted, THE Community_System SHALL show a loading indicator on the `POST` button.

### Requirement 14: User Profile Social Screen (Frontend)

**User Story:** As a user, I want to view another user's profile with their posts and follower stats, so that I can decide whether to follow them.

#### Acceptance Criteria

1. WHEN a username is tapped in the community feed, THE Community_System SHALL navigate to a User Profile screen showing the user's avatar, username, follower count, following count, and post count fetched from `GET /api/community/users/{id}/profile/`.
2. THE Community_System SHALL display a `Follow`/`Unfollow` `ElevatedButton` in the top-right area that calls `POST /api/community/users/{id}/follow/` on tap and toggles its label.
3. THE Community_System SHALL display two tabs: `Posts` (showing the user's posts from `GET /api/community/users/{id}/posts/`) and `Followers` (showing the follower list from `GET /api/community/users/{id}/followers/`).
4. WHILE profile data is loading, THE Community_System SHALL display a `CircularProgressIndicator`.

### Requirement 15: Backend App Registration and URL Routing

**User Story:** As a backend developer, I want the new `challenges` app registered in Django settings and URL patterns configured, so that all API endpoints are accessible.

#### Acceptance Criteria

1. THE Challenge_System SHALL register a new `challenges` Django app in `INSTALLED_APPS` in `backend/backend/settings.py`.
2. THE Challenge_System SHALL include challenge URL patterns at `api/challenges/` in `backend/backend/urls.py`.
3. THE Community_System SHALL include community URL patterns at `api/community/` in `backend/backend/urls.py`.
4. WHEN `python manage.py check` is run, THE Challenge_System SHALL report no errors.

### Requirement 16: Integration Tests (Backend)

**User Story:** As a developer, I want integration tests for the core challenge and community flows, so that regressions are caught automatically.

#### Acceptance Criteria

1. THE Challenge_System SHALL include test case TC-CG01: given an authenticated user, when the user joins a challenge and a `WorkoutLog` is saved for that user, then `ChallengeParticipant.progress` SHALL be greater than 0.
2. THE Community_System SHALL include test case TC-CM01: given an authenticated user, when the user creates a post via `POST /api/community/posts/`, then `GET /api/community/feed/` SHALL return a response containing that post's `id`.
3. FOR ALL valid `Post` objects created and then fetched, THE Community_System SHALL return the same `content` value (round-trip property).

### Requirement 17: Frontend State Management (Frontend)

**User Story:** As a developer, I want Provider-based state management for challenge and community data, so that UI state is consistent and testable.

#### Acceptance Criteria

1. THE Challenge_System SHALL provide a `ChallengeProvider` using the `provider` package that exposes: `challenges` list, `isLoading` boolean, `error` string, `fetchChallenges()`, `joinChallenge(id)`, and `leaveChallenge(id)` methods.
2. THE Community_System SHALL provide a `CommunityProvider` using the `provider` package that exposes: `posts` list, `isLoading` boolean, `error` string, `fetchFeed()`, `createPost(content, imageUrls)`, `toggleLike(postId)`, and `loadMore()` methods.
3. WHEN `ChallengeProvider.joinChallenge(id)` is called successfully, THE Challenge_System SHALL update the matching challenge in the `challenges` list to reflect the joined state without requiring a full list refresh.
4. WHEN `CommunityProvider.toggleLike(postId)` is called, THE Community_System SHALL optimistically update the `like_count` and `is_liked_by_me` fields in the local `posts` list before the API call completes.
