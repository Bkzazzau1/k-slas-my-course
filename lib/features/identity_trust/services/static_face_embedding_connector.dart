import 'face_embedding_connector.dart';

class StaticFaceEmbeddingConnector implements FaceEmbeddingConnector {
  StaticFaceEmbeddingConnector({
    required this.embedding,
    this.version = 'static-embedding-v1',
    this.qualityScore = 1.0,
  });

  final List<double> embedding;
  final String version;
  final double qualityScore;
  bool _ready = false;

  @override
  String get connectorId => 'static_face_embedding_connector';

  @override
  String get modelVersion => version;

  @override
  bool get isReady => _ready;

  @override
  Future<void> load() async {
    _ready = true;
  }

  @override
  Future<FaceEmbeddingOutput> run(FaceEmbeddingInput input) async {
    if (!_ready) await load();
    return FaceEmbeddingOutput(
      embedding: embedding,
      modelVersion: version,
      inferenceTimeMs: 1,
      qualityScore: qualityScore,
    );
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
