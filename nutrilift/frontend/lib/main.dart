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
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    final textTheme = base.textTheme.copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w900),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w900),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12),
    );

    return MaterialApp(
      title: 'NutriLift',
      theme: base.copyWith(textTheme: textTheme),
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

  late final AnimationController _animController;

  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
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
    if (index < 0 || index >= _habits.length) return;
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
    if (index < 0 || index >= _habits.length) return;
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
    final level = (_points ~/ 100).clamp(0, 99);

    // filtered view
    final visible = _habits.where((h) {
      if (_search.isEmpty) return true;
      final t = h.title.toLowerCase();
      final s = h.subtitle.toLowerCase();
      return t.contains(_search) || s.contains(_search);
    }).toList();

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
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final t = _animController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.9 + t * 0.5, -1),
                    end: Alignment(1, 1),
                    colors: [
                      Colors.red.shade900,
                      Colors.red.shade600.withOpacity(0.95),
                      Colors.red.shade400.withOpacity(0.9),
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [primary.withOpacity(0.35), Colors.transparent]),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: progress),
                                  duration: const Duration(milliseconds: 900),
                                  builder: (context, value, _) => Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 114,
                                        height: 114,
                                        child: CircularProgressIndicator(
                                          value: value,
                                          strokeWidth: 12,
                                          backgroundColor: Colors.white12,
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
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _incrementPoints(1),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add 1'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 6,
                                            shadowColor: primary.withOpacity(0.6),
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
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.rocket_launch, color: Colors.white70, size: 14),
                                              const SizedBox(width: 6),
                                              Text('Lv. $level', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        )
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
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                                hintText: 'Search habits',
                                hintStyle: const TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                suffixIcon: _search.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (val) {},
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text('Today', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: List.generate(visible.length, (vIndex) {
                        final h = visible[vIndex];
                        final origIndex = _habits.indexOf(h);
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 350 + (vIndex * 40)),
                          curve: Curves.easeOut,
                          builder: (context, val, child) {
                            return Opacity(
                              opacity: val,
                              child: Transform.translate(offset: Offset(0, (1 - val) * 8), child: child),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Dismissible(
                              key: ValueKey(h.title + h.subtitle + origIndex.toString()),
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 18),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Toggle done', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 18),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade800,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: const [
                                    Icon(Icons.delete, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (dir) async {
                                if (dir == DismissDirection.startToEnd) {
                                  _toggleHabit(origIndex);
                                  return false;
                                } else {
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
                              onDismissed: (_) => _deleteHabit(origIndex),
                              child: Material(
                                color: h.done ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.02),
                                elevation: 6,
                                shadowColor: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _toggleHabit(origIndex),
                                  onLongPress: () {
                                    // quick edit on long press
                                    final titleCtrl = TextEditingController(text: h.title);
                                    final subCtrl = TextEditingController(text: h.subtitle);
                                    showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Edit Habit'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                                            TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(c, true);
                                            },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    ).then((ok) {
                                      if (ok == true) {
                                        setState(() {
                                          h.title = titleCtrl.text.trim();
                                          h.subtitle = subCtrl.text.trim();
                                        });
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: h.done
                                                ? LinearGradient(colors: [primary.withOpacity(0.95), primary.withOpacity(0.6)])
                                                : null,
                                            color: h.done ? null : Colors.white12,
                                            border: Border.all(color: Colors.white10),
                                          ),
                                          child: Icon(h.done ? Icons.check : Icons.water_drop, color: Colors.white),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(h.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                              const SizedBox(height: 4),
                                              Text(h.subtitle, style: TextStyle(color: Colors.white70, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Switch.adaptive(
                                              value: h.done,
                                              onChanged: (_) => _toggleHabit(origIndex),
                                              activeColor: primary,
                                            ),
                                            PopupMenuButton<String>(
                                              color: Colors.grey.shade900,
                                              onSelected: (v) {
                                                if (v == 'edit') {
                                                  final titleCtrl = TextEditingController(text: h.title);
                                                  final subCtrl = TextEditingController(text: h.subtitle);
                                                  showDialog<bool>(
                                                    context: context,
                                                    builder: (c) => AlertDialog(
                                                      title: const Text('Edit Habit'),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                                                          TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(c, true);
                                                          },
                                                          child: const Text('Save'),
                                                        ),
                                                      ],
                                                    ),
                                                  ).then((ok) {
                                                    if (ok == true) {
                                                      setState(() {
                                                        h.title = titleCtrl.text.trim();
                                                        h.subtitle = subCtrl.text.trim();
                                                      });
                                                    }
                                                  });
                                                } else if (v == 'delete') {
                                                  _deleteHabit(origIndex);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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
        label: const Text('Old Habit'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
