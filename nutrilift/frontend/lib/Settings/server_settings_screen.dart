import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/app_config.dart';
import '../widgets/nutrilift_header.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: AppConfig.currentHost);
    _portController = TextEditingController(text: AppConfig.currentPort.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (host.isEmpty) {
      setState(() { _testResult = 'Please enter a host IP or address.'; _testSuccess = false; });
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      setState(() { _testResult = 'Port must be a number between 1 and 65535.'; _testSuccess = false; });
      return;
    }

    setState(() { _testing = true; _testResult = null; _saved = false; });

    try {
      final url = Uri.parse('http://$host:$port/api/auth/');
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        setState(() {
          _testSuccess = true;
          _testResult = 'Connected successfully to $host:$port';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testResult = 'Server responded with status ${response.statusCode}. Check the URL.';
        });
      }
    } on Exception catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Could not connect: ${_friendlyError(e)}';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (host.isEmpty) {
      _showError('Host cannot be empty.');
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      _showError('Port must be a number between 1 and 65535.');
      return;
    }

    await AppConfig.setServer(host, port);
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server set to $host:$port — restart the app to apply.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _reset() async {
    await AppConfig.resetToDefault();
    if (mounted) {
      setState(() {
        _hostController.text = AppConfig.currentHost;
        _portController.text = AppConfig.currentPort.toString();
        _testResult = null;
        _saved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default server settings.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String _friendlyError(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('timed out')) return 'Connection timed out. Is the server running?';
    if (msg.contains('refused') || msg.contains('connection refused')) return 'Connection refused. Check IP and port.';
    if (msg.contains('network') || msg.contains('socket')) return 'Network error. Are you on the same WiFi?';
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Server Settings',
      showBackButton: true,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Set the IP address of the machine running the Django backend. '
                      'Your phone and the server must be on the same network.',
                      style: TextStyle(color: Colors.blue[800], fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current URL preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current API URL', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(AppConfig.baseUrl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Host field
            const Text('Server Host / IP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _hostController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.1.100 or 10.0.2.2',
                prefixIcon: const Icon(Icons.dns_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onChanged: (_) => setState(() { _testResult = null; _saved = false; }),
            ),
            const SizedBox(height: 16),

            // Port field
            const Text('Port', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '8000',
                prefixIcon: const Icon(Icons.settings_ethernet_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onChanged: (_) => setState(() { _testResult = null; _saved = false; }),
            ),
            const SizedBox(height: 24),

            // Test result
            if (_testResult != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _testSuccess ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _testSuccess ? Colors.green[300]! : Colors.red[300]!),
                ),
                child: Row(children: [
                  Icon(
                    _testSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    color: _testSuccess ? Colors.green[700] : Colors.red[700],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testSuccess ? Colors.green[800] : Colors.red[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ]),
              ),

            // Test connection button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testing ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_find_outlined),
                label: Text(_testing ? 'Testing...' : 'Test Connection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_saved ? Icons.check_rounded : Icons.save_outlined),
                label: Text(_saved ? 'Saved!' : 'Save Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saved ? Colors.green : const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Reset button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Reset to Default'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
            ),

            const SizedBox(height: 24),
            // Quick reference
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Reference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _refRow('Android Emulator', '10.0.2.2'),
                  _refRow('PC Hotspot', '192.168.137.1'),
                  _refRow('Same WiFi', 'Your PC\'s IPv4 address'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _refRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    ]),
  );
}
