import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'admin_service.dart';

const _kRed = Color(0xFFE53935);
const _kBg = Color(0xFFF5F6FA);

class AdminFAQScreen extends StatefulWidget {
  const AdminFAQScreen({Key? key}) : super(key: key);

  @override
  State<AdminFAQScreen> createState() => _AdminFAQScreenState();
}

class _AdminFAQScreenState extends State<AdminFAQScreen> {
  final AdminService _adminService = AdminService();
  List<FAQ> _faqs = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  static const _categories = {
    'all': 'All',
    'getting_started': 'Getting Started',
    'nutrition': 'Nutrition',
    'workout': 'Workout',
    'challenges': 'Challenges',
    'general': 'General',
  };

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() => _isLoading = true);
    try {
      final faqs = await _adminService.getFAQs();
      setState(() { _faqs = faqs; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) showCenterToast(context, 'Error loading FAQs: $e', isError: true);
    }
  }

  List<FAQ> get _filtered => _selectedCategory == 'all'
      ? _faqs
      : _faqs.where((f) => f.category == _selectedCategory).toList();

  Future<void> _showDialog({FAQ? faq}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FAQDialog(adminService: _adminService, faq: faq),
    );
    if (result == true) _loadFAQs();
  }

  Future<void> _delete(FAQ faq) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete FAQ'),
        content: Text('Delete "${faq.question}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _adminService.deleteFAQ(faq.id);
        _loadFAQs();
        if (mounted) showCenterToast(context, 'FAQ deleted');
      } catch (e) {
        if (mounted) showCenterToast(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // Category filter
              Container(
                color: _kRed,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.entries.map((e) {
                  final selected = _selectedCategory == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(e.value, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: selected ? _kRed : Colors.white,
                        )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Text('${_filtered.length} FAQs', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kRed))
                : _filtered.isEmpty
                    ? const Center(child: Text('No FAQs found', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        color: _kRed,
                        onRefresh: _loadFAQs,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final faq = _filtered[index];
                            return _FAQCard(faq: faq, onEdit: () => _showDialog(faq: faq), onDelete: () => _delete(faq));
                          },
                        ),
                      ),
          ),
        ],
      ),
          // FAB overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'admin_faq_fab',
              onPressed: () => _showDialog(),
              backgroundColor: _kRed,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQCard extends StatelessWidget {
  final FAQ faq;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _FAQCard({required this.faq, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.help_outline_rounded, color: _kRed, size: 18),
          ),
          title: Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                  child: Text(faq.category, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ),
                const SizedBox(width: 6),
                if (!faq.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Inactive', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626))),
                  ),
              ],
            ),
          ),
          children: [
            Text(faq.answer, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(foregroundColor: _kRed, side: const BorderSide(color: _kRed)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQDialog extends StatefulWidget {
  final AdminService adminService;
  final FAQ? faq;
  const _FAQDialog({required this.adminService, this.faq});

  @override
  State<_FAQDialog> createState() => _FAQDialogState();
}

class _FAQDialogState extends State<_FAQDialog> {
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  String _category = 'getting_started';
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.faq != null) {
      _questionCtrl.text = widget.faq!.question;
      _answerCtrl.text = widget.faq!.answer;
      _orderCtrl.text = widget.faq!.order.toString();
      _category = widget.faq!.category;
      _isActive = widget.faq!.isActive;
    } else {
      _orderCtrl.text = '0';
    }
  }

  InputDecoration _field(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kRed)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  Future<void> _submit() async {
    if (_questionCtrl.text.trim().isEmpty || _answerCtrl.text.trim().isEmpty) {
      showCenterToast(context, 'Question and answer are required', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.faq != null) {
        await widget.adminService.updateFAQ(widget.faq!.id,
          category: _category, question: _questionCtrl.text.trim(),
          answer: _answerCtrl.text.trim(), order: int.tryParse(_orderCtrl.text) ?? 0, isActive: _isActive);
      } else {
        await widget.adminService.createFAQ(
          category: _category, question: _questionCtrl.text.trim(),
          answer: _answerCtrl.text.trim(), order: int.tryParse(_orderCtrl.text) ?? 0, isActive: _isActive);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.faq != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: _kRed),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit FAQ' : 'New FAQ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: _field('Category'),
              items: const [
                DropdownMenuItem(value: 'general', child: Text('General')),
                DropdownMenuItem(value: 'getting_started', child: Text('Getting Started')),
                DropdownMenuItem(value: 'nutrition', child: Text('Nutrition')),
                DropdownMenuItem(value: 'workout', child: Text('Workout')),
                DropdownMenuItem(value: 'challenges', child: Text('Challenges')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _questionCtrl, decoration: _field('Question *'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: _answerCtrl, decoration: _field('Answer *'), maxLines: 5),
            const SizedBox(height: 12),
            TextField(controller: _orderCtrl, decoration: _field('Display Order'), keyboardType: TextInputType.number),
            const SizedBox(height: 4),
            SwitchListTile(
              value: _isActive, onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Active', style: TextStyle(fontSize: 14)),
              activeColor: _kRed, contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Update FAQ' : 'Create FAQ', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
