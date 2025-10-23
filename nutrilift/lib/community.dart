import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Community age screen for a fitness app with improved UI and live preview.
class CommunityAgePage extends StatefulWidget {
  const CommunityAgePage({super.key});

  @override
  State<CommunityAgePage> createState() => _CommunityAgePageState();
}

class _CommunityAgePageState extends State<CommunityAgePage> {
  int? _age;
  final TextEditingController _ageController = TextEditingController();

  // Example community posts with target age ranges
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'author': 'Alex',
      'minAge': 13,
      'maxAge': 19,
      'title': 'Teen bodyweight challenge',
      'content': '4 week bodyweight plan for teens wanting to build stamina.'
    },
    {
      'id': 2,
      'author': 'Jamal',
      'minAge': 20,
      'maxAge': 35,
      'title': 'Morning HIIT group',
      'content': 'Join daily 20-min HIIT sessions, great for busy young adults.'
    },
    {
      'id': 3,
      'author': 'Priya',
      'minAge': 36,
      'maxAge': 55,
      'title': 'Low impact strength',
      'content': 'Strength maintenance with low-impact routines and mobility.'
    },
    {
      'id': 4,
      'author': 'Maria',
      'minAge': 56,
      'maxAge': 120,
      'title': 'Active seniors walk club',
      'content': 'Social walks and gentle strength exercises for seniors.'
    },
    {
      'id': 5,
      'author': 'CoachSam',
      'minAge': 18,
      'maxAge': 120,
      'title': 'Nutrition tips for everyone',
      'content': 'Safe, general nutrition advice relevant across ages.'
    },
  ];

  @override
  void initState() {
    super.initState();
    // If you later add persistence, restore _age here and set controller.
    _ageController.addListener(_onAgeTextChanged);
  }

  void _onAgeTextChanged() {
    // Rebuild to provide live preview of group and posts while editing.
    setState(() {});
  }

  @override
  void dispose() {
    _ageController.removeListener(_onAgeTextChanged);
    _ageController.dispose();
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
    if (age == null) return [];
    return _posts.where((p) {
      final min = p['minAge'] as int;
      final max = p['maxAge'] as int;
      return age >= min && age <= max;
    }).toList();
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
    // Persist here if you add shared_preferences.
  }

  @override
  Widget build(BuildContext context) {
    final previewAge = _previewAge;
    final filtered = _filteredPostsFor(previewAge);

    return Scaffold(
      appBar: AppBar(title: const Text('Community — Age')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top card: Age input and live preview
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                child: Row(
                  children: [
                    // Left: age input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your age',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
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
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 12.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
                                  final value =
                                      int.tryParse(_ageController.text);
                                  if (value == null || value < 13) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Enter a valid age (13+)')),
                                    );
                                    return;
                                  }
                                  _saveAge(value);
                                },
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
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
                        const Text('Group',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder:
                              (child, animation) => ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                          child: previewAge == null
                              ? Chip(
                                  key: const ValueKey('unknown'),
                                  label: const Text('Unset'),
                                  backgroundColor: Colors.grey.shade200,
                                )
                              : Chip(
                                  key: ValueKey('group_$previewAge'),
                                  label: Text(_ageGroupLabel(previewAge)),
                                  backgroundColor:
                                      _ageGroupColor(previewAge).withAlpha((0.25 * 255).round()),
                                  avatar: CircleAvatar(
                                    backgroundColor:
                                        _ageGroupColor(previewAge),
                                    child: Text(
                                      _ageGroupLabel(previewAge)
                                          .split(' ')
                                          .first[0],
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
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Header: matched posts count
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
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
                        // Quick explore: reset to show all general posts (age-agnostic)
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
                              'No community posts found for your age group.\nTry exploring general channels.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.separated(
                            key: const ValueKey('list'),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final post = filtered[index];
                              final author = post['author'] as String;
                              final initials = author.isNotEmpty
                                  ? author[0].toUpperCase()
                                  : '?';
                              final min = post['minAge'] as int;
                              final max = post['maxAge'] as int;

                              return Card(
                                elevation: 1,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.primaries[index % Colors.primaries.length]
                                            .shade300,
                                    child: Text(
                                      initials,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(post['title'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        post['content'] as String,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                            avatar: const Icon(Icons.person,
                                                size: 16),
                                            label: Text(author),
                                            backgroundColor:
                                                Colors.grey.shade100,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(post['title'] as String),
                                        content:
                                            Text(post['content'] as String),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('Close'),
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