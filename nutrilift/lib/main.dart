import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class GitHubCopilot {}

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
      home: const MyHomePage(title: 'NutriLift'),
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

class Habit {
  String title;
  String subtitle;
  bool done;
  Habit(this.title, this.subtitle, {this.done = false});
}

class _MyHomePageState extends State<MyHomePage> {
  int _points = 12;
  final List<Habit> _habits = [
    Habit('Drink water', '8 glasses target'),
    Habit('Walk', '20 minutes'),
    Habit('Vegetables', 'Include in meal'),
    Habit('Sleep early', 'Before 11pm'),
  ];

  void _incrementPoints([int by = 1]) {
    setState(() {
      _points += by;
      if (_points > 9999) _points = 9999;
    });
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Points added'),
        duration: Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmReset() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset points?'),
        content: const Text('This will set points back to zero.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (res == true) {
      setState(() {
        _points = 0;
        for (var h in _habits) h.done = false;
      });
    }
  }

  void _toggleHabit(int index) {
    setState(() {
      _habits[index].done = !_habits[index].done;
      _points += _habits[index].done ? 5 : -5;
      if (_points < 0) _points = 0;
    });
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_habits[index].done ? 'Marked done' : 'Marked undone'),
        duration: const Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final progress = ((_points % 100) / 100).clamp(0.0, 1.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade200, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // subtle blur card area
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    // header card with progress ring
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              // circular progress
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 96,
                                    height: 96,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${_points % 100}', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                                      Text('pts', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 18),
                              // text info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Daily Progress', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text('Keep going — small habits add up.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _incrementPoints(1),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add 1'),
                                          style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        ),
                                        const SizedBox(width: 10),
                                        OutlinedButton(
                                          onPressed: _confirmReset,
                                          child: const Text('Reset'),
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // categories chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryChip(label: 'Hydration', color: Colors.blue.shade300),
                          const SizedBox(width: 8),
                          _CategoryChip(label: 'Exercise', color: Colors.orange.shade300),
                          const SizedBox(width: 8),
                          _CategoryChip(label: 'Nutrition', color: Colors.green.shade300),
                          const SizedBox(width: 8),
                          _CategoryChip(label: 'Sleep', color: Colors.purple.shade300),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // habits list
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        color: Colors.white.withOpacity(0.04),
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _habits.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                          itemBuilder: (context, index) {
                            final h = _habits[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: h.done ? primary : Colors.white24,
                                child: Icon(h.done ? Icons.check : Icons.health_and_safety, color: Colors.white),
                              ),
                              title: Text(h.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              subtitle: Text(h.subtitle, style: TextStyle(color: Colors.white70)),
                              trailing: Switch(
                                value: h.done,
                                onChanged: (_) => _toggleHabit(index),
                                activeColor: primary,
                              ),
                              onTap: () => _toggleHabit(index),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Tip: toggle habits to add/remove points', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _confirmReset,
        child: FloatingActionButton.extended(
          onPressed: () => _incrementPoints(1),
          backgroundColor: primary,
          icon: const Icon(Icons.add),
          label: const Text('Add Point'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      backgroundColor: color.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
