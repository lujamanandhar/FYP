import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date Range Filter Result
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
/// Allows users to select a date range for filtering workout history.
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDateButton(
            label: 'From Date',
            date: _dateFrom,
            onTap: () => _selectDate(context, isFromDate: true),
          ),
          const SizedBox(height: 16),
          _buildDateButton(
            label: 'To Date',
            date: _dateTo,
            onTap: () => _selectDate(context, isFromDate: false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              DateRangeFilterResult(cleared: true),
            );
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _dateFrom != null || _dateTo != null
              ? () {
                  Navigator.pop(
                    context,
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

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                    fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                    color: date != null ? Colors.black : Colors.grey[400],
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

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
          // If to date is before from date, clear it
          if (_dateTo != null && _dateTo!.isBefore(picked)) {
            _dateTo = null;
          }
        } else {
          _dateTo = picked;
          // If from date is after to date, clear it
          if (_dateFrom != null && _dateFrom!.isAfter(picked)) {
            _dateFrom = null;
          }
        }
      });
    }
  }
}
