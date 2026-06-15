import 'package:flutter_test/flutter_test.dart';
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

  test('JPEG preprocessor passes through until decoder is added', () async {
    const preprocessor = PassThroughFaceImagePreprocessor();

    final input = await preprocessor.preprocess(
      const FaceImagePreprocessRequest(
        values: <int>[1, 2, 3, 4],
        sourceWidth: 0,
        sourceHeight: 0,
        format: 'jpeg',
      ),
    );

    expect(input.values, <int>[1, 2, 3, 4]);
    expect(input.width, 0);
    expect(input.height, 0);
    expect(input.metadata['preprocessed'], false);
  });
}
