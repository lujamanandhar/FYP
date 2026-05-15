import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'main_navigation.dart';
import '../Admin/admin_main_navigation.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/error_handler.dart';
import '../services/form_validator.dart';

const _kRed = Color(0xFFE53935);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, ErrorHandlingMixin {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _validationErrors;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _formValidator = FormValidator();


  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) { _fadeCtrl.forward(); _slideCtrl.forward(); }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; _validationErrors = null; });
    try {
      final loginRequest = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final validationErrors = loginRequest.validate();
      if (validationErrors.isNotEmpty) throw ApiException(validationErrors.first);
      final result = await _authService.login(loginRequest);
      if (result?.token != null) {
        final profile = await _authService.getProfile();
        showSuccessMessage('Welcome back!');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => profile.isStaff
                  ? const AdminMainNavigation()
                  : const MainNavigation(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      setState(() {
        _validationErrors = handleValidationErrors(e);
        if (_validationErrors == null) _errorMessage = ErrorHandler().handleApiError(e);
      });
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset('assets/nutrilift_logo.png', fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: _kRed,
                                        child: const Icon(Icons.fitness_center, color: Colors.white, size: 40),
                                      )),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('NUTRILIFT',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 3)),
                              const SizedBox(height: 4),
                              const Text('Your fitness companion',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text('Welcome back',
                                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        const SizedBox(width: 8),
                                        CustomPaint(
                                          size: const Size(26, 26),
                                          painter: _NamastePainter(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Sign in to continue', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                                    const SizedBox(height: 24),
                                    ValidatedTextFormField(
                                      label: 'Email Address',
                                      controller: _emailController,
                                      validator: _formValidator.validateEmail,
                                      enabled: !_isLoading,
                                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                      keyboardType: TextInputType.emailAddress,
                                      serverError: _validationErrors?['email']?.first,
                                    ),
                                    const SizedBox(height: 16),
                                    ValidatedTextFormField(
                                      label: 'Password',
                                      controller: _passwordController,
                                      validator: (v) => _formValidator.validateRequired(v, 'Password'),
                                      enabled: !_isLoading,
                                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      showValidationIcon: false,
                                      serverError: _validationErrors?['password']?.first,
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading ? null : () => Navigator.push(context,
                                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                        child: const Text('Forgot Password?',
                                            style: TextStyle(color: _kRed, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_errorMessage != null)
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.red[200]!),
                                        ),
                                        child: Row(children: [
                                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                                        ]),
                                      ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _kRed,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(width: 22, height: 22,
                                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                            : const Text('Sign In',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                GestureDetector(
                                  onTap: _isLoading ? null : () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                                  child: const Text('Sign Up',
                                      style: TextStyle(color: _kRed, fontWeight: FontWeight.w700, fontSize: 14)),
                                ),
                              ]),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NamastePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Draw two simplified praying hands as mirrored triangular shapes

    // Left hand
    final leftHand = Path()
      ..moveTo(cx, cy - size.height * 0.35)
      ..lineTo(cx - size.width * 0.32, cy + size.height * 0.35)
      ..lineTo(cx - size.width * 0.05, cy + size.height * 0.35)
      ..lineTo(cx, cy - size.height * 0.1)
      ..close();

    // Right hand
    final rightHand = Path()
      ..moveTo(cx, cy - size.height * 0.35)
      ..lineTo(cx + size.width * 0.32, cy + size.height * 0.35)
      ..lineTo(cx + size.width * 0.05, cy + size.height * 0.35)
      ..lineTo(cx, cy - size.height * 0.1)
      ..close();

    // Wrist/base
    final base = Path()
      ..moveTo(cx - size.width * 0.2, cy + size.height * 0.35)
      ..lineTo(cx + size.width * 0.2, cy + size.height * 0.35)
      ..lineTo(cx + size.width * 0.15, cy + size.height * 0.48)
      ..lineTo(cx - size.width * 0.15, cy + size.height * 0.48)
      ..close();

    canvas.drawPath(leftHand, paint);
    canvas.drawPath(rightHand, paint);
    canvas.drawPath(base, paint);

    // Small dot at top (fingertips meeting)
    canvas.drawCircle(Offset(cx, cy - size.height * 0.38), size.width * 0.06, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
