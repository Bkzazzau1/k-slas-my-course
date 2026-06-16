import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/camera_ai/tflite_face_model_connector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('TfliteFaceModelConnector should load bundled face detector', () async {
    final connector = TfliteFaceModelConnector();

    await connector.load();
    final output = await connector.detectFaces(_fakeImage());
    await connector.dispose();

    expect(output.imageWidth, 128);
    expect(output.imageHeight, 128);
    expect(output.faces.length, lessThanOrEqualTo(4));
  });

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
    expect(faces.first.width, closeTo(400, 0.0001));
    expect(faces.first.height, closeTo(200, 0.0001));
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

CameraImage _fakeImage() {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // ignore: deprecated_member_use
  return CameraImage.fromPlatformData(<dynamic, dynamic>{
    'format': 35,
    'height': 128,
    'width': 128,
    'lensAperture': 0.0,
    'sensorExposureTime': 0,
    'sensorSensitivity': 0.0,
    'planes': <dynamic>[
      <dynamic, dynamic>{
        'bytes': Uint8List.fromList(List<int>.filled(128 * 128, 128)),
        'bytesPerRow': 128,
        'bytesPerPixel': 1,
        'height': 128,
        'width': 128,
      },
    ],
  });
}
