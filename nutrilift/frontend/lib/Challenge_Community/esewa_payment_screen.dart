import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'challenge_api_service.dart';
import 'esewa_webview_stub.dart'
    if (dart.library.io) 'esewa_webview_impl.dart';

/// eSewa payment screen.
/// On Android: loads eSewa WebView form.
/// On Web: shows "use mobile app" message.
class EsewaPaymentScreen extends StatefulWidget {
  final ChallengeModel challenge;
  final VoidCallback onSuccess;

  const EsewaPaymentScreen({
    super.key,
    required this.challenge,
    required this.onSuccess,
  });

  @override
  State<EsewaPaymentScreen> createState() => _EsewaPaymentScreenState();
}

class _EsewaPaymentScreenState extends State<EsewaPaymentScreen> {
  final _service = ChallengeApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _params;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _initPayment();
    else setState(() => _loading = false);
  }

  Future<void> _initPayment() async {
    try {
      final params = await _service.initiateEsewaPayment(widget.challenge.id);
      // Backend simulation mode — payment already completed server-side
      if (params['status'] == 'SIMULATED_SUCCESS') {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Payment successful! You have joined the challenge.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }
      if (mounted) setState(() { _params = params; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.network(
          'https://esewa.com.np/common/images/esewa_logo.png',
          height: 28,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (_, __, ___) => const Text(
            'eSewa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        backgroundColor: const Color(0xFF60BB46),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: kIsWeb
          ? _buildWebMessage()
          : _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF60BB46)))
              : _error != null
                  ? _buildError()
                  : _EsewaWebView(
                      params: _params!,
                      onSuccess: () {
                        Navigator.pop(context);
                        widget.onSuccess();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Payment successful! You have joined the challenge.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      onFailure: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Payment cancelled or failed.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildWebMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF60BB46).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('e',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF60BB46))),
            ),
            const SizedBox(height: 24),
            const Text('eSewa Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'eSewa payment requires the mobile app.\nPlease run on an Android device to complete payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text('${widget.challenge.currency} ${widget.challenge.price.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF60BB46), foregroundColor: Colors.white),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () { setState(() { _error = null; _loading = true; }); _initPayment(); },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// WebView widget — only used on Android, defined in separate file
class _EsewaWebView extends StatelessWidget {
  final Map<String, dynamic> params;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const _EsewaWebView({required this.params, required this.onSuccess, required this.onFailure});

  @override
  Widget build(BuildContext context) {
    // Delegate to platform-specific implementation
    return EsewaWebViewImpl(params: params, onSuccess: onSuccess, onFailure: onFailure);
  }
}

/// Shows the payment bottom sheet before opening eSewa.
void showPaymentSheet(BuildContext context, ChallengeModel challenge, VoidCallback onSuccess) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(challenge: challenge, onSuccess: onSuccess),
  );
}

class _PaymentSheet extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback onSuccess;
  const _PaymentSheet({required this.challenge, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Join Premium Challenge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Entry Fee', style: TextStyle(color: Colors.grey)),
                    Text('${challenge.currency} ${challenge.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFE53935))),
                  ],
                ),
                if (challenge.prizeDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('🎁 ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(challenge.prizeDescription,
                        style: const TextStyle(fontSize: 13, color: Colors.brown))),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
            child: const Column(children: [
              Row(children: [Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18), SizedBox(width: 8), Text('Certificate of completion', style: TextStyle(fontSize: 13))]),
              SizedBox(height: 4),
              Row(children: [Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18), SizedBox(width: 8), Text('Achievement badge on profile', style: TextStyle(fontSize: 13))]),
              SizedBox(height: 4),
              Row(children: [Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18), SizedBox(width: 8), Text('Prize for top finishers', style: TextStyle(fontSize: 13))]),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EsewaPaymentScreen(challenge: challenge, onSuccess: onSuccess),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60BB46),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: const Text('e', style: TextStyle(color: Color(0xFF60BB46), fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 8),
                const Text('Pay with eSewa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
