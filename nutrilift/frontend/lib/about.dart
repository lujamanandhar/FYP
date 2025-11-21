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
  late final Animation<double> _logoRotation;
  late final Animation<Offset> _slideUp;
  late final List<Animation<double>> _featureFade;
  late final List<Animation<Offset>> _featureSlide;
  late final Animation<double> _actionScale;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.28, curve: Curves.easeOutBack)));
    _logoRotation = Tween<double>(begin: -0.05, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));

    _featureFade = List.generate(3, (i) {
      final start = 0.32 + i * 0.08;
      final end = start + 0.28;
      return CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOut));
    });

    _featureSlide = List.generate(3, (i) {
      final start = 0.32 + i * 0.08;
      final end = start + 0.28;
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _actionScale = CurvedAnimation(parent: _controller, curve: const Interval(0.7, 0.95, curve: Curves.elasticOut));
    _footerFade = CurvedAnimation(parent: _controller, curve: const Interval(0.85, 1.0, curve: Curves.easeIn));

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
                Container(height: 4, width: 40, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4))),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.red),
                  title: const Text('support@nutrilift.com'),
                  subtitle: const Text('Tap or use copy button'),
                  onTap: () => _copyToClipboard('support@nutrilift.com', 'Email'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, color: Colors.red),
                    onPressed: () => _copyToClipboard('support@nutrilift.com', 'Email'),
                    tooltip: 'Copy email',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: Colors.red),
                  title: const Text('+1 (555) 123-4567'),
                  subtitle: const Text('Tap or use copy button'),
                  onTap: () => _copyToClipboard('+1 (555) 123-4567', 'Phone'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, color: Colors.red),
                    onPressed: () => _copyToClipboard('+1 (555) 123-4567', 'Phone'),
                    tooltip: 'Copy phone',
                  ),
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
          content: SelectableText('https://www.nutrilift.com', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade700)),
          actions: [
            TextButton(onPressed: () { _copyToClipboard('https://www.nutrilift.com', 'Website'); Navigator.of(context).pop(); }, child: const Text('Copy')),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _featureTile(IconData icon, String title, String subtitle, Color color) {
    return Material(
      color: color.withOpacity(0.02),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title — Feature tapped'))),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(color: color.withOpacity(0.16), shape: BoxShape.circle),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Red & white themed palette
    final Color primary = Colors.red.shade600;
    final Color primaryLight = Colors.red.shade400;
    final Color surface = Colors.white;
    final Color onSurface = Colors.black87;
    final Color cardBg = Colors.white;
    final Color subtleDivider = Colors.red.shade50;

    final features = [
      _featureTile(Icons.restaurant_menu, 'Personalized meal tracking', 'Track meals, calories & macros', primary),
      _featureTile(Icons.show_chart, 'Progress monitoring', 'Charts & trends to visualize growth', primaryLight),
      _featureTile(Icons.track_changes, 'Adaptive recommendations', 'Smart suggestions based on progress', Colors.red.shade200),
    ];

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text('About NutriLift'),
        centerTitle: true,
        elevation: 1,
        backgroundColor: surface,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: primary),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Large header with scale + subtle rotation animation
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primary.withOpacity(0.12), surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.8), blurRadius: 8 * _logoScale.value, offset: const Offset(0, 4))],
                          border: Border.all(color: subtleDivider),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // logo with rotation + scale (increased size slightly)
                            ScaleTransition(
                              scale: _logoScale,
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Transform.rotate(angle: _logoRotation.value, child: child);
                                },
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.local_florist, color: primary, size: 44),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('NutriLift', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: onSurface)),
                                  const SizedBox(height: 6),
                                  Text('Version 1.0.0 • Stable', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Chip(avatar: const Icon(Icons.person, size: 16, color: Colors.white), label: const Text('Personalized'), backgroundColor: primary.withOpacity(0.9)),
                                      Chip(avatar: const Icon(Icons.science, size: 16, color: Colors.white), label: const Text('Evidence-based'), backgroundColor: primaryLight.withOpacity(0.95)),
                                      Chip(avatar: const Icon(Icons.security, size: 16, color: Colors.white), label: const Text('Privacy-first'), backgroundColor: Colors.red.shade300.withOpacity(0.95)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(onPressed: _showWebsiteDialog, icon: Icon(Icons.open_in_new, color: primary), tooltip: 'Website'),
                                const SizedBox(height: 6),
                                IconButton(onPressed: _showContactSheet, icon: Icon(Icons.email_outlined, color: onSurface), tooltip: 'Contact'),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 18),

                    // Features card with responsive grid and staggered animations
                    Card(
                      color: cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Key Features', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: onSurface)),
                            const SizedBox(height: 12),
                            LayoutBuilder(builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                              // keep mainAxisExtent so tiles stay compact
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: features.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisExtent: 82,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 8,
                                ),
                                itemBuilder: (context, index) {
                                  return FadeTransition(
                                    opacity: _featureFade[index],
                                    child: SlideTransition(
                                      position: _featureSlide[index],
                                      child: features[index],
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Overview / Mission / Privacy
                    Card(
                      color: cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: onSurface)),
                            const SizedBox(height: 8),
                            Text(
                              'NutriLift is a comprehensive nutrition and fitness application designed to help individuals achieve sustainable health outcomes. We provide tools and guidance grounded in evidence.',
                              style: theme.textTheme.bodyLarge?.copyWith(color: onSurface),
                            ),
                            const SizedBox(height: 12),
                            Text('Mission', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: onSurface)),
                            const SizedBox(height: 8),
                            Text('To empower users with clear, actionable insights that make healthy living accessible, measurable, and maintainable.', style: theme.textTheme.bodyLarge?.copyWith(color: onSurface)),
                            const SizedBox(height: 12),
                            Text('Privacy & Data', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: onSurface)),
                            const SizedBox(height: 8),
                            Text('We treat user data with care. Personal information is processed only to provide and improve our services. Visit our website for the full Privacy Policy.', style: theme.textTheme.bodyLarge?.copyWith(color: onSurface)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Footer actions animated with slight layout improvements
                    ScaleTransition(
                      scale: _actionScale,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showContactSheet,
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Contact'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _showWebsiteDialog,
                            icon: Icon(Icons.public, color: primary),
                            label: const Text('Website'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              side: BorderSide(color: primary.withOpacity(0.14)),
                              foregroundColor: primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for considering a rating!'))),
                            icon: Icon(Icons.star_border, color: primary),
                            label: const Text('Rate'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              side: BorderSide(color: primary.withOpacity(0.08)),
                              foregroundColor: primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bottom bar (fade in)
                    FadeTransition(
                      opacity: _footerFade,
                      child: Center(
                        child: Text('© ${DateTime.now().year} NutriLift • Built with care • v1.0.0', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                      ),
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
