import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _iconController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _iconAnimation = CurvedAnimation(
    parent: _iconController,
    curve: Curves.elasticOut,
  );

  late final AnimationController _welcomeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _welcomeAnimation = CurvedAnimation(
    parent: _welcomeController,
    curve: Curves.easeIn,
  );

  late final AnimationController _cardController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _workoutFade = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ),
  );
  late final Animation<Offset> _workoutSlide = Tween<Offset>(
    begin: const Offset(-1.2, 0),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ),
  );
  late final Animation<double> _nutritionFade = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ),
  );
  late final Animation<Offset> _nutritionSlide = Tween<Offset>(
    begin: const Offset(1.2, 0),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
    ),
  );

  // Background circles animation
  late final AnimationController _bgCircleController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final Animation<double> _bgCircleScale = Tween<double>(begin: 0.8, end: 1.1).animate(
    CurvedAnimation(parent: _bgCircleController, curve: Curves.easeInOut),
  );

  // Quote fade-in animation
  late final AnimationController _quoteController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _quoteFade = CurvedAnimation(
    parent: _quoteController,
    curve: Curves.easeIn,
  );

  // Tip card shimmer animation
  late final AnimationController _tipController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  late final Animation<double> _tipShimmer = Tween<double>(begin: -1, end: 2).animate(
    CurvedAnimation(parent: _tipController, curve: Curves.linear),
  );

  // FAB pulse animation
  late final AnimationController _fabController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
    lowerBound: 0.98,
    upperBound: 1.03,
  );

  // Flip animations for the two cards (workout, nutrition)
  late final AnimationController _flipWorkoutController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _flipWorkoutAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flipWorkoutController, curve: Curves.easeInOut));

  late final AnimationController _flipNutritionController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _flipNutritionAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flipNutritionController, curve: Curves.easeInOut));

  // Stagger controller for tip + settings entrance
  late final AnimationController _staggerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _tipFade = CurvedAnimation(
    parent: _staggerController,
    curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
  );
  late final Animation<double> _settingsFade = CurvedAnimation(
    parent: _staggerController,
    curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _welcomeController.forward();
    });
    _cardController.forward();
    _bgCircleController.repeat(reverse: true);
    _quoteController.forward();
    _tipController.repeat();
    _fabController.repeat(reverse: true);
    _staggerController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _welcomeController.dispose();
    _cardController.dispose();
    _bgCircleController.dispose();
    _quoteController.dispose();
    _tipController.dispose();
    _fabController.dispose();
    _flipWorkoutController.dispose();
    _flipNutritionController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero);
        final fade = Tween<double>(begin: 0.0, end: 1.0);
        return SlideTransition(
          position: tween.animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: fade.animate(animation), child: child),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Animation<double>? fadeAnimation,
    Animation<Offset>? slideAnimation,
    Animation<double>? flipAnimation,
    Widget? backChild,
    required VoidCallback onLongPress,
    double cardWidth = 160,
  }) {
    final double cardHeight = cardWidth * 1.12;
    const double borderRadius = 24; // increased radius for softer corners

    // Front content
    final front = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.98), Colors.white.withOpacity(0.12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _iconAnimation,
              child: CircleAvatar(
                radius: cardWidth * 0.18,
                backgroundColor: Colors.white,
                child: Icon(icon, size: cardWidth * 0.26, color: color),
              ),
            ),
            SizedBox(height: cardHeight * 0.06),
            Text(
              title,
              style: TextStyle(
                fontSize: max(16, cardWidth * 0.12),
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: cardHeight * 0.03),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: max(12, cardWidth * 0.08),
                  color: color.withOpacity(0.85),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    final back = backChild ??
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: cardWidth * 0.18, color: color),
                SizedBox(height: cardHeight * 0.06),
                Text(
                  'Quick info',
                  style: TextStyle(fontSize: max(14, cardWidth * 0.10), fontWeight: FontWeight.bold, color: color),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    'Tap to open. Long press to flip.',
                    style: TextStyle(fontSize: max(11, cardWidth * 0.07), color: color.withOpacity(0.85)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );

    Widget cardContent = Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(borderRadius),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedBuilder(
          animation: flipAnimation ?? const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            final value = flipAnimation?.value ?? 0.0;
            final angle = value * pi;
            final isFront = value <= 0.5;
            final display = isFront ? front : back;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);
            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: isFront
                  ? display
                  : Transform(
                      transform: Matrix4.rotationY(pi),
                      alignment: Alignment.center,
                      child: display,
                    ),
            );
          },
        ),
      ),
    );

    // Apply entrance animations if provided
    Widget wrapped = cardContent;
    if (fadeAnimation != null && slideAnimation != null) {
      wrapped = FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: wrapped,
        ),
      );
    }

    // Use the same fade animation for a subtle scale for a livelier feel
    wrapped = ScaleTransition(
      scale: fadeAnimation ?? const AlwaysStoppedAnimation(1),
      child: wrapped,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: cardWidth, maxWidth: cardWidth),
      child: wrapped,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = min(180.0, max(140.0, width * 0.38));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 88,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurpleAccent.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.only(top: 18),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                Hero(
                  tag: 'appIcon',
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: const Icon(Icons.directions_run, size: 38, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'NutriLift',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.account_circle, size: 32, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, _createRoute(const ProfileScreen()));
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          heroTag: 'quickLog',
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurpleAccent,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          label: const Text('Quick Log'),
          icon: const Icon(Icons.add),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create quick log (demo)')),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFF7F6FF), Colors.purple.shade50.withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Animated background circles
              AnimatedBuilder(
                animation: _bgCircleController,
                builder: (context, child) {
                  return Positioned(
                    top: -120,
                    left: -80,
                    child: Transform.scale(
                      scale: _bgCircleScale.value,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.deepPurpleAccent.withOpacity(0.14), Colors.deepPurple.withOpacity(0.06)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _bgCircleController,
                builder: (context, child) {
                  return Positioned(
                    bottom: -80,
                    right: -60,
                    child: Transform.scale(
                      scale: 1.18 - (_bgCircleScale.value - 0.8),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.purple.withOpacity(0.10), Colors.deepPurpleAccent.withOpacity(0.06)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // subtle glass overlay near top for depth
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.transparent, height: 0),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    // Greeting + search
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _iconAnimation,
                            child: AnimatedBuilder(
                              animation: _iconController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _iconController.value * 0.1,
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7367F0), Color(0xFFE0C3FC)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withOpacity(0.12),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.self_improvement, size: 64, color: Colors.deepPurpleAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _welcomeAnimation,
                            child: AnimatedBuilder(
                              animation: _welcomeController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, -8 * (1 - _welcomeAnimation.value)),
                                  child: child,
                                );
                              },
                              child: Text(
                                'Welcome back!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.deepPurple.shade800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Small habits → big results. Track meals, workouts and stay consistent.',
                              style: TextStyle(fontSize: 14.5, color: Colors.deepPurpleAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Search bar
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                icon: const Icon(Icons.search, color: Colors.deepPurple),
                                hintText: 'Search workouts, recipes, tips...',
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.mic, color: Colors.deepPurpleAccent),
                                  onPressed: () {},
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Cards row
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: min(28.0, width * 0.06)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCard(
                            icon: Icons.fitness_center,
                            title: 'Workouts',
                            subtitle: 'Log & view workouts',
                            color: Colors.deepPurpleAccent,
                            onTap: () {
                              Navigator.push(context, _createRoute(const WorkoutsScreen()));
                            },
                            fadeAnimation: _workoutFade,
                            slideAnimation: _workoutSlide,
                            flipAnimation: _flipWorkoutAnimation,
                            onLongPress: () {
                              if (_flipWorkoutController.isCompleted) {
                                _flipWorkoutController.reverse();
                              } else {
                                _flipWorkoutController.forward();
                              }
                            },
                            backChild: Container(
                              width: cardWidth,
                              height: cardWidth * 1.12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.deepPurpleAccent.withOpacity(0.06),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.show_chart, color: Colors.deepPurpleAccent, size: cardWidth * 0.16),
                                  const SizedBox(height: 8),
                                  Text('Weekly summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: max(13, cardWidth * 0.09))),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('Long press toggles this card', textAlign: TextAlign.center, style: TextStyle(fontSize: max(11, cardWidth * 0.07))),
                                  ),
                                ],
                              ),
                            ),
                            cardWidth: cardWidth,
                          ),
                          SizedBox(width: width > 420 ? 26 : 12),
                          _buildCard(
                            icon: Icons.restaurant,
                            title: 'Nutrition',
                            subtitle: 'Track your meals',
                            color: Colors.purple,
                            onTap: () {
                              Navigator.push(context, _createRoute(const NutritionScreen()));
                            },
                            fadeAnimation: _nutritionFade,
                            slideAnimation: _nutritionSlide,
                            flipAnimation: _flipNutritionAnimation,
                            onLongPress: () {
                              if (_flipNutritionController.isCompleted) {
                                _flipNutritionController.reverse();
                              } else {
                                _flipNutritionController.forward();
                              }
                            },
                            backChild: Container(
                              width: cardWidth,
                              height: cardWidth * 1.12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.purple.withOpacity(0.06),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_dining, color: Colors.purple, size: cardWidth * 0.16),
                                  const SizedBox(height: 8),
                                  Text('Meal tips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: max(13, cardWidth * 0.09))),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('Long press toggles this card', textAlign: TextAlign.center, style: TextStyle(fontSize: max(11, cardWidth * 0.07))),
                                  ),
                                ],
                              ),
                            ),
                            cardWidth: cardWidth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Tip card with shimmer effect and staggered fade
                    FadeTransition(
                      opacity: _tipFade,
                      child: AnimatedBuilder(
                        animation: _tipController,
                        builder: (context, child) {
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            elevation: 10,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            child: Stack(
                              children: [
                                // subtle shimmering accent
                                Positioned.fill(
                                  child: FractionallySizedBox(
                                    widthFactor: 1,
                                    child: ShaderMask(
                                      shaderCallback: (rect) {
                                        return LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.0),
                                            Colors.deepPurple.withOpacity(0.06),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                          stops: [
                                            (_tipShimmer.value - 0.2).clamp(0.0, 1.0),
                                            _tipShimmer.value.clamp(0.0, 1.0),
                                            (_tipShimmer.value + 0.2).clamp(0.0, 1.0),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ).createShader(rect);
                                      },
                                      blendMode: BlendMode.srcATop,
                                      child: Container(color: Colors.transparent),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.lightbulb_outline, color: Colors.deepPurpleAccent),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Tip: Consistency is key. Try a 10-minute routine daily and hydrate regularly.',
                                          style: TextStyle(fontSize: 15.5, color: Colors.black87),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text('Learn', style: TextStyle(color: Colors.deepPurpleAccent)),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Quote with fade-in animation
                    FadeTransition(
                      opacity: _quoteFade,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple.shade700, Colors.deepPurpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.format_quote, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '"Progress, not perfection."',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _settingsFade,
                      child: AnimatedBuilder(
                        animation: _welcomeController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.96 + 0.04 * _welcomeAnimation.value,
                            child: child,
                          );
                        },
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                          ),
                          icon: const Icon(Icons.settings, color: Colors.white),
                          label: const Text(
                            'Settings',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.push(context, _createRoute(const SettingsScreen()));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'appIcon',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7367F0), Color(0xFFE0C3FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.directions_run, size: 96, color: Colors.deepPurpleAccent),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This is the Profile Screen',
              style: TextStyle(fontSize: 21, color: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Workouts'),
      ),
      body: const Center(
        child: Text(
          'Track your workouts here!',
          style: TextStyle(fontSize: 21, color: Colors.deepPurple),
        ),
      ),
    );
  }
}

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('Nutrition'),
      ),
      body: const Center(
        child: Text(
          'Track your nutrition here!',
          style: TextStyle(fontSize: 21, color: Colors.purple),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text(
          'Settings will be available soon!',
          style: TextStyle(fontSize: 21, color: Colors.deepPurpleAccent),
        ),
      ),
    );
  }
}
