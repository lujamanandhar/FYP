import 'package:flutter/material.dart';

class NutritionTracking extends StatelessWidget {
  const NutritionTracking({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const NutritionTrackerHome();
  }
}

class NutritionTrackerHome extends StatefulWidget {
  const NutritionTrackerHome({Key? key}) : super(key: key);

  @override
  State<NutritionTrackerHome> createState() => _NutritionTrackerHomeState();
}

class _NutritionTrackerHomeState extends State<NutritionTrackerHome> {
  int _selectedIndex = 0;
  DateTime selectedDate = DateTime(2025, 4, 22);

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      _buildHomeScreen(),
      const Center(child: Text('Workout Screen')),
      const AddMealScreen(),
      const Center(child: Text('Profile Screen')),
    ]);
  }

  // Widget _buildHomeScreen() {
  //   return SingleChildScrollView(
  //     child: Column(
  //       children: [
  //         // Date Selector
  //         Container(
  //           padding: const EdgeInsets.symmetric(vertical: 16),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               IconButton(
  //                 icon: const Icon(Icons.chevron_left),
  //                 onPressed: () {
  //                   setState(() {
  //                     selectedDate = selectedDate.subtract(const Duration(days: 1));
  //                   });
  //                 },
  //               ),
  //               Text(
  //                 '${_getMonthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}',
  //                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //               ),
  //               IconButton(
  //                 icon: const Icon(Icons.chevron_right),
  //                 onPressed: () {
  //                   setState(() {
  //                     selectedDate = selectedDate.add(const Duration(days: 1));
  //                   });
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),

          // Macro Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMacroCard('Protein', '65g', '/300g', 'red'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroCard('Carbs', '300g', '/200g', 'red'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroCard('Fats', '70g', '/70g', 'red'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Meals Section
          _buildMealSection('Breakfast', 450, [
            {'name': 'Pokhak Satu', 'calories': '170g, 300 cal'},
            {'name': 'Banana', 'calories': '100g, 150 cal'},
          ]),

          _buildMealSection('Lunch', 500, [
            {'name': 'Chicken Rice', 'calories': '300g, 500 cal'},
            {'name': 'Lassi', 'calories': '200g, 150 cal'},
          ]),

          _buildMealSection('Dinner', 300, [
            {'name': 'Steak', 'calories': '200g, 300 cal'},
            {'name': 'Mango Juice', 'calories': '150 ml'},
          ]),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String label, String value, String target, String color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            target,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String title, int calories, List<Map<String, String>> foods) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$calories cal',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...foods.map((food) => _buildFoodItem(food['name']!, food['calories']!)),
        ],
      ),
    );
  }

  Widget _buildFoodItem(String name, String details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fastfood, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  details,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, size: 20),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NUTRILIFT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE53935),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({Key? key}) : super(key: key);

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> recentFoods = [
    {'name': 'Grilled Chicken Breast', 'calories': '165 cal per 100g', 'icon': Icons.restaurant},
    {'name': 'Yogurt', 'calories': '59 cal per 100g', 'icon': Icons.food_bank},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {},
        ),
        title: const Text('Add Food'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search food',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Recent Foods
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Foods',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...recentFoods.map((food) => _buildFoodCard(
                  food['name'],
                  food['calories'],
                  food['icon'],
                )),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('+ Add Custom Food'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(String name, String calories, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  calories,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFFE53935)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}