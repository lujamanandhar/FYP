import 'package:flutter/material.dart';
import 'community_api_service.dart';

/// Screen showing a user's public profile with Posts and Followers tabs.
///
/// Validates: Requirements 14.1–14.4
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late final CommunityApiService _service;
  late final TabController _tabController;

  UserProfileModel? _profile;
  List<PostModel> _posts = [];
  List<UserProfileModel> _followers = [];

  bool _loadingProfile = true;
  bool _loadingPosts = true;
  bool _loadingFollowers = true;
  bool _togglingFollow = false;

  String? _profileError;

  @override
  void initState() {
    super.initState();
    _service = CommunityApiService();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    _loadPosts();
    _loadFollowers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await _service.fetchProfile(widget.userId);
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _profileError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final posts = await _service.fetchUserPosts(widget.userId);
      if (mounted) setState(() => _posts = posts);
    } catch (_) {
      // Posts tab will show empty state
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadFollowers() async {
    setState(() => _loadingFollowers = true);
    try {
      final followers = await _service.fetchFollowers(widget.userId);
      if (mounted) setState(() => _followers = followers);
    } catch (_) {
      // Followers tab will show empty state
    } finally {
      if (mounted) setState(() => _loadingFollowers = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null || _togglingFollow) return;
    setState(() => _togglingFollow = true);
    try {
      await _service.toggleFollow(widget.userId);
      if (mounted) {
        setState(() {
          _profile!.isFollowingMe = !_profile!.isFollowingMe;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update follow: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? 'Profile'),
        actions: [
          if (_profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _togglingFollow
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _profile!.isFollowingMe
                            ? Colors.grey[300]
                            : const Color(0xFF4CAF50),
                        foregroundColor: _profile!.isFollowingMe
                            ? Colors.black87
                            : Colors.white,
                      ),
                      child: Text(
                        _profile!.isFollowingMe ? 'Unfollow' : 'Follow',
                      ),
                    ),
            ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _profileError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_profileError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _ProfileHeader(profile: _profile!),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Followers'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _PostsTab(
                            posts: _posts,
                            isLoading: _loadingPosts,
                          ),
                          _FollowersTab(
                            followers: _followers,
                            isLoading: _loadingFollowers,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfileModel profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person, size: 36)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                        label: 'Posts', value: profile.postCount),
                    _StatColumn(
                        label: 'Followers', value: profile.followerCount),
                    _StatColumn(
                        label: 'Following', value: profile.followingCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _PostsTab extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading;

  const _PostsTab({required this.posts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (posts.isEmpty) {
      return const Center(
        child: Text('No posts yet', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.favorite_border,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.likeCount}',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.mode_comment_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FollowersTab extends StatelessWidget {
  final List<UserProfileModel> followers;
  final bool isLoading;

  const _FollowersTab({required this.followers, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (followers.isEmpty) {
      return const Center(
        child: Text('No followers yet', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: followers.length,
      itemBuilder: (context, index) {
        final user = followers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(user.username),
        );
      },
    );
  }
}
