import 'dart:async';
import 'package:flutter/material.dart';

const Color _kRed = Color(0xFFE53935);

/// Shows a rest timer bottom sheet after completing a set.
/// Default rest time is 90 seconds, user can adjust.
void showRestTimer(BuildContext context, {int seconds = 90}) {
  showModalBottomSheet(
    context: context,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RestTimerSheet(initialSeconds: seconds),
  );
}

class _RestTimerSheet extends StatefulWidget {
  final int initialSeconds;
  const _RestTimerSheet({required this.initialSeconds});

  @override
  State<_RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<_RestTimerSheet> {
  late int _remaining;
  late int _total;
  Timer? _timer;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _total = widget.initialSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          t.cancel();
          _running = false;
        }
      });
    });
  }

  void _addTime(int secs) {
    setState(() => _remaining = (_remaining + secs).clamp(0, 600));
  }

  String get _timeStr {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _total > 0 ? _remaining / _total : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Rest Timer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),

          // Circular progress
          SizedBox(
            width: 140, height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140, height: 140,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remaining <= 10 ? Colors.orange : _kRed,
                    ),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_timeStr,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _remaining <= 10 ? Colors.orange : Colors.black87,
                      )),
                  if (!_running)
                    const Text('Done!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdjustBtn(label: '-15s', onTap: () => _addTime(-15)),
              const SizedBox(width: 12),
              _AdjustBtn(label: '-30s', onTap: () => _addTime(-30)),
              const SizedBox(width: 12),
              _AdjustBtn(label: '+30s', onTap: () => _addTime(30)),
              const SizedBox(width: 12),
              _AdjustBtn(label: '+60s', onTap: () => _addTime(60)),
            ],
          ),
          const SizedBox(height: 16),

          // Skip button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Skip Rest',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AdjustBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kRed,
        side: const BorderSide(color: _kRed),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
