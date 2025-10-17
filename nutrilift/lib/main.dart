import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLift',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MyHomePage(title: 'NutriLift Home'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int _counter = 0;
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added +1'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset counter?'),
        content: const Text('This will set the counter back to zero.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (res == true) {
      setState(() {
        _counter = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About NutriLift'),
                  content: const Text('NutriLift helps you track your healthy habits!'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withAlpha((0.95 * 255).round()), Colors.green.shade700.withAlpha((0.95 * 255).round())],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
      ),
      body: Stack(
        children: [
          // Animated subtle gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final t = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + t * 2, -1),
                    end: Alignment(1 - t * 2, 1),
                    colors: [
                      Colors.green.shade50,
                      Colors.green.shade100,
                      Colors.green.shade300,
                      Colors.green.shade600,
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.12 * 255).round()),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withAlpha((0.10 * 255).round())),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.08 * 255).round()),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // top icon/brand
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [primary, Colors.green.shade300]),
                                boxShadow: [
                                    BoxShadow(color: primary.withAlpha((0.35 * 255).round()), blurRadius: 24, offset: const Offset(0, 10)),
                                  ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                radius: 44,
                                child: Icon(Icons.health_and_safety, color: Colors.white, size: 44),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'NutriLift',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track healthy habits — small steps daily',
                              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 22),
                            // counter display with gradient text
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: Container(
                                key: ValueKey<int>(_counter),
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.white.withAlpha((0.06 * 255).round()), Colors.white.withAlpha((0.03 * 255).round())]),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withAlpha((0.06 * 255).round())),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'You pressed',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 6),
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [primary, Colors.green.shade300],
                                      ).createShader(bounds),
                                      child: Text(
                                        '$_counter',
                                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 56),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _incrementCounter,
                                    icon: const Icon(Icons.add),
                                    label: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      child: Text('Increment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _confirmReset,
                                  icon: const Icon(Icons.refresh),
                                  label: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text('Reset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withAlpha((0.12 * 255).round())),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tip: long-press the floating button to reset.',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _confirmReset,
        child: FloatingActionButton.extended(
          onPressed: _incrementCounter,
          backgroundColor: primary,
          label: const Text('Add'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
