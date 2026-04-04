import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/app_config.dart';
import '../services/dio_client.dart';
import '../services/dashboard_service.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_api_service.dart';
import 'challenge_provider.dart';
import 'day_completion_overlay.dart';

class ActiveChallengeScreen extends StatefulWidget {
  final String? challengeId;
  const ActiveChallengeScreen({super.key, this.challengeId});

  @override
  State<ActiveChallengeScreen> createState() => _ActiveChallengeScreenState();
}

class _ActiveChallengeScreenState extends State<ActiveChallengeScreen> {
  bool _isUploading = false;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChallengeProvider>();
      if (provider.challenges.isEmpty) {
        provider.fetchChallenges().then((_) => _fetchLog());
      } else {
        _fetchLog();
      }
    });
  }

  Future<void> _loadStreak() async {
    try {
      final dashboardService = DashboardService();
      final streak = await dashboardService.getCurrentStreak();
      if (mounted) {
        setState(() {
          _currentStreak = streak;
        });
      }
    } catch (e) {
      print('Error loading streak: $e');
    }
  }

  void _fetchLog() {
    final id = _resolveId();
    if (id != null) {
      context.read<ChallengeProvider>().fetchTodayLog(id);
    }
  }

  String? _resolveId() {
    if (widget.challengeId != null) return widget.challengeId;
    final provider = context.read<ChallengeProvider>();
    try {
      return provider.challenges.firstWhere((c) => c.isJoined).id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickMedia(BuildContext ctx, String challengeId) async {
    final picker = ImagePicker();

    // On web, camera is not supported — only gallery/file picker works
    String? choice;
    if (kIsWeb) {
      choice = await showModalBottomSheet<String>(
        context: ctx,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Photo / Video'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
            ],
          ),
        ),
      );
    } else {
      choice = await showModalBottomSheet<String>(
        context: ctx,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(ctx, 'photo'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () => Navigator.pop(ctx, 'video'),
              ),
            ],
          ),
        ),
      );
    }

    if (choice == null || !mounted) return;

    bool isVideo = choice == 'video';
    XFile? file;
    if (kIsWeb) {
      // On web, use gallery for both images and videos
      file = await picker.pickMedia();
    } else {
      file = isVideo
          ? await picker.pickVideo(source: ImageSource.camera)
          : choice == 'photo'
              ? await picker.pickImage(source: ImageSource.camera)
              : await picker.pickImage(source: ImageSource.gallery);
    }

    if (file == null || !mounted) return;

    // Detect video by mime type on web
    if (kIsWeb) {
      final mime = file.mimeType ?? '';
      isVideo = mime.startsWith('video/');
    }

    setState(() => _isUploading = true);
    try {
      final dio = DioClient().dio;
      MultipartFile multipart;
      if (kIsWeb) {
        // On web, file.path is a blob URL — must use bytes
        final bytes = await file.readAsBytes();
        multipart = MultipartFile.fromBytes(bytes, filename: file.name);
      } else {
        multipart = await MultipartFile.fromFile(file.path, filename: file.name);
      }
      final formData = FormData.fromMap({'file': multipart});
      final response = await dio.post('/upload/', data: formData);
      final url = (response.data['url'] ?? response.data['file_url']) as String;
      final serverIsVideo = response.data['is_video'] as bool? ?? isVideo;
      if (mounted) {
        await context.read<ChallengeProvider>().attachMedia(challengeId, url, serverIsVideo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return NutriLiftScaffold(
            streakCount: _currentStreak,
            title: 'Active Challenge',
            showBackButton: true,
            showDrawer: false,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        ChallengeModel? challenge;
        if (widget.challengeId != null) {
          try {
            challenge = provider.challenges.firstWhere((c) => c.id == widget.challengeId);
          } catch (_) {}
        } else {
          try {
            challenge = provider.challenges.firstWhere((c) => c.isJoined);
          } catch (_) {}
        }

        if (challenge == null) {
          return NutriLiftScaffold(
            streakCount: _currentStreak,
            title: 'Active Challenge',
            showBackButton: true,
            showDrawer: false,
            body: const Center(
              child: Text('No active challenge found',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
          );
        }

        final challengeId = challenge.id;
        final log = provider.todayLog;

        return NutriLiftScaffold(
          streakCount: _currentStreak,
          title: challenge.name,
          showBackButton: true,
          showDrawer: false,
          body: provider.isDailyLogLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null && log == null
                  ? _ErrorRetry(
                      message: provider.error!,
                      onRetry: () => provider.fetchTodayLog(challengeId),
                    )
                  : _DailyLogBody(
                      challenge: challenge,
                      log: log,
                      isUploading: _isUploading,
                      onPickMedia: () => _pickMedia(context, challengeId),
                      onToggleTask: (i) => provider.toggleTask(challengeId, i),
                      onRemoveMedia: (i) => provider.removeMedia(challengeId, i),
                      onComplete: () async {
                        await provider.completeDailyLog(challengeId);
                        if (!context.mounted) return;
                        // Re-resolve challenge with updated progress from provider
                        final updatedChallenge = provider.challenges.firstWhere(
                          (c) => c.id == challengeId,
                          orElse: () => challenge!,
                        );
                        final completedLog = provider.todayLog;
                        if (completedLog != null) {
                          // Collect non-video image URLs for sharing
                          final imageUrls = completedLog.mediaUrls
                              .where((m) => !m.isVideo)
                              .map((m) => m.url)
                              .toList();
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => DayCompletionOverlay(
                              dayNumber: completedLog.dayNumber,
                              challengeName: updatedChallenge.name,
                              challengeId: challengeId,
                              firstMediaUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
                              imageUrls: imageUrls,
                            ),
                          );
                        }
                        // Fetch next day's log so day number + tasks refresh
                        if (context.mounted) {
                          await provider.fetchTodayLog(challengeId);
                        }
                      },
                    ),
        );
      },
    );
  }
}

// ── Daily Log Body ────────────────────────────────────────────────────────

class _DailyLogBody extends StatelessWidget {
  final ChallengeModel challenge;
  final ChallengeDailyLogModel? log;
  final bool isUploading;
  final VoidCallback onPickMedia;
  final void Function(int) onToggleTask;
  final void Function(int) onRemoveMedia;
  final VoidCallback onComplete;

  const _DailyLogBody({
    required this.challenge,
    required this.log,
    required this.isUploading,
    required this.onPickMedia,
    required this.onToggleTask,
    required this.onRemoveMedia,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final dayNum = log?.dayNumber ?? 1;
    final tasks = log?.taskItems ?? [];
    final media = log?.mediaUrls ?? [];
    final allDone = log?.allTasksComplete ?? false;
    final alreadyComplete = log?.isComplete ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Challenge name + description + progress ────────────────
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description always visible
                  Text(
                    challenge.description,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Day $dayNum',
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: challenge.goalValue > 0
                          ? (challenge.participantProgress / challenge.goalValue).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFE53935)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${challenge.participantProgress.toStringAsFixed(0)} / ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '${((challenge.goalValue > 0 ? challenge.participantProgress / challenge.goalValue : 0).clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Day heading ────────────────────────────────────────────
          if (alreadyComplete)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Day $dayNum Completed! ✅',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2E7D32))),
                        const Text('Come back tomorrow for the next day.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Task checklist ─────────────────────────────────────────
          if (tasks.isNotEmpty) ...[
            const Text('Tasks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            ...tasks.asMap().entries.map((entry) {
              final i = entry.key;
              final task = entry.value;
              return CheckboxListTile(
                value: task.completed,
                onChanged: alreadyComplete ? null : (_) => onToggleTask(i),
                title: Text(task.label),
                activeColor: const Color(0xFFE53935),
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 16),
          ],

          // ── Media attachment ───────────────────────────────────────
          Row(
            children: [
              const Text('Media', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              if (!alreadyComplete)
                isUploading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.add_a_photo_outlined),
                        onPressed: onPickMedia,
                        tooltip: 'Attach photo/video',
                      ),
            ],
          ),
          if (media.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final item = media[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.isVideo
                            ? Container(
                                width: 80, height: 80,
                                color: Colors.black87,
                                child: const Icon(Icons.play_circle_outline,
                                    color: Colors.white, size: 36),
                              )
                            : Image.network(AppConfig.resolveMediaUrl(item.url),
                                width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      if (!alreadyComplete)
                        Positioned(
                          top: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => onRemoveMedia(i),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // ── Complete Day button ────────────────────────────────────
          if (!alreadyComplete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: allDone ? onComplete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  'Complete Day $dayNum',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Error + Retry ─────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
