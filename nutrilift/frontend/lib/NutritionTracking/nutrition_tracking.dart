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
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalorieCard(),
              SizedBox(height: 24),
              Text('Macronutrients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Daily Calories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: progress > 1 ? 1 : progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(Colors.green),
                  ),
                ),
                Column(
                  children: [
                    Text('${calories.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('/ ${calorieGoal.toStringAsFixed(0)} kcal',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${value.toStringAsFixed(1)}g / ${goal.toStringAsFixed(1)}g',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}