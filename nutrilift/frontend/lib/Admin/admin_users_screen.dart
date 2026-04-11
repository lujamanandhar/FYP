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
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String search = ''}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _adminService.getUsers(search: search);
      setState(() {
        _users = response['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      await _adminService.updateUser(user['id'].toString(), isActive: !(user['is_active'] == true));
      _loadUsers(search: _searchController.text);
      showCenterToast(context, 'User status updated');
    } catch (e) {
      showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBg,
      child: Column(
        children: [
          // Search bar
          Container(
            color: _kRed,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
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
          ),

          // User count
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('${_users.length} users', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
                            onRefresh: () => _loadUsers(search: _searchController.text),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return _UserCard(user: user, onToggle: () => _toggleUserStatus(user));
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  const _UserCard({required this.user, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? user['email'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final isActive = user['is_active'] == true;
    final isStaff = user['is_staff'] == true;

    return Container(
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
              child: Text(name[0].toUpperCase(), style: const TextStyle(color: _kRed, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      if (isStaff) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Admin', style: TextStyle(fontSize: 10, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }
}

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
