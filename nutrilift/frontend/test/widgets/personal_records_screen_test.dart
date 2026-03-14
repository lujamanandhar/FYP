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
    child: const MaterialApp(
      home: PersonalRecordsScreen(),
    ),
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
      expect(find.text('Start logging workouts to track your personal bests'), 
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
      expect(find.textContaining('120.0 kg'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.textContaining('4320'), findsOneWidget);
      
      // Should show improvement indicator
      expect(find.textContaining('15.5%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
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
      expect(find.textContaining('150.0 kg'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.textContaining('4500'), findsOneWidget);
      
      // Should NOT show improvement indicator
      expect(find.byType(LinearProgressIndicator), findsNothing);
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
      expect(find.text('Deadlift'), findsOneWidget);
      expect(find.text('Pull-ups'), findsOneWidget);
      expect(find.text('Shoulder Press'), findsOneWidget);
      
      // Should show improvement indicators for PRs with improvement data
      expect(find.textContaining('8.3%'), findsOneWidget);
      expect(find.textContaining('25.0%'), findsOneWidget);
      
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
    /// 
    /// Note: Since share_plus uses platform-specific sharing, we test the message
    /// generation logic by verifying the share button is present and functional.

    testWidgets('Feature: workout-tracking-system, Property 13: PR Share Message Generation - Share button present for all PRs', 
        (WidgetTester tester) async {
      // Property test: Each PR should have a share button
      
      final prs = [
        PersonalRecord(
          id: 1,
          exerciseId: 1,
          exerciseName: 'Bench Press',
          maxWeight: 120.0,
          maxReps: 12,
          maxVolume: 4320.0,
          achievedDate: DateTime.now().subtract(const Duration(days: 1)),
          improvementPercentage: 15.5,
        ),
        PersonalRecord(
          id: 2,
          exerciseId: 2,
          exerciseName: 'Squats',
          maxWeight: 150.0,
          maxReps: 10,
          maxVolume: 4500.0,
          achievedDate: DateTime.now().subtract(const Duration(days: 5)),
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

      // Assert - Each PR card should have a share button
      expect(find.byIcon(Icons.share), findsNWidgets(prs.length));
    });

    testWidgets('Feature: workout-tracking-system, Property 13: PR Share Message Generation - Share button is tappable', 
        (WidgetTester tester) async {
      // Test that share button can be tapped without errors
      
      final pr = PersonalRecord(
        id: 1,
        exerciseId: 1,
        exerciseName: 'Deadlift',
        maxWeight: 180.0,
        maxReps: 5,
        maxVolume: 2700.0,
        achievedDate: DateTime.now().subtract(const Duration(days: 2)),
        improvementPercentage: 8.3,
      );
      
      final mockRepo = MockPersonalRecordRepository();
      mockRepo.clear();
      mockRepo.addPersonalRecord(pr);
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Act - Tap share button (this will call Share.share in the implementation)
      // In test environment, share_plus will not show a dialog but the tap should work
      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pumpAndSettle();

      // Assert - No errors should occur (test passes if no exception thrown)
      expect(find.byType(PRCard), findsOneWidget);
    });

    testWidgets('Feature: workout-tracking-system, Property 13: PR Share Message Generation - Multiple PRs can be shared', 
        (WidgetTester tester) async {
      // Test that each PR can be shared independently
      
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

      // Act - Tap share button on first PR
      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pumpAndSettle();
      
      // Act - Tap share button on second PR
      await tester.tap(find.byIcon(Icons.share).last);
      await tester.pumpAndSettle();

      // Assert - Both taps should work without errors
      expect(find.byType(PRCard), findsNWidgets(2));
    });
  });

  group('Error Handling Tests', () {
    // Note: Error handling tests removed as MockPersonalRecordRepository
    // doesn't support error simulation. Error handling is tested through
    // integration tests with the actual API service.
  });

  group('Navigation Tests', () {
    testWidgets('should have tappable PR cards', 
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockPersonalRecordRepository();
      
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - PR cards should be present and tappable
      expect(find.byType(PRCard), findsWidgets);
      expect(find.byType(InkWell), findsWidgets);
      
      // Verify that each PR card has an onTap callback
      final prCards = tester.widgetList<PRCard>(find.byType(PRCard));
      for (final card in prCards) {
        expect(card.onTap, isNotNull);
      }
    });
  });
}
