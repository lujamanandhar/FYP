import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/widgets/date_range_filter_dialog.dart';

void main() {
  group('DateRangeFilterDialog', () {
    testWidgets('should display dialog with date selection buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DateRangeFilterDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.text('Filter by Date Range'), findsOneWidget);
      expect(find.text('From Date'), findsOneWidget);
      expect(find.text('To Date'), findsOneWidget);
      expect(find.text('Select date'), findsNWidgets(2));
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('should disable Apply button when no dates selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DateRangeFilterDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find Apply button
      final applyButton = find.widgetWithText(ElevatedButton, 'Apply');
      expect(applyButton, findsOneWidget);

      // Verify button is disabled
      final button = tester.widget<ElevatedButton>(applyButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('should return cleared result when Clear is tapped', (WidgetTester tester) async {
      DateRangeFilterResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<DateRangeFilterResult>(
                    context: context,
                    builder: (context) => const DateRangeFilterDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Clear button
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.cleared, isTrue);
      expect(result!.dateFrom, isNull);
      expect(result!.dateTo, isNull);
    });

    testWidgets('should close dialog when Cancel is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DateRangeFilterDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Filter by Date Range'), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Filter by Date Range'), findsNothing);
    });

    testWidgets('should show error when end date is before start date', (WidgetTester tester) async {
      final fromDate = DateTime(2024, 1, 15);
      final toDate = DateTime(2024, 1, 10); // Before fromDate

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DateRangeFilterDialog(
                      initialDateFrom: fromDate,
                      initialDateTo: toDate,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('End date must be after start date'), findsOneWidget);

      // Verify Apply button is disabled
      final applyButton = find.widgetWithText(ElevatedButton, 'Apply');
      final button = tester.widget<ElevatedButton>(applyButton);
      expect(button.onPressed, isNull);
    });
  });
}
