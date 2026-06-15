import 'face_embedding_connector.dart';
import 'live_face_embedding_source.dart';

abstract class FaceEmbeddingInputProvider {
  Future<FaceEmbeddingInput> buildInput({
    required String studentId,
    required String purpose,
  });
}

class ModelLiveFaceEmbeddingSource implements LiveFaceEmbeddingSource {
  ModelLiveFaceEmbeddingSource({
    required this.connector,
    required this.inputProvider,
  });

  final FaceEmbeddingConnector connector;
  final FaceEmbeddingInputProvider inputProvider;

  @override
  Future<List<double>> getLiveEmbedding({
    required String studentId,
    required String purpose,
  }) async {
    if (!connector.isReady) {
      await connector.load();
    }

    final input = await inputProvider.buildInput(
      studentId: studentId,
      purpose: purpose,
    );
    final output = await connector.run(input);

    if (!output.isUsable) {
      throw StateError('Live face embedding is not usable for verification.');
    }

    return output.embedding;
  }
}
