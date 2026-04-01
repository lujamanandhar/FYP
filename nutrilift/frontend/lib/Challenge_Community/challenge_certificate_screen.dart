import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'challenge_api_service.dart';

class ChallengeCertificateScreen extends StatefulWidget {
  final ChallengeCompletionModel completion;
  const ChallengeCertificateScreen({super.key, required this.completion});

  @override
  State<ChallengeCertificateScreen> createState() => _ChallengeCertificateScreenState();
}

class _ChallengeCertificateScreenState extends State<ChallengeCertificateScreen> {
  final GlobalKey _certKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareCertificate() async {
    setState(() => _sharing = true);
    try {
      final boundary = _certKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/nutrilift_certificate.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🏆 I completed the ${widget.completion.challengeName} challenge on NutriLift! Certificate #${widget.completion.certificateNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Certificate', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.share, color: Colors.white),
            onPressed: _sharing ? null : _shareCertificate,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              RepaintBoundary(
                key: _certKey,
                child: _CertificateCard(completion: widget.completion),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sharing ? null : _shareCertificate,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Certificate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final ChallengeCompletionModel completion;
  const _CertificateCard({required this.completion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner decorations
          Positioned(top: 8, left: 8, child: _cornerDeco()),
          Positioned(top: 8, right: 8, child: _cornerDeco()),
          Positioned(bottom: 8, left: 8, child: _cornerDeco()),
          Positioned(bottom: 8, right: 8, child: _cornerDeco()),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center, color: Color(0xFFE53935), size: 20),
                      SizedBox(width: 8),
                      Text('NUTRILIFT',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 3,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Certificate title
                const Text(
                  'CERTIFICATE OF ACHIEVEMENT',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 13,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color(0xFFFFD700).withOpacity(0.4)),
                const SizedBox(height: 20),

                // "This certifies that"
                const Text(
                  'This certifies that',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),

                // Challenge name
                Text(
                  completion.challengeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'has been successfully completed',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('Days', '${completion.daysTaken}'),
                    _divider(),
                    _statItem('Rank', completion.rank != null ? '#${completion.rank}' : '—'),
                    _divider(),
                    _statItem('Participants', '${completion.totalParticipants}'),
                  ],
                ),
                const SizedBox(height: 20),

                // Prize description
                if (completion.prizeDescription.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎁', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            completion.prizeDescription,
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Container(height: 1, color: const Color(0xFFFFD700).withOpacity(0.4)),
                const SizedBox(height: 12),

                // Certificate number + date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${completion.certificateNumber}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    Text(
                      '${completion.completedAt.day}/${completion.completedAt.month}/${completion.completedAt.year}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white24);

  Widget _cornerDeco() => Container(
        width: 16, height: 16,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.6), width: 2),
            left: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.6), width: 2),
          ),
        ),
      );
}
