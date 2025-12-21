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
  int _selectedIndex = 0; // Default to home, but will show meal icon as active
  DateTime selectedDate = DateTime.now();
  bool _showAddMealScreen = false;
  bool _isInMealSection = true; // Always true since all date views are meal section
  String? _selectedMacro; // Track which macro was clicked

  Widget _getCurrentScreen() {
    if (_showAddMealScreen) {
      return AddMealScreen(onBack: () {
        setState(() {
          _showAddMealScreen = false;
        });
      });
    }
    
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return const Center(child: Text('Workout Screen'));
      case 2:
        return _buildHomeScreen(); // Meal section shows home screen
      case 3:
        return const Center(child: Text('Profile Screen'));
      default:
        return _buildHomeScreen();
    }
  }

  bool _isToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  bool _isPast() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isBefore(today);
  }

  bool _isFuture() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAfter(today);
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  '${_getMonthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.add(const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),

          _buildMacroCards(),

          const SizedBox(height: 24),

          if (_isPast()) ..._buildPastMeals(),
          if (_isToday()) ..._buildTodayMeals(),
          if (_isFuture()) ..._buildFutureMeals(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMacroCards() {
    String protein = '0g', carbs = '0g', fats = '0g';
    
    if (_isPast()) {
      protein = '65g';
      carbs = '300g';
      fats = '70g';
    } else if (_isToday()) {
      protein = '65g';
      carbs = '200g';
      fats = '20g';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showMacroOverview('Protein'),
              child: _buildMacroCard('Protein', protein, '/300g'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showMacroOverview('Carbs'),
              child: _buildMacroCard('Carbs', carbs, '/200g'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showMacroOverview('Fats'),
              child: _buildMacroCard('Fats', fats, '/70g'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPastMeals() {
    return [
      _buildMealSection('Breakfast', 450, [
        {'name': 'Poshak Satu', 'calories': '170g, 300 cal'},
        {'name': 'Banana', 'calories': '100g, 150 cal'},
      ], false),
      _buildMealSection('Lunch', 500, [
        {'name': 'Chicken Rice', 'calories': '300g, 500 cal'},
        {'name': 'Lassi', 'calories': '200g, 150 cal'},
      ], false),
      _buildMealSection('Dinner', 300, [
        {'name': 'Steak', 'calories': '200g, 300 cal'},
        {'name': 'Mango Juice', 'calories': '150 ml'},
      ], false),
    ];
  }

  List<Widget> _buildTodayMeals() {
    return [
      _buildMealSection('Breakfast', 450, [
        {'name': 'Poshak Satu', 'calories': '170g, 300 cal'},
        {'name': 'Banana', 'calories': '100g, 150 cal'},
      ], false),
      _buildMealSection('Lunch', 500, [
        {'name': 'Chicken Rice', 'calories': '300g, 500 cal'},
      ], true),
      _buildMealSection('Dinner', 300, [
        {'name': 'Steak', 'calories': '200g, 300 cal'},
      ], false),
    ];
  }

  List<Widget> _buildFutureMeals() {
    return [
      _buildMealSection('Breakfast', 0, [], true),
      _buildMealSection('Lunch', 0, [], true),
      _buildMealSection('Dinner', 0, [], true),
    ];
  }

  Widget _buildMacroCard(String label, String value, String target) {
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

  Widget _buildMealSection(String title, int calories, List<Map<String, String>> foods, bool showAddButton) {
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
          if (showAddButton) 
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAddMealScreen = true;
                });
              },
              child: _buildAddFoodButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildAddFoodButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE53935), style: BorderStyle.solid, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '+ Add Food',
          style: TextStyle(
            color: Color(0xFFE53935),
            fontWeight: FontWeight.w500,
          ),
        ),
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

  void _showMacroOverview(String macro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MacroOverviewSheet(
        macro: macro,
        onClose: () => Navigator.pop(context),
      ),
    );
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
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _isInMealSection ? 2 : _selectedIndex, // Always show meal icon as active
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 2) {
              _isInMealSection = true;
              _showAddMealScreen = false;
            } else {
              _isInMealSection = false;
            }
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

class MacroOverviewSheet extends StatefulWidget {
  final String macro;
  final VoidCallback onClose;

  const MacroOverviewSheet({
    Key? key,
    required this.macro,
    required this.onClose,
  }) : super(key: key);

  @override
  State<MacroOverviewSheet> createState() => _MacroOverviewSheetState();
}

class _MacroOverviewSheetState extends State<MacroOverviewSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _targetValue = 120.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.macro} Overview',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFE53935),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE53935),
            tabs: const [
              Tab(text: 'Adjust'),
              Tab(text: 'Overview'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdjustTab(),
                _buildOverviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Protein Sources',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Current Intake', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '65g',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Of 120g',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Adjust Target', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFE53935),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: const Color(0xFFE53935),
              overlayColor: const Color(0xFFE53935).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _targetValue,
              min: 0,
              max: 200,
              onChanged: (value) {
                setState(() {
                  _targetValue = value;
                });
              },
            ),
          ),
          Center(
            child: Text(
              '${_targetValue.round()}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Center(
            child: Text(
              'Recommended: 100-145g',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClose,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFE53935)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Protein Sources',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: DonutChartPainter(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '65g',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Protein',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFoodSourceItem(
            'Poshak Satu',
            '25g',
            '38% of daily intake',
            const Color(0xFFE53935),
          ),
          const SizedBox(height: 12),
          _buildFoodSourceItem(
            'Banana',
            '40g',
            '100% of daily intake',
            const Color(0xFFFFA726),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSourceItem(String name, String amount, String percentage, Color color) {
    return Container(
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
            child: const Icon(Icons.fastfood, size: 28),
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
                const SizedBox(height: 2),
                Text(
                  '83.3 g Protein',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 30) / 2;

    // Red arc (38%)
    paint.color = const Color(0xFFE53935);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // Start at top (-90 degrees in radians)
      2.37, // 38% of circle (0.38 * 2π)
      false,
      paint,
    );

    // Orange arc (62%)
    paint.color = const Color(0xFFFFA726);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.80, // Continue from red
      3.87, // 62% of circle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class AddMealScreen extends StatefulWidget {
  final VoidCallback onBack;
  
  const AddMealScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showCustomFoodForm = false;

  final List<Map<String, dynamic>> recentFoods = [
    {'name': 'Grilled Chicken Breast', 'calories': '1 Meal - 165 cal', 'icon': Icons.restaurant},
    {'name': 'Yogurt', 'calories': '1 Cup - 109 cal', 'icon': Icons.food_bank},
  ];

  final List<Map<String, dynamic>> recentFoodImages = [
    {'name': 'Salmon', 'image': Icons.set_meal},
    {'name': 'Banana', 'image': Icons.breakfast_dining},
    {'name': 'Yogurt', 'image': Icons.emoji_food_beverage},
  ];

  @override
  Widget build(BuildContext context) {
    if (_showCustomFoodForm) {
      return _buildCustomFoodForm();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFE53935)),
          onPressed: widget.onBack,
        ),
        title: const Text('Add Food'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Food',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF5F5),
                ),
              ),
            ),

            ...recentFoods.map((food) => _buildFoodCard(
              food['name'],
              food['calories'],
              food['icon'],
            )),

            const SizedBox(height: 16),

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: recentFoodImages.map((food) => 
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(food['image'], size: 40),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              food['name'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showCustomFoodForm = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE53935), style: BorderStyle.solid, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          '+ Add Custom Food',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFoodForm() {
    final TextEditingController foodNameController = TextEditingController();
    final TextEditingController brandController = TextEditingController();
    final TextEditingController servingSizeController = TextEditingController();
    final TextEditingController caloriesController = TextEditingController();
    final TextEditingController proteinController = TextEditingController();
    final TextEditingController carbsController = TextEditingController();
    final TextEditingController fatsController = TextEditingController();
    
    String selectedUnit = 'Choose unit';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFE53935)),
          onPressed: () {
            setState(() {
              _showCustomFoodForm = false;
            });
          },
        ),
        title: const Text('Add Custom Food'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log your own food manually if not found in our database',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const Text('Food Name', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: foodNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. boil curry',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Brand Name(Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: brandController,
                decoration: InputDecoration(
                  hintText: 'Enter brand name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Serving Size*', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: servingSizeController,
                          decoration: InputDecoration(
                            hintText: '0/Size',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit*', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          items: ['Choose unit', 'g', 'ml', 'oz', 'cup']
                              .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                              .toList(),
                          onChanged: (value) {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Nutrition Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildNutritionField('Calories*', caloriesController, '0'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNutritionField('Protein*', proteinController, '0'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildNutritionField('Carbs(g)*', carbsController, '0'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNutritionField('Fats(g)*', fatsController, '0'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_a_photo, color: Color(0xFFE53935)),
                    label: const Text('Add Photo', style: TextStyle(color: Color(0xFFE53935))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE53935)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showCustomFoodForm = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE53935)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFFE53935))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildFoodCard(String name, String calories, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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