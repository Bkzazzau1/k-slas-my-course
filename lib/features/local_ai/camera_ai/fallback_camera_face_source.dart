import 'package:camera/camera.dart';

import 'camera_face_source.dart';
import 'face_presence_detector.dart';

class FallbackCameraFaceSource implements CameraFaceSource {
  FallbackCameraFaceSource({
    required this.primary,
    required this.fallback,
    this.disablePrimaryAfterFailure = true,
  });

  final CameraFaceSource primary;
  final CameraFaceSource fallback;
  final bool disablePrimaryAfterFailure;

  bool _primaryDisabled = false;
  String? _lastPrimaryError;

  bool get primaryDisabled => _primaryDisabled;
  String? get lastPrimaryError => _lastPrimaryError;

  @override
  Future<FacePresenceObservation> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
    required int faceMissingDurationSeconds,
  }) async {
    if (!_primaryDisabled) {
      try {
        final observation = await primary.analyzeFrame(
          image: image,
          timestamp: timestamp,
          faceMissingDurationSeconds: faceMissingDurationSeconds,
        );
        return _withSourceMetadata(
          observation,
          source: 'primary',
          error: null,
        );
      } catch (error) {
        _lastPrimaryError = error.toString();
        if (disablePrimaryAfterFailure) _primaryDisabled = true;
      }
    }

    final fallbackObservation = await fallback.analyzeFrame(
      image: image,
      timestamp: timestamp,
      faceMissingDurationSeconds: faceMissingDurationSeconds,
    );
    return _withSourceMetadata(
      fallbackObservation,
      source: 'fallback',
      error: _lastPrimaryError,
    );
  }

  FacePresenceObservation _withSourceMetadata(
    FacePresenceObservation observation, {
    required String source,
    required String? error,
  }) {
    return FacePresenceObservation(
      timestamp: observation.timestamp,
      faceCount: observation.faceCount,
      primaryFaceConfidence: observation.primaryFaceConfidence,
      faceMissingDurationSeconds: observation.faceMissingDurationSeconds,
      metadata: <String, Object?>{
        ...observation.metadata,
        'faceSourcePath': source,
        if (error != null) 'primaryFaceSourceError': error,
      },
    );
  }
}
