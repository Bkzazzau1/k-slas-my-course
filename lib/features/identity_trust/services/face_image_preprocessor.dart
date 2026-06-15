import 'face_embedding_connector.dart';

class FaceImagePreprocessConfig {
  const FaceImagePreprocessConfig({
    this.targetWidth = 112,
    this.targetHeight = 112,
    this.normalizationMean = 127.5,
    this.normalizationStd = 128.0,
  });

  final int targetWidth;
  final int targetHeight;
  final double normalizationMean;
  final double normalizationStd;
}

class FaceImagePreprocessRequest {
  const FaceImagePreprocessRequest({
    required this.values,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.format,
    this.metadata = const <String, Object?>{},
  });

  final List<int> values;
  final int sourceWidth;
  final int sourceHeight;
  final String format;
  final Map<String, Object?> metadata;
}

abstract class FaceImagePreprocessor {
  Future<FaceEmbeddingInput> preprocess(FaceImagePreprocessRequest request);
}

class PassThroughFaceImagePreprocessor implements FaceImagePreprocessor {
  const PassThroughFaceImagePreprocessor({
    this.config = const FaceImagePreprocessConfig(),
  });

  final FaceImagePreprocessConfig config;

  @override
  Future<FaceEmbeddingInput> preprocess(FaceImagePreprocessRequest request) async {
    return FaceEmbeddingInput(
      values: request.values,
      width: request.sourceWidth,
      height: request.sourceHeight,
      format: request.format,
      metadata: <String, Object?>{
        ...request.metadata,
        'preprocessed': false,
        'targetWidth': config.targetWidth,
        'targetHeight': config.targetHeight,
        'normalizationMean': config.normalizationMean,
        'normalizationStd': config.normalizationStd,
      },
    );
  }
}
