import 'package:camera/camera.dart';

import 'camera_face_source.dart';
import 'face_model_connector.dart';
import 'face_presence_detector.dart';

class ModelBackedFaceSource implements CameraFaceSource {
  ModelBackedFaceSource({required this.connector});

  final FaceModelConnector connector;

  @override
  Future<FacePresenceObservation> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
    required int faceMissingDurationSeconds,
  }) async {
    if (!connector.isReady) {
      await connector.load();
    }

    final output = await connector.detectFaces(image);
    return FacePresenceObservation(
      timestamp: timestamp,
      faceCount: output.faceCount,
      primaryFaceConfidence: output.primaryFaceConfidence,
      faceMissingDurationSeconds: faceMissingDurationSeconds,
      metadata: output.toJson(),
    );
  }
}
