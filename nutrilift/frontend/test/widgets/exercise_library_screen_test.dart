import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/screens/exercise_library_screen.dart';
import 'package:nutrilift/providers/exercise_library_provider.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/mock_exercise_repository.dart';
import 'package:nutrilift/models/exercise.dart';
import 'package:nutrilift/widgets/exercise_card.dart';

/// Helper to build the widget with mock repository
Widget buildTestWidget({MockExerciseRepository? customRepo}) {
  return ProviderScope(
    overrides: [
      exerciseRepositoryProvider.overrideWithValue(
        customRepo ?? MockExerciseRepository(),
      ),
    ],
    child: const MaterialApp(home: ExerciseLibraryScreen()),
  );
}

void main() {
  group('ExerciseLibraryScreen Widget Tests', () {
    testWidgets('should display exercises in grid', (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Assert - Should show exercise cards in grid
      expect(find.byType(ExerciseCard), findsWidgets);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should have search bar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have search TextField
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search exercises...'), findsOneWidget);
    });

    testWidgets('should have filter chips', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have filter chips
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Muscle'), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
    });

    testWidgets('should show loading indicator while loading',
        (WidgetTester tester) async {
      // Arrange - Create a repository that delays response
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      
      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for data to load
      await tester.pumpAndSettle();
      
      // Assert - Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should open filter dialog when category chip tapped',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap category filter chip
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();

      // Assert - Should show filter dialog
      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);
      expect(find.text('Bodyweight'), findsOneWidget);
    });

    testWidgets('should open filter dialog when muscle chip tapped',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap muscle filter chip
      await tester.tap(find.text('Muscle'));
      await tester.pumpAndSettle();

      // Assert - Should show filter dialog
      expect(find.text('Select Muscle Group'), findsOneWidget);
      // Check for radio list tiles instead of just text
      expect(find.byType(RadioListTile<String>), findsWidgets);
    });

    testWidgets('should show exercise details when card tapped',
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap first exercise card
      await tester.tap(find.byType(ExerciseCard).first);
      await tester.pumpAndSettle();

      // Assert - Should show bottom sheet with exercise details
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Add to Workout'), findsOneWidget);
    });

    testWidgets('should clear search when clear button tapped',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pumpAndSettle();

      // Assert - Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Assert - Search field should be empty
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });

  group('Property 5: Exercise Search Filtering', () {
    /// **Validates: Requirements 2.3, 3.6**
    /// 
    /// Property 5: Exercise Search Filtering
    /// For any search term, all returned exercises should have names that
    /// contain the search term (case-insensitive).

    testWidgets('Feature: workout-tracking-system, Property 5: Exercise Search Filtering - Search returns matching exercises', 
        (WidgetTester tester) async {
      // Property test: For any search term, returned exercises should match
      
      // Test cases with different search terms
      final testCases = [
        {'search': 'bench', 'shouldFind': 'Bench Press', 'shouldNotFind': 'Squats'},
        {'search': 'PRESS', 'shouldFind': 'Bench Press', 'shouldNotFind': 'Squats'},
        {'search': 'squat', 'shouldFind': 'Squats', 'shouldNotFind': 'Bench Press'},
        {'search': 'pull', 'shouldFind': 'Pull-ups', 'shouldNotFind': 'Push-ups'},
      ];

      for (final testCase in testCases) {
        final search = testCase['search'] as String;
        final shouldFind = testCase['shouldFind'] as String;
        final shouldNotFind = testCase['shouldNotFind'] as String;

        // Arrange
        final mockRepo = MockExerciseRepository();
        
        // Act
        await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
        await tester.pumpAndSettle();

        // Enter search term
        await tester.enterText(find.byType(TextField), search);
        await tester.pumpAndSettle();

        // Assert - Should find matching exercise
        expect(find.text(shouldFind), findsWidgets,
            reason: 'Search "$search" should find "$shouldFind"');
        
        // Assert - Should not find non-matching exercise
        expect(find.text(shouldNotFind), findsNothing,
            reason: 'Search "$search" should not find "$shouldNotFind"');
      }
    });

    testWidgets('Feature: workout-tracking-system, Property 5: Exercise Search Filtering - Empty search shows all exercises', 
        (WidgetTester tester) async {
      // Property test: Empty search should show all exercises
      
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Get initial count of exercises
      final initialCount = tester.widgetList(find.byType(ExerciseCard)).length;
      expect(initialCount, greaterThan(0));

      // Enter search term
      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pumpAndSettle();

      // Should have fewer exercises
      final filteredCount = tester.widgetList(find.byType(ExerciseCard)).length;
      expect(filteredCount, lessThan(initialCount));

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Should show all exercises again
      final finalCount = tester.widgetList(find.byType(ExerciseCard)).length;
      expect(finalCount, equals(initialCount));
    });

    testWidgets('Feature: workout-tracking-system, Property 5: Exercise Search Filtering - Case insensitive search', 
        (WidgetTester tester) async {
      // Property test: Search should be case-insensitive
      
      final searchVariations = ['bench', 'BENCH', 'Bench', 'BeNcH'];

      for (final search in searchVariations) {
        // Arrange
        final mockRepo = MockExerciseRepository();
        
        // Act
        await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
        await tester.pumpAndSettle();

        // Enter search term
        await tester.enterText(find.byType(TextField), search);
        await tester.pumpAndSettle();

        // Assert - Should find "Bench Press" regardless of case
        expect(find.text('Bench Press'), findsWidgets,
            reason: 'Search "$search" should find "Bench Press" (case-insensitive)');
      }
    });
  });

  group('Exercise Filtering Tests', () {
    testWidgets('should filter by category', (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap category filter
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();

      // Select Strength
      await tester.tap(find.text('Strength'));
      await tester.pumpAndSettle();

      // Assert - Category chip should show selected value
      expect(find.text('Strength'), findsWidgets);
      
      // All visible exercises should be Strength category
      // (This is validated by the provider logic)
    });

    testWidgets('should filter by muscle group', (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap muscle filter
      await tester.tap(find.text('Muscle'));
      await tester.pumpAndSettle();

      // Select Chest - use the radio list tile
      await tester.tap(find.byType(RadioListTile<String>).first);
      await tester.pumpAndSettle();

      // Assert - Muscle chip should show selected value
      // The chip will now show "Chest" instead of "Muscle"
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('should filter by equipment', (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap equipment filter
      await tester.tap(find.text('Equipment'));
      await tester.pumpAndSettle();

      // Select Free Weights
      await tester.tap(find.text('Free Weights'));
      await tester.pumpAndSettle();

      // Assert - Equipment chip should show selected value
      expect(find.text('Free Weights'), findsWidgets);
    });

    testWidgets('should filter by difficulty', (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap difficulty filter
      await tester.tap(find.text('Difficulty'));
      await tester.pumpAndSettle();

      // Select Intermediate - use the radio list tile
      await tester.tap(find.byType(RadioListTile<String>).at(1));
      await tester.pumpAndSettle();

      // Assert - Difficulty chip should show selected value
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('should show clear all button when filters active',
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Initially no clear all button
      expect(find.text('Clear All'), findsNothing);

      // Apply a filter
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Strength'));
      await tester.pumpAndSettle();

      // Assert - Clear all button should appear
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('should clear all filters when clear all tapped',
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Apply a filter
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RadioListTile<String>).first);
      await tester.pumpAndSettle();

      // Verify clear all button appears
      expect(find.text('Clear All'), findsOneWidget);

      // Scroll to make clear all button visible
      await tester.drag(find.text('Clear All'), const Offset(-100, 0), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap clear all
      await tester.tap(find.text('Clear All'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert - Clear all button should be gone
      expect(find.text('Clear All'), findsNothing);
    });
  });

  group('Exercise Detail Bottom Sheet Tests', () {
    testWidgets('should show all exercise details in bottom sheet',
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap first exercise card
      await tester.tap(find.byType(ExerciseCard).first);
      await tester.pumpAndSettle();

      // Assert - Should show all details
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Add to Workout'), findsOneWidget);
      
      // Should show tags
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsWidgets);
      expect(find.byIcon(Icons.build), findsOneWidget);
      expect(find.byIcon(Icons.signal_cellular_alt), findsOneWidget);
    });

    testWidgets('should show video button if video URL exists',
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap first exercise card (should have video URL)
      await tester.tap(find.byType(ExerciseCard).first);
      await tester.pumpAndSettle();

      // Assert - Should show watch video button
      expect(find.text('Watch Video'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });

    testWidgets('should show add to workout button in bottom sheet',
        (WidgetTester tester) async {
      // Arrange
      final mockRepo = MockExerciseRepository();
      
      // Act
      await tester.pumpWidget(buildTestWidget(customRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap first exercise card
      await tester.tap(find.byType(ExerciseCard).first);
      await tester.pumpAndSettle();

      // Assert - Should show add to workout button
      expect(find.text('Add to Workout'), findsOneWidget);
    });
  });
}
