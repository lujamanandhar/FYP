import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'challenge_api_service.dart';
import '../Admin/admin_service.dart';
import '../services/app_config.dart';
import '../widgets/center_toast.dart';
import '../services/app_config.dart';


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
  List<ChallengeParticipantModel> _leaderboard = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final Set<String> _awardedParticipants = {};
  final Set<String> _awarding = {};
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final Set<String> _awardedParticipants = {};
  final Set<String> _awarding = {};

  bool get _hasEnded => widget.endDate.isBefore(DateTime.now());
ded => widget.endDate.isBefore(DateTime.now());

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      List<ChallengeParticipantModel> list;
      if (widget.isAdmin) {
        final data = await AdminService().getAdminChallengeLeaderboard(widget.challengeId);
        list = (data['leaderboard'] as List? ?? [])
            .map((e) => ChallengeParticipantModel.fromJson(e as Map<String, dynamic>))
            .toList();
        // Pre-populate already-awarded participants
        final awarded = (data['leaderboard'] as List? ?? [])
            .where((e) => e['prize_paid'] == true)
            .map((e) => e['participant_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        _awardedParticipants.addAll(awarded);
      } else {
        list = await ChallengeApiService().fetchLeaderboard(widget.challengeId);
      }
      backgroundColor: Colors.white,
      body: CustomScrollView((from: 0);
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFFE53935), backgroundColor: Colors.white)),
            )> _awardPrize(ChallengeParticipantModel entry) async {
    final pid = entry.participantId;
    if (pid == null) return;
    setState(() => _awarding.add(pid));
    try {
      await AdminService().awardPrize(widget.challengeId, pid);
      setState(() => _awardedParticipants.add(pid));
      if (mounted) showCenterToast(context, '🎉 Prize awarded to ${entry.username}!');
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => FadeTransition(
                  opacity: _fadeAnim,
                  child: _RankRow(
                    entry: _leaderboard[i],
                    isCurrentUser: widget.currentUserId != null &&
                        _leaderboard[i].userId == widget.currentUserId,
                    isAdmin: widget.isAdmin,
                    challengeId: widget.challengeId,
                    onRefresh: _load,
                  ),
                ),
                childCount: _leaderboard.length,
              ),
            ),      onDisqualify: widget.isAdmin ? () => _disqualify(_leaderboard[i]) : null,
                  ),
                ),
                childCount: _leaderboard.length,
              ),
            ), (_) => AlertDialog(
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
  }     list = await ChallengeApiService().fetchLeaderboard(widget.challengeId);
      }
      setState(() { _leaderboard = list; _isLoading = false; });
      _animController.forward(from: 0);
    return Scaffold(
      backgroundColor: Colors.white,= e.toString(); });
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
                  ),
                ),
                childCount: _leaderboard.length,
              ),
            ),ldAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
            )
          else if (_error != null)
          aining(child: _buildError())
          else if (_leaderboard.isEmpty)
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
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
                    delay: i * 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F8F8), Color(0xFFEEEEEE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );
  }
          const Text('TOP FINISHERS',
            style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
    final remaining = widget.endDate.difference(DateTime.now());
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF1A0A0A),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _load,
          tooltip: 'Refresh',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const Bn(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B0000), Color(0xFFE53935), Color(0xFFFF6F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
        Text(
          _hasEnded ? 'Final Rankings' : 'Live Rankings',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const Spacer(),
        Text('${_leaderboard.length} participants',
          style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  color: Colors.white.withOpacity(0.06)))),
            Positioned(bottom: -20, left: -20,
              child: Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04)))),
            // Content
            Positioned(
        const Icon(Icons.error_outline_rounded, size: 52, color: Colors.red),
        const SizedBox(height: 12),
        const Text('Failed to load', style: TextStyle(color: Colors.black54)),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          const Text('TOP FINISHERS',
            style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
    if (_leaderboard.isEmpty) return const SizedBox.shrink();
    final first = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
        Text(
          _hasEnded ? 'Final Rankings' : 'Live Rankings',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const Spacer(),
        Text('${_leaderboard.length} participants',
          style: const TextStyle(color: Colors.black38, fontSize: 12)),
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
              else const Sizedwidth: 90),
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
size: 18),
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
class _RankRow extends StatelessWidget {
  final ChallengeParticipantModel entry;
  final bool isCurrentUser;
  final bool isAdmin;
  final String challengeId;
  final VoidCallback? onRefresh;
  const _RankRow({
    required this.entry,
    required this.isCurrentUser,
    this.isAdmin = false,
    this.challengeId = '',
    this.onRefresh,
  });

  static const _rankColors = {
    1: Color(0xFFFFD700),
    2: Color(0xFFB0BEC5),
    3: Color(0xFFCD7F32),
  };

  Color get _rankColor => _rankColors[entry.rank] ?? const Color(0xFF4A4A6A);
  bool get _isTop3 => entry.rank <= 3;
  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Future<void> _awardPrize(BuildContext context) async {
    try {
      await AdminService().awardPrize(challengeId, entry.participantId ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prize awarded and user notified'), backgroundColor: Colors.green),
      );
      onRefresh?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _disqualify(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disqualify Participant'),
        content: Text('Remove ${entry.username} from this challenge?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminService().disqualifyParticipant(challengeId, entry.participantId ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant removed'), backgroundColor: Colors.orange),
      );
      onRefresh?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

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
                  backgroundImage: entry.avatarUrl != null ? NetworkImage(AppConfig.resolveMediaUrl(entry.avatarUrl!)) : null,
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
                        if (isAdmin && entry.prizePaid == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Prize Paid', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      if (isAdmin && entry.email != null)
                        Text(entry.email!,
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                          overflow: TextOverflow.ellipsis)
                      else
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
            // Admin action buttons
            if (isAdmin) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (entry.prizePaid != true)
                    TextButton.icon(
                      onPressed: () => _awardPrize(context),
                      icon: const Icon(Icons.card_giftcard_rounded, size: 14),
                      label: const Text('Award Prize', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _disqualify(context),
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
}                           decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(6)),
                            child: const Text('Prize Paid', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
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
            // Admin action buttons
            if (isAdmin) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: isAwarding
                      ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)))
                      : OutlinedButton.icon(
                          onPressed: isAwarded ? null : onAwardPrize,
                          icon: Icon(isAwarded ? Icons.check_circle : Icons.card_giftcard,
                              size: 14, color: isAwarded ? Colors.grey : Colors.amber),
                          label: Text(isAwarded ? 'Prize Awarded' : 'Award Prize',
                              style: TextStyle(fontSize: 11, color: isAwarded ? Colors.grey : Colors.amber)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isAwarded ? Colors.grey.withOpacity(0.3) : Colors.amber.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDisqualify,
                  icon: const Icon(Icons.person_remove, size: 14, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(fontSize: 11, color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}                 decoration: BoxDecoration(
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
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    ),  ),
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
                    style: const TextStyle(color: Colors.black45, fontSize: 12)),hite38, fontSize: 11))
                      else
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
            // Admin award prize button
            if (isAdmin && entry.participantId != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: isAwarded
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green, size: 15),
                            SizedBox(width: 6),
                            Text('Prize Awarded', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: isAwarding ? null : onAwardPrize,
                        icon: isAwarding
                            ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                            : const Icon(Icons.card_giftcard_rounded, size: 15, color: Colors.amber),
                        label: Text(
                          isAwarding ? 'Awarding...' : 'Award Prize & Notify',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.amber.withOpacity(0.6)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }             : const Color(0xFF181828),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFE53935).withOpacity(0.6)
              : _isTop3
                  ? _rankColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
          width: isCurrentUser || _isT 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 38,
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.leaderboard_outlined, size: 64, color: Colors.black12),
      SizedBox(height: 16),
      Text('No participants yet', style: TextStyle(color: Colors.black45, fontSize: 16)),
      SizedBox(height: 8),
      Text('Be the first to join!', style: TextStyle(color: Colors.black26, fontSize: 13)),
    ]),
  );            style: TextStyle(color: _rankColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: _rankColor.withOpacity(0.15),
              backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
              child: entry.avatarUrl == null
                  ? Text(
                      entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                      style: TextStyle(color: _rankColor, fontWeight: FontWeight.bold, fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
        exible(
                      child: Text(entry.username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDn(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('You',
                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('Progress: ${_formatProgress(entry.progress)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatProgress(entry.progress),
                  style: TextStyle(color: _rankColor, fontWeight: FontWeight.bold, fontSize: 16)),
                if (_isTop3)
                  Icon(Icons.star_rounded, size: 12, color: _rankColor),
              ],
            ),
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
      const Icon, size: 14),
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
    padding: const Ec(horizontal: 10, vertical: 5),
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

// ── Empty State ──────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.leaderboard_outlined, size: 64, color: Colors.white24),
      SizedBox(height: 16),
      Text('No participants yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
      SizedBox(height: 8),
ite24, fontSize: 13)),
    ]),
  );
}
