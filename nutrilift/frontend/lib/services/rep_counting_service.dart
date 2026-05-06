import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Exercises that have reliable, validated camera tracking.
/// All others show "Coming Soon".
const Set<String> kCameraSupported = {'BICEP_CURL', 'PUSH_UP', 'SQUAT'};

/// Human-readable names for supported exercises
const Map<String, String> kSupportedExerciseNames = {
  'BICEP_CURL': 'Bicep Curl',
  'PUSH_UP': 'Push-Up',
  'SQUAT': 'Squat',
};

/// Returns true if camera tracking is available for this exercise type.
bool isCameraTrackingSupported(String exerciseType) {
  return kCameraSupported.contains(exerciseType.toUpperCase());
}

/// Minimum confidence threshold — below this, counting is paused.
const double kMinConfidence = 0.55;

/// Calculates the angle at joint B formed by points A-B-C
double _calcAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final r = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
  double d = r.abs() * 180 / pi;
  if (d > 180) d = 360 - d;
  return d;
}

/// Returns the average likelihood of a set of landmarks.
/// Returns null if any required landmark is missing.
double? _avgLikelihood(List<PoseLandmark?> landmarks) {
  if (landmarks.any((l) => l == null)) return null;
  final sum = landmarks.fold<double>(0, (s, l) => s + l!.likelihood);
  return sum / landmarks.length;
}

enum RepState { idle, inPosition, completed }

class RepCountingService {
  final String exerciseType;
  int _repCount = 0;
  bool _isInDownPosition = false;
  DateTime? _lastRepTime;

  /// Whether the last processed frame had sufficient confidence.
  bool _lowConfidence = false;
  bool get isLowConfidence => _lowConfidence;

  RepCountingService(this.exerciseType) {
    assert(
      isCameraTrackingSupported(exerciseType),
      'RepCountingService created for unsupported exercise: $exerciseType',
    );
  }

  int get repCount => _repCount;

  /// Process pose landmarks and detect reps.
  /// Returns true if a new rep was detected this frame.
  /// Sets [isLowConfidence] if body is not clearly visible.
  bool processPose(Pose pose) {
    final lm = pose.landmarks;

    switch (exerciseType.toUpperCase()) {
      case 'PUSH_UP':
        return _detectPushUp(lm);
      case 'SQUAT':
        return _detectSquat(lm);
      case 'BICEP_CURL':
        return _detectBicepCurl(lm);
      default:
        return false;
    }
  }

  // ── Bicep Curl ────────────────────────────────────────────────────────────
  // Uses BOTH arms — counts when either arm completes a full curl.
  // Extended (>150°) → curled (<50°) = 1 rep.
  bool _detectBicepCurl(Map<PoseLandmarkType, PoseLandmark> lm) {
    // Try left arm first, fall back to right
    final ls = lm[PoseLandmarkType.leftShoulder];
    final le = lm[PoseLandmarkType.leftElbow];
    final lw = lm[PoseLandmarkType.leftWrist];
    final rs = lm[PoseLandmarkType.rightShoulder];
    final re = lm[PoseLandmarkType.rightElbow];
    final rw = lm[PoseLandmarkType.rightWrist];

    // Check confidence on the landmarks we'll use
    final conf = _avgLikelihood([ls, le, lw]) ?? _avgLikelihood([rs, re, rw]);
    if (conf == null || conf < kMinConfidence) {
      _lowConfidence = true;
      return false;
    }
    _lowConfidence = false;

    // Prefer the arm with higher confidence
    double angle;
    if (ls != null && le != null && lw != null &&
        (rs == null || re == null || rw == null ||
         _avgLikelihood([ls, le, lw])! >= _avgLikelihood([rs, re, rw])!)) {
      angle = _calcAngle(ls, le, lw);
    } else if (rs != null && re != null && rw != null) {
      angle = _calcAngle(rs, re, rw);
    } else {
      _lowConfidence = true;
      return false;
    }

    if (angle > 150 && !_isInDownPosition) {
      _isInDownPosition = true; // arm extended = ready
    } else if (angle < 50 && _isInDownPosition && _canCountRep()) {
      _isInDownPosition = false;
      _repCount++;
      _lastRepTime = DateTime.now();
      return true;
    }
    return false;
  }

  // ── Push-Up ───────────────────────────────────────────────────────────────
  // Elbow angle < 90° = down position, > 160° = up = rep complete.
  // Requires shoulder, elbow, wrist AND hip visible for body validation.
  bool _detectPushUp(Map<PoseLandmarkType, PoseLandmark> lm) {
    final s = lm[PoseLandmarkType.leftShoulder];
    final e = lm[PoseLandmarkType.leftElbow];
    final w = lm[PoseLandmarkType.leftWrist];
    final h = lm[PoseLandmarkType.leftHip];

    final conf = _avgLikelihood([s, e, w, h]);
    if (conf == null || conf < kMinConfidence) {
      _lowConfidence = true;
      return false;
    }
    _lowConfidence = false;

    final angle = _calcAngle(s!, e!, w!);

    // Extra validation: hip should be roughly level with shoulder (prone position)
    // If hip is much higher than shoulder, user is probably standing — ignore
    final hipShoulderDiff = (h!.y - s.y).abs();
    if (hipShoulderDiff < 30) {
      // Likely standing, not in push-up position
      return false;
    }

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

  // ── Squat ─────────────────────────────────────────────────────────────────
  // Knee angle < 100° = down, > 160° = up = rep complete.
  // Requires hip, knee, ankle visible.
  bool _detectSquat(Map<PoseLandmarkType, PoseLandmark> lm) {
    final h = lm[PoseLandmarkType.leftHip];
    final k = lm[PoseLandmarkType.leftKnee];
    final a = lm[PoseLandmarkType.leftAnkle];

    final conf = _avgLikelihood([h, k, a]);
    if (conf == null || conf < kMinConfidence) {
      _lowConfidence = true;
      return false;
    }
    _lowConfidence = false;

    final angle = _calcAngle(h!, k!, a!);

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

  /// Minimum 600ms between reps to prevent false positives
  bool _canCountRep() {
    if (_lastRepTime == null) return true;
    return DateTime.now().difference(_lastRepTime!).inMilliseconds > 600;
  }

  void reset() {
    _repCount = 0;
    _isInDownPosition = false;
    _lastRepTime = null;
    _lowConfidence = false;
  }
}
