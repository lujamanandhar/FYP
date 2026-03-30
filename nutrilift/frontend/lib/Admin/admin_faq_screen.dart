import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import 'admin_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() => _isLoading = true);
    try {
      final faqs = await _adminService.getFAQs();
      setState(() {
        _faqs = faqs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading FAQs: $e')),
        );
      }
    }
  }

  Future<void> _showFAQDialog({FAQ? faq}) async {
    final isEdit = faq != null;
    final questionCtrl = TextEditingController(text: faq?.question ?? '');
    final answerCtrl = TextEditingController(text: faq?.answer ?? '');
    String category = faq?.category ?? 'getting_started';
    int order = faq?.order ?? 0;
    bool isActive = faq?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit FAQ' : 'Create FAQ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'getting_started', child: Text('Getting Started')),
                    DropdownMenuItem(value: 'nutrition', child: Text('Nutrition Tracking')),
                    DropdownMenuItem(value: 'workout', child: Text('Workout Tracking')),
                    DropdownMenuItem(value: 'challenges', child: Text('Challenges')),
                  ],
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: questionCtrl,
                  decoration: const InputDecoration(labelText: 'Question'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerCtrl,
                  decoration: const InputDecoration(labelText: 'Answer'),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Order'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => order = int.tryParse(v) ?? 0,
                  controller: TextEditingController(text: order.toString()),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (questionCtrl.text.trim().isEmpty || answerCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question and answer are required')),
                  );
                  return;
                }
                
                try {
                  if (isEdit) {
                    await _adminService.updateFAQ(
                      faq!.id,
                      category: category,
                      question: questionCtrl.text.trim(),
                      answer: answerCtrl.text.trim(),
                      order: order,
                      isActive: isActive,
                    );
                  } else {
                    await _adminService.createFAQ(
                      category: category,
                      question: questionCtrl.text.trim(),
                      answer: answerCtrl.text.trim(),
                      order: order,
                      isActive: isActive,
                    );
                  }
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadFAQs();
    }
  }

  Future<void> _deleteFAQ(FAQ faq) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: Text('Are you sure you want to delete this FAQ?\n\n"${faq.question}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteFAQ(faq.id);
        _loadFAQs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FAQ deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting FAQ: $e')),
          );
        }
      }
    }
  }

  List<FAQ> get _filteredFAQs {
    if (_selectedCategory == 'all') return _faqs;
    return _faqs.where((faq) => faq.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'FAQ Management',
      showBackButton: true,
      body: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('all', 'All'),
                  _buildCategoryChip('getting_started', 'Getting Started'),
                  _buildCategoryChip('nutrition', 'Nutrition'),
                  _buildCategoryChip('workout', 'Workout'),
                  _buildCategoryChip('challenges', 'Challenges'),
                ],
              ),
            ),
          ),
          
          // FAQ List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFAQs.isEmpty
                    ? const Center(child: Text('No FAQs found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredFAQs.length,
                        itemBuilder: (context, index) {
                          final faq = _filteredFAQs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(
                                faq.question,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${_getCategoryLabel(faq.category)} • Order: ${faq.order} • ${faq.isActive ? "Active" : "Inactive"}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(faq.answer),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _showFAQDialog(faq: faq),
                                            icon: const Icon(Icons.edit, size: 18),
                                            label: const Text('Edit'),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _deleteFAQ(faq),
                                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFAQDialog(),
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = value);
        },
        selectedColor: const Color(0xFFE53935),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'general': 'General',
      'getting_started': 'Getting Started',
      'nutrition': 'Nutrition',
      'workout': 'Workout',
      'challenges': 'Challenges',
    };
    return labels[category] ?? category;
  }
}
