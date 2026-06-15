import 'face_embedding_connector.dart';
import 'face_image_decoder.dart';
import 'jpeg_face_image_decoder.dart';
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
    this.decoder = const JpegFaceImageDecoder(),
  });

  final FaceImagePreprocessConfig config;
  final RgbFaceResizer resizer;
  final FaceImageDecoder decoder;

  @override
  Future<FaceEmbeddingInput> preprocess(FaceImagePreprocessRequest request) async {
    final preparedRequest = await _decodeIfNeeded(request);
    final isRgb = preparedRequest.format.toLowerCase() == 'rgb';
    final canResize = isRgb &&
        preparedRequest.sourceWidth > 0 &&
        preparedRequest.sourceHeight > 0;

    final outputValues = canResize
        ? resizer.resizeCenterSquare(
            RgbFaceResizeRequest(
              values: preparedRequest.values,
              sourceWidth: preparedRequest.sourceWidth,
              sourceHeight: preparedRequest.sourceHeight,
              targetWidth: config.targetWidth,
              targetHeight: config.targetHeight,
            ),
          )
        : preparedRequest.values;

    return FaceEmbeddingInput(
      values: outputValues,
      width: canResize ? config.targetWidth : preparedRequest.sourceWidth,
      height: canResize ? config.targetHeight : preparedRequest.sourceHeight,
      format: canResize ? 'rgb' : preparedRequest.format,
      metadata: <String, Object?>{
        ...preparedRequest.metadata,
        'preprocessed': canResize,
        'targetWidth': config.targetWidth,
        'targetHeight': config.targetHeight,
        'normalizationMean': config.normalizationMean,
        'normalizationStd': config.normalizationStd,
      },
    );
  }

  Future<FaceImagePreprocessRequest> _decodeIfNeeded(
    FaceImagePreprocessRequest request,
  ) async {
    if (request.format.toLowerCase() == 'rgb') return request;
    if (!decoder.canDecode(request.format)) return request;

    final decoded = await decoder.decode(request);
    return FaceImagePreprocessRequest(
      values: decoded.values,
      sourceWidth: decoded.width,
      sourceHeight: decoded.height,
      format: decoded.format,
      metadata: decoded.metadata,
    );
  }
}
