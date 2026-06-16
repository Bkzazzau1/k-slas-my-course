import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/object_ai/tflite_object_detection_source.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'bundled prohibited object model matches expected tensor contract',
    () async {
      final interpreter = await Interpreter.fromAsset(
        'assets/ml_models/prohibited_object_detector.tflite',
      );
      addTearDown(interpreter.close);

      expect(interpreter.getInputTensor(0).shape, <int>[1, 320, 320, 3]);
      expect(
        interpreter.getOutputTensors(),
        hasLength(greaterThanOrEqualTo(4)),
      );
      expect(interpreter.getOutputTensor(0).shape.last, 4);
      expect(interpreter.getOutputTensor(3).shape, <int>[1]);
    },
  );

  test('bundled source can run a synthetic camera frame', () async {
    final source = TfliteObjectDetectionSource();
    addTearDown(source.dispose);

    final observations = await source.analyzeFrame(
      image: _fakeImage(width: 320, height: 320, value: 128),
      timestamp: DateTime.now(),
    );

    expect(observations, isA<List>());
  });

  test('decoder keeps high confidence prohibited objects', () {
    final timestamp = DateTime.now();

    final observations = TfliteObjectOutputDecoder.decode(
      rawBoxes: const <List<double>>[
        <double>[0.10, 0.20, 0.40, 0.60],
        <double>[0.50, 0.10, 0.80, 0.45],
      ],
      rawClasses: const <double>[1, 2],
      rawScores: const <double>[0.88, 0.74],
      rawCount: 2,
      labels: const <String>['background', 'cell phone', 'book'],
      imageWidth: 1000,
      imageHeight: 500,
      timestamp: timestamp,
      confidenceThreshold: 0.55,
      phoneBlockConfidence: 0.65,
      manualReviewConfidence: 0.45,
      maximumObjects: 8,
      allowedLabels: const <String>{'background'},
    );

    expect(observations, hasLength(2));
    expect(observations.first.label, 'cell phone');
    expect(observations.first.confidence, 0.88);
    expect(observations.first.boundingBox?['x'], 200);
    expect(observations.first.boundingBox?['y'], 50);
    expect(observations.first.boundingBox?['width'], closeTo(400, 0.001));
    expect(observations.first.boundingBox?['height'], closeTo(150, 0.001));
  });

  test('decoder filters low confidence and allowed labels', () {
    final observations = TfliteObjectOutputDecoder.decode(
      rawBoxes: const <List<double>>[
        <double>[0.10, 0.20, 0.40, 0.60],
        <double>[0.50, 0.10, 0.80, 0.45],
      ],
      rawClasses: const <double>[0, 2],
      rawScores: const <double>[0.91, 0.20],
      rawCount: 2,
      labels: const <String>['background', 'cell phone', 'book'],
      imageWidth: 1000,
      imageHeight: 500,
      timestamp: DateTime.now(),
      confidenceThreshold: 0.55,
      phoneBlockConfidence: 0.65,
      manualReviewConfidence: 0.45,
      maximumObjects: 8,
      allowedLabels: const <String>{'background'},
    );

    expect(observations, isEmpty);
  });

  test('decoder respects maximumObjects and sorts by confidence', () {
    final observations = TfliteObjectOutputDecoder.decode(
      rawBoxes: const <List<double>>[
        <double>[0.10, 0.10, 0.30, 0.30],
        <double>[0.20, 0.20, 0.50, 0.50],
        <double>[0.30, 0.30, 0.70, 0.70],
      ],
      rawClasses: const <double>[1, 2, 3],
      rawScores: const <double>[0.70, 0.95, 0.80],
      rawCount: 3,
      labels: const <String>['background', 'cell phone', 'book', 'calculator'],
      imageWidth: 100,
      imageHeight: 100,
      timestamp: DateTime.now(),
      confidenceThreshold: 0.55,
      phoneBlockConfidence: 0.65,
      manualReviewConfidence: 0.45,
      maximumObjects: 2,
      allowedLabels: const <String>{'background'},
    );

    expect(observations, hasLength(2));
    expect(observations.first.label, 'book');
    expect(observations.last.label, 'calculator');
  });

  test('decoder marks phone below block threshold for manual review', () {
    final observations = TfliteObjectOutputDecoder.decode(
      rawBoxes: const <List<double>>[
        <double>[0.10, 0.20, 0.40, 0.60],
      ],
      rawClasses: const <double>[1],
      rawScores: const <double>[0.55],
      rawCount: 1,
      labels: const <String>['background', 'cell phone'],
      imageWidth: 100,
      imageHeight: 100,
      timestamp: DateTime.now(),
      confidenceThreshold: 0.45,
      phoneBlockConfidence: 0.65,
      manualReviewConfidence: 0.45,
      maximumObjects: 8,
      allowedLabels: const <String>{'background'},
      prohibitedLabels: const <String>{'cell phone'},
    );

    expect(observations, hasLength(1));
    expect(observations.first.metadata['reviewPolicy'], 'manualReview');
    expect(observations.first.metadata['requiresHumanDecision'], true);
  });
}

CameraImage _fakeImage({
  required int width,
  required int height,
  required int value,
}) {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // ignore: deprecated_member_use
  return CameraImage.fromPlatformData(<dynamic, dynamic>{
    'format': 35,
    'height': height,
    'width': width,
    'lensAperture': 0.0,
    'sensorExposureTime': 0,
    'sensorSensitivity': 0.0,
    'planes': <dynamic>[
      <dynamic, dynamic>{
        'bytes': Uint8List.fromList(List<int>.filled(width * height, value)),
        'bytesPerRow': width,
        'bytesPerPixel': 1,
        'height': height,
        'width': width,
      },
    ],
  });
}
