import 'face_embedding_connector.dart';
import 'face_embedding_vector_utils.dart';
import 'local_face_embedding_runner.dart';

class TfliteFaceEmbeddingConfig {
  const TfliteFaceEmbeddingConfig({
    this.modelAssetPath = 'assets/ml_models/mobilefacenet.tflite',
    this.modelVersion = 'mobilefacenet-tflite-v1',
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

class TfliteFaceEmbeddingConnector implements FaceEmbeddingConnector {
  TfliteFaceEmbeddingConnector({
    this.config = const TfliteFaceEmbeddingConfig(),
    LocalFaceEmbeddingRunner? runner,
  }) : _runner = runner ?? const EmptyLocalFaceEmbeddingRunner();

  final TfliteFaceEmbeddingConfig config;
  final LocalFaceEmbeddingRunner _runner;
  bool _ready = false;

  @override
  String get connectorId => 'tflite_face_embedding_connector';

  @override
  String get modelVersion => config.modelVersion;

  @override
  bool get isReady => _ready;

  @override
  Future<void> load() async {
    await _runner.load(config.modelAssetPath);
    _ready = true;
  }

  @override
  Future<FaceEmbeddingOutput> run(FaceEmbeddingInput input) async {
    if (!_ready) await load();
    final startedAt = DateTime.now();
    final expectedLength = config.inputWidth * config.inputHeight * 3;
    final validInput = input.format.toLowerCase() == 'rgb' &&
        input.width == config.inputWidth &&
        input.height == config.inputHeight &&
        input.values.length >= expectedLength;
    if (!validInput) return _emptyOutput(startedAt);

    final modelInput = FaceEmbeddingVectorUtils.normalizeRgb(
      values: input.values,
      expectedLength: expectedLength,
      mean: config.normalizationMean,
      std: config.normalizationStd,
    );
    if (modelInput.isEmpty) return _emptyOutput(startedAt);

    final rawEmbedding = await _runner.run(
      LocalFaceEmbeddingRunnerInput(
        values: modelInput,
        width: config.inputWidth,
        height: config.inputHeight,
        channels: 3,
      ),
    );
    final embedding = FaceEmbeddingVectorUtils.l2Normalize(rawEmbedding);

    return FaceEmbeddingOutput(
      embedding: embedding,
      modelVersion: config.modelVersion,
      inferenceTimeMs: DateTime.now().difference(startedAt).inMilliseconds,
      qualityScore: embedding.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<void> dispose() async {
    await _runner.dispose();
    _ready = false;
  }

  FaceEmbeddingOutput _emptyOutput(DateTime startedAt) {
    return FaceEmbeddingOutput(
      embedding: const <double>[],
      modelVersion: config.modelVersion,
      inferenceTimeMs: DateTime.now().difference(startedAt).inMilliseconds,
      qualityScore: 0,
    );
  }
}
