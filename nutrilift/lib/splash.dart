import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: AnimatedBuilder(
            animation: _slideUp,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: child,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[700]!, Colors.red[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'GymPro',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[200],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Push Your Limits',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.orange[100],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 44),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                  strokeWidth: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
