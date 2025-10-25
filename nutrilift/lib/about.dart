import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _avatarFade;
  late Animation<double> _titleFade;
  late Animation<double> _descFade;
  late Animation<double> _logoScale;
  late Animation<double> _buttonPulse;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _avatarFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.35, curve: Curves.easeIn));
    _titleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.45, curve: Curves.easeIn));
    _descFade = CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.75, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.05, 0.4, curve: Curves.elasticOut)),
    );
    _buttonPulse = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 1.0, curve: Curves.easeInOut)),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.55, 0.85, curve: Curves.decelerate)),
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
              Text('Email: support@nutrilift.com', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('Phone: +1 (555) 123-4567', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
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
          title: const Text('Visit Website'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About NutriLift'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FadeTransition(
                      opacity: _avatarFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                          radius: 30,
                          child: Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FadeTransition(
                      opacity: _titleFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NutriLift',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 1.0.0',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _avatarFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Center(
                      child: SizedBox(
                        height: 84,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _descFade,
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
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('• Personalized meal tracking and analysis.'),
                          Text('• Progress monitoring with clear visualizations.'),
                          Text('• Goal planning and adaptive recommendations.'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Privacy & Data', theme.textTheme),
                      const SizedBox(height: 8),
                      Text(
                        'We treat user data with the utmost care. Personal information is processed only to provide and '
                        'improve our services. For full details, please review our Privacy Policy available on the website.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
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
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _descFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Card(
                      color: theme.colorScheme.surfaceVariant,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Release: 1.0.0 • Stable',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
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
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _descFade,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _buttonPulse,
                        child: ElevatedButton.icon(
                          onPressed: _contactUs,
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ScaleTransition(
                        scale: _buttonPulse,
                        child: OutlinedButton.icon(
                          onPressed: _visitWebsite,
                          icon: const Icon(Icons.public),
                          label: const Text('Website'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.12)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                          .animate(_fadeIn),
                      child: Text(
                        'Built with care — NutriLift Team',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}