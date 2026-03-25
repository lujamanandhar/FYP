import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../services/dio_client.dart';

// ==================== Models ====================

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final List<String> imageUrls;
  int likeCount;
  int commentCount;
  bool isLikedByMe;
  final DateTime createdAt;

  /// Local bytes for newly created posts (not serialized — only for immediate display).
  final List<Uint8List> localMediaBytes;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.imageUrls,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByMe,
    required this.createdAt,
    this.localMediaBytes = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      content: json['content'] as String,
      imageUrls: List<String>.from(json['image_urls'] as List? ?? []),
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class UserProfileModel {
  final String id;
  final String username;
  final String? avatarUrl;
  final int followerCount;
  final int followingCount;
  final int postCount;
  bool isFollowingMe;
  // Physical & fitness info
  final String? gender;
  final String? ageGroup;
  final double? height;
  final double? weight;
  final String? fitnessLevel;

  UserProfileModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.isFollowingMe,
    this.gender,
    this.ageGroup,
    this.height,
    this.weight,
    this.fitnessLevel,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      isFollowingMe: json['is_following_me'] as bool? ?? false,
      gender: json['gender'] as String?,
      ageGroup: json['age_group'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      fitnessLevel: json['fitness_level'] as String?,
    );
  }
}

// ==================== Service ====================

/// API service for community feed and social endpoints.
///
/// Validates: Requirements 6.1–6.8, 7.1–7.4
class CommunityApiService {
  final DioClient _dioClient;
  late final Dio _dio;

  CommunityApiService([DioClient? dioClient])
      : _dioClient = dioClient ?? DioClient() {
    _dio = _dioClient.dio;
  }

  /// Fetch paginated community feed.
  ///
  /// Returns a map with 'posts' (List<PostModel>), 'hasMore' (bool), and 'nextPage' (int?).
  ///
  /// Validates: Requirement 6.1
  Future<Map<String, dynamic>> fetchFeed(int page) async {
    try {
      final response = await _dio.get(
        '/community/feed/',
        queryParameters: {'page': page},
      );
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] as List? ?? [];
      final posts =
          results.map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
      final hasMore = data['next'] != null;
      return {
        'posts': posts,
        'hasMore': hasMore,
        'nextPage': hasMore ? page + 1 : null,
      };
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch feed');
    }
  }

  /// Create a new community post.
  ///
  /// Validates: Requirement 6.2
  Future<PostModel> createPost(String content, List<String> imageUrls) async {
    try {
      final response = await _dio.post(
        '/community/posts/',
        data: {'content': content, 'image_urls': imageUrls},
      );
      return PostModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to create post');
    }
  }

  /// Delete a post by ID (owner only).
  ///
  /// Validates: Requirement 6.4
  Future<void> deletePost(String id) async {
    try {
      await _dio.delete('/community/posts/$id/');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to delete post');
    }
  }

  /// Edit a post's content (owner only).
  ///
  /// Validates: Requirement 6.3
  Future<PostModel> editPost(String id, String content) async {
    try {
      final response = await _dio.patch(
        '/community/posts/$id/',
        data: {'content': content},
      );
      return PostModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to edit post');
    }
  }

  /// Toggle like on a post. Returns map with 'liked' (bool) and 'likeCount' (int).
  ///
  /// Validates: Requirement 6.5
  Future<Map<String, dynamic>> toggleLike(String id) async {
    try {
      final response = await _dio.post('/community/posts/$id/like/');
      final data = response.data as Map<String, dynamic>;
      return {
        'liked': data['liked'] as bool? ?? false,
        'likeCount': data['like_count'] as int? ?? 0,
      };
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to toggle like');
    }
  }

  /// Fetch comments for a post (ascending by createdAt).
  ///
  /// Validates: Requirement 6.6, 6.7
  Future<List<CommentModel>> fetchComments(String id) async {
    try {
      final response = await _dio.get('/community/posts/$id/comments/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch comments');
    }
  }

  /// Add a comment to a post.
  ///
  /// Validates: Requirement 6.6
  Future<CommentModel> addComment(String id, String content) async {
    try {
      final response = await _dio.post(
        '/community/posts/$id/comment/',
        data: {'content': content},
      );
      return CommentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to add comment');
    }
  }

  /// Report a post with a reason.
  ///
  /// Validates: Requirement 6.8
  Future<void> reportPost(String id, String reason) async {
    try {
      await _dio.post(
        '/community/posts/$id/report/',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to report post');
    }
  }

  /// Fetch a user's public profile.
  ///
  /// Validates: Requirement 7.1
  Future<UserProfileModel> fetchProfile(String id) async {
    try {
      final response = await _dio.get('/community/users/$id/profile/');
      return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch profile');
    }
  }

  /// Toggle follow on a user. Returns map with 'following' (bool) and 'followerCount' (int).
  ///
  /// Validates: Requirement 7.2
  Future<Map<String, dynamic>> toggleFollow(String id) async {
    try {
      final response = await _dio.post('/community/users/$id/follow/');
      final data = response.data as Map<String, dynamic>;
      return {
        'following': data['following'] as bool? ?? false,
        'followerCount': data['follower_count'] as int? ?? 0,
      };
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to toggle follow');
    }
  }

  /// Fetch posts by a specific user.
  ///
  /// Validates: Requirement 7.3
  Future<List<PostModel>> fetchUserPosts(String id) async {
    try {
      final response = await _dio.get('/community/users/$id/posts/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch user posts');
    }
  }

  /// Fetch followers of a user.
  ///
  /// Validates: Requirement 7.4
  Future<List<UserProfileModel>> fetchFollowers(String id) async {
    try {
      final response = await _dio.get('/community/users/$id/followers/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) => UserProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch followers');
    }
  }

  /// Fetch users that a user is following.
  Future<List<UserProfileModel>> fetchFollowing(String id) async {
    try {
      final response = await _dio.get('/community/users/$id/following/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) => UserProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch following');
    }
  }

  /// Fetch challenge achievement stats for a user's profile.
  Future<Map<String, dynamic>> fetchUserChallengeStats(String id) async {
    try {
      final response = await _dio.get('/community/users/$id/challenge-stats/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch challenge stats');
    }
  }

  Exception _handleError(DioException e, String defaultMessage) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = defaultMessage;
    if (data is Map<String, dynamic>) {
      message = (data['detail'] ?? data['message'] ?? data['error'] ?? defaultMessage)
          .toString();
    }
    return Exception('$message (HTTP $status)');
  }
}
