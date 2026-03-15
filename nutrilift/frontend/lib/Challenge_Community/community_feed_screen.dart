import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/token_service.dart';
import 'community_provider.dart';
import 'community_api_service.dart';
import 'comments_screen.dart' show showCommentsSheet;
import 'create_post_screen.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kRedLight = Color(0xFFFFEBEE);

/// Decode the current user's ID from the stored JWT token.
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
          return const Center(
            child: CircularProgressIndicator(color: _kRed),
          );
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
                    decoration: BoxDecoration(
                      color: _kRedLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 40, color: _kRed),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load feed',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchFeed(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
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
              padding: const EdgeInsets.only(
                  left: 12, right: 12, top: 12, bottom: 80),
              itemCount: provider.posts.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.posts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(color: _kRed)),
                  );
                }
                return _PostCard(post: provider.posts[index]);
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                ),
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Post',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _kRedLight,
                  backgroundImage: post.avatarUrl != null
                      ? NetworkImage(post.avatarUrl!)
                      : null,
                  child: post.avatarUrl == null
                      ? Text(
                          post.username.isNotEmpty
                              ? post.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: _kRed, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _timeAgo(post.createdAt),
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Consumer<CommunityProvider>(
                  builder: (context, provider, _) => PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final controller =
                            TextEditingController(text: post.content);
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 20,
                              bottom: MediaQuery.of(context).viewInsets.bottom +
                                  20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Edit Post',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: controller,
                                  maxLines: 5,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: _kRed),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(controller.text.trim()),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _kRed,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
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
                            content: const Text(
                                'Are you sure you want to delete this post?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                    foregroundColor: _kRed),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          provider.deletePost(post.id);
                        }
                      } else if (value == 'report') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post reported')),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      if (isOwner) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Report'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content text
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),

          // Media (images / videos)
          if (post.imageUrls.isNotEmpty ||
              context.read<CommunityProvider>().localBytesFor(post.id).isNotEmpty)
            _MediaSection(
              urls: post.imageUrls,
              localBytes: context.read<CommunityProvider>().localBytesFor(post.id),
              videoUrls: context.read<CommunityProvider>().videoUrlsFor(post.id),
            ),

          // Divider
          Divider(height: 1, color: Colors.grey[100]),

          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Consumer<CommunityProvider>(
                  builder: (context, provider, _) => _ActionButton(
                    icon: post.isLikedByMe
                        ? Icons.favorite
                        : Icons.favorite_border,
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

class _MediaSection extends StatefulWidget {
  final List<String> urls;
  final List<Uint8List> localBytes;
  final Set<String> videoUrls;
  const _MediaSection({required this.urls, this.localBytes = const [], this.videoUrls = const {}});

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
                // Claim horizontal drags so the parent ListView doesn't consume them
                onHorizontalDragStart: (_) {},
                onHorizontalDragUpdate: (details) {
                  _pageController.position.moveTo(
                    _pageController.offset - details.delta.dx,
                    clamp: true,
                  );
                },
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -300 && _currentPage < count - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  } else if (velocity > 300 && _currentPage > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    // Snap back to nearest page
                    _pageController.animateToPage(
                      _currentPage,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: count,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    if (hasLocal) {
                      return Image.memory(
                        widget.localBytes[i],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _brokenMedia(),
                      );
                    }
                    final url = widget.urls[i];
                    if (url.isEmpty) return _brokenMedia();
                    // Check provider's video set first, then fall back to extension check
                    final isVideo = widget.videoUrls.contains(url) || _isVideoUrl(url);
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
                                      color: _kRed, strokeWidth: 2)),
                            ),
                      errorBuilder: (_, __, ___) => _brokenMedia(),
                    );
                  },
                ),
              ),
            ),
            // Left arrow
            if (count > 1 && _currentPage > 0)
              Positioned(
                left: 4,
                child: _NavArrow(
                  icon: Icons.chevron_left,
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            // Right arrow
            if (count > 1 && _currentPage < count - 1)
              Positioned(
                right: 4,
                child: _NavArrow(
                  icon: Icons.chevron_right,
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            // Image counter badge (top-right)
            if (count > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1}/$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        // Page dots
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
          child:
              Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
        ),
      );
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String url;
  const _VideoThumbnail({required this.url});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  late final String _viewId;
  html.VideoElement? _videoEl;

  // Playback state
  bool _showReplay = false;
  int _loopCount = 0;
  static const int _maxLoops = 2;

  bool _isPaused = false;
  double _currentSec = 0;
  double _durationSec = 0;
  bool _isSeeking = false;

  // Controls visibility
  bool _showControls = false;
  DateTime? _controlsShownAt;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    _registerView();
    // Poll playback position every 250 ms
    _startPoller();
  }

  void _startPoller() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return false;
      final v = _videoEl;
      if (v != null && !_isSeeking) {
        final cur = v.currentTime.toDouble();
        final dur = v.duration.isNaN ? 0.0 : v.duration.toDouble();
        if (mounted) {
          setState(() {
            _currentSec = cur;
            _durationSec = dur;
          });
        }
      }
      // Auto-hide controls after 3 s
      if (_showControls && _controlsShownAt != null) {
        if (DateTime.now().difference(_controlsShownAt!).inSeconds >= 3) {
          if (mounted) setState(() => _showControls = false);
        }
      }
      return mounted;
    });
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final video = html.VideoElement()
        ..src = widget.url
        ..autoplay = true
        ..muted = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.background = '#000';

      video.onEnded.listen((_) {
        _loopCount++;
        if (_loopCount < _maxLoops) {
          video.currentTime = 0;
          video.play();
        } else {
          if (mounted) setState(() => _showReplay = true);
        }
      });

      _videoEl = video;
      return video;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _controlsShownAt = DateTime.now();
    });
  }

  void _resetControlsTimer() {
    _controlsShownAt = DateTime.now();
  }

  void _togglePlayPause() {
    _resetControlsTimer();
    final v = _videoEl;
    if (v == null) return;
    if (v.paused) {
      v.play();
      setState(() => _isPaused = false);
    } else {
      v.pause();
      setState(() => _isPaused = true);
    }
  }

  void _rewind10() {
    _resetControlsTimer();
    final v = _videoEl;
    if (v == null) return;
    final target = (v.currentTime - 10).clamp(0.0, v.duration.isNaN ? 0.0 : v.duration);
    v.currentTime = target;
    setState(() => _currentSec = target.toDouble());
  }

  void _seekTo(double sec) {
    final v = _videoEl;
    if (v == null) return;
    v.currentTime = sec;
    setState(() => _currentSec = sec);
  }

  void _replay() {
    setState(() {
      _showReplay = false;
      _loopCount = 0;
      _isPaused = false;
    });
    _videoEl?.currentTime = 0;
    _videoEl?.play();
  }

  String _fmt(double sec) {
    final s = sec.toInt();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _durationSec > 0 ? (_currentSec / _durationSec).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: _showReplay ? null : _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HtmlElementView(viewType: _viewId),

          // ── Controls overlay (tap to show/hide) ──────────────────
          if (!_showReplay && _showControls)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Centre row: rewind-10 + play/pause
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // -10 s button
                      GestureDetector(
                        onTap: _rewind10,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Play / Pause
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Seek bar + time ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: _kRed,
                            inactiveTrackColor: Colors.white38,
                            thumbColor: Colors.white,
                            overlayColor: _kRed.withOpacity(0.25),
                          ),
                          child: Slider(
                            value: progress,
                            min: 0,
                            max: 1,
                            onChangeStart: (_) {
                              _isSeeking = true;
                              _resetControlsTimer();
                            },
                            onChanged: (v) {
                              final target = v * _durationSec;
                              setState(() => _currentSec = target);
                            },
                            onChangeEnd: (v) {
                              _seekTo(v * _durationSec);
                              _isSeeking = false;
                              _resetControlsTimer();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmt(_currentSec),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                              Text(
                                _fmt(_durationSec),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── "Watch again" overlay after 2 loops ─────────────────
          if (_showReplay)
            Container(
              color: Colors.black.withOpacity(0.65),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _replay,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _kRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.replay, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Watch again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
