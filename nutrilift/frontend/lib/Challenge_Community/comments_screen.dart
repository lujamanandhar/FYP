import 'package:flutter/material.dart';
import 'community_feed_screen.dart';

class CommentsScreen extends StatelessWidget {
  final CommunityPost post;
  const CommentsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final comments = [
      _Comment(
        username: 'c_bum',
        time: '34 sec ago',
        text: 'Nice work brother! Keep it up.',
      ),
      _Comment(
        username: 'ramon_dino',
        time: '10 min ago',
        text: 'Proud of you lujii!',
      ),
      _Comment(
        username: 'ronnie_coleman',
        time: '1 hr ago',
        text: 'Yeah Luja!! Light weight!!',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final c = comments[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(c.username),
                  subtitle: Text(c.text),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.time,
                        style: const TextStyle(fontSize: 11),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          size: 18,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Comment {
  final String username;
  final String time;
  final String text;

  _Comment({
    required this.username,
    required this.time,
    required this.text,
  });
}
