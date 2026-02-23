import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'UserManagement/login_screen.dart';
import 'services/error_handler.dart';

void main() {
  // Initialize global error handler with navigation key for displaying errors globally
  final navigatorKey = GlobalKey<NavigatorState>();
  ErrorHandler().initialize(navKey: navigatorKey);
  
  // Run the app wrapped with ProviderScope for Riverpod state management
  runApp(
    ProviderScope(
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
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
        // Primary red color scheme
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFFE53935),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          primary: const Color(0xFFE53935),
          secondary: const Color(0xFFB71C1C),
        ),
        
        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
        ),    
        
        // Button themes colors
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
          ),
        ),
        
        // Text button theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFE53935),
          ),
        ),
        
        // Floating action button theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE53935),
          foregroundColor: Colors.white,
        ),
        
        // Progress indicator theme
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFE53935),
        ),
        
        // Checkbox theme
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFE53935);
            }
            return null;
          }),
        ),
        
        // Radio theme
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFE53935);
            }
            return null;
          }),
        ),
        
        // Switch theme
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFE53935);
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFE53935).withOpacity(0.5);
            }
            return null;
          }),
        ),
        
        fontFamily: 'Roboto',
      ),
      // Set LoginScreen as the initial route
      home: const LoginScreen(),
      // Hide debug banner in development
      debugShowCheckedModeBanner: false,
    );
  }
}