import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'admin_service.dart';
import 'admin_users_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_support_tickets_screen.dart';
import 'admin_faq_screen.dart';

const _kRed = Color(0xFFE53935);
const _kBg = Color(0xFFF5F6FA);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  AdminStats? _stats;
  List<dynamic> _recentUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getUsers(page: 1),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as AdminStats;
          _recentUsers = ((results[1] as Map<String, dynamic>)['results'] as List? ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCenterToast(context, 'Error loading data: $e', isError: true);
      }
    }
  }

  Future<void> _loadStats() => _loadAll();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBg,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kRed))
          : RefreshIndicator(
              color: _kRed,
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header banner
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: _kRed,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: const Text(
                        'Welcome back, Admin 👋',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Overview'),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              _StatCard('Total Users', '${_stats?.totalUsers ?? 0}', Icons.people_alt_rounded, const Color(0xFF3B82F6)),
                              _StatCard('Active Users', '${_stats?.activeUsers ?? 0}', Icons.person_outline, const Color(0xFF10B981)),
                              _StatCard('Challenges', '${_stats?.totalChallenges ?? 0}', Icons.emoji_events_rounded, const Color(0xFFF59E0B)),
                              _StatCard('Official', '${_stats?.officialChallenges ?? 0}', Icons.verified_rounded, const Color(0xFF8B5CF6)),
                              _StatCard('Open Tickets', '${_stats?.openSupportTickets ?? 0}', Icons.support_agent_rounded, _kRed),
                              _StatCard('In Progress', '${_stats?.inProgressTickets ?? 0}', Icons.pending_rounded, const Color(0xFFEC4899)),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Quick actions
                          const _SectionLabel('Management'),
                          const SizedBox(height: 12),
                          _ActionTile(
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF3B82F6),
                            title: 'User Management',
                            subtitle: 'View, search and manage users',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
                          ),
                          const SizedBox(height: 10),
                          _ActionTile(
                            icon: Icons.emoji_events_rounded,
                            color: const Color(0xFFF59E0B),
                            title: 'Challenge Management',
                            subtitle: 'Create and manage challenges',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChallengesScreen())),
                          ),
                          const SizedBox(height: 10),
                          _ActionTile(
                            icon: Icons.support_agent_rounded,
                            color: _kRed,
                            title: 'Support Tickets',
                            subtitle: '${_stats?.openSupportTickets ?? 0} open tickets',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSupportTicketsScreen())),
                          ),
                          const SizedBox(height: 10),
                          _ActionTile(
                            icon: Icons.help_outline_rounded,
                            color: const Color(0xFF8B5CF6),
                            title: 'FAQ Management',
                            subtitle: 'Manage help & FAQ content',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFAQScreen())),
                          ),

                          const SizedBox(height: 24),

                          // Recent users
                          const _SectionLabel('Recent Users'),
                          const SizedBox(height: 12),
                          if (_recentUsers.isEmpty)
                            const Center(child: Text('No users yet', style: TextStyle(color: Colors.grey)))
                          else
                            ...(_recentUsers.take(5).map((user) => _UserTile(user: user))),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? user['email'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final isActive = user['is_active'] == true;
    final isStaff = user['is_staff'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _kRed.withOpacity(0.12),
          child: Text(name[0].toUpperCase(), style: const TextStyle(color: _kRed, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStaff)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(6)),
                child: const Text('Admin', style: TextStyle(fontSize: 10, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 6),
            Icon(isActive ? Icons.circle : Icons.circle_outlined, size: 10, color: isActive ? Colors.green : Colors.grey),
          ],
        ),
      ),
    );
  }
}
