import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
  }

  void _showContactSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 40, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(4))),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('support@nutrilift.com'),
                  subtitle: const Text('Tap to copy'),
                  onTap: () => _copyToClipboard('support@nutrilift.com', 'Email'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('+1 (555) 123-4567'),
                  subtitle: const Text('Tap to copy'),
                  onTap: () => _copyToClipboard('+1 (555) 123-4567', 'Phone'),
                ),
                const SizedBox(height: 8),
                Text(
                  'For partnership inquiries, media requests, or technical assistance, reach out and we will respond promptly.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close), label: const Text('Close'))),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(onPressed: () => _copyToClipboard('https://www.nutrilift.com', 'Website'), icon: const Icon(Icons.copy), label: const Text('Copy Website')),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWebsiteDialog() {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Website'),
          content: SelectableText('https://www.nutrilift.com', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
          actions: [
            TextButton(onPressed: () => _copyToClipboard('https://www.nutrilift.com', 'Website'), child: const Text('Copy')),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _featureTile(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('About NutriLift'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Large header
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primary.withOpacity(0.12), theme.colorScheme.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NutriLift', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Version 1.0.0 • Stable', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Chip(avatar: const Icon(Icons.person, size: 16), label: const Text('Personalized'), backgroundColor: primary.withOpacity(0.08)),
                                    Chip(avatar: const Icon(Icons.science, size: 16), label: const Text('Evidence-based'), backgroundColor: Colors.teal.withOpacity(0.08)),
                                    Chip(avatar: const Icon(Icons.security, size: 16), label: const Text('Privacy-first'), backgroundColor: Colors.indigo.withOpacity(0.06)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(onPressed: _showWebsiteDialog, icon: Icon(Icons.open_in_new, color: primary), tooltip: 'Website'),
                              const SizedBox(height: 6),
                              IconButton(onPressed: _showContactSheet, icon: Icon(Icons.email_outlined, color: theme.colorScheme.onSurface), tooltip: 'Contact'),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Features grid
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Key Features', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisExtent: 56, childAspectRatio: 6),
                              children: [
                                _featureTile(Icons.restaurant_menu, 'Personalized meal tracking and analysis.', primary),
                                _featureTile(Icons.show_chart, 'Progress monitoring with clear visualizations.', Colors.orange),
                                _featureTile(Icons.track_changes, 'Goal planning and adaptive recommendations.', Colors.teal),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Overview / Mission / Privacy
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                              'NutriLift is a comprehensive nutrition and fitness application designed to help individuals achieve sustainable health outcomes. We provide tools and guidance grounded in evidence.',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            Text('Mission', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text('To empower users with clear, actionable insights that make healthy living accessible, measurable, and maintainable.', style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 12),
                            Text('Privacy & Data', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text('We treat user data with care. Personal information is processed only to provide and improve our services. Visit our website for the full Privacy Policy.', style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Footer actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showContactSheet,
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Contact'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _showWebsiteDialog,
                          icon: const Icon(Icons.public),
                          label: const Text('Website'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Bottom bar
                    Center(
                      child: Text('© ${DateTime.now().year} NutriLift • Built with care', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
