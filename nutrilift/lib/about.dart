import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _logoScale;
  late final Animation<double> _buttonPulse;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1100), vsync: this);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.45, curve: Curves.elasticOut)),
    );
    _buttonPulse = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeInOut)),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.85, curve: Curves.decelerate)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _contactUs() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Contact Us'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined),
                title: Text('support@nutrilift.com', style: theme.textTheme.bodyMedium),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_outlined),
                title: Text('+1 (555) 123-4567', style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(height: 8),
              Text(
                'For partnership inquiries, media requests, or technical assistance, please reach out and we will respond promptly.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _visitWebsite() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Website'),
          content: SelectableText(
            'https://www.nutrilift.com',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String text, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _featureRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with gradient card
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary.withOpacity(0.12), primary.withOpacity(0.03)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ScaleTransition(
                              scale: _logoScale,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  radius: 36,
                                  child: Icon(Icons.fitness_center, color: primary, size: 36),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NutriLift',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Version 1.0.0 • Stable',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Chip(
                                        backgroundColor: primary.withOpacity(0.12),
                                        label: Text('Personalized', style: TextStyle(color: primary)),
                                        avatar: Icon(Icons.person, size: 16, color: primary),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        backgroundColor: theme.colorScheme.tertiaryContainer.withOpacity(0.08),
                                        label: Text('Evidence-based', style: TextStyle(color: Colors.teal)),
                                        avatar: Icon(Icons.science, size: 16, color: Colors.teal),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _visitWebsite,
                              icon: Icon(Icons.open_in_new, color: primary),
                              tooltip: 'Website',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Logo centered
                      Center(
                        child: Container(
                          height: 108,
                          width: 108,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Main card with content
                      SlideTransition(
                        position: _cardSlide,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('Overview', theme.textTheme),
                                const SizedBox(height: 8),
                                Text(
                                  'NutriLift is a comprehensive nutrition and fitness application designed to help individuals '
                                  'achieve sustainable health outcomes. Our product offers evidence-based guidance, tracking tools, '
                                  'and personalized recommendations to support informed lifestyle decisions.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                _sectionTitle('Mission', theme.textTheme),
                                const SizedBox(height: 8),
                                Text(
                                  'To empower users with clear, actionable insights that make healthy living accessible, measurable, and maintainable.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                _sectionTitle('Key Features', theme.textTheme),
                                const SizedBox(height: 10),
                                _featureRow(Icons.restaurant_menu, 'Personalized meal tracking and analysis.', primary),
                                _featureRow(Icons.show_chart, 'Progress monitoring with clear visualizations.', Colors.orange),
                                _featureRow(Icons.track_changes, 'Goal planning and adaptive recommendations.', Colors.teal),
                                const SizedBox(height: 16),
                                Divider(),
                                const SizedBox(height: 12),
                                _sectionTitle('Privacy & Data', theme.textTheme),
                                const SizedBox(height: 8),
                                Text(
                                  'We treat user data with the utmost care. Personal information is processed only to provide and '
                                  'improve our services. For full details, please review our Privacy Policy available on the website.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 14),
                                _sectionTitle('Acknowledgements', theme.textTheme),
                                const SizedBox(height: 8),
                                Text(
                                  'NutriLift is developed by a dedicated multidisciplinary team. We thank our contributors, partners, '
                                  'and early adopters who helped shape the product.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer card with release info + actions
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Card(
                          color: theme.colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Release: 1.0.0 • Stable',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text('© 2024 NutriLift', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _buttonPulse,
                            child: ElevatedButton.icon(
                              onPressed: _contactUs,
                              icon: const Icon(Icons.email_outlined),
                              label: const Text('Contact'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ScaleTransition(
                            scale: _buttonPulse,
                            child: OutlinedButton.icon(
                              onPressed: _visitWebsite,
                              icon: const Icon(Icons.public),
                              label: const Text('Website'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: BorderSide(color: primary.withOpacity(0.18)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Center(
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: Text(
                            'Built with care — NutriLift Team',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}