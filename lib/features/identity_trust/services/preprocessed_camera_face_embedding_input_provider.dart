import 'package:camera/camera.dart';

import 'face_embedding_connector.dart';
import 'face_image_preprocessor.dart';
import 'model_live_face_embedding_source.dart';

class PreprocessedCameraFaceEmbeddingInputProvider
    implements FaceEmbeddingInputProvider {
  PreprocessedCameraFaceEmbeddingInputProvider({
    required this.cameraController,
    this.preprocessor = const PassThroughFaceImagePreprocessor(),
  });

  final CameraController cameraController;
  final FaceImagePreprocessor preprocessor;

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

    return preprocessor.preprocess(
      FaceImagePreprocessRequest(
        values: values,
        sourceWidth: 0,
        sourceHeight: 0,
        format: 'jpeg',
        metadata: <String, Object?>{
          'studentId': studentId,
          'purpose': purpose,
          'source': 'camera_still',
          'path': file.path,
        },
      ),
    );
  }
}
