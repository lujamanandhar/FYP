import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'package:provider/provider.dart';
import '../services/app_config.dart';
import 'community_provider.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kGreen = Color(0xFF4CAF50);

/// Full-screen overlay shown after a day is completed.
/// The day is already marked complete — this only offers sharing to community.
/// Requirements: 24.1–24.7
class DayCompletionOverlay extends StatefulWidget {
  final int dayNumber;
  final String challengeName;
  final String challengeId;
  final String? firstMediaUrl;
  /// Image URLs from the completed log (non-video) to share.
  final List<String> imageUrls;

  const DayCompletionOverlay({
    super.key,
    required this.dayNumber,
    required this.challengeName,
    required this.challengeId,
    this.firstMediaUrl,
    this.imageUrls = const [],
  });

  @override
  State<DayCompletionOverlay> createState() => _DayCompletionOverlayState();
}

class _DayCompletionOverlayState extends State<DayCompletionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _postContent =>
      'I completed Day ${widget.dayNumber} of ${widget.challengeName}! 💪';

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      // Just create a community post — the day is already completed
      await context.read<CommunityProvider>().createPost(
        _postContent,
        widget.imageUrls,
      );
      if (mounted) {
        Navigator.of(context).pop();
        showCenterToast(context, 'Posted to community!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSharing = false);
        showCenterToast(context, 'Failed to share: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black87,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Success animation ──────────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: const Icon(Icons.check_circle, color: _kGreen, size: 100),
              ),
              const SizedBox(height: 20),

              Text(
                'Day ${widget.dayNumber} Complete!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.challengeName,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // ── Post preview ───────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _postContent,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.firstMediaUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          AppConfig.resolveMediaUrl(widget.firstMediaUrl!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Share button ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSharing ? null : _share,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSharing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Share to Community',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: _isSharing ? null : () => Navigator.of(context).pop(),
                child: const Text('Skip',
                    style: TextStyle(color: Colors.white70, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
