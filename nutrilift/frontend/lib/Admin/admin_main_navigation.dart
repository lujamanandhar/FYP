import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_reported_posts_screen.dart';
import 'admin_support_tickets_screen.dart';
import 'admin_faq_screen.dart';
import 'admin_exercises_screen.dart';
import 'admin_service.dart';

const _kRed = Color(0xFFE53935);

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({Key? key}) : super(key: key);

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _selectedIndex = 0;
  int _pendingReports = 0;
  int _openTickets = 0;

  static const _labels = ['Dashboard', 'Users', 'Challenges', 'Reports', 'Support', 'FAQs', 'Exercises'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.emoji_events_rounded,
    Icons.flag_rounded,
    Icons.support_agent_rounded,
    Icons.help_outline_rounded,
    Icons.fitness_center_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadBadgeCounts();
  }

  Future<void> _loadBadgeCounts() async {
    try {
      final stats = await AdminService().getDashboardStats();
      if (mounted) {
        setState(() {
          _pendingReports = stats.pendingReports;
          _openTickets = stats.openSupportTickets;
        });
      }
    } catch (_) {
      // silently fail — badges are cosmetic
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    // Badge counts per tab: Reports=3, Support=4
    final badges = {3: _pendingReports, 4: _openTickets};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          _labels[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh counts',
            onPressed: _loadBadgeCounts,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          AdminDashboardScreen(),
          AdminUsersScreen(),
          AdminChallengesScreen(),
          AdminReportedPostsScreen(),
          AdminSupportTicketsScreen(),
          AdminFAQScreen(),
          AdminExercisesScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_labels.length, (i) {
                final selected = _selectedIndex == i;
                final badgeCount = badges[i] ?? 0;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    if (i == 3 || i == 4) _loadBadgeCounts();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _kRed.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(_icons[i],
                                color: selected ? _kRed : Colors.grey[400], size: 22),
                            if (badgeCount > 0)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    badgeCount > 99 ? '99+' : '$badgeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                            color: selected ? _kRed : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
