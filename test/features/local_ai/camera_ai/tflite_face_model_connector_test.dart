import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/camera_ai/tflite_face_model_connector.dart';

void main() {
  test('FaceModelOutputDecoder should keep boxes above threshold', () {
    final faces = FaceModelOutputDecoder.decode(
      boxes: const <List<double>>[
        <double>[0.10, 0.20, 0.50, 0.60],
        <double>[0.20, 0.30, 0.55, 0.62],
      ],
      scores: const <double>[0.80, 0.20],
      imageWidth: 1000,
      imageHeight: 500,
      confidenceThreshold: 0.55,
      maximumFaces: 4,
    );

    expect(faces, hasLength(1));
    expect(faces.first.left, 200);
    expect(faces.first.top, 50);
    expect(faces.first.width, 400);
    expect(faces.first.height, 200);
    expect(faces.first.confidence, 0.80);
  });

  test('FaceModelOutputDecoder should sort faces by confidence', () {
    final faces = FaceModelOutputDecoder.decode(
      boxes: const <List<double>>[
        <double>[0.10, 0.10, 0.30, 0.30],
        <double>[0.40, 0.40, 0.70, 0.70],
      ],
      scores: const <double>[0.61, 0.93],
      imageWidth: 800,
      imageHeight: 600,
      confidenceThreshold: 0.55,
      maximumFaces: 4,
    );

    expect(faces, hasLength(2));
    expect(faces.first.confidence, 0.93);
    expect(faces.last.confidence, 0.61);
  });

  test('FaceModelOutputDecoder should ignore invalid boxes', () {
    final faces = FaceModelOutputDecoder.decode(
      boxes: const <List<double>>[
        <double>[0.10, 0.10, 0.10, 0.30],
        <double>[0.40, 0.40],
      ],
      scores: const <double>[0.99, 0.99],
      imageWidth: 800,
      imageHeight: 600,
      confidenceThreshold: 0.55,
      maximumFaces: 4,
    );

    expect(faces, isEmpty);
  });
}
