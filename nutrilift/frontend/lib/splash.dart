import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController; // for background cycling
  late final AnimationController _introController; // for logo/text entrance

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _introController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _logoFade = CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _slideUp = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );

    // start entrance animation
    _introController.forward();

    // navigate after a short pause (adjust as needed)
    Future.delayed(const Duration(milliseconds: 2800), _goToNextPage);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const NextPage()),
    );
  }

  // Helper to produce a smoothly interpolated 3-color gradient that cycles
  List<Color> _animatedGradientColors(double t) {
    // Two palettes to lerp between
    final paletteA = [const Color(0xFFFB8C00), const Color(0xFFFF7043), const Color(0xFF7C4DFF)];
    final paletteB = [const Color(0xFFEF5350), const Color(0xFFFFA726), const Color(0xFF5E35B1)];

    return List<Color>.generate(3, (i) => Color.lerp(paletteA[i], paletteB[i], t)!);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final colors = _animatedGradientColors(_bgController.value);
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _logoFade,
                  child: AnimatedBuilder(
                    animation: _introController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glowing circular logo with subtle radial gradient
                        Container(
                          width: size.width * 0.38,
                          height: size.width * 0.38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.04),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.35, 1.0],
                              center: Alignment(-0.2, -0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 30,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.06),
                                blurRadius: 6,
                                spreadRadius: 0,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: size.width * 0.28,
                              height: size.width * 0.28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF8A65), Color(0xFFFF5252)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orangeAccent.withOpacity(0.35),
                                    blurRadius: 30,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 72,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // App title
                        Text(
                          'GymPro',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.98),
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.28),
                                blurRadius: 8,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tagline
                        Text(
                          'Train harder. Recover smarter.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 26),
                        // Progress indicator + micro caption
                        Column(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                strokeWidth: 5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                backgroundColor: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Preparing your workout...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Dummy next page for navigation example
class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Next Page')),
    );
  }
}
