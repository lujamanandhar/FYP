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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
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

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int _points = 12;
  final List<Habit> _habits = [
    Habit('Drink water', '8 glasses target'),
    Habit('Walk', '20 minutes'),
    Habit('Vegetables', 'Include in meal'),
    Habit('Sleep early', 'Before 11pm'),
  ];

  // animation controller for subtle header animation
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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
        content: const Text('This will set points back to zero and uncheck all habits.'),
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

  void _deleteHabit(int index) {
    final removed = _habits[index];
    setState(() => _habits.removeAt(index));
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${removed.title}" removed'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _habits.insert(index, removed));
          },
        ),
      ),
    );
  }

  Future<void> _addHabitDialog() async {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (res == true && titleCtrl.text.trim().isNotEmpty) {
      setState(() => _habits.insert(0, Habit(titleCtrl.text.trim(), subCtrl.text.trim())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final progress = ((_points % 100) / 100).clamp(0.0, 1.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(onPressed: _confirmReset, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          // beautiful layered gradient background
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final t = _animController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.8 + t * 0.4, -1),
                    end: Alignment(1, 1),
                    colors: [
                      Colors.teal.shade800,
                      Colors.teal.shade600.withOpacity(0.9),
                      Colors.green.shade400.withOpacity(0.9),
                    ],
                  ),
                ),
              );
            },
          ),
          // subtle frosted card layout
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // header card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              // animated circular progress
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: progress),
                                  duration: const Duration(milliseconds: 800),
                                  builder: (context, value, _) => Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 110,
                                        height: 110,
                                        child: CircularProgressIndicator(
                                          value: value,
                                          strokeWidth: 10,
                                          backgroundColor: Colors.white24,
                                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 400),
                                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                            child: Text(
                                              '${_points % 100}',
                                              key: ValueKey<int>(_points % 100),
                                              style: theme.textTheme.headlineSmall?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          Text('pts', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Daily Progress', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text('Small habits — big impact. Keep the streak going!', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _incrementPoints(1),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add 1'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        OutlinedButton.icon(
                                          onPressed: _addHabitDialog,
                                          icon: const Icon(Icons.add_task),
                                          label: const Text('Add Habit'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // filter/search row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.04),
                              prefixIcon: const Icon(Icons.search, color: Colors.white70),
                              hintText: 'Search habits',
                              hintStyle: const TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            ),
                            onChanged: (val) {
                              // simple no-op for now; placeholder for future filter
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Chip(
                          label: const Text('Today', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.white.withOpacity(0.06),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // habits list
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        color: Colors.white.withOpacity(0.03),
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _habits.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                          itemBuilder: (context, index) {
                            final h = _habits[index];
                            return Dismissible(
                              key: ValueKey(h.title + h.subtitle + index.toString()),
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 18),
                                color: Colors.green.shade600,
                                child: const Icon(Icons.check, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 18),
                                color: Colors.red.shade600,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (dir) async {
                                if (dir == DismissDirection.startToEnd) {
                                  // swipe right: toggle done
                                  _toggleHabit(index);
                                  return false; // do not remove
                                } else {
                                  // swipe left: delete
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Delete habit?'),
                                      content: Text('Delete "${h.title}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  return confirm == true;
                                }
                              },
                              onDismissed: (_) => _deleteHabit(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                color: h.done ? Colors.white.withOpacity(0.02) : Colors.transparent,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: h.done
                                          ? LinearGradient(colors: [primary.withOpacity(0.9), primary.withOpacity(0.6)])
                                          : null,
                                      color: h.done ? null : Colors.white24,
                                    ),
                                    width: 46,
                                    height: 46,
                                    child: Icon(h.done ? Icons.check : Icons.water_drop, color: Colors.white),
                                  ),
                                  title: Text(h.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                  subtitle: Text(h.subtitle, style: TextStyle(color: Colors.white70)),
                                  trailing: Switch.adaptive(
                                    value: h.done,
                                    onChanged: (_) => _toggleHabit(index),
                                    activeColor: primary,
                                  ),
                                  onTap: () => _toggleHabit(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Text('Tip: swipe right to toggle, left to delete', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60)),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHabitDialog,
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
