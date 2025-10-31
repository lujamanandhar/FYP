import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Community age screen for a fitness app with improved UI, live preview,
/// search, filters, likes/bookmarks, pull-to-refresh and bottom-sheet create-post.
class CommunityAgePage extends StatefulWidget {
  const CommunityAgePage({super.key});

  @override
  State<CommunityAgePage> createState() => _CommunityAgePageState();
}

class _CommunityAgePageState extends State<CommunityAgePage> {
  int? _age;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

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

  final Map<int, int> _likes = {};
  final Set<int> _bookmarked = {};
  final Set<String> _joinedGroups = {};
  final Set<String> _activeGroupFilters = {};
  String _sortBy = 'newest';
  int _nextId = 6;

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_onAgeTextChanged);
    _searchController.addListener(() => setState(() {}));
  }

  void _onAgeTextChanged() => setState(() {});

  @override
  void dispose() {
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
            return title.contains(query) ||
                content.contains(query) ||
                author.contains(query);
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
      _likes[id] = (_likes[id] ?? 0) + 1;
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
    // placeholder for network refresh - small delay for UX
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {});
  }

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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 36, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                Text('Create Post', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author')),
                const SizedBox(height: 8),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content'), maxLines: 4),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
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
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created')));
                        },
                        child: const Text('Post'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupFilterChips() {
    final groups = ['Teens (13-19)', 'Young adults (20-35)', 'Adults (36-55)', 'Seniors (56+)'];
    return Wrap(
      spacing: 8,
      children: groups.map((g) {
        final isActive = _activeGroupFilters.contains(g);
        return ChoiceChip(
          label: Text(g.split(' ').first),
          selected: isActive,
          selectedColor: Colors.blue.shade100,
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

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${(diff.inDays / 30).floor()}mo';
  }

  @override
  Widget build(BuildContext context) {
    final previewAge = _previewAge;
    final filtered = _filteredPostsFor(previewAge);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () => setState(() => _searchController.clear()), icon: const Icon(Icons.clear)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostSheet,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Age card
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
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
                                avatar: CircleAvatar(backgroundColor: _ageGroupColor(previewAge), child: Text(_ageGroupLabel(previewAge).split(' ').first[0], style: const TextStyle(color: Colors.white))),
                                backgroundColor: _ageGroupColor(previewAge).withOpacity(0.15),
                              ),
                      ),
                      if (_age != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Saved: $_age', style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search & sort
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search posts, authors, content',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  DropdownMenuItem(value: 'popularity', child: Text('Popular')),
                  DropdownMenuItem(value: 'ageRange', child: Text('Age')),
                ],
                onChanged: (v) => setState(() => _sortBy = v ?? 'newest'),
              ),
            ]),
            const SizedBox(height: 10),

            // Filter chips
            _buildGroupFilterChips(),
            const SizedBox(height: 12),

            // Header / info
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Text(
                  previewAge == null ? 'Set your age to see tailored posts.' : 'Showing ${filtered.length} post${filtered.length == 1 ? '' : 's'} for ${_ageGroupLabel(previewAge)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (previewAge != null)
                TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Explore general channels'))), icon: const Icon(Icons.explore_outlined), label: const Text('Explore')),
            ]),
            const SizedBox(height: 8),

            // Posts area
            Builder(builder: (context) {
              if (previewAge == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: Text('Set your age to see community posts tailored to your group.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)),
                );
              }

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: Text('No posts found for your age group. Try exploring or create one!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)),
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
                  final groupLabel = _rangeToLabel(min, max);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      elevation: 1,
                      borderRadius: BorderRadius.circular(12),
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
                              const SizedBox(width: 6),
                              Column(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  onPressed: () => _toggleLike(id),
                                  icon: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.favorite_border, size: 18, color: Colors.redAccent),
                                    const SizedBox(width: 6),
                                    Text('$likedCount', style: const TextStyle(fontSize: 14)),
                                  ]),
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
            const SizedBox(height: 80), // spacing for FAB
          ],
        ),
      ),
    );
  }
}
