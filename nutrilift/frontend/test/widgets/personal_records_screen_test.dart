import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/screens/personal_records_screen.dart';
import 'package:nutrilift/providers/personal_records_provider.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/mock_personal_record_repository.dart';
import 'package:nutrilift/models/personal_record.dart';
import 'package:nutrilift/widgets/pr_card.dart';

/// Helper to build the widget with mock repository
Widget buildTestWidget({MockPersonalRecordRepository? customRepo}) {
  return ProviderScope(
    overrides: [
      personalRecordRepositoryProvider.overrideWithValue(
        customRepo ?? MockPersonalRecordRepository(),
      ),
    ],
    child: const MaterialApp(home: PersonalRecordsScreen()),
  );
}

void main() {
  group('PersonalRecordsScreen Widget Tests', () {

    testWidgets('should display personal records in grid layout', 
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockPersonalRecordRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - Should show PR cards in a grid
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(PRCard), findsWidgets);
    });

    testWidgets('should display empty state when no PRs exist', 
        (WidgetTester tester) async {
      // Arrange - Create repo with no PRs
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.clear();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - Should show empty state
      expect(find.text('No Personal Records Yet'), findsOneWidget);
      expect(find.text('Start logging workouts to set your first personal records!'), 
          findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', 
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      
      // Assert - Should show loading indicator before data loads
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for the async operation to complete
      await tester.pumpAndSettle();
    });

    testWidgets('should support pull-to-refresh', 
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockPersonalRecordRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - Should have RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should display share button on each PR card', 
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockPersonalRecordRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - Should have share buttons
      expect(find.byIcon(Icons.share), findsWidgets);
    });

    testWidgets('should show share dialog when share button tapped', 
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockPersonalRecordRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap the first share button
      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pumpAndSettle();

      // Assert - Should show share dialog
      expect(find.text('Share Personal Record'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });
  });

  group('Property 12: Personal Record Display Completeness', () {
    /// **Validates: Requirements 4.2, 4.3**
    /// 
    /// Property 12: Personal Record Display Completeness
    /// For any personal record, the displayed information should include exercise name,
    /// max weight, max reps, max volume, and date achieved. If improvement data exists
    /// (previous values), a progress indicator should be shown.

    testWidgets('Feature: workout-tracking-system, Property 12: Personal Record Display Completeness - All required fields present', 
        (WidgetTester tester) async {
      // Property test: For any PR, all required fields should be displayed
      
      final now = DateTime.now();
      
      // Test case 1: PR with all fields including improvement
      final prWithImprovement = PersonalRecord(
        id: 1,
        exerciseId: 1,
        exerciseName: 'Bench Press',
        maxWeight: 120.0,
        maxReps: 12,
        maxVolume: 4320.0,
        achievedDate: now.subtract(const Duration(days: 1)),
        improvementPercentage: 15.5,
      );
      
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.clear();
      mockRepo.addPersonalRecord(prWithImprovement);
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - All required fields should be present
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('120.0 kg'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('4320.0 kg'), findsOneWidget);
      
      // Should show improvement indicator
      expect(find.text('15.5%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('Feature: workout-tracking-system, Property 12: Personal Record Display Completeness - PR without improvement', 
        (WidgetTester tester) async {
      // Test case 2: PR without improvement data
      final prWithoutImprovement = PersonalRecord(
        id: 2,
        exerciseId: 2,
        exerciseName: 'Squats',
        maxWeight: 150.0,
        maxReps: 10,
        maxVolume: 4500.0,
        achievedDate: DateTime.now().subtract(const Duration(days: 5)),
        improvementPercentage: null, // No improvement data
      );
      
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.clear();
      mockRepo.addPersonalRecord(prWithoutImprovement);
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - All required fields should be present
      expect(find.text('Squats'), findsOneWidget);
      expect(find.text('150.0 kg'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('4500.0 kg'), findsOneWidget);
      
      // Should NOT show improvement indicator
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('Feature: workout-tracking-system, Property 12: Personal Record Display Completeness - Multiple PRs', 
        (WidgetTester tester) async {
      // Test case 3: Multiple PRs with varying data
      final prs = [
        PersonalRecord(
          id: 1,
          exerciseId: 1,
          exerciseName: 'Deadlift',
          maxWeight: 180.0,
          maxReps: 5,
          maxVolume: 2700.0,
          achievedDate: DateTime.now().subtract(const Duration(days: 2)),
          improvementPercentage: 8.3,
        ),
        PersonalRecord(
          id: 2,
          exerciseId: 2,
          exerciseName: 'Pull-ups',
          maxWeight: 0.0, // Bodyweight exercise
          maxReps: 15,
          maxVolume: 15.0,
          achievedDate: DateTime.now().subtract(const Duration(days: 10)),
          improvementPercentage: 25.0,
        ),
        PersonalRecord(
          id: 3,
          exerciseId: 3,
          exerciseName: 'Shoulder Press',
          maxWeight: 60.5,
          maxReps: 8,
          maxVolume: 1452.0,
          achievedDate: DateTime.now().subtract(const Duration(days: 30)),
          improvementPercentage: null,
        ),
      ];
      
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.clear();
      for (final pr in prs) {
        mockRepo.addPersonalRecord(pr);
      }
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - All PRs should be displayed with their fields
      for (final pr in prs) {
        expect(find.text(pr.exerciseName), findsOneWidget);
        expect(find.text('${pr.maxWeight.toStringAsFixed(1)} kg'), findsOneWidget);
        expect(find.text('${pr.maxReps}'), findsOneWidget);
        expect(find.text('${pr.maxVolume.toStringAsFixed(1)} kg'), findsOneWidget);
      }
      
      // Should show improvement indicators for PRs with improvement data
      expect(find.text('8.3%'), findsOneWidget);
      expect(find.text('25.0%'), findsOneWidget);
      
      // Count of progress indicators should match PRs with improvement
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });
  });

  group('Property 13: PR Share Message Generation', () {
    /// **Validates: Requirements 4.5**
    /// 
    /// Property 13: PR Share Message Generation
    /// For any personal record, the system should generate a valid shareable message
    /// containing the exercise name, achievement values, and date.

    testWidgets('Feature: workout-tracking-system, Property 13: PR Share Message Generation - Message contains all required data', 
        (WidgetTester tester) async {
      // Property test: Share message should contain all PR data
      
      final pr = PersonalRecord(
        id: 1,
        exerciseId: 1,
        exerciseName: 'Bench Press',
        maxWeight: 120.0,
        maxReps: 12,
        maxVolume: 4320.0,
        achievedDate: DateTime.now().subtract(const Duration(days: 1)),
        improvementPercentage: 15.5,
      );
      
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.clear();
      mockRepo.addPersonalRecord(pr);
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap share button
      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pumpAndSettle();

      // Assert - Share message should contain all required data
      // Find the dialog content
      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      
      // Check that the share message contains all required fields
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('New Personal Record'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('120.0 kg'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('12'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('4320.0 kg'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('15.5%'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('#NutriLift'),
      ), findsOneWidget);
    });

    testWidgets('Feature: workout-tracking-system, Property 13: PR Share Message Generation - Message without improvement', 
        (WidgetTester tester) async {
      // Test case: PR without improvement percentage
      
      final pr = PersonalRecord(
        id: 2,
        exerciseId: 2,
        exerciseName: 'Squats',
        maxWeight: 150.0,
        maxReps: 10,
        maxVolume: 4500.0,
        achievedDate: DateTime.now().subtract(const Duration(days: 5)),
        improvementPercentage: null,
      );
      
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.clear();
      mockRepo.addPersonalRecord(pr);
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap share button
      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pumpAndSettle();

      // Assert - Share message should contain all required data except improvement
      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('New Personal Record'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('150.0 kg'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('10'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('4500.0 kg'),
      ), findsOneWidget);
      
      // Should NOT contain improvement percentage in the message
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('↑'),
      ), findsNothing);
    });

    testWidgets('Feature: workout-tracking-system, Property 13: PR Share Message Generation - Multiple share messages', 
        (WidgetTester tester) async {
      // Test case: Verify each PR generates its own unique message
      
      final prs = [
        PersonalRecord(
          id: 1,
          exerciseId: 1,
          exerciseName: 'Deadlift',
          maxWeight: 180.0,
          maxReps: 5,
          maxVolume: 2700.0,
          achievedDate: DateTime.now().subtract(const Duration(days: 2)),
          improvementPercentage: 8.3,
        ),
        PersonalRecord(
          id: 2,
          exerciseId: 2,
          exerciseName: 'Pull-ups',
          maxWeight: 0.0,
          maxReps: 15,
          maxVolume: 15.0,
          achievedDate: DateTime.now().subtract(const Duration(days: 10)),
          improvementPercentage: 25.0,
        ),
      ];
      
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.clear();
      for (final pr in prs) {
        mockRepo.addPersonalRecord(pr);
      }
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Test first PR share message
      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pumpAndSettle();
      
      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('180.0 kg'),
      ), findsOneWidget);
      expect(find.descendant(
        of: dialogFinder,
        matching: find.textContaining('8.3%'),
      ), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Test second PR share message
      await tester.tap(find.byIcon(Icons.share).last);
      await tester.pumpAndSettle();
      
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('0.0 kg'),
      ), findsOneWidget);
      expect(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('25.0%'),
      ), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('should display error state when loading fails', 
        (WidgetTester tester) async {
      // Arrange - Create repo that throws error
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.setShouldThrowError(true);
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - Should show error state
      expect(find.text('Failed to Load Records'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should retry loading when retry button tapped', 
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.setShouldThrowError(true);
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Act - Fix the error and tap retry
      mockRepo.setShouldThrowError(false);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Assert - Should now show data
      expect(find.byType(PRCard), findsWidgets);
      expect(find.text('Failed to Load Records'), findsNothing);
    });
  });

  group('Navigation Tests', () {
    testWidgets('should navigate to workout history when PR card tapped', 
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockPersonalRecordRepository();
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Act - Tap on a PR card
      await tester.tap(find.byType(PRCard).first);
      await tester.pump(); // Just pump once to trigger the navigation

      // Assert - Should show snackbar indicating navigation
      await tester.pump(const Duration(milliseconds: 100)); // Wait for snackbar
      expect(find.textContaining('Showing workouts for'), findsOneWidget);
    });
  });
}
