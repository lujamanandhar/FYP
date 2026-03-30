import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import 'admin_service.dart';

class AdminSupportTicketsScreen extends StatefulWidget {
  const AdminSupportTicketsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSupportTicketsScreen> createState() => _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState extends State<AdminSupportTicketsScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final response = await _adminService.getSupportTickets(
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );
      setState(() {
        _tickets = response['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTicketStatus(String ticketId, String newStatus) async {
    try {
      await _adminService.updateSupportTicket(ticketId, status: newStatus);
      _loadTickets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Support Tickets',
      showBackButton: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', ''),
                  _buildFilterChip('Open', 'open'),
                  _buildFilterChip('In Progress', 'in_progress'),
                  _buildFilterChip('Resolved', 'resolved'),
                  _buildFilterChip('Closed', 'closed'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.support_agent,
                            color: _getStatusColor(ticket['status']),
                          ),
                          title: Text(
                            ticket['subject'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${ticket['name']} - ${ticket['email']}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ticket['message']),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Text('Status: '),
                                      DropdownButton<String>(
                                        value: ticket['status'],
                                        items: ['open', 'in_progress', 'resolved', 'closed']
                                            .map((status) => DropdownMenuItem(
                                                  value: status,
                                                  child: Text(status),
                                                ))
                                            .toList(),
                                        onChanged: (newStatus) {
                                          if (newStatus != null) {
                                            _updateTicketStatus(ticket['id'], newStatus);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _statusFilter = value;
          });
          _loadTickets();
        },
        selectedColor: const Color(0xFFE53935).withOpacity(0.2),
      ),
    );
  }
}
