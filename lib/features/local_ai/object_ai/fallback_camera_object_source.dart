import 'package:camera/camera.dart';

import 'camera_object_source.dart';
import 'object_detection_detector.dart';

class FallbackCameraObjectSource implements CameraObjectSource {
  FallbackCameraObjectSource({
    required this.primary,
    required this.fallback,
    this.disablePrimaryAfterFailure = true,
  });

  final CameraObjectSource primary;
  final CameraObjectSource fallback;
  final bool disablePrimaryAfterFailure;

  bool _primaryDisabled = false;
  Object? _lastPrimaryError;

  bool get primaryDisabled => _primaryDisabled;
  Object? get lastPrimaryError => _lastPrimaryError;

  @override
  Future<List<ObjectDetectionObservation>> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
  }) async {
    if (!_primaryDisabled) {
      try {
        final observations = await primary.analyzeFrame(
          image: image,
          timestamp: timestamp,
        );
        _lastPrimaryError = null;
        return _tag(observations, path: 'primary');
      } catch (error) {
        _lastPrimaryError = error;
        if (disablePrimaryAfterFailure) {
          _primaryDisabled = true;
        }
      }
    }

    final observations = await fallback.analyzeFrame(
      image: image,
      timestamp: timestamp,
    );
    return _tag(
      observations,
      path: 'fallback',
      error: _lastPrimaryError?.toString(),
    );
  }

  List<ObjectDetectionObservation> _tag(
    List<ObjectDetectionObservation> observations, {
    required String path,
    String? error,
  }) {
    return observations
        .map(
          (observation) => ObjectDetectionObservation(
            timestamp: observation.timestamp,
            label: observation.label,
            confidence: observation.confidence,
            boundingBox: observation.boundingBox,
            isAllowedByPolicy: observation.isAllowedByPolicy,
            metadata: <String, Object?>{
              ...observation.metadata,
              'objectSourcePath': path,
              if (error != null) 'primaryObjectSourceError': error,
            },
          ),
        )
        .toList(growable: false);
  }
}
