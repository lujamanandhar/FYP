import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/token_service.dart';
import '../services/app_config.dart';
import 'community_provider.dart';
import 'community_api_service.dart';
import 'comments_screen.dart' show showCommentsSheet;
import 'create_post_screen.dart';
import 'user_profile_screen.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kRedLight = Color(0xFFFFEBEE);

Future<String?> _getCurrentUserId() async {
  final token = await TokenService().getToken();
  if (token == null) return null;
  final payload = TokenService().getTokenPayload(token);
  return payload?['user_id'] as String?;
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}

bool _isVideoUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.webm');
}

// ─────────────────────────────────────────────────────────────────────────────
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});
  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchFeed();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CommunityProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _kRed));
        }
        if (provider.error != null && provider.posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: _kRedLight, shape: BoxShape.circle),
                    child: const Icon(Icons.wifi_off_rounded, size: 40, color: _kRed),
                  ),
                  const SizedBox(height: 16),
                  const Text('Could not load feed',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchFeed(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80),
              itemCount: provider.posts.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.posts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: _kRed)),
                  );
                }
                return _PostCard(post: provider.posts[index]);
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const CreatePostScreen())),
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final PostModel post;
  const _PostCard({required this.post});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId().then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isOwner = _currentUserId != null && _currentUserId == post.userId;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: post.userId),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: _kRedLight,
                    backgroundImage:
                        post.avatarUrl != null ? NetworkImage(AppConfig.resolveMediaUrl(post.avatarUrl!)) : null,
                    child: post.avatarUrl == null
                        ? Text(
                            post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
                            style: const TextStyle(color: _kRed, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: post.userId),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_timeAgo(post.createdAt),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Consumer<CommunityProvider>(
                  builder: (context, provider, _) => PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final controller = TextEditingController(text: post.content);
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 20,
                              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Edit Post',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: controller,
                                  maxLines: 5,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _kRed),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel')),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(controller.text.trim()),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _kRed,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                        if (result != null && result.isNotEmpty) {
                          provider.editPost(post.id, result);
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Post'),
                            content:
                                const Text('Are you sure you want to delete this post?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(foregroundColor: _kRed),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) provider.deletePost(post.id);
                      } else if (value == 'report') {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Post reported')));
                      }
                    },
                    itemBuilder: (_) => [
                      if (isOwner) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(children: [
                          Icon(Icons.flag_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Report'),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Text(post.content, style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          Consumer<CommunityProvider>(
            builder: (context, provider, _) {
              final localBytes = provider.localBytesFor(post.id);
              final videoUrls = provider.videoUrlsFor(post.id);
              if (post.imageUrls.isEmpty && localBytes.isEmpty) return const SizedBox.shrink();
              return _MediaSection(
                urls: post.imageUrls,
                localBytes: localBytes,
                videoUrls: videoUrls,
              );
            },
          ),
          Divider(height: 1, color: Colors.grey[100]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Consumer<CommunityProvider>(
                  builder: (context, provider, _) => _ActionButton(
                    icon: post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likeCount}',
                    color: post.isLikedByMe ? _kRed : Colors.grey[600]!,
                    onTap: () => provider.toggleLike(post.id),
                  ),
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.commentCount}',
                  color: Colors.grey[600]!,
                  onTap: () => showCommentsSheet(context, post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _MediaSection extends StatefulWidget {
  final List<String> urls;
  final List<Uint8List> localBytes;
  final Set<String> videoUrls;
  const _MediaSection(
      {required this.urls, this.localBytes = const [], this.videoUrls = const {}});
  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocal = widget.localBytes.isNotEmpty;
    final count = hasLocal ? widget.localBytes.length : widget.urls.length;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 280,
              child: GestureDetector(
                onHorizontalDragStart: (_) {},
                onHorizontalDragUpdate: (details) {
                  _pageController.position
                      .moveTo(_pageController.offset - details.delta.dx, clamp: true);
                },
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -300 && _currentPage < count - 1) {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                  } else if (v > 300 && _currentPage > 0) {
                    _pageController.previousPage(
                        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                  } else {
                    _pageController.animateToPage(_currentPage,
                        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                  }
                },
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: count,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    if (hasLocal) {
                      return Image.memory(widget.localBytes[i],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _brokenMedia());
                    }
                    final url = AppConfig.resolveMediaUrl(widget.urls[i]);
                    if (url.isEmpty) return _brokenMedia();
                    final isVideo = widget.videoUrls.contains(widget.urls[i]) || widget.videoUrls.contains(url) || _isVideoUrl(url);
                    if (isVideo) return _VideoThumbnail(url: url);
                    return Image.network(
                      url,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: Colors.grey[100],
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      color: _kRed, strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => _brokenMedia(),
                    );
                  },
                ),
              ),
            ),
            if (count > 1 && _currentPage > 0)
              Positioned(
                  left: 4,
                  child: _NavArrow(
                      icon: Icons.chevron_left,
                      onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut))),
            if (count > 1 && _currentPage < count - 1)
              Positioned(
                  right: 4,
                  child: _NavArrow(
                      icon: Icons.chevron_right,
                      onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut))),
            if (count > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: Text('${_currentPage + 1}/$count',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        if (count > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                count,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? _kRed : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _brokenMedia() => Container(
        color: Colors.grey[100],
        child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _VideoThumbnail extends StatefulWidget {
  final String url;
  const _VideoThumbnail({required this.url});
  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'vp-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    // Web-only video player - not applicable for mobile
    // For mobile, use native video player or platform-specific implementation
  }

  @override
  Widget build(BuildContext context) {
    // Mobile placeholder - web-only video player not supported on mobile
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Video Player',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Video playback coming soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
