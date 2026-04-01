import 'package:flutter/material.dart';

/// Web stub for EsewaWebViewImpl — WebView not supported on web.
class EsewaWebViewImpl extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const Center(child: Text('WebView not supported on web.'));
  }
}
