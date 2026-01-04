import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'gender_screen.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/error_handler.dart';
import '../services/form_validator.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with ErrorHandlingMixin {
  bool _isLoading = false;
  
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Services
  final _authService = AuthService();
  final _formValidator = FormValidator();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await executeWithErrorHandling(
      () async {
        final registerRequest = RegisterRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );

        // Additional validation
        final validationErrors = registerRequest.validate();
        if (validationErrors.isNotEmpty) {
          throw ApiException(validationErrors.first);
        }

        // Check password confirmation
        if (_passwordController.text != _confirmPasswordController.text) {
          throw ApiException('Passwords do not match');
        }

        return await _authService.register(registerRequest);
      },
      successMessage: 'Account created successfully! Please complete your profile.',
    );

    setState(() {
      _isLoading = false;
    });

    if (result?.token != null) {
      // Navigate to GenderScreen on successful registration
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GenderScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset('assets/nutrilift_logo.png', height: 80),
                const SizedBox(height: 30),
                const Text(
                  'Sign Up To NutriLift',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Let's personalize your fitness with us",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                
                // Name field with real-time validation
                ValidatedTextFormField(
                  label: 'Full Name',
                  controller: _nameController,
                  validator: _formValidator.validateName,
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.person_outlined),
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 20),
                
                // Email field with real-time validation
                ValidatedTextFormField(
                  label: 'Email Address',
                  controller: _emailController,
                  validator: _formValidator.validateEmail,
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                
                // Password field with strength indicator
                PasswordFieldWithStrength(
                  label: 'Password',
                  controller: _passwordController,
                  enabled: !_isLoading,
                  showStrengthIndicator: true,
                ),
                const SizedBox(height: 20),
                
                // Confirm password field with real-time validation
                ValidatedTextFormField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  validator: (value) => _formValidator.validatePasswordConfirmation(
                    _passwordController.text,
                    value,
                  ),
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                
                // Sign up button with loading state
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 20),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: _isLoading ? null : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: _isLoading ? Colors.grey : Colors.red, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Social login section
                const Text(
                  'Or continue with',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialLoginButton(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      onTap: _isLoading ? null : () => _launchURL('https://www.facebook.com/login'),
                    ),
                    const SizedBox(width: 20),
                    _socialLoginButton(
                      icon: Icons.camera_alt,
                      color: const Color(0xFFE4405F),
                      onTap: _isLoading ? null : () => _launchURL('https://www.instagram.com/accounts/login'),
                    ),
                    const SizedBox(width: 20),
                    _socialLoginButton(
                      icon: Icons.business,
                      color: const Color(0xFF0A66C2),
                      onTap: _isLoading ? null : () => _launchURL('https://www.linkedin.com/login'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: onTap != null ? color : color.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: onTap != null ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}