abstract class LiveFaceEmbeddingSource {
  Future<List<double>> getLiveEmbedding({
    required String studentId,
    required String purpose,
  });
}

class StaticLiveFaceEmbeddingSource implements LiveFaceEmbeddingSource {
  const StaticLiveFaceEmbeddingSource({required this.embedding});

  final List<double> embedding;

  @override
  Future<List<double>> getLiveEmbedding({
    required String studentId,
    required String purpose,
  }) async {
    return embedding;
  }
}
