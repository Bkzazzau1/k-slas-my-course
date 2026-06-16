import 'package:camera/camera.dart';

import 'object_detection_detector.dart';

abstract class CameraObjectSource {
  Future<List<ObjectDetectionObservation>> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
  });
}

class NoopCameraObjectSource implements CameraObjectSource {
  const NoopCameraObjectSource();

  @override
  Future<List<ObjectDetectionObservation>> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
  }) async {
    return const <ObjectDetectionObservation>[];
  }
}
