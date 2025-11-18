import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
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

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _logoFade = CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _slideUp = Tween<double>(begin: 32, end: 0).animate(
      CurvedAnimation(
          parent: _introController,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
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
    final paletteA = [
      const Color(0xFFFB8C00),
      const Color(0xFFFF7043),
      const Color(0xFF7C4DFF)
    ];
    final paletteB = [
      const Color(0xFFEF5350),
      const Color(0xFFFFA726),
      const Color(0xFF5E35B1)
    ];

    return List<Color>.generate(
        3, (i) => Color.lerp(paletteA[i], paletteB[i], t)!);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          final colors = _animatedGradientColors(t);
          // animate gradient direction subtly
          final begin = Alignment.lerp(
              Alignment.topLeft, Alignment(-0.8 + 0.6 * t, -1.0 + 0.6 * t), t)!;
          final end = Alignment.lerp(
              Alignment.bottomRight, Alignment(1.0 - 0.6 * t, 0.8 - 0.6 * t), t)!;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: begin,
                end: end,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Top-right skip button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.95),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12.0),
                        ),
                        onPressed: _goToNextPage,
                        child: const Text('Skip'),
                      ),
                    ),
                  ),

                  // Center content
                  Center(
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
                            // Glowing circular logo with subtle radial gradient + hero
                            Hero(
                              tag: 'app-logo',
                              child: Container(
                                width: size.width * 0.36,
                                height: size.width * 0.36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.14),
                                      Colors.white.withOpacity(0.05),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.34, 1.0],
                                    center: const Alignment(-0.2, -0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.26),
                                      blurRadius: 34,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 10),
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
                                    width: size.width * 0.26,
                                    height: size.width * 0.26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF8A65),
                                          Color(0xFFFF5252)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.orangeAccent.withOpacity(
                                                  0.36),
                                          blurRadius: 30,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.fitness_center,
                                        size: 66,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // App title with subtle gradient text effect using ShaderMask
                            Text(
                              'NutriLift',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.98),
                                      Colors.white.withOpacity(0.92)
                                    ],
                                  ).createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                  ),
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.24),
                                    blurRadius: 8,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Tagline more concise
                            Text(
                              'Train smarter. Eat better.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Animated determinate progress indicator + micro caption
                            Column(
                              children: [
                                SizedBox(
                                  width: 62,
                                  height: 62,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 5,
                                    value: (_introController.value).clamp(0.0, 1.0),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    backgroundColor:
                                        Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Preparing your personalized plan...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.86),
                                    fontSize: 13,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom small credit / subtle hint
                  Positioned(
                    bottom: 18,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Made with ❤️ by NutriLift',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
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
      appBar: AppBar(title: const Text('Next')),
      body: Center(child: Hero(tag: 'app-logo', child: Icon(Icons.fitness_center, size: 88))),
    );
  }
}
