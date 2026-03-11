import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Result returned from DateRangeFilterDialog
/// 
/// Contains the selected date range or a flag indicating the filter was cleared.
class DateRangeFilterResult {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool cleared;

  DateRangeFilterResult({
    this.dateFrom,
    this.dateTo,
    this.cleared = false,
  });
}

/// Date Range Filter Dialog
/// 
/// Allows users to select a date range to filter workout history.
/// Provides options for:
/// - Custom date range selection
/// - Quick filters (Last 7 days, Last 30 days, Last 90 days)
/// - Clear filter option
/// 
/// Validates: Requirements 1.2
class DateRangeFilterDialog extends StatefulWidget {
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  const DateRangeFilterDialog({
    Key? key,
    this.initialDateFrom,
    this.initialDateTo,
  }) : super(key: key);

  @override
  State<DateRangeFilterDialog> createState() => _DateRangeFilterDialogState();
}

class _DateRangeFilterDialogState extends State<DateRangeFilterDialog> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Date Range'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick filter buttons
            const Text(
              'Quick Filters',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickFilterButton('Last 7 days', 7),
            const SizedBox(height: 8),
            _buildQuickFilterButton('Last 30 days', 30),
            const SizedBox(height: 8),
            _buildQuickFilterButton('Last 90 days', 90),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Custom date range
            const Text(
              'Custom Range',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // From date
            _buildDateSelector(
              label: 'From',
              date: _dateFrom,
              onTap: () => _selectDate(context, isFromDate: true),
            ),
            const SizedBox(height: 12),
            
            // To date
            _buildDateSelector(
              label: 'To',
              date: _dateTo,
              onTap: () => _selectDate(context, isFromDate: false),
            ),
          ],
        ),
      ),
      actions: [
        // Clear button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              DateRangeFilterResult(cleared: true),
            );
          },
          child: const Text(
            'Clear Filter',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        
        // Cancel button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        
        // Apply button
        ElevatedButton(
          onPressed: _dateFrom != null || _dateTo != null
              ? () {
                  Navigator.of(context).pop(
                    DateRangeFilterResult(
                      dateFrom: _dateFrom,
                      dateTo: _dateTo,
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  /// Build quick filter button
  Widget _buildQuickFilterButton(String label, int days) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _dateTo = DateTime.now();
            _dateFrom = _dateTo!.subtract(Duration(days: days));
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE53935),
          side: const BorderSide(color: Color(0xFFE53935)),
        ),
        child: Text(label),
      ),
    );
  }

  /// Build date selector
  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null ? Colors.black : Colors.grey[400],
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today,
              color: const Color(0xFFE53935),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Select date using date picker
  Future<void> _selectDate(BuildContext context, {required bool isFromDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_dateFrom ?? DateTime.now())
          : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE53935),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _dateFrom = picked;
          // If from date is after to date, clear to date
          if (_dateTo != null && picked.isAfter(_dateTo!)) {
            _dateTo = null;
          }
        } else {
          _dateTo = picked;
          // If to date is before from date, clear from date
          if (_dateFrom != null && picked.isBefore(_dateFrom!)) {
            _dateFrom = null;
          }
        }
      });
    }
  }
}
