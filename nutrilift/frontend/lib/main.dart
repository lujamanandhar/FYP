import 'package:flutter/material.dart';
import 'UserManagement/login_screen.dart';
import 'services/error_handler.dart';

void main() {
  // Initialize global error handler with navigation key for displaying errors globally
  final navigatorKey = GlobalKey<NavigatorState>();
  ErrorHandler().initialize(navKey: navigatorKey);
  
  // Run the app with the navigator key passed to enable global error handling
  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  // Navigator key used for global error handling and navigation management
  final GlobalKey<NavigatorState> navigatorKey;
  
  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Assign navigator key to enable access from ErrorHandler service
      navigatorKey: navigatorKey,
      title: 'NutriLift',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
      ),
      // Set LoginScreen as the initial route
      home: const LoginScreen(),
      // Hide debug banner in development
      debugShowCheckedModeBanner: false,
    );
  }
}