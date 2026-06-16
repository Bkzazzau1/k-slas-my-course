import 'package:camera/camera.dart';

import 'face_embedding_connector.dart';
import 'preprocessed_camera_face_embedding_input_provider.dart';

class CameraFaceEnrollmentSample {
  const CameraFaceEnrollmentSample({
    required this.embedding,
    required this.modelVersion,
    required this.qualityScore,
    required this.inferenceTimeMs,
  });

  final List<double> embedding;
  final String modelVersion;
  final double? qualityScore;
  final int inferenceTimeMs;
}

class CameraFaceEnrollmentSampler {
  CameraFaceEnrollmentSampler({
    required this.cameraController,
    required this.connector,
  });

  final CameraController cameraController;
  final FaceEmbeddingConnector connector;

  Future<CameraFaceEnrollmentSample> captureSample({
    required String studentId,
  }) async {
    if (!cameraController.value.isInitialized) {
      throw StateError('Camera is not initialized for face enrollment.');
    }

    if (!connector.isReady) {
      await connector.load();
    }

    final inputProvider = PreprocessedCameraFaceEmbeddingInputProvider(
      cameraController: cameraController,
    );
    final input = await inputProvider.buildInput(
      studentId: studentId,
      purpose: 'face_enrollment',
    );
    final output = await connector.run(input);
    if (!output.isUsable) {
      throw StateError('Face embedding output is not usable for enrollment.');
    }

    return CameraFaceEnrollmentSample(
      embedding: output.embedding,
      modelVersion: output.modelVersion,
      qualityScore: output.qualityScore,
      inferenceTimeMs: output.inferenceTimeMs,
    );
  }
}
