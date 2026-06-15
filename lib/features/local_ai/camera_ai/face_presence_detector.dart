import '../core/local_ai_config.dart';
import '../core/local_ai_detector.dart';
import '../core/local_ai_event.dart';

class FacePresenceObservation {
  const FacePresenceObservation({
    required this.timestamp,
    required this.faceCount,
    this.primaryFaceConfidence,
    this.faceMissingDurationSeconds = 0,
  });

  final DateTime timestamp;
  final int faceCount;
  final double? primaryFaceConfidence;
  final int faceMissingDurationSeconds;

  bool get hasFace => faceCount > 0;
  bool get hasMultipleFaces => faceCount > 1;
}

class FacePresenceDetector
    implements LocalAiDetector<FacePresenceObservation> {
  FacePresenceDetector({
    this.config = const LocalAiConfig(),
    this.enabled = true,
  });

  final LocalAiConfig config;
  final bool enabled;

  @override
  String get detectorId => 'face_presence_detector';

  @override
  bool get isEnabled => enabled;

  @override
  Future<List<LocalAiEvent>> analyze(FacePresenceObservation input) async {
    if (!input.hasFace) {
      final isHigh = input.faceMissingDurationSeconds >=
          config.faceMissingHighRiskSeconds;
      final isWarning = input.faceMissingDurationSeconds >=
          config.faceMissingWarningSeconds;

      if (!isHigh && !isWarning) return const <LocalAiEvent>[];

      return <LocalAiEvent>[
        LocalAiEvent(
          type: LocalAiEventType.faceMissing,
          severity: isHigh ? LocalAiSeverity.high : LocalAiSeverity.medium,
          timestamp: input.timestamp,
          riskPoints: isHigh ? 20 : 10,
          confidence: input.primaryFaceConfidence,
          message: 'Face missing for ${input.faceMissingDurationSeconds}s.',
          metadata: <String, Object?>{
            'faceCount': input.faceCount,
            'faceMissingDurationSeconds': input.faceMissingDurationSeconds,
          },
        ),
      ];
    }

    if (input.hasMultipleFaces) {
      return <LocalAiEvent>[
        LocalAiEvent(
          type: LocalAiEventType.multipleFacesDetected,
          severity: LocalAiSeverity.high,
          timestamp: input.timestamp,
          riskPoints: 25,
          confidence: input.primaryFaceConfidence,
          message: 'Multiple faces detected in camera feed.',
          metadata: <String, Object?>{
            'faceCount': input.faceCount,
          },
        ),
      ];
    }

    return <LocalAiEvent>[
      LocalAiEvent(
        type: LocalAiEventType.facePresent,
        severity: LocalAiSeverity.info,
        timestamp: input.timestamp,
        riskPoints: 0,
        confidence: input.primaryFaceConfidence,
        message: 'Face visible.',
        metadata: <String, Object?>{
          'faceCount': input.faceCount,
        },
      ),
    ];
  }
}
