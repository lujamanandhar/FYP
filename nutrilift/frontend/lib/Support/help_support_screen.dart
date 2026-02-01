import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/nutrilift_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Handle error if URL can't be launched
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String email, String subject) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    
    if (!await launchUrl(emailUri)) {
      debugPrint('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Help & Support',
      showBackButton: true,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'We\'re Here to Help!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get the support you need to achieve your fitness goals with NutriLift.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Help Section
            const Text(
              'Quick Help',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildHelpCard(
              icon: Icons.quiz,
              title: 'Frequently Asked Questions',
              description: 'Find answers to common questions about NutriLift',
              onTap: () => _showFAQDialog(context),
            ),
            const SizedBox(height: 12),
            
            _buildHelpCard(
              icon: Icons.fitness_center,
              title: 'Getting Started Guide',
              description: 'Learn how to set up your profile and start your fitness journey',
              onTap: () => _showGettingStartedDialog(context),
            ),
            const SizedBox(height: 12),
            
            _buildHelpCard(
              icon: Icons.restaurant,
              title: 'Nutrition Tracking Help',
              description: 'Learn how to track your meals and manage your nutrition',
              onTap: () => _showNutritionHelpDialog(context),
            ),
            const SizedBox(height: 24),

            // Contact Support Section
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildContactCard(
              icon: Icons.email,
              title: 'Email Support',
              description: 'support@nutrilift.com',
              subtitle: 'We typically respond within 24 hours',
              onTap: () => _launchEmail('support@nutrilift.com', 'NutriLift Support Request'),
            ),
            const SizedBox(height: 12),
            
            _buildContactCard(
              icon: Icons.phone,
              title: 'Phone Support',
              description: '+1 (555) 123-4567',
              subtitle: 'Mon-Fri, 9 AM - 6 PM EST',
              onTap: () => _launchURL('tel:+15551234567'),
            ),
            const SizedBox(height: 12),
            
            _buildContactCard(
              icon: Icons.chat,
              title: 'Live Chat',
              description: 'Chat with our support team',
              subtitle: 'Available 24/7',
              onTap: () => _showChatDialog(context),
            ),
            const SizedBox(height: 24),

            // Social Media & Resources
            const Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSocialCard(
                    icon: Icons.facebook,
                    title: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () => _launchURL('https://facebook.com/nutrilift'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSocialCard(
                    icon: Icons.camera_alt,
                    title: 'Instagram',
                    color: const Color(0xFFE4405F),
                    onTap: () => _launchURL('https://instagram.com/nutrilift'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildSocialCard(
                    icon: Icons.play_arrow,
                    title: 'YouTube',
                    color: const Color(0xFFFF0000),
                    onTap: () => _launchURL('https://youtube.com/nutrilift'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSocialCard(
                    icon: Icons.language,
                    title: 'Website',
                    color: const Color(0xFF2D2D2D),
                    onTap: () => _launchURL('https://nutrilift.com'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'NutriLift',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your personal fitness and nutrition companion',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
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
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String description,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Q: How do I track my meals?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('A: Go to the Nutrition tab and tap "Add Food" to log your meals.'),
              SizedBox(height: 16),
              Text(
                'Q: How do I start a workout?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('A: Visit the Workout tab, select a workout, and tap "Start Workout".'),
              SizedBox(height: 16),
              Text(
                'Q: Can I edit my profile?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('A: Yes! Tap "Profile View" in the menu or edit from the Home screen.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGettingStartedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Getting Started'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Complete Your Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Set up your personal information, fitness goals, and preferences.'),
              SizedBox(height: 12),
              Text(
                '2. Track Your Nutrition',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Log your meals and monitor your daily nutrition intake.'),
              SizedBox(height: 12),
              Text(
                '3. Start Working Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Choose from various workout programs tailored to your fitness level.'),
              SizedBox(height: 12),
              Text(
                '4. Join the Community',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Connect with others and participate in fitness challenges.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNutritionHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nutrition Tracking Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adding Foods:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Tap "Add Food" in any meal section\n• Search for foods in our database\n• Add custom foods if not found'),
              SizedBox(height: 12),
              Text(
                'Tracking Macros:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• View protein, carbs, and fats at the top\n• Tap any macro card for detailed breakdown\n• Adjust targets in the macro overview'),
              SizedBox(height: 12),
              Text(
                'Daily Navigation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Use arrows to navigate between dates\n• View past meals for reference\n• Plan future meals in advance'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text('Live chat feature is coming soon! For immediate assistance, please use email or phone support.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}