import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import 'admin_service.dart';
import 'admin_users_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_support_tickets_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  AdminStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Admin Dashboard',
      showBackButton: true,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          'Total Users',
                          '${_stats?.totalUsers ?? 0}',
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Active Users',
                          '${_stats?.activeUsers ?? 0}',
                          Icons.person_add_alt,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Challenges',
                          '${_stats?.totalChallenges ?? 0}',
                          Icons.emoji_events,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Official',
                          '${_stats?.officialChallenges ?? 0}',
                          Icons.verified,
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'Open Tickets',
                          '${_stats?.openSupportTickets ?? 0}',
                          Icons.support_agent,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'In Progress',
                          '${_stats?.inProgressTickets ?? 0}',
                          Icons.pending,
                          Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Recent Users',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _adminService.getUsers(page: 1),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        final users = snapshot.data?['results'] as List? ?? [];
                        return Column(
                          children: users.take(5).map((user) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE53935),
                                  child: Text(
                                    (user['name'] ?? user['email'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(user['name'] ?? user['email'] ?? 'Unknown'),
                                subtitle: Text(
                                  '${user['email']} • ${user['is_active'] ? "Active" : "Inactive"}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: user['is_staff'] == true
                                    ? const Chip(
                                        label: Text('Admin', style: TextStyle(fontSize: 10)),
                                        backgroundColor: Color(0xFFFFEBEE),
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      'User Management',
                      'View and manage all users',
                      Icons.people,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminUsersScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      'Challenge Management',
                      'Manage challenges and mark as official',
                      Icons.emoji_events,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminChallengesScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      'Support Tickets',
                      'View and respond to support requests',
                      Icons.support_agent,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSupportTicketsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFFE53935)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
