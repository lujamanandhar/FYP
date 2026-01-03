import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'signup_screen.dart';
import 'main_navigation.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Services
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loginRequest = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Validate request
      final validationErrors = loginRequest.validate();
      if (validationErrors.isNotEmpty) {
        setState(() {
          _errorMessage = validationErrors.first;
          _isLoading = false;
        });
        return;
      }

      final response = await _authService.login(loginRequest);
      
      if (response.token != null) {
        // Navigate to MainNavigation on successful login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        if (e.isUnauthorized()) {
          _errorMessage = 'Invalid email or password. Please try again.';
        } else if (e.isValidationError()) {
          _errorMessage = e.getFieldError('email') ?? 
                         e.getFieldError('password') ?? 
                         e.message;
        } else if (e.isNetworkError()) {
          _errorMessage = 'Network error. Please check your connection and try again.';
        } else {
          _errorMessage = e.message;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/nutrilift_logo.png', height: 80),
                const SizedBox(height: 30),
                const Text(
                  'Sign In To NutriLift',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Let's personalize your fitness with us",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                
                // Error message display
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
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
                      : const Text('Log In'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: _isLoading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      child: Text(
                        'Signup',
                        style: TextStyle(
                          color: _isLoading ? Colors.grey : Colors.red, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
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