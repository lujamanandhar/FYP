import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';

enum LegalType { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalType type;
  const LegalScreen({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == LegalType.privacy;
    return NutriLiftScaffold(
      title: isPrivacy ? 'Privacy Policy' : 'Terms of Service',
      showBackButton: true,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isPrivacy ? Icons.privacy_tip_outlined : Icons.description_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPrivacy ? 'Privacy Policy' : 'Terms of Service',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: April 2, 2026',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (isPrivacy) ..._privacySections() else ..._termsSections(),

            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 NutriLift. All rights reserved.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _privacySections() => [
        _section('1. Information We Collect',
            'We collect information you provide directly to us when you create an account, including your name, email address, date of birth, height, weight, and fitness goals.\n\nWe also collect data you log within the app such as workout sessions, nutrition intake, body measurements, and activity data.'),
        _section('2. How We Use Your Information',
            'We use the information we collect to:\n• Provide, maintain, and improve our services\n• Personalize your fitness and nutrition recommendations\n• Track your progress and generate insights\n• Send you reminders and notifications (with your permission)\n• Respond to your comments and questions'),
        _section('3. Data Storage & Security',
            'Your data is stored securely on our servers. We implement industry-standard encryption and security measures to protect your personal information. We do not sell your personal data to third parties.'),
        _section('4. Data Sharing',
            'We do not share your personal information with third parties except:\n• With your explicit consent\n• To comply with legal obligations\n• To protect the rights and safety of our users\n• With service providers who assist in our operations under strict confidentiality agreements'),
        _section('5. Your Rights',
            'You have the right to:\n• Access your personal data\n• Correct inaccurate data\n• Request deletion of your data\n• Export your data\n• Withdraw consent at any time\n\nTo exercise these rights, contact us through the Help & Support section.'),
        _section('6. Cookies & Analytics',
            'We use analytics tools to understand how users interact with our app. This helps us improve the user experience. No personally identifiable information is shared with analytics providers.'),
        _section('7. Children\'s Privacy',
            'NutriLift is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.'),
        _section('8. Changes to This Policy',
            'We may update this Privacy Policy from time to time. We will notify you of any significant changes through the app or via email. Continued use of the app after changes constitutes acceptance of the updated policy.'),
        _section('9. Contact Us',
            'If you have questions about this Privacy Policy, please contact us through the Help & Support section in the app.'),
      ];

  List<Widget> _termsSections() => [
        _section('1. Acceptance of Terms',
            'By downloading, installing, or using NutriLift, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.'),
        _section('2. Use of the App',
            'NutriLift is a fitness and nutrition tracking application. You agree to use the app only for lawful purposes and in accordance with these terms. You must be at least 13 years old to use this app.'),
        _section('3. User Accounts',
            'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. We reserve the right to terminate accounts that violate these terms.'),
        _section('4. Health Disclaimer',
            'NutriLift provides general fitness and nutrition information for educational purposes only. The content is not a substitute for professional medical advice, diagnosis, or treatment. Always consult a qualified healthcare provider before starting any fitness or diet program.'),
        _section('5. User Content',
            'You retain ownership of content you create within the app. By using NutriLift, you grant us a non-exclusive license to use your anonymized, aggregated data to improve our services.'),
        _section('6. Prohibited Activities',
            'You agree not to:\n• Use the app for any unlawful purpose\n• Attempt to gain unauthorized access to our systems\n• Transmit harmful, offensive, or misleading content\n• Reverse engineer or attempt to extract source code\n• Use automated tools to access the app'),
        _section('7. Intellectual Property',
            'All content, features, and functionality of NutriLift — including but not limited to text, graphics, logos, and software — are owned by NutriLift and protected by intellectual property laws.'),
        _section('8. Limitation of Liability',
            'NutriLift is provided "as is" without warranties of any kind. We are not liable for any indirect, incidental, or consequential damages arising from your use of the app.'),
        _section('9. Termination',
            'We reserve the right to suspend or terminate your access to NutriLift at any time for violation of these terms or for any other reason at our sole discretion.'),
        _section('10. Changes to Terms',
            'We may modify these Terms of Service at any time. We will notify you of material changes through the app. Continued use after changes constitutes acceptance of the updated terms.'),
        _section('11. Governing Law',
            'These terms are governed by the laws of Nepal. Any disputes arising from these terms shall be resolved in the courts of Kathmandu, Nepal.'),
      ];

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                body,
                style: const TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.6),
              ),
            ),
          ],
        ),
      );
}
