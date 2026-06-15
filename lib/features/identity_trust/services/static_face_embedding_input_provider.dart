import 'face_embedding_connector.dart';
import 'model_live_face_embedding_source.dart';

class StaticFaceEmbeddingInputProvider implements FaceEmbeddingInputProvider {
  const StaticFaceEmbeddingInputProvider({
    this.width = 112,
    this.height = 112,
    this.format = 'rgb',
  });

  final int width;
  final int height;
  final String format;

  @override
  Future<FaceEmbeddingInput> buildInput({
    required String studentId,
    required String purpose,
  }) async {
    return FaceEmbeddingInput(
      values: List<int>.filled(width * height * 3, 0),
      width: width,
      height: height,
      format: format,
      metadata: <String, Object?>{
        'studentId': studentId,
        'purpose': purpose,
      },
    );
  }
}
