import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'face_image_decoder.dart';
import 'face_image_preprocessor.dart';

class JpegFaceImageDecoder implements FaceImageDecoder {
  const JpegFaceImageDecoder();

  @override
  bool canDecode(String format) {
    final value = format.toLowerCase();
    return value == 'jpeg' || value == 'jpg' || value == 'png';
  }

  @override
  Future<DecodedFaceImage> decode(FaceImagePreprocessRequest request) async {
    if (!canDecode(request.format)) {
      throw ArgumentError('Unsupported image format: ${request.format}');
    }

    final decoded = img.decodeImage(Uint8List.fromList(request.values));
    if (decoded == null) {
      throw StateError('Unable to decode face image.');
    }

    final rgbValues = decoded.getBytes(order: img.ChannelOrder.rgb);

    return DecodedFaceImage(
      values: rgbValues.toList(),
      width: decoded.width,
      height: decoded.height,
      format: 'rgb',
      metadata: <String, Object?>{
        ...request.metadata,
        'decoded': true,
        'sourceFormat': request.format,
        'decodedWidth': decoded.width,
        'decodedHeight': decoded.height,
      },
    );
  }
}
