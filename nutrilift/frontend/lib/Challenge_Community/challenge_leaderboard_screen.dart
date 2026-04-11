import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'challenge_api_service.dart';
import '../Admin/admin_service.dart';

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
      } else {
        list = await ChallengeApiService().fetchLeaderboard(widget.challengeId);
      }
      setState(() { _leaderboard = list; _isLoading = false; });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
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
                  ),
                ),
                childCount: _leaderboard.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final remaining = widget.endDate.difference(DateTime.now());
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF1A0A0A),
      foregroundColor: Colors.white,
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B0000), Color(0xFFE53935), Color(0xFFFF6F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(top: -30, right: -30,
              child: Container(width: 140, height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06)))),
            Positioned(bottom: -20, left: -20,
              child: Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04)))),
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.challengeName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  if (widget.prizeDescription != null && widget.prizeDescription!.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text(widget.prizeDescription!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    ]),
                  const SizedBox(height: 8),
                  if (_hasEnded)
                    _StatusChip(label: 'Challenge Ended · Results Final', color: Colors.amber)
                  else
                    _CountdownRow(remaining: remaining),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    final first = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF252535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          const Text('TOP FINISHERS',
            style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
        const Icon(Icons.format_list_numbered_rounded, color: Color(0xFFE53935), size: 18),
        const SizedBox(width: 8),
        Text(
          _hasEnded ? 'Final Rankings' : 'Live Rankings',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const Spacer(),
        Text('${_leaderboard.length} participants',
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 52, color: Colors.red),
        const SizedBox(height: 12),
        const Text('Failed to load', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _load,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
          child: const Text('Retry'),
        ),
      ]),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final ChallengeParticipantModel entry;
  final int rank;
  const _PodiumSlot({required this.entry, required this.rank});

  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};
  static const _colors = {
    1: Color(0xFFFFD700),
    2: Color(0xFFB0BEC5),
    3: Color(0xFFCD7F32),
  };
  static const _heights = {1: 90.0, 2: 65.0, 3: 50.0};
  static const _avatarRadius = {1: 30.0, 2: 24.0, 3: 22.0};

  Color get _color => _colors[rank] ?? Colors.grey;
  double get _barHeight => _heights[rank] ?? 50;
  double get _radius => _avatarRadius[rank] ?? 22;

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_medals[rank] ?? '', style: TextStyle(fontSize: rank == 1 ? 28 : 22)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
          ),
          child: CircleAvatar(
            radius: _radius,
            backgroundColor: _color.withOpacity(0.2),
            backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                    style: TextStyle(color: _color, fontWeight: FontWeight.bold,
                        fontSize: rank == 1 ? 20 : 16))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Text(entry.username,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(color: Colors.white,
              fontWeight: rank == 1 ? FontWeight.bold : FontWeight.w500,
              fontSize: rank == 1 ? 13 : 12)),
        ),
        const SizedBox(height: 2),
        Text(_fmt(entry.progress),
          style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: rank == 1 ? 80 : 70,
          height: _barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_color.withOpacity(0.6), _color.withOpacity(0.2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            border: Border.all(color: _color.withOpacity(0.4)),
          ),
          alignment: Alignment.center,
          child: Text('#$rank',
            style: TextStyle(color: _color, fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 20 : 16)),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final ChallengeParticipantModel entry;
  final bool isCurrentUser;
  const _RankRow({required this.entry, required this.isCurrentUser});

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
            ? const Color(0xFF2A1A1A)
            : _isTop3 ? const Color(0xFF1E1E2E) : const Color(0xFF181828),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFE53935).withOpacity(0.6)
              : _isTop3 ? _rankColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          width: isCurrentUser || _isTop3 ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
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
              backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(6)),
                        child: const Text('You', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('Score: ${_fmt(entry.progress)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  final Duration remaining;
  const _CountdownRow({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final mins = remaining.inMinutes % 60;
    return Row(children: [
      const Icon(Icons.timer_outlined, color: Colors.white60, size: 14),
      const SizedBox(width: 6),
      _Chip('${days}d'),
      const SizedBox(width: 4),
      _Chip('${hours}h'),
      const SizedBox(width: 4),
      _Chip('${mins}m'),
      const SizedBox(width: 8),
      const Text('remaining', style: TextStyle(color: Colors.white60, fontSize: 12)),
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
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.leaderboard_outlined, size: 64, color: Colors.white24),
      SizedBox(height: 16),
      Text('No participants yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
      SizedBox(height: 8),
      Text('Be the first to join!', style: TextStyle(color: Colors.white24, fontSize: 13)),
    ]),
  );
}
