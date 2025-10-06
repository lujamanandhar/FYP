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
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _avatarFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn));
    _titleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeIn));
    _descFade = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.5, curve: Curves.elasticOut)),
    );
    _buttonPulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeInOut)),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 0.9, curve: Curves.decelerate)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _contactUs() {
    // Implement your contact logic here
  }

  void _visitWebsite() {
    // Implement your website logic here
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
          child: Padding(
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
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          radius: 28,
                          child: Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero)
                            .animate(_titleFade),
                        child: Text(
                          'NutriLift',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Logo Section
                FadeTransition(
                  opacity: _avatarFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Center(
                      child: SizedBox(
                        height: 80,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _descFade,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
                        .animate(_descFade),
                    child: Text(
                      'Your personal nutrition and fitness companion.',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _descFade,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
                        .animate(_descFade),
                    child: Text(
                      'Track your meals, monitor your progress, and achieve your health goals with ease. NutriLift empowers you to live healthier every day with personalized insights and easy-to-use tools.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
                            Text(
                              'Version 1.0.0',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // New Buttons Section
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
                          label: const Text('Contact Us'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ScaleTransition(
                        scale: _buttonPulse,
                        child: ElevatedButton.icon(
                          onPressed: _visitWebsite,
                          icon: const Icon(Icons.public),
                          label: const Text('Visit Website'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _fadeIn,
                  child: Center(
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                          .animate(_fadeIn),
                      child: Text(
                        '© 2024 NutriLift Team',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}