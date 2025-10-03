// Changes: Animations are now staggered and use different curves for each card and welcome text.
// The icon uses a bounce effect, welcome text fades in with a delay, and cards slide in with staggered delays.

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  late AnimationController _welcomeController;
  late Animation<double> _welcomeAnimation;

  late AnimationController _cardController;
  late Animation<double> _workoutFade;
  late Animation<Offset> _workoutSlide;
  late Animation<double> _nutritionFade;
  late Animation<Offset> _nutritionSlide;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.bounceOut,
    );
    _iconController.forward();

    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _welcomeAnimation = CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeIn,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      _welcomeController.forward();
    });

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _workoutFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _workoutSlide = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _nutritionFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _nutritionSlide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _cardController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _welcomeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Animation<double>? fadeAnimation,
    Animation<Offset>? slideAnimation,
  }) {
    Widget card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
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
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(icon, size: 38, color: color),
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
      ),
    );

    if (fadeAnimation != null && slideAnimation != null) {
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: card,
        ),
      );
    }
    return card;
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
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
          Positioned(
            bottom: -60,
            right: -40,
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
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  ScaleTransition(
                    scale: _iconAnimation,
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
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _welcomeAnimation,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WorkoutsScreen()),
                          );
                        },
                        fadeAnimation: _workoutFade,
                        slideAnimation: _workoutSlide,
                      ),
                      const SizedBox(width: 24),
                      _buildCard(
                        icon: Icons.restaurant,
                        title: 'Nutrition',
                        subtitle: 'Track your meals',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NutritionScreen()),
                          );
                        },
                        fadeAnimation: _nutritionFade,
                        slideAnimation: _nutritionSlide,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.deepPurple[50]!.withOpacity(0.96),
                    child: Padding(
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
                  ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple[100]!, Colors.deepPurple[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.format_quote, color: Colors.deepPurpleAccent, size: 24),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '"Progress, not perfection."',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.deepPurpleAccent,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
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
      body: const Center(
        child: Text(
          'This is the Profile Screen',
          style: TextStyle(fontSize: 21, color: Colors.deepPurple),
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
