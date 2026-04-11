import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/rep_counting_service.dart';
import '../services/dio_client.dart';

class CameraRepCounterScreen extends StatefulWidget {
  final String exerciseType;
  final String exerciseName;
  
  const CameraRepCounterScreen({
    Key? key,
    required this.exerciseType,
    required this.exerciseName,
  }) : super(key: key);

  @override
  State<CameraRepCounterScreen> createState() => _CameraRepCounterScreenState();
}

class _CameraRepCounterScreenState extends State<CameraRepCounterScreen> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  RepCountingService? _repCounter;
  bool _isProcessing = false;
  bool _isPaused = false;
  String? _sessionId;
  double _confidence = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _repCounter = RepCountingService(widget.exerciseType);
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _createSession();
  }
  
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No camera available');
        return;
      }
      
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {});
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      _showError('Camera initialization failed: $e');
    }
  }
  
  Future<void> _createSession() async {
    try {
      final dio = DioClient.instance;
      final response = await dio.post('/workouts/rep-sessions/', data: {
        'exercise_type': widget.exerciseType,
      });
      
      setState(() {
        _sessionId = response.data['id'].toString();
      });
    } catch (e) {
      print('Error creating session: $e');
    }
  }
  
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isPaused || _poseDetector == null) return;
    
    _isProcessing = true;
    
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }
      
      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty && _repCounter != null) {
        final pose = poses.first;
        
        // Calculate average confidence
        double totalConfidence = 0;
        int landmarkCount = 0;
        for (final landmark in pose.landmarks.values) {
          totalConfidence += landmark.likelihood;
          landmarkCount++;
        }
        final avgConfidence = landmarkCount > 0 ? totalConfidence / landmarkCount : 0.0;
        
        setState(() {
          _confidence = avgConfidence;
        });
        
        // Process pose for rep detection
        final repDetected = _repCounter!.processPose(pose);
        
        if (repDetected && _sessionId != null) {
          // Send rep event to backend
          _addRepEvent(avgConfidence);
        }
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  InputImage? _convertCameraImage(CameraImage image) {
    // Simplified conversion - in production, handle rotation and format properly
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }
  
  Future<void> _addRepEvent(double confidence) async {
    if (_sessionId == null) return;
    
    try {
      final dio = DioClient.instance;
      await dio.post('/workouts/rep-sessions/$_sessionId/add-rep/', data: {
        'confidence': confidence,
        'angle_data': {},
      });
    } catch (e) {
      print('Error adding rep event: $e');
    }
  }
  
  Future<void> _endSession() async {
    if (_sessionId == null) return;
    
    try {
      final dio = DioClient.instance;
      await dio.post('/workouts/rep-sessions/$_sessionId/end-session/');
      
      // Navigate to review screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error ending session: $e');
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      showCenterToast(context, message, isError: true);
    }
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.exerciseName),
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            Center(
              child: CameraPreview(_cameraController!),
            ),
            
            // Top bar with exercise name and confidence
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.exerciseName,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildConfidenceIndicator(),
                  ],
                ),
              ),
            ),
            
            // Rep counter display
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '${_repCounter?.repCount ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Control buttons
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isPaused ? Icons.play_arrow : Icons.pause,
                    label: _isPaused ? 'Resume' : 'Pause',
                    onPressed: () {
                      setState(() {
                        _isPaused = !_isPaused;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.stop,
                    label: 'Stop',
                    color: const Color(0xFFE53935),
                    onPressed: _endSession,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfidenceIndicator() {
    Color color;
    if (_confidence > 0.8) {
      color = Colors.green;
    } else if (_confidence > 0.6) {
      color = Colors.orange;
    } else {
      color = const Color(0xFFE53935);
    }
    
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(_confidence * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final buttonColor = color ?? Colors.white;
    final iconColor = color != null ? Colors.white : const Color(0xFFE53935);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon),
            iconSize: 32,
            color: iconColor,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  bool _canCountRep() {
    if (_lastRepTime == null) return true;
    
    final timeSinceLastRep = DateTime.now().difference(_lastRepTime!);
    return timeSinceLastRep.inMilliseconds > 500;
  }
}
