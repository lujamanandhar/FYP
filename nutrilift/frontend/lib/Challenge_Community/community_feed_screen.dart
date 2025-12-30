import 'package:flutter/material.dart';
import 'challenge_overview_screen.dart';
import 'comments_screen.dart';

class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = [
      CommunityPost(
        username: 'c_bum',
        role: 'Coach',
        time: '34 min ago',
        content:
            'Just completed my intense arm workout. Time to destroy leg tomorrow. #ArmDay #Gym',
      ),
      CommunityPost(
        username: 'luja_manandhar',
        role: 'User',
        time: '1 hr ago',
        content: '4 times in a row!!!',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NUTRILIFT'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ChallengeHeaderTabs(selected: 1),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(post: post);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityPost {
  final String username;
  final String role;
  final String time;
  final String content;

  CommunityPost({
    required this.username,
    required this.role,
    required this.time,
    required this.content,
  });
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(post.username),
            subtitle: Text(post.role),
            trailing: Text(
              post.time,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image, size: 48),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(post.content),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(post: post),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  'View all comments',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
