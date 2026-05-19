import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_reported_posts_screen.dart';
import 'admin_support_tickets_screen.dart';
import 'admin_faq_screen.dart';
import 'admin_exercises_screen.dart';
import 'admin_service.dart';
import '../UserManagement/login_screen.dart';
import '../services/auth_service.dart';

const _kRed = Color(0xFFE53935);
const _kDarkRed = Color(0xFFB71C1C);

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({Key? key}) : super(key: key);

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _selectedIndex = 0;
  int _pendingReports = 0;
  int _openTickets = 0;

  // 4 primary tabs — the rest live in the drawer
  static const _labels = ['Dashboard', 'Users', 'Challenges', 'Reports'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.emoji_events_rounded,
    Icons.flag_rounded,
  ];

  static const _screens = [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminChallengesScreen(),
    AdminReportedPostsScreen(),
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout from the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _openDrawerScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _labels[_selectedIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'More options',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _AdminDrawer(
        openTickets: _openTickets,
        onSupport: (ctx) =>
            _openDrawerScreen(ctx, const AdminSupportTicketsScreen()),
        onExercises: (ctx) =>
            _openDrawerScreen(ctx, const AdminExercisesScreen()),
        onFaqs: (ctx) => _openDrawerScreen(ctx, const AdminFAQScreen()),
        onRefresh: (ctx) {
          Navigator.pop(ctx);
          _loadBadgeCounts();
        },
        onLogout: (ctx) {
          Navigator.pop(ctx);
          _logout();
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AdminBottomNav(
        selectedIndex: _selectedIndex,
        labels: _labels,
        icons: _icons,
        reportsBadge: _pendingReports,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 3) _loadBadgeCounts();
        },
      ),
    );
  }
}

// ─── Side Drawer ─────────────────────────────────────────────────────────────

class _AdminDrawer extends StatelessWidget {
  final int openTickets;
  final void Function(BuildContext) onSupport;
  final void Function(BuildContext) onExercises;
  final void Function(BuildContext) onFaqs;
  final void Function(BuildContext) onRefresh;
  final void Function(BuildContext) onLogout;

  const _AdminDrawer({
    required this.openTickets,
    required this.onSupport,
    required this.onExercises,
    required this.onFaqs,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 24,
              20,
              28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kDarkRed, _kRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'NutriLift Management',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                const _DrawerSectionLabel('MORE TOOLS'),
                Builder(
                  builder: (ctx) => _DrawerTile(
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFFE53935),
                    title: 'Support Tickets',
                    badge: openTickets > 0 ? '$openTickets' : null,
                    onTap: () => onSupport(ctx),
                  ),
                ),
                Builder(
                  builder: (ctx) => _DrawerTile(
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFFE53935),
                    title: 'Exercises',
                    onTap: () => onExercises(ctx),
                  ),
                ),
                Builder(
                  builder: (ctx) => _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    color: const Color(0xFFE53935),
                    title: 'FAQ Management',
                    onTap: () => onFaqs(ctx),
                  ),
                ),
                const Divider(height: 28, indent: 20, endIndent: 20),
                Builder(
                  builder: (ctx) => _DrawerTile(
                    icon: Icons.refresh_rounded,
                    color: Colors.grey,
                    title: 'Refresh Badge Counts',
                    onTap: () => onRefresh(ctx),
                  ),
                ),
                const Divider(height: 28, indent: 20, endIndent: 20),
                Builder(
                  builder: (ctx) => _DrawerTile(
                    icon: Icons.logout_rounded,
                    color: _kRed,
                    title: 'Logout',
                    titleColor: _kRed,
                    onTap: () => onLogout(ctx),
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

class _DrawerSectionLabel extends StatelessWidget {
  final String text;
  const _DrawerSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? badge;
  final Color? titleColor;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.badge,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _AdminBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final int reportsBadge;
  final void Function(int) onTap;

  const _AdminBottomNav({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.reportsBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(labels.length, (i) {
              final selected = selectedIndex == i;
              // Reports tab (index 3) gets the badge
              final badgeCount = i == 3 ? reportsBadge : 0;

              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected ? _kRed.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            icons[i],
                            color: selected ? _kRed : Colors.grey[400],
                            size: 22,
                          ),
                          if (badgeCount > 0)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
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
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: selected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  labels[i],
                                  style: const TextStyle(
                                    color: _kRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
