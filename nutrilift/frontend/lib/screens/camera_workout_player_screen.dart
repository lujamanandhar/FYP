import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'guided_workout_plans.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

/// Per-exercise configuration (sets + reps) set by the user on the setup screen.
class CameraExerciseConfig {
  final GuidedExercise exercise;
  final int sets;
  final int reps;
  CameraExerciseConfig({required this.exercise, required this.sets, required this.reps});
}

// ─────────────────────────────────────────────────────────────────────────────
// Rep detection helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _RepPhase { up, down }

double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final r = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
  double d = r.abs() * 180 / pi;
  if (d > 180) d = 360 - d;
  return d;
}

/// Returns average likelihood of a list of landmarks. Returns null if any is null.
double? _avgConf(List<PoseLandmark?> lms) {
  if (lms.any((l) => l == null)) return null;
  return lms.fold<double>(0, (s, l) => s + l!.likelihood) / lms.length;
}

/// Minimum confidence to count a rep — prevents random body movement from triggering.
const double _kMinConf = 0.55;

/// Minimum milliseconds between reps — prevents double-counting.
const int _kMinRepMs = 700;

typedef _Detector = bool Function(
  Map<PoseLandmarkType, PoseLandmark> lm,
  _RepPhase phase,
  void Function(_RepPhase) setPhase,
);

// Bicep Curl: arm extended (>150°) → curled (<55°) = 1 rep
// Uses whichever arm has higher confidence.
bool _bicepCurlDetect(Map<PoseLandmarkType, PoseLandmark> lm, _RepPhase phase, void Function(_RepPhase) set) {
  final ls = lm[PoseLandmarkType.leftShoulder];
  final le = lm[PoseLandmarkType.leftElbow];
  final lw = lm[PoseLandmarkType.leftWrist];
  final rs = lm[PoseLandmarkType.rightShoulder];
  final re = lm[PoseLandmarkType.rightElbow];
  final rw = lm[PoseLandmarkType.rightWrist];

  final lConf = _avgConf([ls, le, lw]);
  final rConf = _avgConf([rs, re, rw]);
  final bestConf = (lConf ?? 0) >= (rConf ?? 0) ? lConf : rConf;
  if (bestConf == null || bestConf < _kMinConf) return false;

  final double angle;
  if ((lConf ?? 0) >= (rConf ?? 0) && ls != null && le != null && lw != null) {
    angle = _angle(ls, le, lw);
  } else if (rs != null && re != null && rw != null) {
    angle = _angle(rs, re, rw);
  } else {
    return false;
  }

  // Extended position (arm down) → ready to curl
  if (angle > 150 && phase == _RepPhase.up) {
    set(_RepPhase.down);
    return false;
  }
  // Fully curled → rep complete
  if (angle < 55 && phase == _RepPhase.down) {
    set(_RepPhase.up);
    return true;
  }
  return false;
}

// Hammer Curl: same motion as bicep curl — neutral grip doesn't change elbow angle detection
bool _hammerCurlDetect(Map<PoseLandmarkType, PoseLandmark> lm, _RepPhase phase, void Function(_RepPhase) set) {
  return _bicepCurlDetect(lm, phase, set);
}

// Cable Curl: same elbow angle detection — cable vs dumbbell doesn't change the motion
bool _cableCurlDetect(Map<PoseLandmarkType, PoseLandmark> lm, _RepPhase phase, void Function(_RepPhase) set) {
  return _bicepCurlDetect(lm, phase, set);
}

// Push-up: elbow angle < 90° = down, > 160° = up = rep complete
bool _pushUpDetect(Map<PoseLandmarkType, PoseLandmark> lm, _RepPhase phase, void Function(_RepPhase) set) {
  final s = lm[PoseLandmarkType.leftShoulder];
  final e = lm[PoseLandmarkType.leftElbow];
  final w = lm[PoseLandmarkType.leftWrist];
  if (_avgConf([s, e, w]) == null || _avgConf([s, e, w])! < _kMinConf) return false;
  final a = _angle(s!, e!, w!);
  if (a < 90 && phase == _RepPhase.up) { set(_RepPhase.down); return false; }
  if (a > 160 && phase == _RepPhase.down) { set(_RepPhase.up); return true; }
  return false;
}

_Detector _detectorFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('hammer curl')) return _hammerCurlDetect;
  if (n.contains('cable curl')) return _cableCurlDetect;
  if (n.contains('bicep curl') || n.contains('dumbbell curl')) return _bicepCurlDetect;
  if (n.contains('push')) return _pushUpDetect;
  return (lm, phase, set) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CameraWorkoutPlayerScreen extends StatefulWidget {
  final GuidedPlan plan;
  final List<CameraExerciseConfig> exerciseConfigs;

  const CameraWorkoutPlayerScreen({
    Key? key,
    required this.plan,
    required this.exerciseConfigs,
  }) : super(key: key);

  @override
  State<CameraWorkoutPlayerScreen> createState() => _CameraWorkoutPlayerScreenState();
}

class _CameraWorkoutPlayerScreenState extends State<CameraWorkoutPlayerScreen>
    with TickerProviderStateMixin {

  // ── Navigation ──────────────────────────────────────────────────────────────
  int _exerciseIdx = 0;
  int _setNum = 1; // 1-based

  // ── Rep counting ────────────────────────────────────────────────────────────
  int _reps = 0;
  _RepPhase _repPhase = _RepPhase.up;
  DateTime? _lastRepTime;
  double _confidence = 0.0;
  bool _bodyLost = false;
  int _lostFrames = 0;

  // ── State flags ─────────────────────────────────────────────────────────────
  /// True when the current set is done — shows "Next Set" / "Next Exercise" button
  bool _setComplete = false;
  bool _workoutDone = false;

  // ── Camera ──────────────────────────────────────────────────────────────────
  CameraController? _ctrl;
  bool _isFront = false;
  bool _isSwitching = false;

  // ── ML Kit ──────────────────────────────────────────────────────────────────
  PoseDetector? _detector;
  bool _processing = false;
  Pose? _pose;
  Size? _imgSize;

  // ── Rotation ────────────────────────────────────────────────────────────────
  int _rotIdx = 1;
  static const _rotations = [
    InputImageRotation.rotation0deg, InputImageRotation.rotation90deg,
    InputImageRotation.rotation180deg, InputImageRotation.rotation270deg,
  ];

  // ── Flash animation ─────────────────────────────────────────────────────────
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;

  // ── Stopwatch ───────────────────────────────────────────────────────────────
  final _stopwatch = Stopwatch();

  CameraExerciseConfig get _currentConfig => widget.exerciseConfigs[_exerciseIdx];
  GuidedExercise get _currentExercise => _currentConfig.exercise;
  int get _targetReps => _currentConfig.reps;
  int get _targetSets => _currentConfig.sets;
  bool get _isLastExercise => _exerciseIdx == widget.exerciseConfigs.length - 1;
  bool get _isLastSet => _setNum >= _targetSets;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flashAnim = Tween<double>(begin: 0.35, end: 0.0)
        .animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
    _detector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
    _initCamera(front: false);
  }

  Future<void> _initCamera({required bool front}) async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) return;
      final cam = front
          ? cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cams.first)
          : cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      await _ctrl?.stopImageStream();
      await _ctrl?.dispose();
      final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _ctrl = ctrl;
        _isFront = cam.lensDirection == CameraLensDirection.front;
        _isSwitching = false;
        _pose = null;
      });
      ctrl.startImageStream(_onFrame);
    } catch (_) {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  Future<void> _onFrame(CameraImage img) async {
    if (_processing || _detector == null || _setComplete || _workoutDone) return;
    _processing = true;
    try {
      final input = _toInput(img);
      if (input == null) return;
      final poses = await _detector!.processImage(input);
      if (!mounted) return;

      if (poses.isEmpty) {
        _lostFrames++;
        if (_lostFrames > 30) setState(() => _bodyLost = true);
        return;
      }
      _lostFrames = 0;
      final pose = poses.first;

      double tot = 0; int n = 0;
      for (final lm in pose.landmarks.values) { tot += lm.likelihood; n++; }
      final conf = n > 0 ? tot / n : 0.0;

      // Enforce minimum time between reps
      final canCount = _lastRepTime == null ||
          DateTime.now().difference(_lastRepTime!).inMilliseconds > _kMinRepMs;

      bool repDone = false;
      if (canCount) {
        final detect = _detectorFor(_currentExercise.name);
        repDone = detect(pose.landmarks, _repPhase, (s) => _repPhase = s);
      }

      setState(() {
        _confidence = conf;
        _pose = pose;
        _imgSize = Size(img.width.toDouble(), img.height.toDouble());
        _bodyLost = false;
        if (repDone) {
          _reps++;
          _lastRepTime = DateTime.now();
          // Auto-complete set when target reps reached
          if (_reps >= _targetReps) {
            _setComplete = true;
          }
        }
      });

      if (repDone) {
        HapticFeedback.mediumImpact();
        _flashCtrl.forward(from: 0);
      }
    } finally {
      _processing = false;
    }
  }

  InputImage? _toInput(CameraImage img) {
    try {
      final rotation = _rotations[_rotIdx];
      final yPlane = img.planes[0];
      if (img.planes.length == 1) {
        return InputImage.fromBytes(
          bytes: yPlane.bytes,
          metadata: InputImageMetadata(
            size: Size(img.width.toDouble(), img.height.toDouble()),
            rotation: rotation, format: InputImageFormat.nv21,
            bytesPerRow: yPlane.bytesPerRow));
      }
      final uPlane = img.planes[1];
      final vPlane = img.planes.length > 2 ? img.planes[2] : img.planes[1];
      final ySize = img.width * img.height;
      final uvSize = (img.width * img.height) ~/ 2;
      final nv21 = Uint8List(ySize + uvSize);
      int dst = 0;
      for (int row = 0; row < img.height; row++) {
        final src = row * yPlane.bytesPerRow;
        if (src + img.width <= yPlane.bytes.length) nv21.setRange(dst, dst + img.width, yPlane.bytes, src);
        dst += img.width;
      }
      for (int row = 0; row < img.height ~/ 2; row++) {
        for (int col = 0; col < img.width ~/ 2; col++) {
          final vIdx = row * vPlane.bytesPerRow + col * 2;
          final uIdx = row * uPlane.bytesPerRow + col * 2;
          if (dst + 1 < nv21.length) {
            nv21[dst++] = vIdx < vPlane.bytes.length ? vPlane.bytes[vIdx] : 128;
            nv21[dst++] = uIdx < uPlane.bytes.length ? uPlane.bytes[uIdx] : 128;
          }
        }
      }
      return InputImage.fromBytes(bytes: nv21, metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rotation, format: InputImageFormat.nv21, bytesPerRow: img.width));
    } catch (_) { return null; }
  }

  /// Called when user taps "Next Set" or "Next Exercise"
  void _advance() {
    if (_isLastSet && _isLastExercise) {
      // Workout complete
      _stopwatch.stop();
      _ctrl?.stopImageStream();
      setState(() => _workoutDone = true);
    } else if (_isLastSet) {
      // Move to next exercise
      setState(() {
        _exerciseIdx++;
        _setNum = 1;
        _reps = 0;
        _repPhase = _RepPhase.up;
        _lastRepTime = null;
        _setComplete = false;
        _pose = null;
        _bodyLost = false;
        _lostFrames = 0;
      });
    } else {
      // Next set of same exercise
      setState(() {
        _setNum++;
        _reps = 0;
        _repPhase = _RepPhase.up;
        _lastRepTime = null;
        _setComplete = false;
      });
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _detector?.close();
    _flashCtrl.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_workoutDone) return _WorkoutDoneScreen(plan: widget.plan, seconds: _stopwatch.elapsed.inSeconds);

    final initialized = _ctrl?.value.isInitialized == true;
    if (!initialized) {
      return const Scaffold(backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))));
    }

    final progress = (_exerciseIdx + (_setNum - 1) / _targetSets) / widget.exerciseConfigs.length;
    final isDown = _repPhase == _RepPhase.down;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Stack(fit: StackFit.expand, children: [

        // Camera preview
        Transform(
          alignment: Alignment.center,
          transform: _isFront ? (Matrix4.identity()..scale(-1.0, 1.0)) : Matrix4.identity(),
          child: CameraPreview(_ctrl!),
        ),

        // Skeleton overlay
        if (_pose != null && _imgSize != null)
          CustomPaint(painter: _SkeletonPainter(pose: _pose!, imageSize: _imgSize!, mirror: _isFront)),

        // Rep flash
        AnimatedBuilder(animation: _flashAnim,
          builder: (_, __) => IgnorePointer(
            child: Container(color: Colors.white.withOpacity(_flashAnim.value)))),

        // Progress bar
        Positioned(top: 0, left: 0, right: 0,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0), minHeight: 3,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
          )),

        // Top bar
        Positioned(top: 8, left: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              GestureDetector(
                onTap: () => _showQuitDialog(context),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.plan.name, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                Text('Exercise ${_exerciseIdx + 1}/${widget.exerciseConfigs.length} · Set $_setNum/$_targetSets',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ])),
              // Confidence indicator
              Container(width: 8, height: 8, decoration: BoxDecoration(
                color: _confidence > 0.5 ? Colors.green : _confidence > 0.25 ? Colors.orange : Colors.red,
                shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('${(_confidence * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11)),
              const SizedBox(width: 8),
              // Rotation toggle
              GestureDetector(
                onTap: () => setState(() => _rotIdx = (_rotIdx + 1) % 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                  child: Text('R:${['0','90','180','270'][_rotIdx]}',
                      style: const TextStyle(color: Colors.white, fontSize: 10)))),
              const SizedBox(width: 6),
              // Flip camera
              GestureDetector(
                onTap: _isSwitching ? null : () { setState(() => _isSwitching = true); _initCamera(front: !_isFront); },
                child: const Icon(Icons.flip_camera_android, color: Colors.white, size: 20)),
            ]),
          )),

        // Exercise name + muscle group
        Positioned(top: 80, left: 0, right: 0,
          child: Column(children: [
            Text(_currentExercise.name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE53935).withOpacity(0.85), borderRadius: BorderRadius.circular(12)),
              child: Text(_currentExercise.muscleGroup,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
          ])),

        // Phase badge (UP / DOWN)
        Positioned(top: 145, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isDown ? Colors.orange : const Color(0xFFE53935)).withOpacity(0.85),
              borderRadius: BorderRadius.circular(16)),
            child: Text(isDown ? 'CURLING' : 'READY',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),

        // Rep counter (top right)
        Positioned(top: 80, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE53935), width: 2)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$_reps', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, height: 1.0)),
              Text('/ $_targetReps', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const Text('REPS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
            ]))),

        // Body lost warning
        if (_bodyLost)
          Positioned(top: 155, left: 0, right: 0,
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Text('Body not detected — step back', style: TextStyle(color: Colors.white, fontSize: 12)),
              ])))),

        // Next exercise preview
        if (!_isLastExercise && !_setComplete)
          Positioned(bottom: 100, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.arrow_forward_rounded, color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Text('Next: ${widget.exerciseConfigs[_exerciseIdx + 1].exercise.name}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]))),

        // Set complete overlay + Next button
        if (_setComplete)
          Positioned.fill(child: Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFFE53935), size: 52),
                const SizedBox(height: 12),
                Text(
                  _isLastSet ? 'Set $_setNum Complete!' : 'Set $_setNum Complete!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
                const SizedBox(height: 6),
                Text('$_reps reps done',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _advance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isLastSet && _isLastExercise
                        ? 'Finish Workout'
                        : _isLastSet
                            ? 'Next Exercise →'
                            : 'Next Set (${_setNum + 1}/$_targetSets)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                )),
                const SizedBox(height: 8),
                // Manual rep adjust before confirming
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton.icon(
                    onPressed: () => setState(() { if (_reps > 0) _reps--; }),
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Remove rep'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600])),
                  TextButton.icon(
                    onPressed: () => setState(() => _reps++),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add rep'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600])),
                ]),
              ]),
            )),
          )),

        // Bottom manual controls (only when set is active)
        if (!_setComplete)
          Positioned(bottom: 24, left: 16, right: 16,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              // Manual rep adjust
              Row(children: [
                _SmallBtn(icon: Icons.remove_rounded,
                    onTap: () => setState(() { if (_reps > 0) _reps--; })),
                const SizedBox(width: 8),
                _SmallBtn(icon: Icons.add_rounded,
                    onTap: () => setState(() => _reps++)),
              ]),
              // Mark set done manually
              ElevatedButton(
                onPressed: () => setState(() => _setComplete = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Set Done', style: TextStyle(fontWeight: FontWeight.bold))),
            ])),

      ])),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Quit Workout?'),
      content: const Text('Your progress will be lost.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue')),
        TextButton(
          onPressed: () { Navigator.pop(context); Navigator.pop(context); },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Quit')),
      ],
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small icon button
// ─────────────────────────────────────────────────────────────────────────────

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30)),
        child: Icon(icon, color: Colors.white, size: 20)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Workout done screen
// ─────────────────────────────────────────────────────────────────────────────

class _WorkoutDoneScreen extends StatelessWidget {
  final GuidedPlan plan;
  final int seconds;
  const _WorkoutDoneScreen({required this.plan, required this.seconds});

  String _fmt(int s) {
    final m = s ~/ 60; final sec = s % 60;
    return '${m}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3), width: 2)),
            child: const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFFE53935))),
          const SizedBox(height: 20),
          const Text('Workout Complete!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(plan.name, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Stat(icon: Icons.timer_rounded, label: 'Duration', value: _fmt(seconds), color: const Color(0xFFE53935)),
            _Stat(icon: Icons.fitness_center_rounded, label: 'Exercises', value: '${plan.totalExercises}', color: Colors.orange),
          ]),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
        ]),
      )),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _Stat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Icon(icon, color: color, size: 24)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton painter
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonPainter extends CustomPainter {
  final Pose pose; final Size imageSize; final bool mirror;
  _SkeletonPainter({required this.pose, required this.imageSize, required this.mirror});

  static const _bones = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / imageSize.height;
    final sy = size.height / imageSize.width;
    Offset pt(PoseLandmark lm) {
      double x = lm.x * sx;
      if (mirror) x = size.width - x;
      return Offset(x, lm.y * sy);
    }
    final line = Paint()..color = const Color(0xFFE53935).withOpacity(0.9)..strokeWidth = 4..strokeCap = StrokeCap.round;
    final dot = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (final b in _bones) {
      final a = pose.landmarks[b[0]]; final bb = pose.landmarks[b[1]];
      if (a != null && bb != null && a.likelihood > 0.1 && bb.likelihood > 0.1) {
        canvas.drawLine(pt(a), pt(bb), line);
      }
    }
    for (final lm in pose.landmarks.values) {
      if (lm.likelihood > 0.1) canvas.drawCircle(pt(lm), 5, dot);
    }
  }

  @override bool shouldRepaint(_SkeletonPainter old) => true;
}
