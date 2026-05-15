import 'package:flutter/material.dart';
import 'challenge_api_service.dart';
import '../Admin/admin_service.dart';
import '../services/app_config.dart';
import '../widgets/center_toast.dart';

class ChallengeLeaderboardScreen extends StatefulWidget {
  final String challengeId;
  final String challengeName;
  final DateTime endDate;
  final bool isAdmin;
  final String? prizeDescription;
  final String? currentUserId;

  const ChallengeLeaderboardScreen({
    Key? key,
    required this.challengeId,
    required this.challengeName,
    required this.endDate,
    this.isAdmin = false,
    this.prizeDescription,
    this.currentUserId,
  }) : super(key: key);

  @override
  State<ChallengeLeaderboardScreen> createState() => _ChallengeLeaderboardScreenState();
}

class _ChallengeLeaderboardScreenState extends State<ChallengeLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  List<ChallengeParticipantModel> _leaderboard = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final Set<String> _awardedParticipants = {};
  final Set<String> _awarding = {};

  bool get _hasEnded => widget.endDate.isBefore(DateTime.now());

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      List<ChallengeParticipantModel> list;
      if (widget.isAdmin) {
        final data = await AdminService().getAdminChallengeLeaderboard(widget.challengeId);
        list = (data['leaderboard'] as List? ?? [])
            .map((e) => ChallengeParticipantModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final awarded = (data['leaderboard'] as List? ?? [])
            .where((e) => e['prize_paid'] == true)
            .map((e) => e['participant_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        _awardedParticipants.addAll(awarded);
      } else {
        list = await ChallengeApiService().fetchLeaderboard(widget.challengeId);
      }
      setState(() { _leaderboard = list; _isLoading = false; });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _awardPrize(ChallengeParticipantModel entry) async {
    final pid = entry.participantId;
    if (pid == null) return;
    setState(() => _awarding.add(pid));
    try {
      await AdminService().awardPrize(widget.challengeId, pid);
      setState(() => _awardedParticipants.add(pid));
      if (mounted) showCenterToast(context, '🎉 Prize awarded to ${entry.username}!');
    } catch (e) {
      if (mounted) showCenterToast(context, 'Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _awarding.remove(pid));
    }
  }

  Future<void> _disqualify(ChallengeParticipantModel entry) async {
    final pid = entry.participantId;
    if (pid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Participant?'),
        content: Text('Remove ${entry.username} from this challenge? They will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await AdminService().disqualifyParticipant(widget.challengeId, pid);
      setState(() => _leaderboard.removeWhere((e) => e.participantId == pid));
      if (mounted) showCenterToast(context, '${entry.username} removed from challenge');
    } catch (e) {
      if (mounted) showCenterToast(context, 'Failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_leaderboard.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else ...[
            SliverToBoxAdapter(child: _buildPodium()),
            SliverToBoxAdapter(child: _buildListHeader()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => FadeTransition(
                  opacity: _fadeAnim,
                  child: _RankRow(
                    entry: _leaderboard[i],
                    isCurrentUser: widget.currentUserId != null &&
                        _leaderboard[i].userId == widget.currentUserId,
                    isAdmin: widget.isAdmin,
                    isAwarded: _awardedParticipants.contains(_leaderboard[i].participantId),
                    isAwarding: _awarding.contains(_leaderboard[i].participantId),
                    onAwardPrize: () => _awardPrize(_leaderboard[i]),
                    onDisqualify: widget.isAdmin ? () => _disqualify(_leaderboard[i]) : null,
                  ),
                ),
                childCount: _leaderboard.length,
              ),
            ),
          ],
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    final remaining = widget.endDate.difference(DateTime.now());
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFFE53935),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _load,
          tooltip: 'Refresh',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B0000), Color(0xFFE53935), Color(0xFFFF6F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.challengeName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  if (_hasEnded)
                    _StatusChip(label: 'Challenge Ended · Results Final', color: Colors.amber)
                  else
                    _CountdownRow(remaining: remaining),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium() {
    if (_leaderboard.isEmpty) return const SizedBox.shrink();
    final first = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F8F8), Color(0xFFEEEEEE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text('TOP FINISHERS',
            style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (second != null) _PodiumSlot(entry: second, rank: 2)
              else const SizedBox(width: 90),
              if (first != null) _PodiumSlot(entry: first, rank: 1)
              else const SizedBox(width: 90),
              if (third != null) _PodiumSlot(entry: third, rank: 3)
              else const SizedBox(width: 90),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        const Icon(Icons.leaderboard_rounded, color: Colors.black45, size: 18),
        const SizedBox(width: 8),
        Text(
          _hasEnded ? 'Final Rankings' : 'Live Rankings',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const Spacer(),
        Text('${_leaderboard.length} participants',
          style: const TextStyle(color: Colors.black45, fontSize: 12)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 52, color: Colors.red),
        const SizedBox(height: 12),
        const Text('Failed to load', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ]),
    );
  }
}

// ── Podium Slot ───────────────────────────────────────────────────────────────

class _PodiumSlot extends StatelessWidget {
  final ChallengeParticipantModel entry;
  final int rank;
  const _PodiumSlot({required this.entry, required this.rank});

  static const _colors = {1: Color(0xFFFFD700), 2: Color(0xFFB0BEC5), 3: Color(0xFFCD7F32)};
  static const _heights = {1: 90.0, 2: 70.0, 3: 55.0};
  static const _sizes = {1: 44.0, 2: 36.0, 3: 32.0};

  @override
  Widget build(BuildContext context) {
    final color = _colors[rank] ?? Colors.white38;
    final height = _heights[rank] ?? 55.0;
    final size = _sizes[rank] ?? 32.0;
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1) const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 22),
          CircleAvatar(
            radius: size / 2,
            backgroundColor: color.withOpacity(0.2),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(AppConfig.resolveMediaUrl(entry.avatarUrl!))
                : null,
            child: entry.avatarUrl == null
                ? Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 6),
          Text(entry.username,
            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: Text('#$rank', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// ── Rank Row ──────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  final ChallengeParticipantModel entry;
  final bool isCurrentUser;
  final bool isAdmin;
  final bool isAwarded;
  final bool isAwarding;
  final VoidCallback? onAwardPrize;
  final VoidCallback? onDisqualify;

  const _RankRow({
    required this.entry,
    required this.isCurrentUser,
    this.isAdmin = false,
    this.isAwarded = false,
    this.isAwarding = false,
    this.onAwardPrize,
    this.onDisqualify,
  });

  static const _rankColors = {
    1: Color(0xFFFFD700),
    2: Color(0xFFB0BEC5),
    3: Color(0xFFCD7F32),
  };

  Color get _rankColor => _rankColors[entry.rank] ?? const Color(0xFF4A4A6A);
  bool get _isTop3 => entry.rank <= 3;
  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFFFFF3F3)
            : _isTop3 ? const Color(0xFFF8F8FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFE53935).withOpacity(0.6)
              : _isTop3 ? _rankColor.withOpacity(0.3) : Colors.grey.shade200,
          width: isCurrentUser || _isTop3 ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _rankColor.withOpacity(0.15),
                    border: Border.all(color: _rankColor.withOpacity(0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text('#${entry.rank}',
                    style: TextStyle(color: _rankColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _rankColor.withOpacity(0.15),
                  backgroundImage: entry.avatarUrl != null
                      ? NetworkImage(AppConfig.resolveMediaUrl(entry.avatarUrl!))
                      : null,
                  child: entry.avatarUrl == null
                      ? Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                          style: TextStyle(color: _rankColor, fontWeight: FontWeight.bold, fontSize: 14))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(entry.username,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('You',
                              style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text('Score: ${_fmt(entry.progress)}',
                        style: const TextStyle(color: Colors.black45, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmt(entry.progress),
                      style: TextStyle(color: _rankColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (_isTop3) Icon(Icons.star_rounded, size: 12, color: _rankColor),
                  ],
                ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isAwarded)
                    TextButton.icon(
                      onPressed: isAwarding ? null : onAwardPrize,
                      icon: isAwarding
                          ? const SizedBox(width: 13, height: 13,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                          : const Icon(Icons.card_giftcard_rounded, size: 14),
                      label: Text(isAwarding ? 'Awarding...' : 'Award Prize',
                        style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    const Row(children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('Prize Awarded', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ]),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDisqualify,
                    icon: const Icon(Icons.remove_circle_outline, size: 14),
                    label: const Text('Remove', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Countdown ─────────────────────────────────────────────────────────────────

class _CountdownRow extends StatelessWidget {
  final Duration remaining;
  const _CountdownRow({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final mins = remaining.inMinutes % 60;
    return Row(children: [
      const Icon(Icons.timer_outlined, color: Colors.black45, size: 14),
      const SizedBox(width: 6),
      _Chip('${days}d'),
      const SizedBox(width: 4),
      _Chip('${hours}h'),
      const SizedBox(width: 4),
      _Chip('${mins}m'),
      const SizedBox(width: 8),
      const Text('remaining', style: TextStyle(color: Colors.black45, fontSize: 12)),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.lock_rounded, color: color, size: 13),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    ]),
  );
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.leaderboard_outlined, size: 64, color: Colors.black12),
      SizedBox(height: 16),
      Text('No participants yet', style: TextStyle(color: Colors.black45, fontSize: 16)),
      SizedBox(height: 8),
      Text('Be the first to join!', style: TextStyle(color: Colors.black26, fontSize: 13)),
    ]),
  );
}
