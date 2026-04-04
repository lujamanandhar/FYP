import 'package:flutter/material.dart';
import 'dart:math' as math;
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
                        const SizedBox(height: 24),
                        const Text('Or continue with', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        _googleSignInButton(),
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

  Widget _googleSignInButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In coming soon')),
        );
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFBBBBBB), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _GoogleLogo(size: 26),
          SizedBox(width: 14),
          Text(
            'Sign in with Google',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({Key? key, this.size = 40}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _red    = Color(0xFFEA4335);
  static const _blue   = Color(0xFF4285F4);
  static const _yellow = Color(0xFFFBBC05);
  static const _green  = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    final sw = r * 0.34;
    final ir = r - sw / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: ir);
    paint.color = _red;
    canvas.drawArc(arcRect, _r(-50), _r(97), false, paint);
    paint.color = _yellow;
    canvas.drawArc(arcRect, _r(47), _r(68), false, paint);
    paint.color = _green;
    canvas.drawArc(arcRect, _r(115), _r(115), false, paint);
    paint.color = _blue;
    canvas.drawArc(arcRect, _r(230), _r(80), false, paint);
    final barH = sw * 0.85;
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - barH / 2, cx + ir + sw / 2, cy + barH / 2),
      Paint()..color = _blue..style = PaintingStyle.fill,
    );
  }

  double _r(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}