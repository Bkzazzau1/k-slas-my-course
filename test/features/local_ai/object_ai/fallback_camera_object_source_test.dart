import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/object_ai/camera_object_source.dart';
import 'package:my_courses/features/local_ai/object_ai/fallback_camera_object_source.dart';
import 'package:my_courses/features/local_ai/object_ai/object_detection_detector.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('uses primary object source when it succeeds', () async {
    final source = FallbackCameraObjectSource(
      primary: const _FakeObjectSource(label: 'cell phone'),
      fallback: const _FakeObjectSource(label: 'book'),
    );

    final observations = await source.analyzeFrame(
      image: _fakeImage(),
      timestamp: DateTime.now(),
    );

    expect(observations, hasLength(1));
    expect(observations.first.label, 'cell phone');
    expect(observations.first.metadata['objectSourcePath'], 'primary');
    expect(source.primaryDisabled, isFalse);
  });

  test('uses fallback after primary failure', () async {
    final source = FallbackCameraObjectSource(
      primary: _FailingObjectSource(),
      fallback: const _FakeObjectSource(label: 'book'),
    );

    final observations = await source.analyzeFrame(
      image: _fakeImage(),
      timestamp: DateTime.now(),
    );

    expect(observations, hasLength(1));
    expect(observations.first.label, 'book');
    expect(observations.first.metadata['objectSourcePath'], 'fallback');
    expect(observations.first.metadata['primaryObjectSourceError'], isNotNull);
    expect(source.primaryDisabled, isTrue);
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

class _FakeObjectSource implements CameraObjectSource {
  const _FakeObjectSource({required this.label});

  final String label;

  @override
  Future<List<ObjectDetectionObservation>> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
  }) async {
    return <ObjectDetectionObservation>[
      ObjectDetectionObservation(
        timestamp: timestamp,
        label: label,
        confidence: 0.8,
      ),
    ];
  }
}

class _FailingObjectSource implements CameraObjectSource {
  @override
  Future<List<ObjectDetectionObservation>> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
  }) async {
    throw StateError('object model unavailable');
  }
}
