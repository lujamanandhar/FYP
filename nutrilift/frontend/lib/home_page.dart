import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[700]!, Colors.red[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, size: 80, color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'NutriLift',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your Personal Nutrition Guide',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            // Features Section
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _featureCard('Track Nutrition', Icons.bar_chart),
                  SizedBox(height: 15),
                  _featureCard('Meal Planning', Icons.restaurant_menu),
                  SizedBox(height: 15),
                  _featureCard('Health Goals', Icons.favorite),
                ],
              ),
            ),
            // CTA Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text('Get Started', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(String title, IconData icon) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.red[700], size: 30),
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward, color: Colors.red[700]),
      ),
    );
  }
}