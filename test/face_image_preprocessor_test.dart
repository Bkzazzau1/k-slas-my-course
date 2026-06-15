import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/identity_trust.dart';

void main() {
  test('pass through preprocessor returns embedding input metadata', () async {
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

    expect(input.values, <int>[1, 2, 3]);
    expect(input.width, 1);
    expect(input.height, 1);
    expect(input.format, 'rgb');
    expect(input.metadata['preprocessed'], false);
    expect(input.metadata['targetWidth'], 112);
  });
}
