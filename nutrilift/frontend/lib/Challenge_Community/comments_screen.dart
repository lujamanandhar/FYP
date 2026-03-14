import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'community_api_service.dart';
import 'community_provider.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kRedLight = Color(0xFFFFEBEE);

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}

/// Show comments as a draggable bottom sheet.
/// Increments [post.commentCount] in [CommunityProvider] on successful submit.
void showCommentsSheet(BuildContext context, PostModel post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<CommunityProvider>(),
      child: _CommentsSheet(post: post),
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  final PostModel post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final CommunityApiService _service = CommunityApiService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final comments = await _service.fetchComments(widget.post.id);
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (mounted) setState(() { _comments = comments; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      // Call service directly to get the comment object back
      final comment = await _service.addComment(widget.post.id, text);
      // Update the count on the feed card via provider
      context.read<CommunityProvider>().incrementCommentCount(widget.post.id);
      setState(() {
        _comments.add(comment);
        _ctrl.clear();
        _isSending = false;
      });
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Text('Comments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Comments list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kRed))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!,
                                    style:
                                        const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _fetchComments,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: _kRed,
                                      foregroundColor: Colors.white),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _comments.isEmpty
                            ? const Center(
                                child: Text('No comments yet. Be the first!',
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                controller: _scrollCtrl,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _comments.length,
                                itemBuilder: (_, i) {
                                  final c = _comments[i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: _kRedLight,
                                          backgroundImage: c.avatarUrl != null
                                              ? NetworkImage(c.avatarUrl!)
                                              : null,
                                          child: c.avatarUrl == null
                                              ? Text(
                                                  c.username.isNotEmpty
                                                      ? c.username[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                      color: _kRed,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(c.username,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13)),
                                                  const SizedBox(width: 6),
                                                  Text(_timeAgo(c.createdAt),
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey[500])),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(c.content,
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
              // Input bar
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 8, bottomInset + 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: _kRed, strokeWidth: 2))
                        : GestureDetector(
                            onTap: _sendComment,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  color: _kRed, shape: BoxShape.circle),
                              child: const Icon(Icons.send,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
