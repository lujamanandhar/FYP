import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'admin_service.dart';

const _kRed = Color(0xFFE53935);

class AdminReportedPostsScreen extends StatefulWidget {
  const AdminReportedPostsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportedPostsScreen> createState() => _AdminReportedPostsScreenState();
}

class _AdminReportedPostsScreenState extends State<AdminReportedPostsScreen> {
  final _service = AdminService();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200
        && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; _currentPage = 1; });
    try {
      final data = await _service.getReportedPosts(page: 1);
      setState(() {
        _posts = data['results'] ?? [];
        _hasMore = data['next'] != null;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final data = await _service.getReportedPosts(page: _currentPage + 1);
      setState(() {
        _posts.addAll(data['results'] ?? []);
        _hasMore = data['next'] != null;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _removePost(String postId, String authorName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Post', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Remove this post by $authorName? The author will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.removePost(postId);
      showCenterToast(context, 'Post removed and author notified.');
      _load();
    } catch (e) {
      showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _dismissReports(String postId) async {
    try {
      await _service.dismissReports(postId);
      showCenterToast(context, 'Reports dismissed. Post stays visible.');
      _load();
    } catch (e) {
      showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ]),
      );
    }
    if (_posts.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.flag_outlined, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('No reported posts', style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 8),
          Text('All clear!', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return RefreshIndicator(
      color: _kRed,
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: _kRed, strokeWidth: 2)),
            );
          }
          return _ReportedPostCard(
            post: _posts[i],
            onRemove: () => _removePost(_posts[i]['post_id'], _posts[i]['author_name'] ?? ''),
            onDismiss: () => _dismissReports(_posts[i]['post_id']),
          );
        },
      ),
    );
  }
}

class _ReportedPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onRemove;
  final VoidCallback onDismiss;
  const _ReportedPostCard({required this.post, required this.onRemove, required this.onDismiss});

  @override
  State<_ReportedPostCard> createState() => _ReportedPostCardState();
}

class _ReportedPostCardState extends State<_ReportedPostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final reports = post['reports'] as List? ?? [];
    final isRemoved = post['is_removed'] == true;
    final reportCount = post['report_count'] as int? ?? reports.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRemoved ? Colors.grey[300]! : _kRed.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRemoved ? Colors.grey[100] : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isRemoved ? Icons.block : Icons.flag_rounded,
                      size: 13, color: isRemoved ? Colors.grey : _kRed),
                  const SizedBox(width: 4),
                  Text(
                    isRemoved ? 'REMOVED' : '$reportCount REPORT${reportCount != 1 ? 'S' : ''}',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold,
                      color: isRemoved ? Colors.grey : _kRed,
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'by ${post['author_name'] ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            // Post content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                post['content']?.toString().isNotEmpty == true
                    ? post['content']
                    : '[Image post]',
                style: const TextStyle(fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Reports expandable
            if (reports.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(children: [
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _expanded ? 'Hide reasons' : 'View report reasons',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ]),
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                ...reports.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kRed.withOpacity(0.15)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r['reported_by'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(r['reason'] ?? '', style: const TextStyle(fontSize: 12)),
                      ]),
                    ),
                  ]),
                )),
              ],
            ],
            // Actions
            if (!isRemoved) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.check_circle_outline, size: 15, color: Colors.green),
                    label: const Text('Dismiss', style: TextStyle(fontSize: 12, color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline, size: 15),
                    label: const Text('Remove Post', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ]),
            ] else
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('Post has been removed', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
