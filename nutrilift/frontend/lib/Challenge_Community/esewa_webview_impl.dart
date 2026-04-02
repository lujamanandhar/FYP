import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Android WebView implementation for eSewa payment.
/// This file is only compiled on mobile (not web).
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // Force the page to fit mobile screen width
          // eSewa's page is designed for desktop, this scales it to fit
          _controller.runJavaScript('''
            (function() {
              var meta = document.querySelector('meta[name="viewport"]');
              if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
              }
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes';
              
              var style = document.createElement('style');
              style.innerHTML = \`
                html, body {
                  overflow-x: hidden !important;
                  width: 100% !important;
                  max-width: 100vw !important;
                }
                .container, .wrapper, form, .login-form, .payment-form {
                  max-width: 100% !important;
                  width: 100% !important;
                  padding: 8px !important;
                  margin: 0 auto !important;
                }
                .g-recaptcha {
                  transform: scale(0.77) !important;
                  transform-origin: left top !important;
                  margin-bottom: -40px !important;
                }
                .rc-anchor-normal {
                  width: 280px !important;
                }
              \`;
              document.head.appendChild(style);
            })();
          ''');
        },
        onNavigationRequest: (req) {
          final url = req.url;
          if (url.contains('/pay/success/') || url.contains('/pay/verify/')) {
            widget.onSuccess();
            return NavigationDecision.prevent;
          }
          if (url.contains('/pay/failure/')) {
            widget.onFailure();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    final p = widget.params;
    final url = p['esewa_url'] as String;
    return '''<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=3,user-scalable=yes">
<style>
body{display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:#f5f5f5;font-family:sans-serif;}
.c{background:white;padding:24px;border-radius:12px;text-align:center;}
.l{color:#60BB46;font-size:24px;font-weight:bold;}
</style></head>
<body><div class="c"><div class="l">eSewa</div><p>Redirecting...</p><p>NPR ${p['total_amount']}</p></div>
<form id="f" action="$url" method="POST">
<input type="hidden" name="amount" value="${p['amount']}">
<input type="hidden" name="tax_amount" value="${p['tax_amount']}">
<input type="hidden" name="total_amount" value="${p['total_amount']}">
<input type="hidden" name="transaction_uuid" value="${p['transaction_uuid']}">
<input type="hidden" name="product_code" value="${p['product_code']}">
<input type="hidden" name="product_service_charge" value="${p['product_service_charge']}">
<input type="hidden" name="product_delivery_charge" value="${p['product_delivery_charge']}">
<input type="hidden" name="success_url" value="${p['success_url']}">
<input type="hidden" name="failure_url" value="${p['failure_url']}">
<input type="hidden" name="signed_field_names" value="${p['signed_field_names']}">
<input type="hidden" name="signature" value="${p['signature']}">
</form>
<script>window.onload=function(){setTimeout(function(){document.getElementById('f').submit();},500);}</script>
</body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
