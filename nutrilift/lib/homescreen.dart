import 'dart:math';
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
    curve: Curves.bounceOut,
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

  // New: Background circles animation
  late final AnimationController _bgCircleController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final Animation<double> _bgCircleScale = Tween<double>(begin: 0.8, end: 1.1).animate(
    CurvedAnimation(parent: _bgCircleController, curve: Curves.easeInOut),
  );

  // New: Quote fade-in animation
  late final AnimationController _quoteController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _quoteFade = CurvedAnimation(
    parent: _quoteController,
    curve: Curves.easeIn,
  );

  // New: Tip card shimmer animation
  late final AnimationController _tipController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  late final Animation<double> _tipShimmer = Tween<double>(begin: -1, end: 2).animate(
    CurvedAnimation(parent: _tipController, curve: Curves.linear),
  );

  // New: FAB pulse animation
  late final AnimationController _fabController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
    lowerBound: 0.95,
    upperBound: 1.05,
  );

  // New: Flip animations for the two cards (workout, nutrition)
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

  // New: Stagger controller for tip + settings entrance
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
  }) {
    // Front content
    final front = Container(
      width: 160,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), Colors.white.withOpacity(0.18)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedRotation(
            turns: fadeAnimation?.value ?? 0,
            duration: const Duration(milliseconds: 600),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(icon, size: 38, color: color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    final back = backChild ??
        Container(
          width: 160,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 36, color: color),
              const SizedBox(height: 12),
              Text(
                'Quick info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to open. Long press to flip.',
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

    Widget cardContent = GestureDetector(
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

    // Add a slight scale when the fade is animating so it feels lively
    wrapped = AnimatedScale(
      scale: (fadeAnimation?.value ?? 1),
      duration: const Duration(milliseconds: 300),
      child: wrapped,
    );

    return wrapped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'NutriLift',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 32, color: Colors.deepPurpleAccent),
            onPressed: () {
              Navigator.push(context, _createRoute(const ProfileScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton(
          backgroundColor: Colors.deepPurpleAccent,
          child: const Icon(Icons.add),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create quick log (demo)')),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Animated background circles
          AnimatedBuilder(
            animation: _bgCircleController,
            builder: (context, child) {
              return Positioned(
                top: -80,
                left: -60,
                child: Transform.scale(
                  scale: _bgCircleScale.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.deepPurpleAccent.withOpacity(0.18), Colors.deepPurple.withOpacity(0.12)],
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
                bottom: -60,
                right: -40,
                child: Transform.scale(
                  scale: 1.2 - (_bgCircleScale.value - 0.8),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purple.withOpacity(0.15), Colors.deepPurpleAccent.withOpacity(0.10)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  ScaleTransition(
                    scale: _iconAnimation,
                    child: AnimatedBuilder(
                      animation: _iconController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconController.value * 0.2,
                          child: child,
                        );
                      },
                      child: Hero(
                        tag: 'appIcon',
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7367F0), Color(0xFFE0C3FC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.directions_run, size: 80, color: Colors.deepPurpleAccent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _welcomeAnimation,
                    child: AnimatedBuilder(
                      animation: _welcomeController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -10 * (1 - _welcomeAnimation.value)),
                          child: child,
                        );
                      },
                      child: Text(
                        'Welcome!',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Achieve your fitness goals with NutriLift. Track workouts, meals, and progress.',
                      style: TextStyle(fontSize: 16, color: Colors.deepPurpleAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
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
                          width: 160,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: Colors.deepPurpleAccent.withOpacity(0.12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.show_chart, color: Colors.deepPurpleAccent, size: 30),
                              SizedBox(height: 8),
                              Text('Weekly summary', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text('Long press toggles this card', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
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
                          width: 160,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: Colors.purple.withOpacity(0.12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.local_dining, color: Colors.purple, size: 30),
                              SizedBox(height: 8),
                              Text('Meal tips', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text('Long press toggles this card', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Tip card with shimmer effect and staggered fade
                  FadeTransition(
                    opacity: _tipFade,
                    child: AnimatedBuilder(
                      animation: _tipController,
                      builder: (context, child) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.deepPurple[50]!.withOpacity(0.96),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: FractionallySizedBox(
                                  widthFactor: 1,
                                  child: ShaderMask(
                                    shaderCallback: (rect) {
                                      return LinearGradient(
                                        colors: [
                                          Colors.deepPurpleAccent.withOpacity(0.1),
                                          Colors.deepPurpleAccent.withOpacity(0.3),
                                          Colors.deepPurpleAccent.withOpacity(0.1),
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
                                    child: Container(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.info_outline, color: Colors.deepPurpleAccent),
                                    SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'Tip: Consistency is key. Stay hydrated!',
                                        style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quote with fade-in animation
                  FadeTransition(
                    opacity: _quoteFade,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.format_quote, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '"Progress, not perfection."',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _settingsFade,
                    child: AnimatedBuilder(
                      animation: _welcomeController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.95 + 0.05 * _welcomeAnimation.value,
                          child: child,
                        );
                      },
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          ),
        ],
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
