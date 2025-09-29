import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Card(
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: color.withOpacity(0.95),
        shadowColor: color.withOpacity(0.4),
        child: Container(
          width: 180,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), Colors.white.withOpacity(0.12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.18),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, size: 64, color: Colors.deepPurpleAccent), // Changed icon color
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple, // Changed text color
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurpleAccent, // Changed subtitle color
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.withOpacity(0.7), // Changed appbar color
        elevation: 0,
        title: const Text('NutriLift Fitness'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 32, color: Colors.deepPurpleAccent), // Changed icon color
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC), Color(0xFF7367F0)], // Changed background gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7367F0), Color(0xFFE0C3FC)], // Changed icon background gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_run, size: 110, color: Colors.deepPurpleAccent), // Changed icon color
                ),
                const SizedBox(height: 36),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [Color(0xFF7367F0), Color(0xFFE0C3FC)], // Changed gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'Welcome to NutriLift!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    'Track workouts, nutrition, and reach your fitness goals with ease.',
                    style: TextStyle(fontSize: 20, color: Colors.deepPurple, fontWeight: FontWeight.w500), // Changed text color
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCard(
                      icon: Icons.fitness_center,
                      title: 'Workouts',
                      subtitle: 'Log & view workouts',
                      color: Colors.deepPurpleAccent, // Changed card color
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WorkoutsScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 32),
                    _buildCard(
                      icon: Icons.restaurant,
                      title: 'Nutrition',
                      subtitle: 'Track your meals',
                      color: Colors.purple, // Changed card color
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NutritionScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 36),
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: Colors.deepPurple[50]!.withOpacity(0.92), // Changed card color
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.info_outline, color: Colors.deepPurpleAccent), // Changed icon color
                        SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            'Tip: Stay consistent and hydrated for best results!',
                            style: TextStyle(fontSize: 18, color: Colors.deepPurple, fontWeight: FontWeight.w500), // Changed text color
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Add a motivational quote
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple[100]!, Colors.deepPurple[50]!], // Changed gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.format_quote, color: Colors.deepPurpleAccent, size: 28), // Changed icon color
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '"Success starts with self-discipline."',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.deepPurpleAccent, // Changed text color
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Text(
          'This is the Profile Screen',
          style: TextStyle(fontSize: 21, color: Colors.deepPurple), // Changed text color
        ),
      ),
    );
  }
}

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Workouts'),
      ),
      body: const Center(
        child: Text(
          'Track your workouts here!',
          style: TextStyle(fontSize: 21, color: Colors.deepPurple), // Changed text color
        ),
      ),
    );
  }
}

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('Nutrition'),
      ),
      body: const Center(
        child: Text(
          'Track your nutrition here!',
          style: TextStyle(fontSize: 21, color: Colors.purple), // Changed text color
        ),
      ),
    );
  }
}
