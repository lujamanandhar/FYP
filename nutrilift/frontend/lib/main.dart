import 'package:flutter/material.dart';
import 'UserManagement/login_screen.dart';
import 'services/error_handler.dart';

void main() {
  // Initialize global error handler
  final navigatorKey = GlobalKey<NavigatorState>();
  ErrorHandler().initialize(navKey: navigatorKey);
  
  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  
  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'NutriLift',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}