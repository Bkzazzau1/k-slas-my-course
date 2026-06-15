import 'face_image_preprocessor.dart';

class DecodedFaceImage {
  const DecodedFaceImage({
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

abstract class FaceImageDecoder {
  bool canDecode(String format);

  Future<DecodedFaceImage> decode(FaceImagePreprocessRequest request);
}
