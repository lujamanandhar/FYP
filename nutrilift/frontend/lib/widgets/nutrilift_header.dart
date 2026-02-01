import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../UserManagement/profile_edit_screen.dart';
import '../UserManagement/login_screen.dart';
import '../Support/help_support_screen.dart';
import '../Settings/settings_screen.dart';

class NutriLiftHeader extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showDrawer;
  final VoidCallback? onNotificationTap;

  const NutriLiftHeader({
    Key? key,
    this.title,
    this.showBackButton = false,
    this.actions,
    this.showDrawer = true,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<NutriLiftHeader> createState() => _NutriLiftHeaderState();
}

class _NutriLiftHeaderState extends State<NutriLiftHeader> with ErrorHandlingMixin {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: widget.showBackButton,
      title: widget.title != null
          ? Text(
              widget.title!,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          : const Text(
              'NUTRILIFT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
      centerTitle: widget.title != null,
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
                size: 24,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          onPressed: widget.onNotificationTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications coming soon!'),
              ),
            );
          },
        ),
        if (widget.actions != null) ...widget.actions!,
        if (widget.showDrawer)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
      ],
    );
  }
}

// Drawer widget for consistent navigation
class NutriLiftDrawer extends StatefulWidget {
  const NutriLiftDrawer({Key? key}) : super(key: key);

  @override
  State<NutriLiftDrawer> createState() => _NutriLiftDrawerState();
}

class _NutriLiftDrawerState extends State<NutriLiftDrawer> with ErrorHandlingMixin {
  UserProfile? _userProfile;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await executeWithErrorHandling(
      () => _authService.getProfile(),
    );

    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Close the drawer first
        Navigator.of(context).pop();
        
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Logging out...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Perform logout
        await _authService.logout();
        
        // Small delay to ensure everything is processed
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Navigate to login screen - try multiple approaches
        if (mounted) {
          // First try: Use root navigator
          try {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          } catch (e) {
            // Fallback: Use regular navigator
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        // Handle logout error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToProfile() async {
    Navigator.pop(context); // Close drawer first
    
    if (_userProfile != null) {
      final updatedProfile = await Navigator.push<UserProfile>(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileEditScreen(userProfile: _userProfile!),
        ),
      );
      
      if (updatedProfile != null) {
        setState(() {
          _userProfile = updatedProfile;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer first
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userProfile?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userProfile?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.red),
            title: const Text('Profile View'),
            onTap: _navigateToProfile,
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.red),
            title: const Text('Settings'),
            onTap: () => _navigateToPage(context, const SettingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.red),
            title: const Text('Help & Support'),
            onTap: () => _navigateToPage(context, const HelpSupportScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}

// Wrapper widget to provide consistent scaffold with header and drawer
class NutriLiftScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showDrawer;
  final VoidCallback? onNotificationTap;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const NutriLiftScaffold({
    Key? key,
    required this.body,
    this.title,
    this.showBackButton = false,
    this.actions,
    this.showDrawer = true,
    this.onNotificationTap,
    this.bottomNavigationBar,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NutriLiftHeader(
        title: title,
        showBackButton: showBackButton,
        actions: actions,
        showDrawer: showDrawer,
        onNotificationTap: onNotificationTap,
      ),
      endDrawer: showDrawer ? const NutriLiftDrawer() : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}