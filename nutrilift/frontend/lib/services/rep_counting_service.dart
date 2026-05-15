import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Exercises that have reliable, validated camera tracking.
const Set<String> kCameraSupported = {'BICEP_CURL', 'PUSH_UP', 'SQUAT'};

const Map<String, String> kSupportedExerciseNames = {
  'BICEP_CURL': 'Bicep Curl',
  'PUSH_UP': 'Push-Up',
  'SQUAT': 'Squat',
};

bool isCameraTrackingSupported(String exerciseType) =>
    kCameraSupported.contains(exerciseType.toUpperCase());

const double kMinConfidence = 0.55;

// ── Form feedback ─────────────────────────────────────────────────────────────

enum FormStatus { good, warning, error }

/// Real-time form feedback shown as an overlay during camera tracking.
class FormFeedback {
  final FormStatus status;
  final String message;
  final String? detail; // optional secondary tip

  const FormFeedback({required this.status, required this.message, this.detail});

  static const good = FormFeedback(status: FormStatus.good, message: 'Good form!');
  static const notDetected = FormFeedback(status: FormStatus.error, message: 'Body not detected', detail: 'Step back so your full body is visible');
}

// ── Angle helper ──────────────────────────────────────────────────────────────

double _calcAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final r = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
  double d = r.abs() * 180 / pi;
  if (d > 180) d = 360 - d;
  return d;
}

double? _avgLikelihood(List<PoseLandmark?> landmarks) {
  if (landmarks.any((l) => l == null)) return null;
  final sum = landmarks.fold<double>(0, (s, l) => s + l!.likelihood);
  return sum / landmarks.length;
}

enum RepState { idle, inPosition, completed }

// ── Rep counting service ──────────────────────────────────────────────────────

class RepCountingService {
  final String exerciseType;
  int _repCount = 0;
  bool _isInDownPosition = false;
  DateTime? _lastRepTime;
  bool _lowConfidence = false;
  FormFeedback _lastFeedback = FormFeedback.good;

  bool get isLowConfidence => _lowConfidence;

  /// Latest form feedback — updated every frame.
  FormFeedback get formFeedback => _lastFeedback;

  RepCountingService(this.exerciseType) {
    assert(isCameraTrackingSupported(exerciseType),
        'RepCountingService created for unsupported exercise: $exerciseType');
  }

  int get repCount => _repCount;

  bool processPose(Pose pose) {
    final lm = pose.landmarks;
    switch (exerciseType.toUpperCase()) {
      case 'PUSH_UP':   return _detectPushUp(lm);
      case 'SQUAT':     return _detectSquat(lm);
      case 'BICEP_CURL': return _detectBicepCurl(lm);
      default:          return false;
    }
  }

  // ── Bicep Curl ────────────────────────────────────────────────────────────
  bool _detectBicepCurl(Map<PoseLandmarkType, PoseLandmark> lm) {
    final ls = lm[PoseLandmarkType.leftShoulder];
    final le = lm[PoseLandmarkType.leftElbow];
    final lw = lm[PoseLandmarkType.leftWrist];
    final rs = lm[PoseLandmarkType.rightShoulder];
    final re = lm[PoseLandmarkType.rightElbow];
    final rw = lm[PoseLandmarkType.rightWrist];

    final conf = _avgLikelihood([ls, le, lw]) ?? _avgLikelihood([rs, re, rw]);
    if (conf == null || conf < kMinConfidence) {
      _lowConfidence = true;
      _lastFeedback = FormFeedback.notDetected;
      return false;
    }
    _lowConfidence = false;

    PoseLandmark? shoulder, elbow, wrist;
    if (ls != null && le != null && lw != null &&
        (rs == null || re == null || rw == null ||
         _avgLikelihood([ls, le, lw])! >= _avgLikelihood([rs, re, rw])!)) {
      shoulder = ls; elbow = le; wrist = lw;
    } else if (rs != null && re != null && rw != null) {
      shoulder = rs; elbow = re; wrist = rw;
    } else {
      _lowConfidence = true;
      _lastFeedback = FormFeedback.notDetected;
      return false;
    }

    final angle = _calcAngle(shoulder, elbow, wrist);

    // Form feedback for bicep curl
    _lastFeedback = _bicepCurlFeedback(angle, shoulder, elbow);

    if (angle > 150 && !_isInDownPosition) {
      _isInDownPosition = true;
    } else if (angle < 50 && _isInDownPosition && _canCountRep()) {
      _isInDownPosition = false;
      _repCount++;
      _lastRepTime = DateTime.now();
      return true;
    }
    return false;
  }

  FormFeedback _bicepCurlFeedback(double angle, PoseLandmark shoulder, PoseLandmark elbow) {
    // Check if elbow is drifting forward (elbow x should stay close to shoulder x)
    final elbowDrift = (elbow.x - shoulder.x).abs();
    if (elbowDrift > 60) {
      return const FormFeedback(
        status: FormStatus.warning,
        message: 'Keep elbows close to body',
        detail: 'Avoid swinging your elbows forward',
      );
    }
    if (angle > 50 && angle < 150) {
      return const FormFeedback(status: FormStatus.good, message: 'Good form!');
    }
    if (angle >= 150) {
      return const FormFeedback(status: FormStatus.good, message: 'Fully extend arm');
    }
    if (angle <= 50) {
      return const FormFeedback(status: FormStatus.good, message: 'Squeeze at the top!');
    }
    return FormFeedback.good;
  }

  // ── Push-Up ───────────────────────────────────────────────────────────────
  bool _detectPushUp(Map<PoseLandmarkType, PoseLandmark> lm) {
    final s = lm[PoseLandmarkType.leftShoulder];
    final e = lm[PoseLandmarkType.leftElbow];
    final w = lm[PoseLandmarkType.leftWrist];
    final h = lm[PoseLandmarkType.leftHip];

    final conf = _avgLikelihood([s, e, w, h]);
    if (conf == null || conf < kMinConfidence) {
      _lowConfidence = true;
      _lastFeedback = FormFeedback.notDetected;
      return false;
    }
    _lowConfidence = false;

    final angle = _calcAngle(s!, e!, w!);
    final hipShoulderDiff = (h!.y - s.y).abs();

    if (hipShoulderDiff < 30) {
      _lastFeedback = const FormFeedback(
        status: FormStatus.error,
        message: 'Get into push-up position',
        detail: 'Lie face down with hands under shoulders',
      );
      return false;
    }

    _lastFeedback = _pushUpFeedback(angle, s, h);

    if (angle < 90 && !_isInDownPosition) {
      _isInDownPosition = true;
    } else if (angle > 160 && _isInDownPosition && _canCountRep()) {
      _isInDownPosition = false;
      _repCount++;
      _lastRepTime = DateTime.now();
      return true;
    }
    return false;
  }

  FormFeedback _pushUpFeedback(double angle, PoseLandmark shoulder, PoseLandmark hip) {
    // Check body alignment — hip should not sag or pike
    final hipSag = hip.y - shoulder.y;
    if (hipSag < -20) {
      return const FormFeedback(
        status: FormStatus.warning,
        message: 'Hips too high (piking)',
        detail: 'Keep your body in a straight line',
      );
    }
    if (hipSag > 80) {
      return const FormFeedback(
        status: FormStatus.warning,
        message: 'Hips sagging',
        detail: 'Engage your core to keep body straight',
      );
    }
    if (angle < 90) {
      return const FormFeedback(status: FormStatus.good, message: 'Good depth!');
    }
    if (angle > 160) {
      return const FormFeedback(status: FormStatus.good, message: 'Arms fully extended');
    }
    return const FormFeedback(status: FormStatus.good, message: 'Good form!');
  }

  // ── Squat ─────────────────────────────────────────────────────────────────
  bool _detectSquat(Map<PoseLandmarkType, PoseLandmark> lm) {
    final h = lm[PoseLandmarkType.leftHip];
    final k = lm[PoseLandmarkType.leftKnee];
    final a = lm[PoseLandmarkType.leftAnkle];
    final s = lm[PoseLandmarkType.leftShoulder];

    final conf = _avgLikelihood([h, k, a]);
    if (conf == null || conf < kMinConfidence) {
      _lowConfidence = true;
      _lastFeedback = FormFeedback.notDetected;
      return false;
    }
    _lowConfidence = false;

    final angle = _calcAngle(h!, k!, a!);
    _lastFeedback = _squatFeedback(angle, k, a, s);

    if (angle < 100 && !_isInDownPosition) {
      _isInDownPosition = true;
    } else if (angle > 160 && _isInDownPosition && _canCountRep()) {
      _isInDownPosition = false;
      _repCount++;
      _lastRepTime = DateTime.now();
      return true;
    }
    return false;
  }

  FormFeedback _squatFeedback(double angle, PoseLandmark knee, PoseLandmark ankle, PoseLandmark? shoulder) {
    // Check knee tracking — knee x should stay close to ankle x (not caving in)
    final kneeAnkleDiff = (knee.x - ankle.x).abs();
    if (kneeAnkleDiff > 50) {
      return const FormFeedback(
        status: FormStatus.warning,
        message: 'Knees caving in',
        detail: 'Push knees out over your toes',
      );
    }
    // Check depth
    if (angle > 100 && angle < 160) {
      return const FormFeedback(
        status: FormStatus.warning,
        message: 'Squat deeper',
        detail: 'Aim for thighs parallel to floor',
      );
    }
    if (angle <= 100) {
      return const FormFeedback(status: FormStatus.good, message: 'Good depth!');
    }
    return const FormFeedback(status: FormStatus.good, message: 'Good form!');
  }

  bool _canCountRep() {
    if (_lastRepTime == null) return true;
    return DateTime.now().difference(_lastRepTime!).inMilliseconds > 600;
  }

  void reset() {
    _repCount = 0;
    _isInDownPosition = false;
    _lastRepTime = null;
    _lowConfidence = false;
    _lastFeedback = FormFeedback.good;
  }
}
