import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import '../services/dio_client.dart';

/// eSewa payment using in-app WebView with HTML form POST.
class EsewaWebViewImpl extends StatefulWidget {
  final Map<String, dynamic> params;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const EsewaWebViewImpl({
    super.key,
    required this.params,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<EsewaWebViewImpl> createState() => _EsewaWebViewImplState();
}

class _EsewaWebViewImplState extends State<EsewaWebViewImpl> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final p = widget.params;
    final esewaUrl = p['esewa_url'] as String;
    final successUrl = p['success_url'] as String;
    final failureUrl = p['failure_url'] as String;
    final html = _buildFormHtml(esewaUrl, p);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() => _loading = true);
          // Detect success redirect as soon as navigation starts
          if (url.contains('/pay/verify') || url.contains(successUrl) ||
              url.contains('/pay/success')) {
            _handlePaymentSuccess(url);
          } else if (url.contains('/pay/failure') || url.contains(failureUrl)) {
            widget.onFailure();
          }
        },
        onPageFinished: (url) {
          setState(() => _loading = false);
          // Also check on page finish in case onPageStarted missed it
          if (url.contains('/pay/verify') || url.contains('/pay/success')) {
            _handlePaymentSuccess(url);
          }
        },
        onNavigationRequest: (req) {
          final url = req.url;
          if (url.contains('/pay/failure') || url.contains(failureUrl)) {
            widget.onFailure();
            return NavigationDecision.prevent;
          }
          // Allow all other navigation (including eSewa pages)
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(html, baseUrl: esewaUrl);
  }

  /// Called when eSewa redirects to our success URL.
  Future<void> _handlePaymentSuccess(String url) async {
    if (_verifying) return;
    _verifying = true;
    setState(() => _loading = true);

    try {
      final uri = Uri.tryParse(url);
      final txnUuid = uri?.queryParameters['transaction_uuid'] ?? '';

      final successUrl = widget.params['success_url'] as String;
      final challengeIdMatch = RegExp(r'/challenges/([^/]+)/pay/').firstMatch(successUrl);
      final challengeId = challengeIdMatch?.group(1) ?? '';

      if (challengeId.isNotEmpty) {
        final dio = DioClient().dio;
        // Poll up to 5 times with 1s delay
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(seconds: 1));
          try {
            final resp = await dio.get(
              '/challenges/$challengeId/pay/success/',
              queryParameters: txnUuid.isNotEmpty ? {'transaction_uuid': txnUuid} : null,
            );
            if (resp.data['status'] == 'COMPLETE') {
              if (mounted) widget.onSuccess();
              return;
            }
          } catch (_) {}
        }
        // Polling exhausted — payment NOT confirmed, treat as failure
        if (mounted) {
          setState(() { _loading = false; _verifying = false; });
          widget.onFailure();
        }
        return;
      }

      // No challenge ID found — cannot verify, treat as failure
      if (mounted) {
        setState(() { _loading = false; _verifying = false; });
        widget.onFailure();
      }
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _verifying = false; });
        widget.onFailure();
      }
    }
  }

  String _buildFormHtml(String action, Map<String, dynamic> p) {
    String fields(String key) =>
        '<input type="hidden" name="$key" value="${p[key]}">';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { margin: 0; display: flex; align-items: center; justify-content: center;
           height: 100vh; background: #f5f5f5; font-family: sans-serif; }
    .loader { text-align: center; color: #60BB46; }
    .logo { font-size: 48px; font-weight: bold; color: #60BB46; }
  </style>
</head>
<body>
  <div class="loader">
    <div class="logo">eSewa</div>
    <p>Redirecting to payment...</p>
  </div>
  <form id="f" method="POST" action="$action">
    ${fields('amount')}
    ${fields('tax_amount')}
    ${fields('total_amount')}
    ${fields('transaction_uuid')}
    ${fields('product_code')}
    ${fields('product_service_charge')}
    ${fields('product_delivery_charge')}
    ${fields('success_url')}
    ${fields('failure_url')}
    ${fields('signed_field_names')}
    ${fields('signature')}
  </form>
  <script>document.getElementById('f').submit();</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading || _verifying)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    'https://esewa.com.np/common/images/esewa_logo.png',
                    width: 120,
                    errorBuilder: (_, __, ___) => const Text(
                      'eSewa',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF60BB46),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Color(0xFF60BB46)),
                  const SizedBox(height: 12),
                  Text(
                    _verifying ? 'Verifying payment...' : 'Loading payment...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
