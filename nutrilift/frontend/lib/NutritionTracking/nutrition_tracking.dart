import 'package:flutter/material.dart';

class NutritionTrackingPage extends StatefulWidget {
  @override
  State<NutritionTrackingPage> createState() => _NutritionTrackingPageState();
}

class _NutritionTrackingPageState extends State<NutritionTrackingPage> {
  double calories = 1850;
  double calorieGoal = 2000;
  double protein = 85;
  double proteinGoal = 100;
  double carbs = 250;
  double carbsGoal = 250;
  double fat = 65;
  double fatGoal = 70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrition Tracking'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalorieCard(),
              SizedBox(height: 32),
              Text('Macronutrients', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _buildMacroItem('Protein', protein, proteinGoal, Colors.blue),
              _buildMacroItem('Carbs', carbs, carbsGoal, Colors.orange),
              _buildMacroItem('Fat', fat, fatGoal, Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieCard() {
    double progress = calories / calorieGoal;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Daily Calories', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress > 1 ? 1 : progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Column(
                  children: [
                    Text('${calories.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('/ ${calorieGoal.toStringAsFixed(0)} kcal',
                      style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, double value, double goal, Color color) {
    double progress = value / goal;
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${value.toStringAsFixed(1)}g / ${goal.toStringAsFixed(1)}g',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}