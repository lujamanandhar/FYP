import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'admin_service.dart';

const _kRed = Color(0xFFE53935);
const _kBg = Color(0xFFF5F6FA);

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

  Future<void> _updateStatus(String ticketId, String newStatus) async {
    try {
      await _adminService.updateSupportTicket(ticketId, status: newStatus);
      _loadTickets();
      if (mounted) showCenterToast(context, 'Status updated to $newStatus');
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBg,
      child: Column(
        children: [
          // Filter chips
          Container(
            color: _kRed,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip('All', '', _statusFilter, (v) { setState(() => _statusFilter = v); _loadTickets(); }),
                  _FilterChip('Open', 'open', _statusFilter, (v) { setState(() => _statusFilter = v); _loadTickets(); }),
                  _FilterChip('In Progress', 'in_progress', _statusFilter, (v) { setState(() => _statusFilter = v); _loadTickets(); }),
                  _FilterChip('Resolved', 'resolved', _statusFilter, (v) { setState(() => _statusFilter = v); _loadTickets(); }),
                  _FilterChip('Closed', 'closed', _statusFilter, (v) { setState(() => _statusFilter = v); _loadTickets(); }),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kRed))
                : _tickets.isEmpty
                    ? const Center(child: Text('No tickets found', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        color: _kRed,
                        onRefresh: _loadTickets,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _tickets[index];
                            return _TicketCard(ticket: ticket, onUpdateStatus: _updateStatus);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;
  const _FilterChip(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? _kRed : Colors.white,
          )),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final Future<void> Function(String, String) onUpdateStatus;
  const _TicketCard({required this.ticket, required this.onUpdateStatus});

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return const Color(0xFFEF4444);
      case 'in_progress': return const Color(0xFFF59E0B);
      case 'resolved': return const Color(0xFF10B981);
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'in_progress': return 'In Progress';
      default: return s[0].toUpperCase() + s.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ticket['status'] ?? 'open';
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(ticket['subject'] ?? 'No subject', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text('${ticket['name'] ?? ''} • ${ticket['email'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
          ),
          children: [
            Text(ticket['message'] ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 12),
            const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['open', 'in_progress', 'resolved', 'closed'].map((s) {
                final isActive = status == s;
                final c = _statusColor(s);
                return GestureDetector(
                  onTap: isActive ? null : () => onUpdateStatus(ticket['id'].toString(), s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? c : c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c),
                    ),
                    child: Text(_statusLabel(s), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : c)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
