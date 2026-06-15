import 'package:camera/camera.dart';

import 'face_embedding_connector.dart';
import 'model_live_face_embedding_source.dart';

class CameraFaceEmbeddingInputProvider implements FaceEmbeddingInputProvider {
  CameraFaceEmbeddingInputProvider({required this.cameraController});

  final CameraController cameraController;

  @override
  Future<FaceEmbeddingInput> buildInput({
    required String studentId,
    required String purpose,
  }) async {
    if (!cameraController.value.isInitialized) {
      throw StateError('Camera is not initialized for face verification.');
    }

    if (cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
    }

    final file = await cameraController.takePicture();
    final values = await file.readAsBytes();

    return FaceEmbeddingInput(
      values: values,
      width: 0,
      height: 0,
      format: 'jpeg',
      metadata: <String, Object?>{
        'studentId': studentId,
        'purpose': purpose,
        'source': 'camera_still',
        'path': file.path,
      },
    );
  }
}
