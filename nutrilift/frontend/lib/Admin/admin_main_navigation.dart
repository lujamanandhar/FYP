import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_support_tickets_screen.dart';
import 'admin_faq_screen.dart';

const _kRed = Color(0xFFE53935);

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({Key? key}) : super(key: key);

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _selectedIndex = 0;

  static const _labels = ['Dashboard', 'Users', 'Challenges', 'Support', 'FAQs'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.emoji_events_rounded,
    Icons.support_agent_rounded,
    Icons.help_outline_rounded,
  ];

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
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          _labels[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          AdminDashboardScreen(),
          AdminUsersScreen(),
          AdminChallengesScreen(),
          AdminSupportTicketsScreen(),
          AdminFAQScreen(),
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
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _kRed.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icons[i], color: selected ? _kRed : Colors.grey[400], size: 22),
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
