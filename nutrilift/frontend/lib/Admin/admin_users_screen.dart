import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import 'admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String search = ''}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _adminService.getUsers(search: search);
      setState(() {
        _users = response['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'User Management',
      showBackButton: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _loadUsers(search: value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(user['email'][0].toUpperCase()),
                        ),
                        title: Text(user['name'] ?? user['email']),
                        subtitle: Text(user['email']),
                        trailing: Icon(
                          user['is_active'] ? Icons.check_circle : Icons.cancel,
                          color: user['is_active'] ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
