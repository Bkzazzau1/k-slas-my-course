class FaceEmbeddingInput {
  const FaceEmbeddingInput({
    required this.values,
    required this.width,
    required this.height,
    required this.format,
    this.metadata = const <String, Object?>{},
  });

  final List<int> values;
  final int width;
  final int height;
  final String format;
  final Map<String, Object?> metadata;
}

class FaceEmbeddingOutput {
  const FaceEmbeddingOutput({
    required this.embedding,
    required this.modelVersion,
    required this.inferenceTimeMs,
    this.qualityScore,
  });

  final List<double> embedding;
  final String modelVersion;
  final int inferenceTimeMs;
  final double? qualityScore;

  bool get isUsable => embedding.isNotEmpty && (qualityScore == null || qualityScore! >= 0.50);

  Map<String, Object?> toJson() => <String, Object?>{
        'embeddingLength': embedding.length,
        'modelVersion': modelVersion,
        'inferenceTimeMs': inferenceTimeMs,
        'qualityScore': qualityScore,
      };
}

abstract class FaceEmbeddingConnector {
  String get connectorId;
  String get modelVersion;
  bool get isReady;

  Future<void> load();

  Future<FaceEmbeddingOutput> run(FaceEmbeddingInput input);

  Future<void> dispose();
}
