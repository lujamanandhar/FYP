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

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.85),
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 8,
        shadowColor: Colors.green.shade700,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100,
                  Colors.green.shade300,
                  Colors.green.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Card(
                elevation: 18,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                color: Colors.white.withOpacity(0.97),
                shadowColor: Colors.green.shade200,
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              Colors.green.shade200,
                              Colors.green.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade200,
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Icon(Icons.health_and_safety, color: Colors.white, size: 64),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'NutriLift Counter',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'You have pushed the button this many times:',
                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Text(
                          '$_counter',
                          key: ValueKey<int>(_counter),
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 54,
                            shadows: [
                              Shadow(
                                color: Colors.green.shade200,
                                blurRadius: 12,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _incrementCounter,
                        icon: const Icon(Icons.add, size: 28),
                        label: const Text('Increment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 8,
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}
