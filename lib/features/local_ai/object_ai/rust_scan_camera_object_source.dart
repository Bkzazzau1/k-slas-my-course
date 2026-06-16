import 'package:camera/camera.dart';

import '../../../rust/api/proctoring.dart' as proctoring;
import 'camera_object_source.dart';
import 'object_detection_detector.dart';

class RustScanCameraObjectSource implements CameraObjectSource {
  const RustScanCameraObjectSource({
    this.minimumConfidence = 0.72,
    this.allowedLabels = const <String>{'background', 'none', 'clean'},
  });

  final double minimumConfidence;
  final Set<String> allowedLabels;

  @override
  Future<List<ObjectDetectionObservation>> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
  }) async {
    if (image.planes.isEmpty) return const <ObjectDetectionObservation>[];

    final firstPlane = image.planes.first;
    final decision = proctoring.analyzeScanFrame(
      plane0Bytes: firstPlane.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: firstPlane.bytesPerRow,
      pixelFormat: image.format.raw.toString(),
    );

    return decision.objectLabels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .where((label) => !allowedLabels.contains(label.toLowerCase()))
        .map(
          (label) => ObjectDetectionObservation(
            timestamp: timestamp,
            label: label,
            confidence: minimumConfidence,
            boundingBox: const <String, num>{
              'x': 0,
              'y': 0,
              'width': 1,
              'height': 1,
            },
            isAllowedByPolicy: false,
          ),
        )
        .toList(growable: false);
  }
}
