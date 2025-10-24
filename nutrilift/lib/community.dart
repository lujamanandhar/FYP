import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Community age screen for a fitness app with improved UI, live preview,
/// plus search, filters, likes, bookmarks and create-post flow.
class CommunityAgePage extends StatefulWidget {
  const CommunityAgePage({super.key});

  @override
  State<CommunityAgePage> createState() => _CommunityAgePageState();
}

class _CommunityAgePageState extends State<CommunityAgePage> {
  int? _age;
  final TextEditingController _ageController = TextEditingController();

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Example community posts with target age ranges
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

  // Likes and bookmarks (local in-memory)
  final Map<int, int> _likes = {};
  final Set<int> _bookmarked = {};

  // Simple group join tracking (local)
  final Set<String> _joinedGroups = {};

  // UI controls
  String _sortBy = 'newest'; // 'newest' | 'ageRange' | 'popularity'
  final Set<String> _activeGroupFilters = {}; // e.g. 'Teens (13-19)'

  int _nextId = 6;

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_onAgeTextChanged);
    _searchController.addListener(() => setState(() {}));
  }

  void _onAgeTextChanged() {
    setState(() {}); // live preview rebuild
  }

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

  // Combined filtering: by age (if set), by search text, by active group filters.
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

    // Sorting
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

  void _createPostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorCtrl = TextEditingController(text: 'You');
    final minCtrl = TextEditingController(text: '18');
    final maxCtrl = TextEditingController(text: '35');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create post'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author')),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
              Row(
                children: [
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
                  )
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
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
        ],
      ),
    );
  }

  Widget _buildGroupFilterChips() {
    final groups = [
      'Teens (13-19)',
      'Young adults (20-35)',
      'Adults (36-55)',
      'Seniors (56+)'
    ];
    return Wrap(
      spacing: 6,
      children: groups.map((g) {
        final isActive = _activeGroupFilters.contains(g);
        return FilterChip(
          label: Text(g.split(' ').first),
          selected: isActive,
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

  @override
  Widget build(BuildContext context) {
    final previewAge = _previewAge;
    final filtered = _filteredPostsFor(previewAge);

    return Scaffold(
      appBar: AppBar(title: const Text('Community — Age')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPostDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top card: Age input and live preview
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                child: Row(
                  children: [
                    // Left: age input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your age', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Decrease age',
                                onPressed: _decrementAge,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              SizedBox(
                                width: 96,
                                child: TextField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'e.g. 25',
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Increase age',
                                onPressed: _incrementAge,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final value = int.tryParse(_ageController.text);
                                  if (value == null || value < 13) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Enter a valid age (13+)')),
                                    );
                                    return;
                                  }
                                  _saveAge(value);
                                },
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right: live group preview (shows even if not saved)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Group', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: previewAge == null
                              ? Chip(
                                  key: const ValueKey('unknown'),
                                  label: const Text('Unset'),
                                  backgroundColor: Colors.grey.shade200,
                                )
                              : Chip(
                                  key: ValueKey('group_$previewAge'),
                                  label: Text(_ageGroupLabel(previewAge)),
                                  backgroundColor: _ageGroupColor(previewAge).withAlpha((0.25 * 255).round()),
                                  avatar: CircleAvatar(
                                    backgroundColor: _ageGroupColor(previewAge),
                                    child: Text(
                                      _ageGroupLabel(previewAge).split(' ').first[0],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                        ),
                        if (_age != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Saved: $_age',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Search and filter row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search posts, authors, content',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'popularity', child: Text('Popular')),
                    DropdownMenuItem(value: 'ageRange', child: Text('Age range')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v ?? 'newest'),
                )
              ],
            ),

            const SizedBox(height: 8),

            // Group filter chips
            Align(alignment: Alignment.centerLeft, child: _buildGroupFilterChips()),

            const SizedBox(height: 12),

            // Header: matched posts count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      previewAge == null
                          ? 'Set your age to see tailored community posts.'
                          : 'Showing ${filtered.length} post${filtered.length == 1 ? '' : 's'} for ${_ageGroupLabel(previewAge)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (previewAge != null)
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Explore general channels')),
                        );
                      },
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Explore'),
                    )
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Posts area with animated switch between states
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: previewAge == null
                    ? Center(
                        key: const ValueKey('unset'),
                        child: Text(
                          'Set your age to see community posts tailored to your group.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            key: const ValueKey('empty'),
                            child: Text(
                              'No community posts found for your age group.\nTry exploring general channels or create one!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.separated(
                            key: const ValueKey('list'),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final post = filtered[index];
                              final id = post['id'] as int;
                              final author = post['author'] as String;
                              final initials = author.isNotEmpty ? author[0].toUpperCase() : '?';
                              final min = post['minAge'] as int;
                              final max = post['maxAge'] as int;
                              final createdAt = post['createdAt'] as DateTime;

                              return Card(
                                elevation: 1,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.primaries[index % Colors.primaries.length].shade300,
                                    child: Text(initials, style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(post['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      const SizedBox(width: 8),
                                      Text('${_likes[id] ?? 0} ❤', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(post['content'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Chip(
                                            label: Text('$min–$max yrs'),
                                            backgroundColor: Colors.grey.shade100,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          Chip(
                                            avatar: const Icon(Icons.person, size: 16),
                                            label: Text(author),
                                            backgroundColor: Colors.grey.shade100,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          ActionChip(
                                            label: Text(_joinedGroups.contains(_rangeToLabel(min, max)) ? 'Joined' : 'Join'),
                                            onPressed: () => _toggleJoinGroupLabel(_rangeToLabel(min, max)),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.favorite, color: Colors.red.shade300),
                                        tooltip: 'Like',
                                        onPressed: () => _toggleLike(id),
                                      ),
                                      IconButton(
                                        icon: Icon(_bookmarked.contains(id) ? Icons.bookmark : Icons.bookmark_outline),
                                        tooltip: 'Bookmark',
                                        onPressed: () => _toggleBookmark(id),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
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
                                              setState(() {
                                                _bookmarked.add(id);
                                              });
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmarked')));
                                            },
                                            child: const Text('Bookmark'),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}