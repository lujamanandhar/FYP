import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Community age screen for a fitness app.
/// Drop this file in lib/community.dart and add shared_preferences to pubspec.yaml:
/// shared_preferences: ^2.0.0
class CommunityAgePage extends StatefulWidget {
  const CommunityAgePage({Key? key}) : super(key: key);

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
    _loadSavedAge();
  }

  Future<void> _loadSavedAge() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAge = prefs.getInt('user_age');
    if (savedAge != null) {
      setState(() {
        _age = savedAge;
        _ageController.text = savedAge.toString();
      });
    }
  }

  Future<void> _saveAge(int age) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_age', age);
    setState(() {
      _age = age;
      _ageController.text = age.toString();
    });
  }

  String _ageGroupLabel(int age) {
    if (age >= 13 && age <= 19) return 'Teens (13-19)';
    if (age >= 20 && age <= 35) return 'Young Adults (20-35)';
    if (age >= 36 && age <= 55) return 'Adults (36-55)';
    if (age >= 56) return 'Seniors (56+)';
    return 'Unknown';
  }

  List<Map<String, dynamic>> _filteredPosts() {
    if (_age == null) return [];
    return _posts.where((p) {
      final min = p['minAge'] as int;
      final max = p['maxAge'] as int;
      return _age! >= min && _age! <= max;
    }).toList();
  }

  void _incrementAge() {
    final current = int.tryParse(_ageController.text) ?? (_age ?? 25);
    final next = (current + 1).clamp(13, 120);
    _ageController.text = next.toString();
  }

  void _decrementAge() {
    final current = int.tryParse(_ageController.text) ?? (_age ?? 25);
    final next = (current - 1).clamp(13, 120);
    _ageController.text = next.toString();
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPosts();

    return Scaffold(
      appBar: AppBar(title: const Text('Community — Age')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your age',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _decrementAge,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _incrementAge,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
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
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_age != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Group',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(_ageGroupLabel(_age!)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _age == null
                  ? Center(
                      child: Text(
                        'Set your age to see community posts tailored to your group.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No community posts found for your age group.\nTry exploring general channels.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final post = filtered[index];
                            return Card(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(post['title'] as String),
                                subtitle: Text(post['content'] as String),
                                trailing: Text(post['author'] as String),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(post['title'] as String),
                                      content: Text(post['content'] as String),
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
          ],
        ),
      ),
    );
  }
}