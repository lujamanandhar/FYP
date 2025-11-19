import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController; // background cycling
  late final AnimationController _introController; // logo/text entrance
  late final AnimationController _titleShimmer; // title shimmer

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _introController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _titleShimmer = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: false);

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.elasticOut),
    );
    _logoFade = CurvedAnimation(
        parent: _introController, curve: const Interval(0.0, 0.7, curve: Curves.easeIn));
    _slideUp = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOut),
    );

    _introController.forward();

    Future.delayed(const Duration(milliseconds: 2800), _goToNextPage);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _introController.dispose();
    _titleShimmer.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const NextPage()),
    );
  }

  // Two palettes to smoothly mix
  List<Color> _interpolatedColors(double t) {
    final a = [
      const Color(0xFF0F172A),
      const Color(0xFF042A2B),
      const Color(0xFF0B3A2A),
    ];
    final b = [
      const Color(0xFF1E3A8A),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
    ];
    return List<Color>.generate(3, (i) => Color.lerp(a[i], b[i], (sin(2 * pi * t + i) * 0.5 + 0.5))!);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double logoOuter = size.width * 0.34;
    final double logoInner = size.width * 0.24;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          final colors = _interpolatedColors(t);
          final begin = Alignment(-0.9 + 1.8 * t, -1.0 + 1.6 * t);
          final end = Alignment(0.9 - 1.6 * t, 1.0 - 1.8 * t);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: end,
                colors: colors,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Soft animated shaped overlay for depth
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.08,
                        child: Transform.rotate(
                          angle: sin(2 * pi * t) * 0.06,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(-0.4 + 0.8 * t, -0.6 + 1.2 * t),
                                radius: 1.1,
                                colors: [
                                  Colors.white,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Skip button (subtle)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: GestureDetector(
                        onTap: _goToNextPage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.skip_next, color: Colors.white.withOpacity(0.9), size: 18),
                              const SizedBox(width: 6),
                              Text('Skip', style: TextStyle(color: Colors.white.withOpacity(0.92))),
                            ],
                          ),
                        ),
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
                          child: Transform.scale(scale: _logoScale.value, child: child),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Layered circular logo with glass card behind
                            Container(
                              width: logoOuter + 36,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular((logoOuter + 36) / 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.28),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                              child: Center(
                                child: Hero(
                                  tag: 'app-logo',
                                  child: Container(
                                    width: logoOuter,
                                    height: logoOuter,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: logoInner,
                                        height: logoInner,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Color(0xFFFF8A65), Color(0xFFFF5252)],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orangeAccent.withOpacity(0.32),
                                              blurRadius: 26,
                                              spreadRadius: 4,
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.14),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Transform.rotate(
                                            angle: sin(pi * _introController.value) * 0.05,
                                            child: Icon(Icons.fitness_center, size: 62, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // App title with moving shimmer
                            AnimatedBuilder(
                              animation: _titleShimmer,
                              builder: (context, _) {
                                final shimmerPos = _titleShimmer.value;
                                return ShaderMask(
                                  shaderCallback: (rect) {
                                    return LinearGradient(
                                      begin: Alignment(-1.0 + 2.0 * shimmerPos, -0.2),
                                      end: Alignment(-0.2 + 2.0 * shimmerPos, 0.2),
                                      colors: [
                                        Colors.white.withOpacity(0.98),
                                        Colors.white.withOpacity(0.6),
                                        Colors.white.withOpacity(0.98),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
                                  },
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    'NutriLift',
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 6),

                            // Description / tagline with subtle emphasis
                            Text(
                              'Train smarter • Eat better • Live stronger',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 18),

                            // Progress row with dots + message
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 76,
                                  height: 76,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 4.5,
                                        value: (_introController.value).clamp(0.0, 1.0),
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                        backgroundColor: Colors.white.withOpacity(0.12),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(3, (i) {
                                          final active = (_introController.value * 3).floor() == i;
                                          return AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            width: active ? 8 : 6,
                                            height: active ? 8 : 6,
                                            decoration: BoxDecoration(
                                              color: active ? Colors.white : Colors.white.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        }),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Preparing your plan',
                                      style: TextStyle(color: Colors.white.withOpacity(0.94), fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Personalized tips are loading...',
                                      style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom credit and small CTA
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Made with ❤️ by NutriLift',
                          style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: _goToNextPage,
                          child: Row(
                            children: const [
                              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Get Started', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        )
                      ],
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

// Simple NextPage to demonstrate Hero transition
class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Hero(
          tag: 'app-logo',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFF8A65), Color(0xFFFF5252)]),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: Offset(0, 12))],
            ),
            padding: const EdgeInsets.all(28),
            child: const Icon(Icons.fitness_center, size: 88, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
