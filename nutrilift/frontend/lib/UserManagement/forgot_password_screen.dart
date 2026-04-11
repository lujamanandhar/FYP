import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'package:dio/dio.dart';
import '../services/app_config.dart';

Dio _plainDio() => Dio(BaseOptions(
  baseUrl: AppConfig.baseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: {'Content-Type': 'application/json'},
));

// ─── Step 1: Enter email ──────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) { setState(() => _error = 'Enter your email.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _plainDio().post('/auth/password-reset/', data: {'email': email});
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => EnterOtpScreen(email: email, prefillOtp: ''),
        ));
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.response?.data?['error'] ?? e.message;
      setState(() => _error = 'Error $status: $msg');
    } catch (e) {
      setState(() => _error = 'Failed. Is the server running at ${AppConfig.baseUrl}?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Forgot Password'), backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Center(child: Container(width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.lock_reset_rounded, color: Colors.red, size: 40))),
          const SizedBox(height: 20),
          const Center(child: Text('Reset Your Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Center(child: Text('Enter your registered email to receive a 6-digit code.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          const SizedBox(height: 32),
          if (_error != null) _errorBox(_error!),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDec('Email Address', Icons.email_outlined),
          ),
          const SizedBox(height: 24),
          _primaryBtn('Send Code', _loading, _send),
        ]),
      ),
    );
  }
}

// ─── Step 2: Enter 6-digit OTP ────────────────────────────────────────────────
class EnterOtpScreen extends StatefulWidget {
  final String email;
  final String prefillOtp;
  const EnterOtpScreen({Key? key, required this.email, required this.prefillOtp}) : super(key: key);
  @override
  State<EnterOtpScreen> createState() => _EnterOtpScreenState();
}

class _EnterOtpScreenState extends State<EnterOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _next() {
    if (_otp.length != 6) { setState(() => _error = 'Enter all 6 digits.'); return; }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NewPasswordScreen(email: widget.email, otp: _otp),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Enter Code'), backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Center(child: Container(width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined, color: Colors.green, size: 40))),
          const SizedBox(height: 20),
          const Center(child: Text('Enter Verification Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Center(child: Text('Check your Django terminal for the 6-digit code\nand enter it below.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          const SizedBox(height: 32),
          if (_error != null) _errorBox(_error!),
          // 6 individual digit boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) => SizedBox(
              width: 46, height: 56,
              child: TextField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                autofocus: i == 0,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                onChanged: (v) => _onDigitEntered(i, v),
              ),
            )),
          ),
          const SizedBox(height: 32),
          _primaryBtn('Verify Code', false, _next),
        ]),
      ),
    );
  }
}

// ─── Step 3: New password ─────────────────────────────────────────────────────
class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const NewPasswordScreen({Key? key, required this.email, required this.otp}) : super(key: key);
  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  @override
  void dispose() { _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _reset() async {
    if (_passCtrl.text.length < 8) { setState(() => _error = 'Password must be at least 8 characters.'); return; }
    if (_passCtrl.text != _confirmCtrl.text) { setState(() => _error = 'Passwords do not match.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await _plainDio().post('/auth/password-reset/confirm/', data: {
        'email': widget.email,
        'otp': widget.otp,
        'new_password': _passCtrl.text,
      });
      if (mounted) {
        showCenterToast(context, 'Password reset successful! Please log in.');
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['error'] ?? 'Invalid or expired code.');
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('New Password'), backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Center(child: Container(width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline_rounded, color: Colors.red, size: 40))),
          const SizedBox(height: 20),
          const Center(child: Text('Set New Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Center(child: Text('Choose a strong password with at least 8 characters.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          const SizedBox(height: 32),
          if (_error != null) _errorBox(_error!),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure1,
            onChanged: (_) => setState(() {}),
            decoration: _inputDec('New Password', Icons.lock_outlined).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _strengthBar(_passCtrl.text),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscure2,
            decoration: _inputDec('Confirm New Password', Icons.lock_outlined).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _primaryBtn('Reset Password', _loading, _reset),
        ]),
      ),
    );
  }

  Widget _strengthBar(String p) {
    if (p.isEmpty) return const SizedBox.shrink();
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.green];
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final idx = (s - 1).clamp(0, 3);
    return Row(children: [
      ...List.generate(4, (i) => Expanded(child: Container(
        height: 4, margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
        decoration: BoxDecoration(color: i < s ? colors[idx] : Colors.grey[200], borderRadius: BorderRadius.circular(2))))),
      const SizedBox(width: 10),
      Text(labels[idx], style: TextStyle(fontSize: 12, color: colors[idx], fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon, color: Colors.red),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
);

Widget _errorBox(String msg) => Container(
  padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
  child: Row(children: [
    const Icon(Icons.error_outline, color: Colors.red, size: 18), const SizedBox(width: 8),
    Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 13))),
  ]),
);

Widget _primaryBtn(String label, bool loading, VoidCallback onTap) => SizedBox(
  width: double.infinity, height: 52,
  child: ElevatedButton(
    onPressed: loading ? null : onTap,
    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
    child: loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ),
);
