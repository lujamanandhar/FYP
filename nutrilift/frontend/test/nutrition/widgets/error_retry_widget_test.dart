import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/NutritionTracking/widgets/error_retry_widget.dart';

void main() {
  group('ErrorRetryWidget Tests', () {
    testWidgets('should display error message in compact mode', (WidgetTester tester) async {
      // Arrange
      bool retryTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Network error occurred',
              isCompact: true,
              onRetry: () {
                retryTapped = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Network error occurred'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display error message in full mode', (WidgetTester tester) async {
      // Arrange
      bool retryTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Failed to load data',
              isCompact: false,
              onRetry: () {
                retryTapped = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Oops! Something went wrong'), findsOneWidget);
      expect(find.text('Failed to load data'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should call onRetry when retry button tapped in compact mode', (WidgetTester tester) async {
      // Arrange
      bool retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Network error',
              isCompact: true,
              onRetry: () {
                retryTapped = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Assert
      expect(retryTapped, isTrue);
    });

    testWidgets('should call onRetry when retry button tapped in full mode', (WidgetTester tester) async {
      // Arrange
      bool retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Failed to load',
              isCompact: false,
              onRetry: () {
                retryTapped = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      // Assert
      expect(retryTapped, isTrue);
    });

    testWidgets('should clean "Exception: " prefix from error message', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Exception: Network error',
              isCompact: true,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert - Should show cleaned message without "Exception: " prefix
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Exception: Network error'), findsNothing);
    });

    testWidgets('should display correct styling in compact mode', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Error',
              isCompact: true,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert - Should have Container with red background
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.error_outline),
          matching: find.byType(Container),
        ).first,
      );
      
      expect(container.decoration, isA<BoxDecoration>());
    });

    testWidgets('should display correct styling in full mode', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Error',
              isCompact: false,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert - Should have Center widget
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('NetworkErrorWidget Tests', () {
    testWidgets('should display network error message', (WidgetTester tester) async {
      // Arrange
      bool retryTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(
              onRetry: () {
                retryTapped = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Please check your network connection and try again.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should call onRetry when retry button tapped', (WidgetTester tester) async {
      // Arrange
      bool retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(
              onRetry: () {
                retryTapped = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      // Assert
      expect(retryTapped, isTrue);
    });

    testWidgets('should display wifi_off icon', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('should have centered layout', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('Error Message Cleaning Tests', () {
    testWidgets('should handle various error message formats', (WidgetTester tester) async {
      final testCases = [
        {'input': 'Exception: Network error', 'expected': 'Network error'},
        {'input': 'Simple error', 'expected': 'Simple error'},
        {'input': 'Exception: ', 'expected': ''},
        {'input': '', 'expected': ''},
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorRetryWidget(
                errorMessage: testCase['input']!,
                isCompact: true,
                onRetry: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.text(testCase['expected']!), findsOneWidget);
        
        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });

  group('Visual Regression Tests', () {
    testWidgets('compact mode should have consistent layout', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Test error message',
              isCompact: true,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert - Check layout structure
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Row), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('full mode should have consistent layout', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              errorMessage: 'Test error message',
              isCompact: false,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert - Check layout structure
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
