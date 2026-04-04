import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/dio_client.dart';
import 'community_provider.dart';

const Color _kRed = Color(0xFFE53935);

/// Screen for creating a new community post with photo/video support.
/// Uses Image.memory (XFile.readAsBytes) so it works on both web and mobile.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

// Holds a picked media item with its pre-loaded bytes for preview.
class _MediaItem {
  final XFile file;
  final bool isVideo;
  final Uint8List? bytes; // null for videos (no thumbnail)

  const _MediaItem({required this.file, required this.isVideo, this.bytes});
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<_MediaItem> _selectedMedia = [];
  bool _isSubmitting = false;

  static const int _maxChars = 1000;
  static const int _maxMedia = 4;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _contentController.text.trim().isNotEmpty || _selectedMedia.isNotEmpty;

  Future<void> _pickImages() async {
    final remaining = _maxMedia - _selectedMedia.length;
    if (remaining <= 0) return;
    try {
      final picked = await ImagePicker().pickMultiImage(limit: remaining);
      if (picked.isEmpty) return;
      // Load bytes for each image so Image.memory works on web + mobile
      final items = await Future.wait(
        picked.take(remaining).map((f) async {
          final bytes = await f.readAsBytes();
          return _MediaItem(file: f, isVideo: false, bytes: bytes);
        }),
      );
      setState(() => _selectedMedia.addAll(items));
    } catch (e) {
      _showSnack('Could not pick images: $e');
    }
  }

  Future<void> _pickVideo() async {
    if (_selectedMedia.length >= _maxMedia) {
      _showSnack('Maximum $_maxMedia media items allowed');
      return;
    }
    try {
      final picked =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        // Videos: no thumbnail bytes, just show play icon
        setState(() => _selectedMedia
            .add(_MediaItem(file: picked, isVideo: true, bytes: null)));
      }
    } catch (e) {
      _showSnack('Could not pick video: $e');
    }
  }

  void _removeMedia(int index) =>
      setState(() => _selectedMedia.removeAt(index));

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_canPost || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final imageUrls = <String>[];
      final localBytes = <Uint8List>[];
      final videoUrls = <String>{};

      for (final item in _selectedMedia) {
        // Read bytes for videos too (needed for upload)
        final bytes = item.bytes ?? await item.file.readAsBytes();
        if (!item.isVideo) localBytes.add(bytes);

        final result = await _uploadMedia(item, bytes);
        imageUrls.add(result['url'] as String);
        if (result['is_video'] == true) {
          videoUrls.add(result['url'] as String);
        }
      }

      await context.read<CommunityProvider>().createPost(
            _contentController.text.trim(),
            imageUrls,
            localMediaBytes: localBytes,
            videoUrls: videoUrls,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Failed to post: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<Map<String, dynamic>> _uploadMedia(_MediaItem item, Uint8List bytes) async {
    final ext = item.file.name.contains('.') ? item.file.name.split('.').last.toLowerCase() : (item.isVideo ? 'mp4' : 'jpg');
    final fieldName = item.isVideo ? 'file' : 'image';

    // Compress images to save server space; videos upload as-is
    Uint8List uploadBytes = bytes;
    String uploadExt = ext;
    if (!item.isVideo) {
      final CompressFormat format = ext == 'png' ? CompressFormat.png : CompressFormat.jpeg;
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 75,       // 75% quality — good balance of size vs clarity
        format: format,
      );
      if (compressed != null && compressed.length < bytes.length) {
        uploadBytes = compressed;
        uploadExt = ext == 'png' ? 'png' : 'jpg';
      }
    }

    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(uploadBytes, filename: 'post.$uploadExt'),
    });
    final dio = DioClient().dio;
    final response = await dio.post('/upload/', data: formData);
    final data = response.data as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null) throw Exception('Upload failed');
    return {'url': url, 'is_video': data['is_video'] ?? false};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Create Post',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSubmitting
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : TextButton(
                    onPressed: _canPost ? _submit : null,
                    style: TextButton.styleFrom(
                      backgroundColor:
                          _canPost ? Colors.white : Colors.white38,
                      foregroundColor: _kRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                    ),
                    child: const Text('POST',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Text input ──────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLength: _maxChars,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style:
                          const TextStyle(fontSize: 16, height: 1.5),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle:
                            TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${_contentController.text.length}/$_maxChars',
                      style: TextStyle(
                        color:
                            _contentController.text.length >= _maxChars
                                ? _kRed
                                : Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Media previews ──────────────────────────────────────────
          if (_selectedMedia.isNotEmpty) ...[
            const Divider(height: 1),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                itemCount: _selectedMedia.length,
                itemBuilder: (context, i) {
                  final item = _selectedMedia[i];
                  return Stack(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[200],
                          border:
                              Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.isVideo
                              ? _VideoThumb()
                              : item.bytes != null
                                  ? Image.memory(
                                      item.bytes!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const _BrokenPlaceholder(),
                                    )
                                  : const _BrokenPlaceholder(),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeMedia(i),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: _kRed,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          // ── Bottom toolbar ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _MediaButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Photo',
                      onTap: _selectedMedia.length < _maxMedia
                          ? _pickImages
                          : null,
                    ),
                    const SizedBox(width: 4),
                    _MediaButton(
                      icon: Icons.videocam_outlined,
                      label: 'Video',
                      onTap: _selectedMedia.length < _maxMedia
                          ? _pickVideo
                          : null,
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedMedia.length}/$_maxMedia',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _VideoThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black87),
          const Center(
            child: Icon(Icons.play_circle_fill,
                color: Colors.white, size: 36),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('VIDEO',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
}

class _BrokenPlaceholder extends StatelessWidget {
  const _BrokenPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 32, color: Colors.grey),
        ),
      );
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MediaButton(
      {required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: enabled ? _kRed : Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled ? _kRed : Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
