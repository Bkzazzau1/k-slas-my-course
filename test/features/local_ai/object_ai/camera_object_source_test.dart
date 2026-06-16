import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/object_ai/camera_object_source.dart';
import 'package:my_courses/features/local_ai/object_ai/object_detection_detector.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('NoopCameraObjectSource returns no observations', () async {
    final source = const NoopCameraObjectSource();

    final observations = await source.analyzeFrame(
      image: _fakeImage(),
      timestamp: DateTime.now(),
    );

    expect(observations, isEmpty);
  });

  test('ObjectDetectionDetector emits phone event for phone labels', () async {
    final detector = ObjectDetectionDetector();

    final events = await detector.analyze(
      ObjectDetectionObservation(
        timestamp: DateTime.now(),
        label: 'cell phone',
        confidence: 0.82,
      ),
    );

    expect(events, hasLength(1));
    expect(events.first.type.name, 'phoneDetected');
    expect(events.first.riskPoints, 30);
  });

  test('ObjectDetectionDetector emits prohibited material for other labels', () async {
    final detector = ObjectDetectionDetector();

    final events = await detector.analyze(
      ObjectDetectionObservation(
        timestamp: DateTime.now(),
        label: 'book',
        confidence: 0.75,
      ),
    );

    expect(events, hasLength(1));
    expect(events.first.type.name, 'prohibitedMaterialDetected');
    expect(events.first.riskPoints, 25);
  });

  test('ObjectDetectionDetector ignores policy-allowed labels', () async {
    final detector = ObjectDetectionDetector();

    final events = await detector.analyze(
      ObjectDetectionObservation(
        timestamp: DateTime.now(),
        label: 'book',
        confidence: 0.75,
        isAllowedByPolicy: true,
      ),
    );

    expect(events, isEmpty);
  });
}

CameraImage _fakeImage() {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // ignore: deprecated_member_use
  return CameraImage.fromPlatformData(<dynamic, dynamic>{
    'format': 35,
    'height': 1,
    'width': 1,
    'lensAperture': 0.0,
    'sensorExposureTime': 0,
    'sensorSensitivity': 0.0,
    'planes': <dynamic>[
      <dynamic, dynamic>{
        'bytes': Uint8List.fromList(<int>[0]),
        'bytesPerRow': 1,
        'bytesPerPixel': 1,
        'height': 1,
        'width': 1,
      },
    ],
  });
}
