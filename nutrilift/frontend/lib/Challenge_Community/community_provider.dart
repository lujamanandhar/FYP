import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'community_api_service.dart';

/// Provider for community feed state.
///
/// Validates: Requirements 17.2, 17.4
class CommunityProvider extends ChangeNotifier {
  final CommunityApiService _service;

  List<PostModel> posts = [];
  bool isLoading = false;
  String? error;
  int currentPage = 1;
  bool hasMore = true;

  /// Persistent local bytes cache keyed by post ID.
  /// Survives fetchFeed() calls — never cleared automatically.
  final Map<String, List<Uint8List>> _localBytesCache = {};

  CommunityProvider(CommunityApiService service) : _service = service;

  /// Returns local bytes for a post if available.
  List<Uint8List> localBytesFor(String postId) =>
      _localBytesCache[postId] ?? const [];

  /// Fetch the first page of the community feed, resetting state.
  Future<void> fetchFeed() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _service.fetchFeed(1);
      posts = List<PostModel>.from(result['posts'] as List);
      hasMore = result['hasMore'] as bool;
      currentPage = 1;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load the next page and append results to [posts].
  ///
  /// No-op if [hasMore] is false or a load is already in progress.
  Future<void> loadMore() async {
    if (!hasMore || isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      final nextPage = currentPage + 1;
      final result = await _service.fetchFeed(nextPage);
      final newPosts = List<PostModel>.from(result['posts'] as List);
      posts = [...posts, ...newPosts];
      hasMore = result['hasMore'] as bool;
      currentPage = nextPage;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new post and prepend it to [posts].
  /// [localMediaBytes] are stored in the persistent cache keyed by post ID.
  Future<void> createPost(
    String content,
    List<String> imageUrls, {
    List<Uint8List> localMediaBytes = const [],
  }) async {
    try {
      final newPost = await _service.createPost(content, imageUrls);
      // Store bytes in persistent cache — survives fetchFeed()
      if (localMediaBytes.isNotEmpty) {
        _localBytesCache[newPost.id] = localMediaBytes;
      }
      posts = [newPost, ...posts];
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a post by ID and remove it from [posts].
  Future<void> deletePost(String postId) async {
    final backup = List<PostModel>.from(posts);
    posts = posts.where((p) => p.id != postId).toList();
    _localBytesCache.remove(postId);
    notifyListeners();
    try {
      await _service.deletePost(postId);
    } catch (e) {
      // Roll back on failure
      posts = backup;
      error = e.toString();
      notifyListeners();
    }
  }

  /// Edit a post's content (owner only). Optimistically updates the list.
  Future<void> editPost(String postId, String newContent) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final old = posts[index];
    // Optimistic update
    posts[index] = PostModel(
      id: old.id,
      userId: old.userId,
      username: old.username,
      avatarUrl: old.avatarUrl,
      content: newContent,
      imageUrls: old.imageUrls,
      likeCount: old.likeCount,
      commentCount: old.commentCount,
      isLikedByMe: old.isLikedByMe,
      createdAt: old.createdAt,
    );
    notifyListeners();
    try {
      await _service.editPost(postId, newContent);
    } catch (e) {
      // Roll back
      posts[index] = old;
      error = e.toString();
      notifyListeners();
    }
  }

  /// Optimistically toggle the like state on a post before the API call.
  ///
  /// Rolls back on failure — Requirement 17.4.
  Future<void> toggleLike(String postId) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = posts[index];
    // Optimistic update
    final wasLiked = post.isLikedByMe;
    post.isLikedByMe = !wasLiked;
    post.likeCount += wasLiked ? -1 : 1;
    notifyListeners();

    try {
      await _service.toggleLike(postId);
    } catch (e) {
      // Roll back on failure
      post.isLikedByMe = wasLiked;
      post.likeCount += wasLiked ? 1 : -1;
      error = e.toString();
      notifyListeners();
    }
  }

  /// Increment comment count for a post (called from comments sheet).
  void incrementCommentCount(String postId) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      posts[index].commentCount += 1;
      notifyListeners();
    }
  }

  /// Add a comment to a post and increment its [commentCount].
  Future<void> addComment(String postId, String content) async {
    try {
      await _service.addComment(postId, content);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        posts[index].commentCount += 1;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
