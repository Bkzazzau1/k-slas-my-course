import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/camera_ai/camera_face_source.dart';
import 'package:my_courses/features/local_ai/camera_ai/face_presence_detector.dart';
import 'package:my_courses/features/local_ai/camera_ai/fallback_camera_face_source.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'FallbackCameraFaceSource should use primary when it succeeds',
    () async {
      final source = FallbackCameraFaceSource(
        primary: _FakeFaceSource(faceCount: 1, source: 'primary_fake'),
        fallback: _FakeFaceSource(faceCount: 0, source: 'fallback_fake'),
      );

      final observation = await source.analyzeFrame(
        image: _fakeImage(),
        timestamp: DateTime.now(),
        faceMissingDurationSeconds: 0,
      );

      expect(observation.faceCount, 1);
      expect(observation.metadata['faceSourcePath'], 'primary');
      expect(source.primaryDisabled, isFalse);
    },
  );

  test(
    'FallbackCameraFaceSource should use fallback after primary failure',
    () async {
      final source = FallbackCameraFaceSource(
        primary: _FailingFaceSource(),
        fallback: _FakeFaceSource(faceCount: 1, source: 'fallback_fake'),
      );

      final observation = await source.analyzeFrame(
        image: _fakeImage(),
        timestamp: DateTime.now(),
        faceMissingDurationSeconds: 3,
      );

      expect(observation.faceCount, 1);
      expect(observation.metadata['faceSourcePath'], 'fallback');
      expect(observation.metadata['primaryFaceSourceError'], isNotNull);
      expect(source.primaryDisabled, isTrue);
    },
  );
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

class _FakeFaceSource implements CameraFaceSource {
  const _FakeFaceSource({required this.faceCount, required this.source});

  final int faceCount;
  final String source;

  @override
  Future<FacePresenceObservation> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
    required int faceMissingDurationSeconds,
  }) async {
    return FacePresenceObservation(
      timestamp: timestamp,
      faceCount: faceCount,
      primaryFaceConfidence: faceCount > 0 ? 0.9 : null,
      faceMissingDurationSeconds: faceMissingDurationSeconds,
      metadata: <String, Object?>{'source': source},
    );
  }
}

class _FailingFaceSource implements CameraFaceSource {
  @override
  Future<FacePresenceObservation> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
    required int faceMissingDurationSeconds,
  }) async {
    throw StateError('model asset unavailable');
  }
}
