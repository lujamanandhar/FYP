// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutrilift/main.dart';

void main() {
  testWidgets('App launches with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MyApp(navigatorKey: navigatorKey));

    // Verify that the login screen is displayed
    expect(find.text('Sign In To NutriLift'), findsOneWidget);
    expect(find.text("Let's personalize your fitness with us"), findsOneWidget);
  });
}
