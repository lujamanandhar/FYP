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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets({String? search, String? status}) async {
    final q = search ?? _searchController.text;
    final s = status ?? _statusFilter;
    setState(() => _isLoading = true);
    try {
      final response = await _adminService.getSupportTickets(
        status: s.isEmpty ? null : s,
        search: q,
      );
      setState(() {
        _tickets = response['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
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

  Future<void> _saveNotes(String ticketId, String notes) async {
    try {
      await _adminService.updateSupportTicket(ticketId, adminNotes: notes);
      _loadTickets();
      if (mounted) showCenterToast(context, 'Notes saved');
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
          // Header: search + filter chips
          Container(
            color: _kRed,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => _loadTickets(search: v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by subject, email or name...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                        _loadTickets(status: v);
                      }),
                      const SizedBox(width: 8),
                      _FilterChip('Open', 'open', _statusFilter, (v) {
                        setState(() => _statusFilter = v);
                        _loadTickets(status: v);
                      }),
                      const SizedBox(width: 8),
                      _FilterChip('In Progress', 'in_progress', _statusFilter, (v) {
                        setState(() => _statusFilter = v);
                        _loadTickets(status: v);
                      }),
                      const SizedBox(width: 8),
                      _FilterChip('Resolved', 'resolved', _statusFilter, (v) {
                        setState(() => _statusFilter = v);
                        _loadTickets(status: v);
                      }),
                      const SizedBox(width: 8),
                      _FilterChip('Closed', 'closed', _statusFilter, (v) {
                        setState(() => _statusFilter = v);
                        _loadTickets(status: v);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(children: [
                Text('${_tickets.length} ticket${_tickets.length != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
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
                            return _TicketCard(
                              ticket: ticket,
                              onUpdateStatus: _updateStatus,
                              onSaveNotes: _saveNotes,
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
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _kRed : Colors.white)),
      ),
    );
  }
}

// ── Ticket card ───────────────────────────────────────────────────────────────

class _TicketCard extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final Future<void> Function(String, String) onUpdateStatus;
  final Future<void> Function(String, String) onSaveNotes;
  const _TicketCard({
    required this.ticket,
    required this.onUpdateStatus,
    required this.onSaveNotes,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _expanded = false;
  late TextEditingController _notesCtrl;
  bool _savingNotes = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.ticket['admin_notes'] ?? '');
  }

  @override
  void didUpdateWidget(_TicketCard old) {
    super.didUpdateWidget(old);
    // Refresh notes if ticket data changed
    if (old.ticket['admin_notes'] != widget.ticket['admin_notes']) {
      _notesCtrl.text = widget.ticket['admin_notes'] ?? '';
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

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

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final status = ticket['status'] ?? 'open';
    final color = _statusColor(status);
    final hasNotes = (ticket['admin_notes'] ?? '').toString().isNotEmpty;
    final createdAt = _formatDate(ticket['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(ticket['subject'] ?? 'No subject',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(_statusLabel(status),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                      ),
                      const SizedBox(width: 8),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[400], size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('${ticket['name'] ?? ''} • ${ticket['email'] ?? ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (createdAt.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(createdAt, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ],
                    ],
                  ),
                  if (hasNotes && !_expanded) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.sticky_note_2_outlined, size: 13, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      const Text('Has admin notes', style: TextStyle(fontSize: 11, color: Colors.amber)),
                    ]),
                  ],
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message
                  const Text('Message', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(ticket['message'] ?? '',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
                  ),

                  const SizedBox(height: 16),

                  // Admin notes
                  Row(
                    children: [
                      const Text('Admin Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Internal only',
                            style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add internal notes about this ticket...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFFFFBEB),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.amber.withOpacity(0.4))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.amber.withOpacity(0.4))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.amber)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _savingNotes
                          ? null
                          : () async {
                              setState(() => _savingNotes = true);
                              await widget.onSaveNotes(
                                  ticket['id'].toString(), _notesCtrl.text.trim());
                              if (mounted) setState(() => _savingNotes = false);
                            },
                      icon: _savingNotes
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Save Notes', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status update
                  const Text('Update Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['open', 'in_progress', 'resolved', 'closed'].map((s) {
                      final isActive = status == s;
                      final c = _statusColor(s);
                      return GestureDetector(
                        onTap: isActive
                            ? null
                            : () => widget.onUpdateStatus(ticket['id'].toString(), s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive ? c : c.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: c),
                          ),
                          child: Text(_statusLabel(s),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.white : c)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
