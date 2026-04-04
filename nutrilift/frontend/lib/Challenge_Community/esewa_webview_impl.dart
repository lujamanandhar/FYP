import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// eSewa payment using in-app WebView with HTML form POST.
/// This is the correct approach — eSewa's endpoint requires a form POST,
/// not a GET with query params.
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

    // Build HTML that auto-submits a POST form — the only correct way to hit eSewa
    final html = _buildFormHtml(esewaUrl, p);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (req) {
          final url = req.url;
          // Detect success redirect
          if (url.contains(successUrl) || url.contains('/pay/verify')) {
            widget.onSuccess();
            return NavigationDecision.prevent;
          }
          // Detect failure redirect
          if (url.contains(failureUrl) || url.contains('/pay/failure')) {
            widget.onFailure();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(html, baseUrl: esewaUrl);
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
        if (_loading)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // eSewa official logo from their CDN
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
                  const Text('Loading payment...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
