import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../services/streak_service.dart';
import '../UserManagement/profile_edit_screen.dart';
import '../widgets/nutrilift_header.dart';
import '../widgets/streak_overview_widget.dart';
import 'community_api_service.dart';
import 'challenge_api_service.dart';
import 'challenge_certificate_screen.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kRedLight = Color(0xFFFFEBEE);
const Color _kGold = Color(0xFFFFC107);
const Color _kGreen = Color(0xFF4CAF50);

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

// ── Main screen ────────────────────────────────────────────────────────────────
class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final _service = CommunityApiService();
  final _authService = AuthService();
  late final TabController _tabs;

  UserProfileModel? _profile;
  List<PostModel> _posts = [];
  Map<String, dynamic>? _challengeStats;
  AllStreaks _allStreaks = const AllStreaks();
  bool _loadingStreaks = false;

  bool _loadingProfile = true;
  bool _loadingPosts = true;
  bool _loadingStats = true;
  bool _toggling = false;
  String? _error;
  String? _currentUserId;
  UserProfile? _myProfile;

  bool get _isOwnProfile =>
      _currentUserId != null && _currentUserId == widget.userId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _initCurrentUser();
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _initCurrentUser() async {
    final token = await TokenService().getToken();
    if (token == null) return;
    final payload = TokenService().getTokenPayload(token);
    final uid = payload?['user_id'];
    if (mounted) setState(() => _currentUserId = uid?.toString());
  }

  void _loadAll() {
    _loadProfile();
    _loadPosts();
    _loadStats();
    if (_isOwnProfile) _loadStreaks();
  }

  Future<void> _loadStreaks() async {
    setState(() => _loadingStreaks = true);
    try {
      final streaks = await StreakService().fetchAllStreaks();
      if (mounted) setState(() => _allStreaks = streaks);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingStreaks = false);
    }
  }

  Future<void> _loadProfile() async {
    setState(() { _loadingProfile = true; _error = null; });
    try {
      final p = await _service.fetchProfile(widget.userId);
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final p = await _service.fetchUserPosts(widget.userId);
      if (mounted) setState(() => _posts = p);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final s = await _service.fetchUserChallengeStats(widget.userId);
      if (mounted) setState(() => _challengeStats = s);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null || _toggling) return;
    setState(() => _toggling = true);
    try {
      await _service.toggleFollow(widget.userId);
      if (mounted) setState(() => _profile!.isFollowingMe = !_profile!.isFollowingMe);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _openEditProfile() async {
    UserProfile? up = _myProfile;
    if (up == null) {
      try {
        up = await _authService.getProfile();
        if (mounted) setState(() => _myProfile = up);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        return;
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileEditScreen(userProfile: up!)),
    );
    _loadProfile();
  }

  void _openFollowersList() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FollowListScreen(
        userId: widget.userId,
        title: 'Followers',
        fetchFn: _service.fetchFollowers,
      ),
    ));
  }

  void _openFollowingList() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FollowListScreen(
        userId: widget.userId,
        title: 'Following',
        fetchFn: _service.fetchFollowing,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: _profile?.username ?? '',
      showBackButton: true,
      showDrawer: false,
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: _kRed))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadAll)
              : NestedScrollView(
                  headerSliverBuilder: (_, __) => [
                    SliverToBoxAdapter(
                      child: _ProfileHeader(
                        profile: _profile!,
                        isOwnProfile: _isOwnProfile,
                        toggling: _toggling,
                        onToggleFollow: _toggleFollow,
                        onEditProfile: _openEditProfile,
                        onTapFollowers: _openFollowersList,
                        onTapFollowing: _openFollowingList,
                      ),
                    ),
                    // Show streak section for own profile
                    if (_isOwnProfile)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: GestureDetector(
                            onTap: () => showStreakOverview(context, _allStreaks),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _MiniStreak('💪', 'Workout', _allStreaks.workout.currentStreak),
                                  Container(width: 1, height: 30, color: Colors.white30),
                                  _MiniStreak('🍎', 'Nutrition', _allStreaks.nutrition.currentStreak),
                                  Container(width: 1, height: 30, color: Colors.white30),
                                  _MiniStreak('🏆', 'Challenge', _allStreaks.challenge.currentStreak),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          controller: _tabs,
                          indicatorColor: _kRed,
                          indicatorWeight: 2,
                          labelColor: Colors.black87,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_on_rounded, size: 20)),
                            Tab(icon: Icon(Icons.emoji_events_outlined, size: 20)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabs,
                    children: [
                      _PostsGrid(posts: _posts, loading: _loadingPosts),
                      _AchievementsTab(
                        stats: _challengeStats,
                        loading: _loadingStats,
                        profile: _profile,
                        isOwnProfile: _isOwnProfile,
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserProfileModel profile;
  final bool isOwnProfile;
  final bool toggling;
  final VoidCallback onToggleFollow;
  final VoidCallback onEditProfile;
  final VoidCallback onTapFollowers;
  final VoidCallback onTapFollowing;

  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.toggling,
    required this.onToggleFollow,
    required this.onEditProfile,
    required this.onTapFollowers,
    required this.onTapFollowing,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        profile.username.isNotEmpty ? profile.username[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: _kRedLight,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(initials,
                        style: const TextStyle(
                            color: _kRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 28))
                    : null,
              ),
              const SizedBox(width: 24),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCol(label: 'Posts', value: profile.postCount),
                    GestureDetector(
                      onTap: onTapFollowers,
                      child: _StatCol(
                          label: 'Followers', value: profile.followerCount),
                    ),
                    GestureDetector(
                      onTap: onTapFollowing,
                      child: _StatCol(
                          label: 'Following', value: profile.followingCount),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(profile.username,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          // ── Fitness level badge ──────────────────────────────────
          if (profile.fitnessLevel != null) ...[
            const SizedBox(height: 4),
            _FitnessLevelBadge(level: profile.fitnessLevel!),
          ],
          const SizedBox(height: 12),
          // Action button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: isOwnProfile
                ? ElevatedButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRedLight,
                      foregroundColor: _kRed,
                      elevation: 0,
                      side: const BorderSide(color: _kRed, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                : toggling
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kRed),
                        ),
                      )
                    : profile.isFollowingMe
                        ? OutlinedButton.icon(
                            onPressed: onToggleFollow,
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Following',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kRed,
                              side: const BorderSide(color: _kRed),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: onToggleFollow,
                            icon: const Icon(Icons.person_add_outlined, size: 16),
                            label: const Text('Follow',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final int value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_fmt(value),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

// ── Fitness level badge ────────────────────────────────────────────────────────
class _FitnessLevelBadge extends StatelessWidget {
  final String level;
  const _FitnessLevelBadge({required this.level});

  Color get _color {
    switch (level.toLowerCase()) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advance': return _kRed;
      default: return Colors.grey;
    }
  }

  IconData get _icon {
    switch (level.toLowerCase()) {
      case 'beginner': return Icons.directions_walk_rounded;
      case 'intermediate': return Icons.directions_run_rounded;
      case 'advance': return Icons.bolt_rounded;
      default: return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon, size: 13, color: _color),
      const SizedBox(width: 3),
      Text(level,
          style: TextStyle(
              color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── Pinned tab bar ─────────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(children: [
        Divider(height: 1, color: Colors.grey[200]),
        tabBar,
      ]),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ── Achievements tab ───────────────────────────────────────────────────────────
class _AchievementsTab extends StatefulWidget {
  final Map<String, dynamic>? stats;
  final bool loading;
  final UserProfileModel? profile;
  final bool isOwnProfile;
  const _AchievementsTab({
    required this.stats,
    required this.loading,
    this.profile,
    this.isOwnProfile = false,
  });

  @override
  State<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<_AchievementsTab> {
  List<ChallengeCompletionModel> _completions = [];
  bool _loadingCerts = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOwnProfile) _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() => _loadingCerts = true);
    try {
      final certs = await ChallengeApiService().fetchCompletions();
      if (mounted) setState(() => _completions = certs);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingCerts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }

    final totalJoined = widget.stats?['total_joined'] as int? ?? 0;
    final totalCompleted = widget.stats?['total_completed'] as int? ?? 0;
    final totalDays = widget.stats?['total_days_logged'] as int? ?? 0;
    final streak = widget.stats?['current_streak'] as int? ?? 0;
    final challenges =
        (widget.stats?['challenges'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final hasPhysical = widget.profile != null &&
        (widget.profile!.gender != null ||
            widget.profile!.ageGroup != null ||
            widget.profile!.height != null ||
            widget.profile!.weight != null ||
            widget.profile!.fitnessLevel != null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        if (hasPhysical) ...[
          _SectionTitle(title: 'Physical & Fitness Info', icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _InfoCard(profile: widget.profile!),
          const SizedBox(height: 20),
        ],

        _SectionTitle(title: 'Challenge Stats', icon: Icons.emoji_events_outlined),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _SummaryCard(icon: Icons.flag_rounded, label: 'Joined', value: '$totalJoined', color: _kRed)),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard(icon: Icons.check_circle_rounded, label: 'Completed', value: '$totalCompleted', color: _kGreen)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _SummaryCard(icon: Icons.calendar_today_rounded, label: 'Days Logged', value: '$totalDays', color: Colors.blue)),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard(icon: Icons.local_fire_department_rounded, label: 'Streak', value: '$streak 🔥', color: Colors.orange)),
        ]),
        const SizedBox(height: 20),

        // ── Certificates ────────────────────────────────────────────
        if (widget.isOwnProfile) ...[
          _SectionTitle(title: '🏆 Certificates', icon: Icons.workspace_premium),
          const SizedBox(height: 10),
          if (_loadingCerts)
            const Center(child: CircularProgressIndicator())
          else if (_completions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Complete a challenge to earn your first certificate!',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            )
          else
            ..._completions.map((c) => _CertificateTile(completion: c)),
          const SizedBox(height: 8),
        ],

        if (challenges.isNotEmpty) ...[
          _SectionTitle(title: 'Challenges', icon: Icons.list_alt_rounded),
          const SizedBox(height: 10),
          ...challenges.map((c) => _ChallengeCard(data: c)),
        ] else if (widget.stats != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('No challenges joined yet',
                  style: TextStyle(color: Colors.grey[500])),
            ),
          ),
      ],
    );
  }
}

class _CertificateTile extends StatelessWidget {
  final ChallengeCompletionModel completion;
  const _CertificateTile({required this.completion});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeCertificateScreen(completion: completion),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('🏆', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(completion.challengeName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${completion.daysTaken} days • #${completion.certificateNumber}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.grey[600]),
      const SizedBox(width: 6),
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
    ]);
  }
}

class _InfoCard extends StatelessWidget {
  final UserProfileModel profile;
  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[];

    if (profile.gender != null)
      items.add(_InfoItem(icon: Icons.wc_rounded, label: 'Gender', value: profile.gender!));
    if (profile.ageGroup != null)
      items.add(_InfoItem(icon: Icons.cake_outlined, label: 'Age Group', value: profile.ageGroup!));
    if (profile.height != null)
      items.add(_InfoItem(icon: Icons.height_rounded, label: 'Height', value: '${profile.height!.toStringAsFixed(0)} cm'));
    if (profile.weight != null)
      items.add(_InfoItem(icon: Icons.monitor_weight_outlined, label: 'Weight', value: '${profile.weight!.toStringAsFixed(0)} kg'));
    if (profile.fitnessLevel != null)
      items.add(_InfoItem(icon: Icons.fitness_center_rounded, label: 'Fitness Level', value: profile.fitnessLevel!));

    // Compute BMI if both available
    if (profile.height != null && profile.weight != null && profile.height! > 0) {
      final bmi = profile.weight! / ((profile.height! / 100) * (profile.height! / 100));
      String category;
      if (bmi < 18.5) category = 'Underweight';
      else if (bmi < 25) category = 'Normal';
      else if (bmi < 30) category = 'Overweight';
      else category = 'Obese';
      items.add(_InfoItem(
        icon: Icons.calculate_outlined,
        label: 'BMI',
        value: '${bmi.toStringAsFixed(1)} ($category)',
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Icon(item.icon, size: 18, color: _kRed),
            const SizedBox(width: 10),
            Text(item.label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const Spacer(),
            Text(item.value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        )).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ]),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ChallengeCard({required this.data});

  Color _typeColor(String t) {
    switch (t) {
      case 'nutrition': return const Color(0xFF43A047);
      case 'workout': return const Color(0xFFFF7043);
      default: return const Color(0xFF7E57C2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '';
    final type = data['challenge_type'] as String? ?? '';
    final progress = (data['progress'] as num?)?.toDouble() ?? 0;
    final goal = (data['goal_value'] as num?)?.toDouble() ?? 1;
    final unit = data['unit'] as String? ?? '';
    final completed = data['completed'] as bool? ?? false;
    final daysLogged = data['days_logged'] as int? ?? 0;
    final pct = (goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 0.0);
    final tc = _typeColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tc.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(type.toUpperCase(),
                style: TextStyle(
                    color: tc, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          if (completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Completed ✓',
                  style: TextStyle(
                      color: _kGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ]),
        const SizedBox(height: 8),
        Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_kRed),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              '$daysLogged days logged',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ]),
    );
  }
}

// ── Posts grid ─────────────────────────────────────────────────────────────────
class _PostsGrid extends StatelessWidget {
  final List<PostModel> posts;
  final bool loading;
  const _PostsGrid({required this.posts, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _kRed));
    if (posts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.photo_library_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No posts yet', style: TextStyle(color: Colors.grey[500])),
        ]),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: posts.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _PostViewer(posts: posts, initialIndex: i),
        )),
        child: _Thumb(post: posts[i]),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final PostModel post;
  const _Thumb({required this.post});

  @override
  Widget build(BuildContext context) {
    final hasImg = post.imageUrls.isNotEmpty;
    return Container(
      color: Colors.grey[100],
      child: hasImg
          ? Stack(fit: StackFit.expand, children: [
              Image.network(post.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined, color: Colors.grey)),
              if (post.imageUrls.length > 1)
                const Positioned(
                  top: 5, right: 5,
                  child: Icon(Icons.collections_rounded,
                      color: Colors.white, size: 14),
                ),
            ])
          : Container(
              color: _kRedLight,
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(post.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFB71C1C),
                        height: 1.4)),
              ),
            ),
    );
  }
}

// ── Post viewer ────────────────────────────────────────────────────────────────
class _PostViewer extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;
  const _PostViewer({required this.posts, required this.initialIndex});

  @override
  State<_PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<_PostViewer> {
  late final PageController _pc;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: '${_current + 1} / ${widget.posts.length}',
      showBackButton: true,
      showDrawer: false,
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.posts.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) {
          final post = widget.posts[i];
          return SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (post.imageUrls.isNotEmpty)
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(post.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[100])),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (post.content.isNotEmpty)
                    Text(post.content,
                        style: const TextStyle(fontSize: 14, height: 1.6)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.favorite, size: 16, color: _kRed),
                    const SizedBox(width: 4),
                    Text('${post.likeCount}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.mode_comment_outlined,
                        size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ]),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ── Mini streak display for profile ───────────────────────────────────────────
class _MiniStreak extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  const _MiniStreak(this.emoji, this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔥$emoji', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// ── Followers / Following list screen ─────────────────────────────────────────
class _FollowListScreen extends StatefulWidget {
  final String userId;
  final String title;
  final Future<List<UserProfileModel>> Function(String) fetchFn;
  const _FollowListScreen(
      {required this.userId, required this.title, required this.fetchFn});

  @override
  State<_FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<_FollowListScreen> {
  List<UserProfileModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.fetchFn(widget.userId).then((list) {
      if (mounted) setState(() { _users = list; _loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: widget.title,
      showBackButton: true,
      showDrawer: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kRed))
          : _users.isEmpty
              ? Center(
                  child: Text('No ${widget.title.toLowerCase()} yet',
                      style: TextStyle(color: Colors.grey[500])))
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, indent: 72, color: Colors.grey[100]),
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    final initials = u.username.isNotEmpty
                        ? u.username[0].toUpperCase()
                        : '?';
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: _kRedLight,
                        backgroundImage: u.avatarUrl != null
                            ? NetworkImage(u.avatarUrl!)
                            : null,
                        child: u.avatarUrl == null
                            ? Text(initials,
                                style: const TextStyle(
                                    color: _kRed,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      title: Text(u.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 20),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: u.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kRed, foregroundColor: Colors.white),
          ),
        ]),
      ),
    );
  }
}
