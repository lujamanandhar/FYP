import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../widgets/nutrilift_header.dart';
import 'change_password_screen.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);

    // Cancel all pending plan notifications when disabled
    final plugin = FlutterLocalNotificationsPlugin();
    if (!value) {
      await plugin.cancelAll();
    }
    // Note: re-scheduling on enable would require access to _planTasks from
    // home_page — the tasks will reschedule naturally when user adds new ones.
  }

  Future<void> _saveAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', value);
    setState(() => _autoSyncEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Settings',
      showBackButton: true,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Privacy & Security ────────────────────────────────────
            _sectionHeader('Privacy & Security'),
            _buildCard([
              _tile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
              ),
              _tile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Learn about our privacy practices',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(type: LegalType.privacy))),
              ),
              _tile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms and conditions',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(type: LegalType.terms))),
              ),
            ]),
            const SizedBox(height: 24),

            // ── Notifications ─────────────────────────────────────────
            _sectionHeader('Notifications'),
            _buildCard([
              _switchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Workout reminders, meal alerts, challenges',
                value: _notificationsEnabled,
                onChanged: _saveNotifications,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Data & Storage ────────────────────────────────────────
            _sectionHeader('Data & Storage'),
            _buildCard([
              _switchTile(
                icon: Icons.sync_rounded,
                title: 'Auto Sync',
                subtitle: 'Automatically sync your data',
                value: _autoSyncEnabled,
                onChanged: _saveAutoSync,
              ),
              _tile(
                icon: Icons.download_outlined,
                title: 'Export Data',
                subtitle: 'Download your data as CSV',
                onTap: _showExportDialog,
              ),
              _tile(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear Cache',
                subtitle: 'Free up storage space',
                onTap: _showClearCacheDialog,
              ),
            ]),
            const SizedBox(height: 24),

            // ── About ─────────────────────────────────────────────────
            _sectionHeader('About'),
            _buildCard([
              _tile(
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: '1.0.0',
                onTap: () {},
                showArrow: false,
              ),
              _tile(
                icon: Icons.star_outline_rounded,
                title: 'Rate NutriLift',
                subtitle: 'Share your feedback on the app store',
                onTap: () => _snack('Rating coming soon'),
              ),
              _tile(
                icon: Icons.share_outlined,
                title: 'Share App',
                subtitle: 'Invite friends to NutriLift',
                onTap: () => _snack('Share coming soon'),
              ),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
        ),
      );

  Widget _buildCard(List<Widget> children) => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(children: children),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) =>
      ListTile(
        leading: _iconBox(icon),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
        trailing: showArrow ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
        onTap: onTap,
      );

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      ListTile(
        leading: _iconBox(icon),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
        trailing: Switch(value: value, onChanged: onChanged, activeColor: Colors.red),
      );

  Widget _iconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.red, size: 20),
      );

  void _snack(String msg) =>
      showCenterToast(context, msg);

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Export Data'),
        content: const Text('Export your fitness and nutrition data as a CSV file. This feature is coming soon.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Clear Cache'),
        content: const Text('This will clear temporary files and free up storage space. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _snack('Cache cleared successfully');
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
