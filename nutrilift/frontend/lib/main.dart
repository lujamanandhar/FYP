import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLift',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Times New Roman',
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}