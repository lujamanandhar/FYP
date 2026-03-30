import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import 'admin_service.dart';

class AdminChallengesScreen extends StatefulWidget {
  const AdminChallengesScreen({Key? key}) : super(key: key);

  @override
  State<AdminChallengesScreen> createState() => _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends State<AdminChallengesScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final response = await _adminService.getChallenges();
      setState(() {
        _challenges = response['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOfficial(String challengeId, bool currentValue) async {
    try {
      await _adminService.updateChallenge(challengeId, isOfficial: !currentValue);
      _loadChallenges();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Challenge Management',
      showBackButton: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _challenges.length,
              itemBuilder: (context, index) {
                final challenge = _challenges[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      challenge['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(challenge['challenge_type']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (challenge['is_official'])
                          const Icon(Icons.verified, color: Colors.blue),
                        IconButton(
                          icon: Icon(
                            challenge['is_official'] ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => _toggleOfficial(
                            challenge['id'],
                            challenge['is_official'],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
