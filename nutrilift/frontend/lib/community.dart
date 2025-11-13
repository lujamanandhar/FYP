import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Community age screen with tabs:
/// - Posts (existing feed)
/// - Results (users post body-status results, others can comment)
/// - Challenges (list of challenges to join/participate/create)
class CommunityAgePage extends StatefulWidget {
  const CommunityAgePage({super.key});

  @override
  State<CommunityAgePage> createState() => _CommunityAgePageState();
}

class _CommunityAgePageState extends State<CommunityAgePage> with SingleTickerProviderStateMixin {
  int? _age;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // ----- Posts (existing) -----
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'author': 'Alex',
      'minAge': 13,
      'maxAge': 19,
      'title': 'Teen bodyweight challenge',
      'content': '4 week bodyweight plan for teens wanting to build stamina.',
      'createdAt': DateTime.now().subtract(const Duration(days: 10))
    },
    {
      'id': 2,
      'author': 'Jamal',
      'minAge': 20,
      'maxAge': 35,
      'title': 'Morning HIIT group',
      'content': 'Join daily 20-min HIIT sessions, great for busy young adults.',
      'createdAt': DateTime.now().subtract(const Duration(days: 3))
    },
    {
      'id': 3,
      'author': 'Priya',
      'minAge': 36,
      'maxAge': 55,
      'title': 'Low impact strength',
      'content': 'Strength maintenance with low-impact routines and mobility.',
      'createdAt': DateTime.now().subtract(const Duration(days: 6))
    },
    {
      'id': 4,
      'author': 'Maria',
      'minAge': 56,
      'maxAge': 120,
      'title': 'Active seniors walk club',
      'content': 'Social walks and gentle strength exercises for seniors.',
      'createdAt': DateTime.now().subtract(const Duration(days: 1))
    },
    {
      'id': 5,
      'author': 'CoachSam',
      'minAge': 18,
      'maxAge': 120,
      'title': 'Nutrition tips for everyone',
      'content': 'Safe, general nutrition advice relevant across ages.',
      'createdAt': DateTime.now().subtract(const Duration(days: 8))
    },
  ];

  // like counts and toggled liked set
  final Map<int, int> _likes = {};
  final Set<int> _liked = {};
  final Set<int> _bookmarked = {};
  final Set<String> _joinedGroups = {};
  final Set<String> _activeGroupFilters = {};
  String _sortBy = 'newest';
  int _nextId = 6;

  // ----- Comments for posts and results -----
  final Map<int, List<Map<String, dynamic>>> _postComments = {}; // postId -> list of {author, text, createdAt}
  final Map<int, List<Map<String, dynamic>>> _resultComments = {}; // resultId -> list...

  // ----- Results (body status posts) -----
  final List<Map<String, dynamic>> _results = []; // {id, author, title, status, imageUrl?, createdAt, age}
  int _nextResultId = 1;

  // ----- Challenges -----
  final List<Map<String, dynamic>> _challenges = []; // {id, title, description, requirements(List<String>), minAge, maxAge, createdAt, participants:Set<int>}
  int _nextChallengeId = 1;
  final Set<int> _joinedChallenges = {};

  // UI controller for tabs
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_onAgeTextChanged);
    _searchController.addListener(() => setState(() {}));
    _tabController = TabController(length: 3, vsync: this);
    // seed likes for demo
    for (var p in _posts) {
      _likes[p['id'] as int] = (p['id'] as int) % 3; // small demo counts
    }
  }

  void _onAgeTextChanged() => setState(() {});

  @override
  void dispose() {
    _tabController.dispose();
    _ageController.removeListener(_onAgeTextChanged);
    _ageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int? get _previewAge {
    final parsed = int.tryParse(_ageController.text);
    if (parsed != null) return parsed;
    return _age;
  }

  String _ageGroupLabel(int age) {
    if (age >= 13 && age <= 19) return 'Teens (13-19)';
    if (age >= 20 && age <= 35) return 'Young adults (20-35)';
    if (age >= 36 && age <= 55) return 'Adults (36-55)';
    if (age >= 56) return 'Seniors (56+)';
    return 'Unknown';
  }

  Color _ageGroupColor(int age) {
    if (age >= 13 && age <= 19) return Colors.purple.shade300;
    if (age >= 20 && age <= 35) return Colors.blue.shade300;
    if (age >= 36 && age <= 55) return Colors.orange.shade300;
    if (age >= 56) return Colors.green.shade300;
    return Colors.grey.shade300;
  }

  List<Map<String, dynamic>> _filteredPostsFor(int? age) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredByAge = age == null
        ? _posts
        : _posts.where((p) {
            final min = p['minAge'] as int;
            final max = p['maxAge'] as int;
            return age >= min && age <= max;
          }).toList();

    final filteredByQuery = query.isEmpty
        ? filteredByAge
        : filteredByAge.where((p) {
            final title = (p['title'] as String).toLowerCase();
            final content = (p['content'] as String).toLowerCase();
            final author = (p['author'] as String).toLowerCase();
            return title.contains(query) || content.contains(query) || author.contains(query);
          }).toList();

    final filteredByGroupFilters = _activeGroupFilters.isEmpty
        ? filteredByQuery
        : filteredByQuery.where((p) {
            final min = p['minAge'] as int;
            final max = p['maxAge'] as int;
            final label = _rangeToLabel(min, max);
            return _activeGroupFilters.contains(label);
          }).toList();

    filteredByGroupFilters.sort((a, b) {
      if (_sortBy == 'newest') {
        final da = a['createdAt'] as DateTime;
        final db = b['createdAt'] as DateTime;
        return db.compareTo(da);
      } else if (_sortBy == 'popularity') {
        final la = _likes[a['id'] as int] ?? 0;
        final lb = _likes[b['id'] as int] ?? 0;
        return lb.compareTo(la);
      } else if (_sortBy == 'ageRange') {
        final amin = a['minAge'] as int;
        final bmin = b['minAge'] as int;
        return amin.compareTo(bmin);
      }
      return 0;
    });

    return filteredByGroupFilters;
  }

  String _rangeToLabel(int min, int max) {
    if (min >= 13 && max <= 19) return 'Teens (13-19)';
    if (min >= 20 && max <= 35) return 'Young adults (20-35)';
    if (min >= 36 && max <= 55) return 'Adults (36-55)';
    if (min >= 56) return 'Seniors (56+)';
    return 'Mixed';
  }

  void _incrementAge() {
    final current = int.tryParse(_ageController.text) ?? (_age ?? 25);
    final next = ((current + 1).clamp(13, 120)).toInt();
    _ageController.text = next.toString();
  }

  void _decrementAge() {
    final current = int.tryParse(_ageController.text) ?? (_age ?? 25);
    final next = ((current - 1).clamp(13, 120)).toInt();
    _ageController.text = next.toString();
  }

  void _saveAge(int age) {
    setState(() {
      _age = age;
      _ageController.text = age.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Age saved')),
    );
  }

  void _toggleLike(int id) {
    setState(() {
      if (_liked.contains(id)) {
        // unlike
        _liked.remove(id);
        _likes[id] = (_likes[id] ?? 1) - 1;
        if (_likes[id]! < 0) _likes[id] = 0;
      } else {
        _liked.add(id);
        _likes[id] = (_likes[id] ?? 0) + 1;
      }
    });
  }

  void _toggleBookmark(int id) {
    setState(() {
      if (_bookmarked.contains(id)) {
        _bookmarked.remove(id);
      } else {
        _bookmarked.add(id);
      }
    });
  }

  void _toggleJoinGroupLabel(String label) {
    setState(() {
      if (_joinedGroups.contains(label)) {
        _joinedGroups.remove(label);
      } else {
        _joinedGroups.add(label);
      }
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {});
  }

  // ----- Create post (existing) -----
  void _openCreatePostSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorCtrl = TextEditingController(text: 'You');
    final minCtrl = TextEditingController(text: '18');
    final maxCtrl = TextEditingController(text: '35');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 36, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Create Post', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 8),
                TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 8),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title))),
                const SizedBox(height: 8),
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content', prefixIcon: Icon(Icons.message)), maxLines: 4),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      decoration: const InputDecoration(labelText: 'Min age'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      decoration: const InputDecoration(labelText: 'Max age'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final content = contentCtrl.text.trim();
                        final author = authorCtrl.text.trim().isEmpty ? 'Anonymous' : authorCtrl.text.trim();
                        final min = int.tryParse(minCtrl.text) ?? 13;
                        final max = int.tryParse(maxCtrl.text) ?? 120;
                        if (title.isEmpty || content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and content required')));
                          return;
                        }
                        if (min < 13) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Min age must be >= 13')));
                          return;
                        }
                        setState(() {
                          final newPost = {
                            'id': _nextId++,
                            'author': author,
                            'minAge': min,
                            'maxAge': max,
                            'title': title,
                            'content': content,
                            'createdAt': DateTime.now(),
                          };
                          _posts.insert(0, newPost);
                          _likes[newPost['id'] as int] = 0;
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created')));
                      },
                      child: const Text('Post'),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----- Results: create result (body status) -----
  void _openCreateResultSheet({int? linkedChallengeId}) {
    final titleCtrl = TextEditingController();
    final statusCtrl = TextEditingController();
    final imgCtrl = TextEditingController(); // image URL (optional)
    final authorCtrl = TextEditingController(text: 'You');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(height: 4, width: 36, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(linkedChallengeId != null ? 'Submit Result' : 'Post Result', style: Theme.of(context).textTheme.titleLarge),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 8),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title))),
              const SizedBox(height: 8),
              TextField(controller: statusCtrl, decoration: const InputDecoration(labelText: 'Body status / description', prefixIcon: Icon(Icons.info)), maxLines: 4),
              const SizedBox(height: 8),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Optional image URL', prefixIcon: Icon(Icons.image))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final status = statusCtrl.text.trim();
                      final author = authorCtrl.text.trim().isEmpty ? 'Anonymous' : authorCtrl.text.trim();
                      final img = imgCtrl.text.trim().isEmpty ? null : imgCtrl.text.trim();
                      if (title.isEmpty || status.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and status required')));
                        return;
                      }
                      setState(() {
                        final newResult = {
                          'id': _nextResultId++,
                          'author': author,
                          'title': title,
                          'status': status,
                          'image': img,
                          'createdAt': DateTime.now(),
                          'age': _previewAge,
                          'linkedChallengeId': linkedChallengeId,
                        };
                        _results.insert(0, newResult);
                        _resultComments[newResult['id'] as int] = [];
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result posted')));
                    },
                    child: const Text('Post'),
                  ),
                )
              ]),
              const SizedBox(height: 16),
            ]),
          ),
        );
      },
    );
  }

  // ----- Comments handling -----
  void _openCommentsForPost(int postId) {
    final comments = _postComments[postId] ?? [];
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 420,
            child: Column(children: [
              ListTile(title: Text('Comments (${comments.length})'), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())),
              const Divider(height: 1),
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text('No comments yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final c = comments[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text((c['author'] as String).isNotEmpty ? c['author'][0].toUpperCase() : '?')),
                            title: Text(c['author'] as String),
                            subtitle: Text(c['text'] as String),
                            trailing: Text(_timeAgo(c['createdAt'] as DateTime), style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Write a comment...'))),
                  IconButton(
                    onPressed: () {
                      final txt = ctrl.text.trim();
                      if (txt.isEmpty) return;
                      setState(() {
                        _postComments.putIfAbsent(postId, () => []).add({'author': 'You', 'text': txt, 'createdAt': DateTime.now()});
                      });
                      ctrl.clear();
                      // stay open
                    },
                    icon: const Icon(Icons.send),
                  )
                ]),
              )
            ]),
          ),
        );
      },
    );
  }

  void _openCommentsForResult(int resultId) {
    final comments = _resultComments[resultId] ?? [];
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 420,
            child: Column(children: [
              ListTile(title: Text('Comments (${comments.length})'), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())),
              const Divider(height: 1),
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text('No comments yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final c = comments[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text((c['author'] as String).isNotEmpty ? c['author'][0].toUpperCase() : '?')),
                            title: Text(c['author'] as String),
                            subtitle: Text(c['text'] as String),
                            trailing: Text(_timeAgo(c['createdAt'] as DateTime), style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Write a comment...'))),
                  IconButton(
                    onPressed: () {
                      final txt = ctrl.text.trim();
                      if (txt.isEmpty) return;
                      setState(() {
                        _resultComments.putIfAbsent(resultId, () => []).add({'author': 'You', 'text': txt, 'createdAt': DateTime.now()});
                      });
                      ctrl.clear();
                      // stay open
                    },
                    icon: const Icon(Icons.send),
                  )
                ]),
              )
            ]),
          ),
        );
      },
    );
  }

  // ----- Challenges: create and join/participate -----
  void _openCreateChallengeSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final reqCtrl = TextEditingController(); // comma separated requirements
    final minCtrl = TextEditingController(text: '13');
    final maxCtrl = TextEditingController(text: '120');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(height: 4, width: 36, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Create Challenge', style: Theme.of(context).textTheme.titleLarge),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: reqCtrl, decoration: const InputDecoration(labelText: 'Requirements (comma separated)')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: minCtrl, decoration: const InputDecoration(labelText: 'Min age'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: maxCtrl, decoration: const InputDecoration(labelText: 'Max age'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final desc = descCtrl.text.trim();
                      final reqs = reqCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                      final min = int.tryParse(minCtrl.text) ?? 13;
                      final max = int.tryParse(maxCtrl.text) ?? 120;
                      if (title.isEmpty || desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and description required')));
                        return;
                      }
                      setState(() {
                        final ch = {
                          'id': _nextChallengeId++,
                          'title': title,
                          'description': desc,
                          'requirements': reqs,
                          'minAge': min,
                          'maxAge': max,
                          'createdAt': DateTime.now(),
                          'participants': <int>{},
                        };
                        _challenges.insert(0, ch);
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Challenge created')));
                    },
                    child: const Text('Create'),
                  ),
                )
              ]),
              const SizedBox(height: 16),
            ]),
          ),
        );
      },
    );
  }

  void _toggleJoinChallenge(int challengeId) {
    setState(() {
      if (_joinedChallenges.contains(challengeId)) {
        _joinedChallenges.remove(challengeId);
      } else {
        _joinedChallenges.add(challengeId);
      }
    });
  }

  // ----- Utility: time ago -----
  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${(diff.inDays / 30).floor()}mo';
  }

  Widget _buildGroupFilterChips() {
    final groups = ['Teens (13-19)', 'Young adults (20-35)', 'Adults (36-55)', 'Seniors (56+)'];
    return Wrap(
      spacing: 8,
      children: groups.map((g) {
        final isActive = _activeGroupFilters.contains(g);
        final isJoined = _joinedGroups.contains(g);
        return FilterChip(
          label: Text(g, style: const TextStyle(fontSize: 12)),
          selected: isActive,
          avatar: isJoined ? const Icon(Icons.check_circle, size: 18, color: Colors.white) : null,
          backgroundColor: Colors.grey.shade100,
          selectedColor: Colors.blue.shade50,
          onSelected: (sel) {
            setState(() {
              if (sel) {
                _activeGroupFilters.add(g);
              } else {
                _activeGroupFilters.remove(g);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _postsTab(int? previewAge, List<Map<String, dynamic>> filtered, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Age card (same as before)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Your age', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(children: [
                        IconButton(onPressed: _decrementAge, icon: const Icon(Icons.remove_circle_outline)),
                        SizedBox(
                          width: 92,
                          child: TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'e.g. 25',
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        IconButton(onPressed: _incrementAge, icon: const Icon(Icons.add_circle_outline)),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            final value = int.tryParse(_ageController.text);
                            if (value == null || value < 13) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid age (13+)')));
                              return;
                            }
                            _saveAge(value);
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ])
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Group', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: previewAge == null
                          ? Chip(key: const ValueKey('u'), label: const Text('Unset'), backgroundColor: Colors.grey.shade200)
                          : Chip(
                              key: ValueKey(previewAge),
                              label: Text(_ageGroupLabel(previewAge)),
                              avatar: CircleAvatar(
                                backgroundColor: _ageGroupColor(previewAge),
                                child: Text(_ageGroupLabel(previewAge).split(' ').first[0], style: const TextStyle(color: Colors.white)),
                              ),
                              backgroundColor: _ageGroupColor(previewAge).withOpacity(0.12),
                            ),
                    ),
                    if (_age != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Saved: $_age', style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters summary and reset
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(
                previewAge == null ? 'Set your age to see tailored posts.' : 'Showing ${filtered.length} post${filtered.length == 1 ? '' : 's'} for ${previewAge != null ? _ageGroupLabel(previewAge) : ''}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _activeGroupFilters.clear();
                  _joinedGroups.clear();
                  _searchController.clear();
                  _sortBy = 'newest';
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filters reset')));
              },
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Reset'),
            )
          ]),
          const SizedBox(height: 10),
          _buildGroupFilterChips(),
          const SizedBox(height: 12),
          // Posts list (same as original, plus comments)
          Builder(builder: (context) {
            if (previewAge == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Text('Set your age to see community posts tailored to your group.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(onPressed: () => _ageController.text = '25', icon: const Icon(Icons.person), label: const Text('Quick set to 25')),
                    ],
                  ),
                ),
              );
            }

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Text('No posts found for your age group. Try exploring or create one!', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(onPressed: _openCreatePostSheet, icon: const Icon(Icons.add), label: const Text('Create a post')),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: filtered.map((post) {
                final id = post['id'] as int;
                final author = post['author'] as String;
                final initials = author.isNotEmpty ? author[0].toUpperCase() : '?';
                final min = post['minAge'] as int;
                final max = post['maxAge'] as int;
                final createdAt = post['createdAt'] as DateTime;
                final likedCount = _likes[id] ?? 0;
                final isBookmarked = _bookmarked.contains(id);
                final isLiked = _liked.contains(id);
                final groupLabel = _rangeToLabel(min, max);
                final commentsCount = (_postComments[id] ?? []).length;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(post['title'] as String),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post['content'] as String),
                                const SizedBox(height: 12),
                                Text('Author: $author'),
                                Text('Target: $min–$max yrs'),
                                Text('Posted: ${createdAt.toLocal()}'),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                              TextButton(
                                onPressed: () {
                                  setState(() => _bookmarked.add(id));
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmarked')));
                                },
                                child: const Text('Bookmark'),
                              )
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.primaries[(id + 3) % Colors.primaries.length].shade300,
                              child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(post['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700))),
                                  const SizedBox(width: 8),
                                  Text(_timeAgo(createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ]),
                                const SizedBox(height: 6),
                                Text(post['content'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, runSpacing: 6, children: [
                                  Chip(label: Text('$min–$max yrs'), backgroundColor: Colors.grey.shade100, visualDensity: VisualDensity.compact),
                                  ActionChip(
                                    label: Text(groupLabel),
                                    onPressed: () => _toggleJoinGroupLabel(groupLabel),
                                    avatar: Icon(_joinedGroups.contains(groupLabel) ? Icons.check_circle : Icons.group, size: 18),
                                  ),
                                  Chip(avatar: const Icon(Icons.person, size: 16), label: Text(author), backgroundColor: Colors.grey.shade100),
                                ])
                              ]),
                            ),
                            const SizedBox(width: 8),
                            Column(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                onPressed: () => _toggleLike(id),
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                  child: isLiked
                                      ? const Icon(Icons.favorite, key: ValueKey('fav'), color: Colors.redAccent)
                                      : const Icon(Icons.favorite_border, key: ValueKey('fav_outline'), color: Colors.redAccent),
                                ),
                              ),
                              Text(likedCount.toString(), style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 6),
                              IconButton(
                                onPressed: () => _openCommentsForPost(id),
                                icon: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.mode_comment_outlined),
                                    if (commentsCount > 0)
                                      Positioned(right: -6, top: -6, child: CircleAvatar(radius: 8, backgroundColor: Colors.redAccent, child: Text(commentsCount.toString(), style: const TextStyle(fontSize: 10, color: Colors.white)))),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _toggleBookmark(id),
                                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _resultsTab(ThemeData theme) {
    final filteredResults = _results.where((r) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return (r['title'] as String).toLowerCase().contains(query) || (r['status'] as String).toLowerCase().contains(query) || (r['author'] as String).toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text('Results feed — people post their body status and progress. Tap to view and comment.', style: theme.textTheme.bodyMedium)),
          TextButton.icon(onPressed: () => _openCreateResultSheet(), icon: const Icon(Icons.add), label: const Text('New')),
        ]),
        const SizedBox(height: 12),
        if (filteredResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                children: [
                  Text('No results yet. Be the first to post!', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: () => _openCreateResultSheet(), icon: const Icon(Icons.add), label: const Text('Post result')),
                ],
              ),
            ),
          )
        else
          Column(
            children: filteredResults.map((r) {
              final id = r['id'] as int;
              final author = r['author'] as String;
              final createdAt = r['createdAt'] as DateTime;
              final img = r['image'] as String?;
              final title = r['title'] as String;
              final status = r['status'] as String;
              final linked = r['linkedChallengeId'] as int?;
              final commentsCount = (_resultComments[id] ?? []).length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(backgroundColor: Colors.primaries[id % Colors.primaries.length].shade300, child: Text(author.isNotEmpty ? author[0].toUpperCase() : '?')) ,
                        const SizedBox(width: 10),
                        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Text(_timeAgo(createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      Text(status),
                      if (img != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(height: 160, child: Center(child: Text('Image preview (URL): $img', style: const TextStyle(fontSize: 12)))),
                      ],
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, children: [
                        TextButton.icon(onPressed: () => _openCommentsForResult(id), icon: const Icon(Icons.mode_comment_outlined), label: Text('Comment (${commentsCount.toString()})')),
                        if (linked != null)
                          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.flag), label: Text('Challenge #$linked')),
                      ]),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _challengesTab(ThemeData theme) {
    final filtered = _challenges.where((c) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return (c['title'] as String).toLowerCase().contains(query) || (c['description'] as String).toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text('Challenges — join, participate, or create challenges with requirements.', style: theme.textTheme.bodyMedium)),
          TextButton.icon(onPressed: _openCreateChallengeSheet, icon: const Icon(Icons.add_box), label: const Text('Create')),
        ]),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                children: [
                  Text('No challenges yet. Create one!', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: _openCreateChallengeSheet, icon: const Icon(Icons.post_add), label: const Text('Create challenge')),
                ],
              ),
            ),
          )
        else
          Column(
            children: filtered.map((c) {
              final id = c['id'] as int;
              final title = c['title'] as String;
              final desc = c['description'] as String;
              final reqs = (c['requirements'] as List).cast<String>();
              final createdAt = c['createdAt'] as DateTime;
              final min = c['minAge'] as int;
              final max = c['maxAge'] as int;
              final joined = _joinedChallenges.contains(id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Text(_timeAgo(createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      Text(desc),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: reqs.map((r) => Chip(label: Text(r), backgroundColor: Colors.grey.shade100)).toList()),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Target: $min–$max yrs', style: TextStyle(color: Colors.grey.shade700)),
                        Row(children: [
                          TextButton.icon(
                            onPressed: () {
                              _toggleJoinChallenge(id);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(joined ? 'Left challenge' : 'Joined challenge')));
                            },
                            icon: Icon(joined ? Icons.exit_to_app : Icons.person_add),
                            label: Text(joined ? 'Leave' : 'Join'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Participate -> open create result sheet with linked challenge id
                              _openCreateResultSheet(linkedChallengeId: id);
                            },
                            child: const Text('Participate'),
                          )
                        ]),
                      ])
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 80),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewAge = _previewAge;
    final filtered = _filteredPostsFor(previewAge);
    final theme = Theme.of(context);

    // contextual FAB label/icon
    final fabLabel = _tabController.index == 0
        ? 'New Post'
        : _tabController.index == 1
            ? 'New Result'
            : 'New Challenge';
    final fabIcon = _tabController.index == 0 ? Icons.forum : _tabController.index == 1 ? Icons.self_improvement : Icons.emoji_events;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Community'),
            if (_age != null) Text('Saved age: $_age', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort / New post',
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'new_post') {
                // open sheet depending on tab
                if (_tabController.index == 0) _openCreatePostSheet();
                if (_tabController.index == 1) _openCreateResultSheet();
                if (_tabController.index == 2) _openCreateChallengeSheet();
              } else {
                setState(() => _sortBy = v);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'new_post', child: Text('Create')),
              const PopupMenuItem(value: 'newest', child: Text('Sort: Newest')),
              const PopupMenuItem(value: 'popularity', child: Text('Sort: Popular')),
              const PopupMenuItem(value: 'ageRange', child: Text('Sort: Age range')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      elevation: 1,
                      borderRadius: BorderRadius.circular(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search posts, results, challenges',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() => _searchController.clear()),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    tooltip: 'Sort',
                    icon: const Icon(Icons.sort),
                    onSelected: (v) => setState(() => _sortBy = v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'newest', child: Text('Newest')),
                      PopupMenuItem(value: 'popularity', child: Text('Popular')),
                      PopupMenuItem(value: 'ageRange', child: Text('Age range')),
                    ],
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.forum), text: 'Posts'),
                Tab(icon: Icon(Icons.self_improvement), text: 'Results'),
                Tab(icon: Icon(Icons.emoji_events), text: 'Challenges'),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // context aware create
          if (_tabController.index == 0) _openCreatePostSheet();
          if (_tabController.index == 1) _openCreateResultSheet();
          if (_tabController.index == 2) _openCreateChallengeSheet();
        },
        icon: Icon(fabIcon),
        label: Text(fabLabel),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _postsTab(previewAge, filtered, theme),
          _resultsTab(theme),
          _challengesTab(theme),
        ],
      ),
    );
  }
}
