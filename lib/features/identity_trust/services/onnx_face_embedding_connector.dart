import 'face_embedding_connector.dart';

class OnnxFaceEmbeddingConfig {
  const OnnxFaceEmbeddingConfig({
    this.modelAssetPath = 'assets/ml_models/mobilefacenet.onnx',
    this.modelVersion = 'mobilefacenet-onnx-v1',
    this.inputWidth = 112,
    this.inputHeight = 112,
    this.embeddingSize = 192,
    this.normalizationMean = 127.5,
    this.normalizationStd = 128.0,
  });

  final String modelAssetPath;
  final String modelVersion;
  final int inputWidth;
  final int inputHeight;
  final int embeddingSize;
  final double normalizationMean;
  final double normalizationStd;
}

class OnnxFaceEmbeddingConnector implements FaceEmbeddingConnector {
  OnnxFaceEmbeddingConnector({this.config = const OnnxFaceEmbeddingConfig()});

  final OnnxFaceEmbeddingConfig config;
  bool _ready = false;

  @override
  String get connectorId => 'onnx_face_embedding_connector';

  @override
  String get modelVersion => config.modelVersion;

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
      embedding: const <double>[],
      modelVersion: config.modelVersion,
      inferenceTimeMs: 0,
      qualityScore: 0,
    );
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
