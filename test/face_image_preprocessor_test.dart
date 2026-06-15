import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:my_courses/features/identity_trust/identity_trust.dart';

void main() {
  test('RGB preprocessor resizes to model input size', () async {
    const preprocessor = PassThroughFaceImagePreprocessor();

    final input = await preprocessor.preprocess(
      const FaceImagePreprocessRequest(
        values: <int>[1, 2, 3],
        sourceWidth: 1,
        sourceHeight: 1,
        format: 'rgb',
        metadata: <String, Object?>{
          'studentId': 'KASU/CSC/001',
        },
      ),
    );

    expect(input.width, 112);
    expect(input.height, 112);
    expect(input.format, 'rgb');
    expect(input.values.length, 112 * 112 * 3);
    expect(input.metadata['preprocessed'], true);
  });

  test('JPEG preprocessor decodes and resizes camera image', () async {
    const preprocessor = PassThroughFaceImagePreprocessor();
    final image = img.Image(width: 2, height: 2);
    image.setPixelRgb(0, 0, 255, 0, 0);
    image.setPixelRgb(1, 0, 0, 255, 0);
    image.setPixelRgb(0, 1, 0, 0, 255);
    image.setPixelRgb(1, 1, 255, 255, 255);
    final jpegValues = img.encodeJpg(image);

    final input = await preprocessor.preprocess(
      FaceImagePreprocessRequest(
        values: jpegValues,
        sourceWidth: 0,
        sourceHeight: 0,
        format: 'jpeg',
      ),
    );

    expect(input.width, 112);
    expect(input.height, 112);
    expect(input.format, 'rgb');
    expect(input.values.length, 112 * 112 * 3);
    expect(input.metadata['decoded'], true);
    expect(input.metadata['preprocessed'], true);
  });
}
