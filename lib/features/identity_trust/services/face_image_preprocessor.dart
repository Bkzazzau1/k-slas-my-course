import 'face_embedding_connector.dart';
import 'rgb_face_resizer.dart';

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
    this.resizer = const RgbFaceResizer(),
  });

  final FaceImagePreprocessConfig config;
  final RgbFaceResizer resizer;

  @override
  Future<FaceEmbeddingInput> preprocess(FaceImagePreprocessRequest request) async {
    final isRgb = request.format.toLowerCase() == 'rgb';
    final canResize = isRgb && request.sourceWidth > 0 && request.sourceHeight > 0;
    final outputValues = canResize
        ? resizer.resizeCenterSquare(
            RgbFaceResizeRequest(
              values: request.values,
              sourceWidth: request.sourceWidth,
              sourceHeight: request.sourceHeight,
              targetWidth: config.targetWidth,
              targetHeight: config.targetHeight,
            ),
          )
        : request.values;

    return FaceEmbeddingInput(
      values: outputValues,
      width: canResize ? config.targetWidth : request.sourceWidth,
      height: canResize ? config.targetHeight : request.sourceHeight,
      format: request.format,
      metadata: <String, Object?>{
        ...request.metadata,
        'preprocessed': canResize,
        'targetWidth': config.targetWidth,
        'targetHeight': config.targetHeight,
        'normalizationMean': config.normalizationMean,
        'normalizationStd': config.normalizationStd,
      },
    );
  }
}
