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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _kRedLight,
                  backgroundImage:
                      post.avatarUrl != null ? NetworkImage(post.avatarUrl!) : null,
                  child: post.avatarUrl == null
                      ? Text(
                          post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
                          style: const TextStyle(color: _kRed, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
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
                    final url = widget.urls[i];
                    if (url.isEmpty) return _brokenMedia();
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
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final vid = _viewId;
      final videoUrl = widget.url;

      // ── Inject CSS once ──────────────────────────────────────────
      const styleId = 'vp-style-v15';
      if (html.document.getElementById(styleId) == null) {
        final s = html.StyleElement()..id = styleId;
        s.text = r'''
          .vpc{position:absolute;bottom:0;left:0;right:0;padding:0 12px 12px;
            background:linear-gradient(to top,rgba(0,0,0,.9) 0%,rgba(0,0,0,.3) 60%,transparent 100%);
            opacity:0;transition:opacity .2s;pointer-events:none;box-sizing:border-box}
          .vpc.on{opacity:1;pointer-events:all}
          .vpp{position:relative;height:28px;cursor:pointer;display:flex;align-items:center;
            margin-bottom:4px;touch-action:none;-webkit-user-select:none;user-select:none}
          .vpt{position:absolute;left:0;right:0;height:4px;background:rgba(255,255,255,.3);border-radius:2px}
          .vpf{position:absolute;left:0;top:0;height:4px;background:#E53935;border-radius:2px;
            width:0%;pointer-events:none}
          .vpth{position:absolute;top:50%;width:14px;height:14px;background:#fff;border-radius:50%;
            transform:translate(-50%,-50%);left:0%;box-shadow:0 1px 4px rgba(0,0,0,.7);pointer-events:none}
          .vpr{display:flex;align-items:center;gap:4px}
          .vptm{color:#fff;font-size:11px;font-family:system-ui,sans-serif;
            font-variant-numeric:tabular-nums;min-width:32px}
          .vptd{color:rgba(255,255,255,.55);text-align:right}
          .vpsp{flex:1}
          .vpb{background:rgba(255,255,255,.12);border:none;padding:0;cursor:pointer;
            display:flex;align-items:center;justify-content:center;
            width:48px;height:48px;border-radius:50%;color:#fff;
            font-size:11px;font-weight:bold;font-family:system-ui,sans-serif;
            transition:background .15s;touch-action:manipulation;-webkit-user-select:none;user-select:none}
          .vpb:hover{background:rgba(255,255,255,.28)}
          .vpcw{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);
            opacity:0;transition:opacity .2s;pointer-events:none}
          .vpcw.on{opacity:1;pointer-events:all}
          .vpplay{background:rgba(229,57,53,.88);cursor:pointer;width:60px;height:60px;
            border-radius:50%;display:flex;align-items:center;justify-content:center;
            box-shadow:0 3px 16px rgba(0,0,0,.55);transition:transform .12s,background .15s;
            touch-action:manipulation;-webkit-user-select:none;user-select:none}
          .vpplay:hover{transform:scale(1.08);background:#E53935}
          .vpstate-pause .vp-bar{width:4px;height:20px;background:#fff;border-radius:2px;
            display:block;margin:0 2px}
          .vpstate-play::after{content:'';display:block;border-style:solid;
            border-width:11px 0 11px 20px;border-color:transparent transparent transparent #fff;
            margin-left:5px}
          .vpro{position:absolute;inset:0;background:rgba(0,0,0,.65);display:none;
            flex-direction:column;align-items:center;justify-content:center;gap:12px}
          .vpro.on{display:flex}
          .vprb{background:#E53935;cursor:pointer;width:60px;height:60px;border-radius:50%;
            display:flex;align-items:center;justify-content:center;
            box-shadow:0 3px 16px rgba(0,0,0,.55);transition:transform .12s;
            touch-action:manipulation}
          .vprb:hover{transform:scale(1.08)}
          .vp-replay-icon{width:22px;height:22px;border-radius:50%;border:3px solid white;
            border-bottom-color:transparent;transform:rotate(45deg);position:relative}
          .vp-replay-icon::after{content:'';position:absolute;border:5px solid transparent;
            border-right-color:white;border-top-color:white;bottom:-4px;left:-6px;
            transform:rotate(-45deg)}
          .vprl{color:#fff;font-size:13px;font-weight:600;font-family:system-ui,sans-serif}
        ''';
        html.document.head!.append(s);
      }

      // ── Build DOM ────────────────────────────────────────────────
      final root = html.DivElement()
        ..id = '${vid}r'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.background = '#000'
        ..style.overflow = 'hidden';

      // Use trusted sanitizer so all HTML is preserved
      final tmp = html.DivElement();
      tmp.setInnerHtml('''
        <video id="${vid}v" src="$videoUrl" autoplay muted playsinline
          style="width:100%;height:100%;object-fit:contain;display:block;pointer-events:none"></video>
        <div class="vpcw" id="${vid}cw">
          <div class="vpplay vpstate-pause" id="${vid}pb">
            <div class="vp-bar"></div><div class="vp-bar"></div>
          </div>
        </div>
        <div class="vpc" id="${vid}ct">
          <div class="vpp" id="${vid}pg">
            <div class="vpt"></div>
            <div class="vpf" id="${vid}fl"></div>
            <div class="vpth" id="${vid}th"></div>
          </div>
          <div class="vpr">
            <span class="vptm" id="${vid}cu">0:00</span>
            <button class="vpb" id="${vid}b1">&#9664;&#9664;10</button>
            <button class="vpb" id="${vid}f1">10&#9654;&#9654;</button>
            <div class="vpsp"></div>
            <span class="vptm vptd" id="${vid}du">0:00</span>
          </div>
        </div>
        <div class="vpro" id="${vid}ro">
          <div class="vprb" id="${vid}rb"><div class="vp-replay-icon"></div></div>
          <span class="vprl">Watch again</span>
        </div>
      ''', treeSanitizer: html.NodeTreeSanitizer.trusted);
      root.append(tmp);

      // ── Inject JS — all event handling as native browser JS ──────
      // This bypasses Flutter's pointer event interception entirely.
      final script = html.ScriptElement();
      // Build the JS string using Dart string interpolation for the vid prefix,
      // but all logic is pure JS executed by the browser.
      script.text = '''
(function(){
  var P="${vid}";
  function init(){
    var v=document.getElementById(P+"v"),
        ct=document.getElementById(P+"ct"),
        cw=document.getElementById(P+"cw"),
        pb=document.getElementById(P+"pb"),
        pg=document.getElementById(P+"pg"),
        fl=document.getElementById(P+"fl"),
        th=document.getElementById(P+"th"),
        cu=document.getElementById(P+"cu"),
        du=document.getElementById(P+"du"),
        b1=document.getElementById(P+"b1"),
        f1=document.getElementById(P+"f1"),
        ro=document.getElementById(P+"ro"),
        rb=document.getElementById(P+"rb"),
        rt=document.getElementById(P+"r");
    if(!v||!ct){setTimeout(init,50);return;}
    var drag=false,htimer=null,loops=0,unmuted=false;
    function fmt(s){s=isNaN(s)||!isFinite(s)?0:Math.floor(s);return Math.floor(s/60)+":"+(s%60<10?"0":"")+(s%60);}
    function dur(){var d=v.duration;return isNaN(d)||!isFinite(d)?0:d;}
    function bar(t){var d=dur(),p=d>0?Math.min(100,Math.max(0,t/d*100)):0;fl.style.width=p+"%";th.style.left=p+"%";cu.textContent=fmt(t);du.textContent=fmt(d);}
    function show(){ct.classList.add("on");cw.classList.add("on");clearTimeout(htimer);htimer=setTimeout(function(){ct.classList.remove("on");cw.classList.remove("on");},4000);}
    function unmute(){if(!unmuted){unmuted=true;v.muted=false;}}
    function pause_icon(){pb.className="vpplay vpstate-pause";if(!pb.querySelector(".vp-bar")){pb.innerHTML='<div class="vp-bar"></div><div class="vp-bar"></div>';}}
    function play_icon(){pb.className="vpplay vpstate-play";pb.innerHTML="";}
    // root click = toggle controls
    if(rt)rt.addEventListener("click",function(e){unmute();if(ct.classList.contains("on")){ct.classList.remove("on");cw.classList.remove("on");clearTimeout(htimer);}else show();});
    if(rt)rt.addEventListener("mousemove",function(){show();});
    // play/pause
    pb.addEventListener("click",function(e){e.stopPropagation();unmute();if(v.paused){v.play().catch(function(){});pause_icon();}else{v.pause();play_icon();}show();});
    // skip
    function skip(d){return function(e){e.stopPropagation();e.preventDefault();unmute();var t=Math.min(Math.max(0,v.currentTime+d),dur()||Infinity);v.currentTime=t;bar(t);show();};}
    b1.addEventListener("click",skip(-10));
    f1.addEventListener("click",skip(10));
    b1.addEventListener("touchend",skip(-10));
    f1.addEventListener("touchend",skip(10));
    // progress bar mouse
    function seek(cx){var r=pg.getBoundingClientRect(),x=Math.min(Math.max(0,cx-r.left),r.width),t=(x/r.width)*dur();v.currentTime=t;bar(t);show();}
    pg.addEventListener("mousedown",function(e){e.stopPropagation();e.preventDefault();drag=true;seek(e.clientX);});
    pg.addEventListener("click",function(e){e.stopPropagation();});
    document.addEventListener("mousemove",function(e){if(drag)seek(e.clientX);});
    document.addEventListener("mouseup",function(){drag=false;});
    // progress bar touch
    pg.addEventListener("touchstart",function(e){e.stopPropagation();e.preventDefault();drag=true;seek(e.touches[0].clientX);},{passive:false});
    pg.addEventListener("touchmove",function(e){e.stopPropagation();e.preventDefault();if(drag)seek(e.touches[0].clientX);},{passive:false});
    pg.addEventListener("touchend",function(e){e.stopPropagation();drag=false;});
    // video events
    v.addEventListener("timeupdate",function(){if(!drag)bar(v.currentTime);});
    v.addEventListener("loadedmetadata",function(){du.textContent=fmt(dur());show();});
    v.addEventListener("ended",function(){loops++;if(loops<2){v.currentTime=0;v.play().catch(function(){});}else{ro.classList.add("on");ct.classList.remove("on");cw.classList.remove("on");}});
    // replay
    rb.addEventListener("click",function(){loops=0;ro.classList.remove("on");v.currentTime=0;v.play().catch(function(){});pause_icon();show();});
  }
  setTimeout(init,0);
})();
''';
      html.document.body!.append(script);

      return root;
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewId);
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
