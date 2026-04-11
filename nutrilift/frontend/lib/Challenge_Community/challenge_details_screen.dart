import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import '../services/dashboard_service.dart';
import 'challenge_provider.dart';
import 'challenge_api_service.dart';
import 'active_challenge_screen.dart';
import 'esewa_payment_screen.dart';
import 'challenge_leaderboard_screen.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final ChallengeModel challenge;

  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final dashboardService = DashboardService();
      final streak = await dashboardService.getCurrentStreak();
      if (mounted) {
        setState(() {
          _currentStreak = streak;
        });
      }
    } catch (e) {
      print('Error loading streak: $e');
    }
  }

  int get _daysRemaining {
    final diff = widget.challenge.endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'nutrition':
        return Colors.green;
      case 'workout':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final typeColor = _typeColor(challenge.challengeType);

    return NutriLiftScaffold(
      streakCount: _currentStreak,
      title: 'Challenge Details',
      showBackButton: true,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ──────────────────────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            challenge.challengeType.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white),
                          ),
                          backgroundColor: typeColor,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.description,
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    // Dates
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label:
                          'Start: ${_formatDate(challenge.startDate)}',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.event,
                      label: 'End: ${_formatDate(challenge.endDate)}',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.schedule,
                      label: '$_daysRemaining days remaining',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.flag,
                      label:
                          'Goal: ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.people,
                      label: challenge.maxParticipants != null
                          ? '${challenge.participantCount} / ${challenge.maxParticipants} joined'
                          : '${challenge.participantCount} participants',
                    ),
                    if (challenge.maxParticipants != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: challenge.spotsLeft == 0
                            ? Icons.block
                            : Icons.event_seat,
                        label: challenge.spotsLeft == 0
                            ? 'Challenge is full'
                            : '${challenge.spotsLeft} spots remaining',
                        color: challenge.spotsLeft == 0
                            ? Colors.red
                            : challenge.spotsLeft! <= 5
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Circular progress ────────────────────────────────────────
            Consumer<ChallengeProvider>(
              builder: (context, provider, _) {
                final live = provider.challenges.firstWhere(
                  (c) => c.id == challenge.id,
                  orElse: () => challenge,
                );
                final progressPercent = live.goalValue > 0
                    ? (live.participantProgress / live.goalValue).clamp(0.0, 1.0)
                    : 0.0;
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Progress',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: progressPercent,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(typeColor),
                                ),
                                Center(
                                  child: Text(
                                    '${(progressPercent * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            '${live.participantProgress.toStringAsFixed(0)} / ${live.goalValue.toStringAsFixed(0)} ${live.unit}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Leaderboard button ───────────────────────────────────────
            _LeaderboardButton(challenge: challenge),
            const SizedBox(height: 24),

            // ── JOIN / LEAVE buttons ─────────────────────────────────
            Consumer<ChallengeProvider>(
              builder: (context, provider, _) {
                final current = provider.challenges.firstWhere(
                  (c) => c.id == challenge.id,
                  orElse: () => challenge,
                );
                if (current.isJoined) {
                  // Already joined — show "Go to Daily Log" + Leave
                  return Column(children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ActiveChallengeScreen(
                                  challengeId: challenge.id)),
                        ),
                        icon: const Icon(Icons.today),
                        label: const Text("Today's Daily Log",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Leave Challenge?'),
                              content: const Text(
                                  'Are you sure you want to leave? All your progress will be reset and cannot be recovered.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Cancel',
                                        style: TextStyle(
                                            color: Colors.grey[600]))),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFE53935)),
                                    child: const Text('Leave')),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) {
                            await provider.leaveChallenge(challenge.id);
                            if (context.mounted) {
                              showCenterToast(context, 'Left challenge successfully');
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                          side: const BorderSide(color: Color(0xFFE53935)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Leave Challenge',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]);
                }
                // Not joined — show JOIN button (with payment check)
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (current.isPaid && !current.hasPaid) {
                        // Show payment sheet
                        showPaymentSheet(context, current, () async {
                          // Payment intercepted by WebView — now join the challenge directly
                          try {
                            await provider.joinChallenge(challenge.id);
                          } catch (_) {
                            // May already be joined if backend verify ran — ignore
                          }
                          await provider.fetchChallenges();
                          if (context.mounted) {
                            showCenterToast(context, '✅ Payment successful! You have joined the challenge.');
                            // Navigate to active challenge screen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActiveChallengeScreen(challengeId: challenge.id),
                              ),
                            );
                          }
                        });
                      } else {
                        await provider.joinChallenge(challenge.id);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ActiveChallengeScreen(
                                    challengeId: challenge.id)),
                          );
                        }
                      }
                    },
                    icon: Icon(current.isPaid && !current.hasPaid
                        ? Icons.lock
                        : Icons.emoji_events),
                    label: Text(
                      current.isPaid && !current.hasPaid
                          ? 'Pay ${current.currency} ${current.price.toStringAsFixed(0)} to Join'
                          : 'Join Challenge',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: current.isPaid && !current.hasPaid
                          ? const Color(0xFF60BB46)
                          : const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[600]!;
    return Row(
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: color != null ? c : Colors.grey[700], fontSize: 13)),
      ],
    );
  }
}

class _LeaderboardButton extends StatelessWidget {
  final ChallengeModel challenge;
  const _LeaderboardButton({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final hasEnded = challenge.endDate.isBefore(DateTime.now());
    // Get current user ID from provider if available
    final currentUserId = challenge.createdById; // fallback; real ID fetched in screen
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          // Fetch current user ID for "You" highlight
          String? userId;
          try {
            final provider = context.read<ChallengeProvider>();
            userId = provider.currentUserId;
          } catch (_) {}
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengeLeaderboardScreen(
                  challengeId: challenge.id,
                  challengeName: challenge.name,
                  endDate: challenge.endDate,
                  prizeDescription: challenge.prizeDescription.isNotEmpty ? challenge.prizeDescription : null,
                  currentUserId: userId,
                ),
              ),
            );
          }
        },
        icon: Icon(hasEnded ? Icons.emoji_events : Icons.leaderboard, color: const Color(0xFFE53935)),
        label: Text(
          hasEnded ? 'View Final Leaderboard' : 'View Leaderboard',
          style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE53935)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
