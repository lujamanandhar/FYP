import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class RepCountingService {
  final String exerciseType;
  int _repCount = 0;
  bool _isInDownPosition = false;
  DateTime? _lastRepTime;
  
  RepCountingService(this.exerciseType);
  
  int get repCount => _repCount;
  
  /// Process pose landmarks and detect reps
  /// Returns true if a new rep was detected
  bool processPose(Pose pose) {
    final landmarks = pose.landmarks;
    
    switch (exerciseType) {
      case 'PUSH_UP':
        return _detectPushUp(landmarks);
      case 'SQUAT':
        return _detectSquat(landmarks);
      case 'BICEP_CURL':
        return _detectBicepCurl(landmarks);
      default:
        return false;
    }
  }
  
  bool _detectPushUp(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Get landmarks for elbow angle
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    
    if (leftShoulder == null || leftElbow == null || leftWrist == null) {
      return false;
    }
    
    // Calculate elbow angle
    final angle = _calculateAngle(
      leftShoulder.x, leftShoulder.y,
      leftElbow.x, leftElbow.y,
      leftWrist.x, leftWrist.y,
    );
    
    // Push-up detection: angle < 100° = down, angle > 160° = up
    if (angle < 100 && !_isInDownPosition) {
      _isInDownPosition = true;
    } else if (angle > 160 && _isInDownPosition) {
      if (_canCountRep()) {
        _repCount++;
        _isInDownPosition = false;
        _lastRepTime = DateTime.now();
        return true;
      }
    }
    
    return false;
  }
  
  bool _detectSquat(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Get landmarks for knee angle
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    
    if (leftHip == null || leftKnee == null || leftAnkle == null) {
      return false;
    }
    
    // Calculate knee angle
    final angle = _calculateAngle(
      leftHip.x, leftHip.y,
      leftKnee.x, leftKnee.y,
      leftAnkle.x, leftAnkle.y,
    );
    
    // Squat detection: angle < 100° = down, angle > 160° = up
    if (angle < 100 && !_isInDownPosition) {
      _isInDownPosition = true;
    } else if (angle > 160 && _isInDownPosition) {
      if (_canCountRep()) {
        _repCount++;
        _isInDownPosition = false;
        _lastRepTime = DateTime.now();
        return true;
      }
    }
    
    return false;
  }
  
  bool _detectBicepCurl(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Get landmarks for elbow angle
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    
    if (leftShoulder == null || leftElbow == null || leftWrist == null) {
      return false;
    }
    
    // Calculate elbow angle
    final angle = _calculateAngle(
      leftShoulder.x, leftShoulder.y,
      leftElbow.x, leftElbow.y,
      leftWrist.x, leftWrist.y,
    );
    
    // Bicep curl detection: angle < 60° = curled, angle > 150° = extended
    if (angle < 60 && !_isInDownPosition) {
      _isInDownPosition = true;
    } else if (angle > 150 && _isInDownPosition) {
      if (_canCountRep()) {
        _repCount++;
        _isInDownPosition = false;
        _lastRepTime = DateTime.now();
        return true;
      }
    }
    
    return false;
  }
  
  /// Calculate angle between three points
  double _calculateAngle(double x1, double y1, double x2, double y2, double x3, double y3) {
    final radians = atan2(y3 - y2, x3 - x2) - atan2(y1 - y2, x1 - x2);
    var angle = radians.abs() * 180 / pi;
    
    if (angle > 180) {
      angle = 360 - angle;
    }
    
    return angle;
  }
  
  /// Check if enough time has passed since last rep (prevent false positives)
  bool _canCountRep() {
    if (_lastRepTime == null) return true;
    
    final timeSinceLastRep = DateTime.now().difference(_lastRepTime!);
    return timeSinceLastRep.inMilliseconds > 500; // 0.5 second minimum
  }
  
  void reset() {
    _repCount = 0;
    _isInDownPosition = false;
    _lastRepTime = null;
  }
}
