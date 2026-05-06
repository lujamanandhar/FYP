import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'admin_service.dart';

const _kRed = Color(0xFFE53935);
const _kBg = Color(0xFFF5F6FA);

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200
        && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadUsers({String? search, String? status}) async {
    final q = search ?? _searchController.text;
    final s = status ?? _statusFilter;
    setState(() { _isLoading = true; _error = null; _currentPage = 1; });
    try {
      final response = await _adminService.getUsers(search: q, statusFilter: s, page: 1);
      setState(() {
        _users = response['results'] ?? [];
        _hasMore = response['next'] != null;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final response = await _adminService.getUsers(
        search: _searchController.text,
        statusFilter: _statusFilter,
        page: _currentPage + 1,
      );
      setState(() {
        _users.addAll(response['results'] ?? []);
        _hasMore = response['next'] != null;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final isActive = user['is_active'] == true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isActive ? 'Deactivate User' : 'Activate User'),
        content: Text(isActive
            ? 'This will prevent the user from logging in.'
            : 'This will restore the user\'s access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _adminService.updateUser(user['id'].toString(), isActive: !isActive);
      _loadUsers();
      if (mounted) showCenterToast(context, isActive ? 'User deactivated' : 'User activated');
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  void _openUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: user,
        onToggleStatus: () {
          Navigator.pop(context);
          _toggleUserStatus(user);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBg,
      child: Column(
        children: [
          // Search + filter header
          Container(
            color: _kRed,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => _loadUsers(search: v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip('All', '', _statusFilter, (v) {
                        setState(() => _statusFilter = v);
                        _loadUsers(status: v);
                      }),
                      const SizedBox(width: 8),
                      _FilterChip('Active', 'active', _statusFilter, (v) {
                        setState(() => _statusFilter = v);
                        _loadUsers(status: v);
                      }),
                      const SizedBox(width: 8),
                      _FilterChip('Inactive', 'inactive', _statusFilter, (v) {
                        setState(() => _statusFilter = v);
                        _loadUsers(status: v);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Count row
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text('${_users.length} user${_users.length != 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  if (_statusFilter.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusFilter == 'active' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusFilter == 'active' ? 'Active only' : 'Inactive only',
                        style: TextStyle(
                          fontSize: 11,
                          color: _statusFilter == 'active' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kRed))
                : _error != null
                    ? _ErrorView(onRetry: _loadUsers)
                    : _users.isEmpty
                        ? const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
                        : RefreshIndicator(
                            color: _kRed,
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _users.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _users.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator(color: _kRed, strokeWidth: 2)),
                                  );
                                }
                                final user = _users[index];
                                return _UserCard(
                                  user: user,
                                  onToggle: () => _toggleUserStatus(user),
                                  onTap: () => _openUserDetail(user),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;
  const _FilterChip(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _kRed : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  const _UserCard({required this.user, required this.onToggle, required this.onTap});

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? user['email'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final isActive = user['is_active'] == true;
    final isStaff = user['is_staff'] == true;
    final joinDate = _formatDate(user['created_at']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _kRed.withOpacity(0.12),
                child: Text(name[0].toUpperCase(),
                    style: const TextStyle(color: _kRed, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isStaff) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Admin',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis),
                    if (joinDate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Joined $joinDate',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User detail bottom sheet ──────────────────────────────────────────────────

class _UserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggleStatus;
  const _UserDetailSheet({required this.user, required this.onToggleStatus});

  String _formatDate(String? raw) {
    if (raw == null) return 'Unknown';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? user['email'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final isActive = user['is_active'] == true;
    final isStaff = user['is_staff'] == true;
    final gender = user['gender'] ?? '—';
    final ageGroup = user['age_group'] ?? '—';
    final height = user['height'] != null ? '${user['height']} cm' : '—';
    final weight = user['weight'] != null ? '${user['weight']} kg' : '—';
    final fitnessLevel = user['fitness_level'] ?? '—';
    final joinDate = _formatDate(user['created_at']);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar + name
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _kRed.withOpacity(0.12),
                child: Text(name[0].toUpperCase(),
                    style: const TextStyle(color: _kRed, fontWeight: FontWeight.bold, fontSize: 22)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(email, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Badge(
                          label: isActive ? 'Active' : 'Inactive',
                          color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          bg: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        ),
                        if (isStaff) ...[
                          const SizedBox(width: 6),
                          const _Badge(label: 'Admin', color: Color(0xFF7C3AED), bg: Color(0xFFEDE9FE)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Profile details grid
          const Text('Profile Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 12),
          _DetailGrid(items: [
            _DetailItem('Joined', joinDate, Icons.calendar_today_rounded),
            _DetailItem('Gender', gender, Icons.person_outline),
            _DetailItem('Age Group', ageGroup, Icons.cake_outlined),
            _DetailItem('Height', height, Icons.height_rounded),
            _DetailItem('Weight', weight, Icons.monitor_weight_outlined),
            _DetailItem('Fitness Level', fitnessLevel, Icons.fitness_center_rounded),
          ]),

          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onToggleStatus,
              icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded),
              label: Text(isActive ? 'Deactivate User' : 'Activate User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}

class _DetailItem {
  final String label;
  final String value;
  final IconData icon;
  const _DetailItem(this.label, this.value, this.icon);
}

class _DetailGrid extends StatelessWidget {
  final List<_DetailItem> items;
  const _DetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: items.map((item) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 16, color: _kRed),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  Text(item.value,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load users', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
