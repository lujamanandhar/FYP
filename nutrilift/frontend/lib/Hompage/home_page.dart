import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../UserManagement/profile_edit_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showChart = false;
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  final List<ChartData> chartData = [
    ChartData('Sun', 70),
    ChartData('Mon', 85),
    ChartData('Tue', 65),
    ChartData('Wed', 95),
    ChartData('Thu', 80),
    ChartData('Fri', 90),
    ChartData('Sat', 75),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profile = await _authService.getProfile();
      
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProfile() async {
    await _loadUserProfile();
  }

  void nextView() {
    setState(() {
      showChart = true;
    });
  }

  void prevView() {
    setState(() {
      showChart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NUTRILIFT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Text('🔔', style: TextStyle(fontSize: 20)),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeSection(),
                                const SizedBox(height: 24),

                                // Stats/Chart Section
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      showChart ? 'Overview' : 'Daily Summary',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D2D2D),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Stack(
                                      children: [
                                        // Content
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: showChart
                                              ? _buildChart()
                                              : _buildStatsGrid(),
                                        ),

                                        // Left Arrow
                                        Positioned(
                                          left: -16,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.chevron_left),
                                                color: const Color(0xFF666666),
                                                onPressed: prevView,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Right Arrow
                                        Positioned(
                                          right: -16,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.chevron_right),
                                                color: const Color(0xFF666666),
                                                onPressed: nextView,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                _buildProfileSection(),
                                const SizedBox(height: 24),

                                // Today's Plan
                                const Text(
                                  "Today's Plan",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPlanItem(
                                  Icons.fitness_center,
                                  'Cardio',
                                  '07:00-08:00 AM',
                                  'START',
                                ),
                                const SizedBox(height: 8),
                                _buildPlanItem(
                                  Icons.restaurant,
                                  'Lunch',
                                  '01:00-02:00 PM',
                                  'LOG',
                                ),
                                const SizedBox(height: 24),

                                // Quick Actions
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickAction(
                                        Icons.restaurant,
                                        'SCAN MEAL',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickAction(
                                        Icons.fitness_center,
                                        'ADD SHORTCUTS',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // AI Assistant
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFB71C1C), Color(0xFFC62828)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AI Assistant',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Get Personalized Recommendations',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.chat_bubble,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Active Challenges
                                const Text(
                                  'Active Challenges',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '30 Days Pushup Challenge',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2D2D2D),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Day 15 of 30',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF999999),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final userName = _userProfile?.displayName ?? 'User';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $userName!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Let's Crush Your Fitness Goals Today!",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_userProfile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_userProfile != null) {
                  final updatedProfile = await Navigator.push<UserProfile>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(userProfile: _userProfile!),
                    ),
                  );
                  
                  if (updatedProfile != null) {
                    setState(() {
                      _userProfile = updatedProfile;
                    });
                  }
                }
              },
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileItem(Icons.person, 'Name', _userProfile!.displayName),
              if (_userProfile!.gender != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.wc, 'Gender', _userProfile!.gender!),
              ],
              if (_userProfile!.ageGroup != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.cake, 'Age Group', _userProfile!.ageGroup!),
              ],
              if (_userProfile!.height != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.height, 'Height', '${_userProfile!.height!.toStringAsFixed(1)} cm'),
              ],
              if (_userProfile!.weight != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.monitor_weight, 'Weight', '${_userProfile!.weight!.toStringAsFixed(1)} kg'),
              ],
              if (_userProfile!.fitnessLevel != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.fitness_center, 'Fitness Level', _userProfile!.fitnessLevel!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      key: const ValueKey('stats'),
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(Icons.local_fire_department, '700', 'Calories Burned'),
        _buildStatCard(Icons.restaurant, '1580', 'Calories Intake'),
        _buildStatCard(Icons.access_time, '45min', 'Active Time'),
        _buildStatCard(Icons.check_circle, '3', 'Workout Completed'),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    double maxValue = chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return Container(
      key: const ValueKey('chart'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade50,
            Colors.pink.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24),
      height: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chartData.map((data) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 32,
                    height: (data.value / maxValue) * 160,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.day,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanItem(IconData icon, String title, String time, String buttonText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String day;
  final double value;

  ChartData(this.day, this.value);
}