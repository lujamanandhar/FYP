import 'package:flutter/material.dart';
import 'dart:async';

/// Shows a centered toast overlay with a blurred/dimmed background.
/// Auto-dismisses after [duration]. Tapping the overlay also dismisses it.
///
/// Usage:
///   showCenterToast(context, 'Meal logged successfully!');
///   showCenterToast(context, 'Error occurred', isError: true);
void showCenterToast(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
}) {
  // Ignore if context is no longer valid
  if (!context.mounted) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _CenterToast(
      message: message,
      isError: isError,
      duration: duration,
      onDismiss: () {
        try { entry.remove(); } catch (_) {}
      },
    ),
  );

  overlay.insert(entry);
}

class _CenterToast extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final VoidCallback onDismiss;

  const _CenterToast({
    required this.message,
    required this.isError,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_CenterToast> createState() => _CenterToastState();
}

class _CenterToastState extends State<_CenterToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _timer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Blurred dim background
            Container(color: Colors.black.withOpacity(0.35)),

            // Centered card
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: widget.isError ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
