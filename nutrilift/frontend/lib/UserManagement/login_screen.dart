import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'main_navigation.dart';
import '../Admin/admin_main_navigation.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/error_handler.dart';
import '../services/form_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ErrorHandlingMixin {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _validationErrors;
  
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Services
  final _authService = AuthService();
  final _formValidator = FormValidator();

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
        showCenterToast(context, 'Could not launch $url');
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
      _validationErrors = null;
    });

    try {
      final loginRequest = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Validate request
      final validationErrors = loginRequest.validate();
      if (validationErrors.isNotEmpty) {
        throw ApiException(validationErrors.first);
      }

      final result = await _authService.login(loginRequest);
      
      if (result?.token != null) {
        // Get user profile to check if admin
        final profile = await _authService.getProfile();
        
        // Show success message
        showSuccessMessage('Welcome back! Login successful.');
        
        // Navigate based on user role
        if (mounted) {
          if (profile.isStaff) {
            // Admin user - go to admin interface
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminMainNavigation()),
            );
          } else {
            // Regular user - go to normal interface
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
            );
          }
        }
      }
    } on ApiException catch (e) {
      setState(() {
        _validationErrors = handleValidationErrors(e);
        if (_validationErrors == null) {
          _errorMessage = ErrorHandler().handleApiError(e);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _isLoading,
          loadingMessage: 'Signing you in...',
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Image.asset('assets/nutrilift_logo.png', height: 80),
                        const SizedBox(height: 24),
                        const Text(
                          'Sign In To NutriLift',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "Let's personalize your fitness with us",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        ValidatedTextFormField(
                          label: 'Email Address',
                          controller: _emailController,
                          validator: _formValidator.validateEmail,
                          enabled: !_isLoading,
                          prefixIcon: const Icon(Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          serverError: _validationErrors?['email']?.first,
                        ),
                        const SizedBox(height: 15),
                        ValidatedTextFormField(
                          label: 'Password',
                          controller: _passwordController,
                          validator: (value) => _formValidator.validateRequired(value, 'Password'),
                          enabled: !_isLoading,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          showValidationIcon: false,
                          serverError: _validationErrors?['password']?.first,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ));
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: const Text('Forgot Password?', style: TextStyle(color: Colors.red, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ServerValidationErrorDisplay(
                          errors: _validationErrors,
                          generalError: _errorMessage,
                          onDismiss: () => setState(() {
                            _validationErrors = null;
                            _errorMessage = null;
                          }),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: _isLoading ? null : () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => const SignupScreen()));
                              },
                              child: Text(
                                'Signup',
                                style: TextStyle(
                                  color: _isLoading ? Colors.grey : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}