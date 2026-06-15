import 'package:camera/camera.dart';

import 'face_presence_detector.dart';

abstract class CameraFaceSource {
  Future<FacePresenceObservation> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
    required int faceMissingDurationSeconds,
  });
}

/// Temporary MVP source used until a real on-device face model is connected.
///
/// Replace this with a MediaPipe/TFLite/ONNX face detector implementation.
class PlaceholderCameraFaceSource implements CameraFaceSource {
  const PlaceholderCameraFaceSource({this.assumedFaceCount = 1});

  final int assumedFaceCount;

  @override
  Future<FacePresenceObservation> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
    required int faceMissingDurationSeconds,
  }) async {
    return FacePresenceObservation(
      timestamp: timestamp,
      faceCount: assumedFaceCount,
      primaryFaceConfidence: assumedFaceCount > 0 ? 0.50 : null,
      faceMissingDurationSeconds: faceMissingDurationSeconds,
    );
  }
}
