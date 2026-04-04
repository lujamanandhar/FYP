import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exercise result — reps + weight per set per exercise
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseSetResult {
  final int exerciseId;
  final String exerciseName;
  final List<SetResult> sets;
  ExerciseSetResult({required this.exerciseId, required this.exerciseName, required this.sets});
}

class SetResult {
  final int setNumber;
  int reps;
  double weight;
  SetResult({required this.setNumber, required this.reps, this.weight = 0});
}

// ─────────────────────────────────────────────────────────────────────────────
// Pose detection helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _RepState { up, down }

double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final r = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
  double d = r.abs() * 180 / pi;
  if (d > 180) d = 360 - d;
  return d;
}

// Maps exercise name → detector function
typedef _Detector = bool Function(Map<PoseLandmarkType, PoseLandmark> lm, _RepState state, void Function(_RepState) setState);

bool _pushUpDetect(Map<PoseLandmarkType, PoseLandmark> lm, _RepState state, void Function(_RepState) set) {
  final s = lm[PoseLandmarkType.leftShoulder]; final e = lm[PoseLandmarkType.leftElbow]; final w = lm[PoseLandmarkType.leftWrist];
  if (s == null || e == null || w == null) return false;
  final a = _angle(s, e, w);
  if (a < 90 && state == _RepState.up) { set(_RepState.down); return false; }
  if (a > 160 && state == _RepState.down) { set(_RepState.up); return true; }
  return false;
}

bool _squatDetect(Map<PoseLandmarkType, PoseLandmark> lm, _RepState state, void Function(_RepState) set) {
  final h = lm[PoseLandmarkType.leftHip]; final k = lm[PoseLandmarkType.leftKnee]; final a = lm[PoseLandmarkType.leftAnkle];
  if (h == null || k == null || a == null) return false;
  final ang = _angle(h, k, a);
  if (ang < 90 && state == _RepState.up) { set(_RepState.down); return false; }
  if (ang > 160 && state == _RepState.down) { set(_RepState.up); return true; }
  return false;
}

bool _curlDetect(Map<PoseLandmarkType, PoseLandmark> lm, _RepState state, void Function(_RepState) set) {
  final s = lm[PoseLandmarkType.leftShoulder]; final e = lm[PoseLandmarkType.leftElbow]; final w = lm[PoseLandmarkType.leftWrist];
  if (s == null || e == null || w == null) return false;
  final a = _angle(s, e, w);
  if (a > 150 && state == _RepState.up) { set(_RepState.down); return false; }
  if (a < 50 && state == _RepState.down) { set(_RepState.up); return true; }
  return false;
}

bool _lungeDetect(Map<PoseLandmarkType, PoseLandmark> lm, _RepState state, void Function(_RepState) set) {
  final h = lm[PoseLandmarkType.leftHip]; final k = lm[PoseLandmarkType.leftKnee]; final a = lm[PoseLandmarkType.leftAnkle];
  if (h == null || k == null || a == null) return false;
  final ang = _angle(h, k, a);
  if (ang < 90 && state == _RepState.up) { set(_RepState.down); return false; }
  if (ang > 150 && state == _RepState.down) { set(_RepState.up); return true; }
  return false;
}

_Detector _detectorFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('push') || n.contains('press') || n.contains('dip') || n.contains('chest') || n.contains('tricep')) return _pushUpDetect;
  if (n.contains('squat') || n.contains('deadlift') || n.contains('leg') || n.contains('calf')) return _squatDetect;
  if (n.contains('curl') || n.contains('bicep') || n.contains('row') || n.contains('pull')) return _curlDetect;
  if (n.contains('lunge') || n.contains('step')) return _lungeDetect;
  if (n.contains('shoulder') || n.contains('overhead') || n.contains('lateral')) return _pushUpDetect;
  if (n.contains('crunch') || n.contains('sit') || n.contains('ab') || n.contains('core')) return _curlDetect;
  return _squatDetect; // default
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CameraWorkoutPlayerScreen extends StatefulWidget {
  final String title;
  final List<Exercise> exercises;
  final Color difficultyColor;
  final void Function(List<ExerciseSetResult> results, int durationSeconds) onComplete;

  const CameraWorkoutPlayerScreen({
    Key? key,
    required this.title,
    required this.exercises,
    required this.difficultyColor,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<CameraWorkoutPlayerScreen> createState() => _CameraWorkoutPlayerScreenState();
}

class _CameraWorkoutPlayerScreenState extends State<CameraWorkoutPlayerScreen>
    with TickerProviderStateMixin {

  // ── Navigation ──────────────────────────────────────────────────────────────
  int _exerciseIdx = 0;
  int _setNum = 1;
  static const int _totalSets = 3;

  // ── Results ─────────────────────────────────────────────────────────────────
  final List<ExerciseSetResult> _results = [];
  final _stopwatch = Stopwatch();

  // ── Camera ──────────────────────────────────────────────────────────────────
  CameraController? _ctrl;
  bool _isFront = false;
  bool _isSwitching = false;

  // ── ML Kit ──────────────────────────────────────────────────────────────────
  PoseDetector? _detector;
  bool _processing = false;
  Pose? _pose;
  Size? _imgSize;

  // ── Rep counting ────────────────────────────────────────────────────────────
  int _reps = 0;
  _RepState _repState = _RepState.up;
  DateTime? _lastRepTime;
  double _confidence = 0.0;
  bool _bodyLost = false;
  int _lostFrames = 0;

  // ── Weight input ────────────────────────────────────────────────────────────
  final _weightCtrl = TextEditingController(text: '0');

  // ── Rotation ────────────────────────────────────────────────────────────────
  int _rotIdx = 1;
  static const _rotations = [
    InputImageRotation.rotation0deg, InputImageRotation.rotation90deg,
    InputImageRotation.rotation180deg, InputImageRotation.rotation270deg,
  ];

  // ── Flash ───────────────────────────────────────────────────────────────────
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;

  Exercise get _currentExercise => widget.exercises[_exerciseIdx];
  bool get _isLastExercise => _exerciseIdx == widget.exercises.length - 1;
  bool get _isLastSet => _setNum >= _totalSets;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flashAnim = Tween<double>(begin: 0.3, end: 0.0).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
    _detector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
    _initCamera(front: false);
    _initResultsForCurrentExercise();
  }

  void _initResultsForCurrentExercise() {
    if (_exerciseIdx >= _results.length) {
      _results.add(ExerciseSetResult(
        exerciseId: _currentExercise.id,
        exerciseName: _currentExercise.name,
        sets: [],
      ));
    }
  }

  Future<void> _initCamera({required bool front}) async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) return;
      final cam = front
          ? cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cams.first)
          : cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      await _ctrl?.stopImageStream(); await _ctrl?.dispose();
      final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() { _ctrl = ctrl; _isFront = cam.lensDirection == CameraLensDirection.front; _isSwitching = false; _pose = null; });
      ctrl.startImageStream(_onFrame);
    } catch (_) { if (mounted) setState(() => _isSwitching = false); }
  }

  Future<void> _onFrame(CameraImage img) async {
    if (_processing || _detector == null) return;
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

      // Run detector for current exercise
      final detect = _detectorFor(_currentExercise.name);
      bool repDone = false;
      if (_lastRepTime == null || DateTime.now().difference(_lastRepTime!).inMilliseconds > 600) {
        repDone = detect(pose.landmarks, _repState, (s) => _repState = s);
      }

      setState(() {
        _confidence = conf;
        _pose = pose;
        _imgSize = Size(img.width.toDouble(), img.height.toDouble());
        _bodyLost = false;
        if (repDone) {
          _reps++;
          _lastRepTime = DateTime.now();
        }
      });
      if (repDone) {
        HapticFeedback.mediumImpact();
        _flashCtrl.forward(from: 0);
      }
    } finally { _processing = false; }
  }

  InputImage? _toInput(CameraImage img) {
    try {
      final rotation = _rotations[_rotIdx];
      final int width = img.width; final int height = img.height;
      final yPlane = img.planes[0];
      if (img.planes.length == 1) {
        return InputImage.fromBytes(bytes: yPlane.bytes, metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()), rotation: rotation,
          format: InputImageFormat.nv21, bytesPerRow: yPlane.bytesPerRow));
      }
      final uPlane = img.planes[1];
      final vPlane = img.planes.length > 2 ? img.planes[2] : img.planes[1];
      final int ySize = width * height;
      final int uvSize = (width * height) ~/ 2;
      final nv21 = Uint8List(ySize + uvSize);
      int dst = 0;
      for (int row = 0; row < height; row++) {
        final src = row * yPlane.bytesPerRow;
        if (src + width <= yPlane.bytes.length) nv21.setRange(dst, dst + width, yPlane.bytes, src);
        dst += width;
      }
      final int uvStride = uPlane.bytesPerRow;
      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          final int uIdx = row * uvStride + col * 2;
          final int vIdx = row * vPlane.bytesPerRow + col * 2;
          if (dst + 1 < nv21.length) {
            nv21[dst++] = vIdx < vPlane.bytes.length ? vPlane.bytes[vIdx] : 128;
            nv21[dst++] = uIdx < uPlane.bytes.length ? uPlane.bytes[uIdx] : 128;
          }
        }
      }
      return InputImage.fromBytes(bytes: nv21, metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()), rotation: rotation,
        format: InputImageFormat.nv21, bytesPerRow: width));
    } catch (_) { return null; }
  }

  void _setDone() {
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    _results[_exerciseIdx].sets.add(SetResult(setNumber: _setNum, reps: _reps, weight: weight));

    if (_isLastSet) {
      _nextExercise();
    } else {
      setState(() { _setNum++; _reps = 0; _repState = _RepState.up; _lastRepTime = null; });
    }
  }

  void _nextExercise() {
    if (_isLastExercise) {
      _finish();
    } else {
      setState(() {
        _exerciseIdx++;
        _setNum = 1;
        _reps = 0;
        _repState = _RepState.up;
        _lastRepTime = null;
        _pose = null;
      });
      _initResultsForCurrentExercise();
    }
  }

  void _finish() {
    _stopwatch.stop();
    _ctrl?.stopImageStream();
    widget.onComplete(_results, _stopwatch.elapsed.inSeconds);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _detector?.close();
    _flashCtrl.dispose();
    _weightCtrl.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _ctrl?.value.isInitialized == true;
    if (!initialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))));
    }

    final progress = (_exerciseIdx + (_setNum - 1) / _totalSets) / widget.exercises.length;
    final isDown = _repState == _RepState.down;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Stack(fit: StackFit.expand, children: [
        // Camera
        Transform(alignment: Alignment.center,
          transform: _isFront ? (Matrix4.identity()..scale(-1.0, 1.0)) : Matrix4.identity(),
          child: CameraPreview(_ctrl!)),

        // Skeleton
        if (_pose != null && _imgSize != null)
          CustomPaint(painter: _CamSkeletonPainter(pose: _pose!, imageSize: _imgSize!, mirror: _isFront)),

        // Flash
        AnimatedBuilder(animation: _flashAnim,
          builder: (_, __) => IgnorePointer(child: Container(color: Colors.white.withOpacity(_flashAnim.value)))),

        // Progress bar at top
        Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0), minHeight: 3,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(widget.difficultyColor),
        )),

        // Top bar
        Positioned(top: 8, left: 12, right: 12, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            GestureDetector(onTap: () => _showQuitDialog(context), child: const Icon(Icons.close_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text('${_exerciseIdx + 1}/${widget.exercises.length} · Set $_setNum/$_totalSets',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ])),
            // Confidence dot
            Container(width: 8, height: 8, decoration: BoxDecoration(
              color: _confidence > 0.5 ? Colors.green : _confidence > 0.2 ? Colors.orange : Colors.red,
              shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${(_confidence * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11)),
            const SizedBox(width: 8),
            // Rotation button
            GestureDetector(
              onTap: () => setState(() => _rotIdx = (_rotIdx + 1) % 4),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                child: Text('R:${['0','90','180','270'][_rotIdx]}', style: const TextStyle(color: Colors.white, fontSize: 10)))),
            const SizedBox(width: 6),
            // Flip camera
            GestureDetector(onTap: _isSwitching ? null : () { setState(() => _isSwitching = true); _initCamera(front: !_isFront); },
              child: const Icon(Icons.flip_camera_android, color: Colors.white, size: 20)),
          ]),
        )),

        // Exercise name + muscle group
        Positioned(top: 80, left: 0, right: 0, child: Column(children: [
          Text(_currentExercise.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: widget.difficultyColor.withOpacity(0.85), borderRadius: BorderRadius.circular(12)),
            child: Text(_currentExercise.muscleGroup,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ])),

        // State badge
        Positioned(top: 145, left: 16, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: (isDown ? Colors.orange : Colors.green).withOpacity(0.85), borderRadius: BorderRadius.circular(16)),
          child: Text(isDown ? '⬇ DOWN' : '⬆ UP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        )),

        // Rep counter — top right
        Positioned(top: 80, right: 16, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE53935), width: 2)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$_reps', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, height: 1.0)),
            const Text('REPS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          ]),
        )),

        // Body lost warning
        if (_bodyLost) Positioned(top: 155, left: 0, right: 0, child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
            const SizedBox(width: 6),
            const Text('Body not detected — step back', style: TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        ))),

        // Next exercise preview
        if (!_isLastExercise) Positioned(bottom: 160, left: 16, right: 16, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.arrow_forward_rounded, color: Colors.white54, size: 14),
            const SizedBox(width: 6),
            Text('Next: ${widget.exercises[_exerciseIdx + 1].name}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        )),

        // Bottom controls
        Positioned(bottom: 24, left: 16, right: 16, child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Weight input row
          Row(children: [
            const Icon(Icons.monitor_weight_outlined, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            const Text('Weight (kg):', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                filled: true, fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            )),
            const Spacer(),
            // Manual rep adjust
            IconButton(onPressed: () => setState(() => _reps = (_reps - 1).clamp(0, 999)),
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white70)),
            IconButton(onPressed: () => setState(() => _reps++),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white70)),
          ]),
          const SizedBox(height: 10),
          // Set done / next exercise / finish button
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _setDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.difficultyColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _isLastSet && _isLastExercise ? 'Finish Workout' : _isLastSet ? 'Next Exercise →' : 'Set Done ($_reps reps)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          )),
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
        TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Quit')),
      ],
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _CamSkeletonPainter extends CustomPainter {
  final Pose pose; final Size imageSize; final bool mirror;
  _CamSkeletonPainter({required this.pose, required this.imageSize, required this.mirror});

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
    Offset pt(PoseLandmark lm) { double x = lm.x * sx; if (mirror) x = size.width - x; return Offset(x, lm.y * sy); }
    final line = Paint()..color = Colors.greenAccent.withOpacity(0.9)..strokeWidth = 4..strokeCap = StrokeCap.round;
    final dot = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (final b in _bones) {
      final a = pose.landmarks[b[0]]; final bb = pose.landmarks[b[1]];
      if (a != null && bb != null && a.likelihood > 0.1 && bb.likelihood > 0.1) canvas.drawLine(pt(a), pt(bb), line);
    }
    for (final lm in pose.landmarks.values) { if (lm.likelihood > 0.1) canvas.drawCircle(pt(lm), 5, dot); }
  }

  @override bool shouldRepaint(_CamSkeletonPainter old) => true;
}
