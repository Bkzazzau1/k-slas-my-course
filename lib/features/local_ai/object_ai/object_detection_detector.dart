import '../core/local_ai_detector.dart';
import '../core/local_ai_event.dart';

class ObjectDetectionObservation {
  const ObjectDetectionObservation({
    required this.timestamp,
    required this.label,
    required this.confidence,
    this.boundingBox,
    this.isAllowedByPolicy = false,
    this.metadata = const <String, Object?>{},
  });

  final DateTime timestamp;
  final String label;
  final double confidence;
  final Map<String, num>? boundingBox;
  final bool isAllowedByPolicy;
  final Map<String, Object?> metadata;
}

class ObjectDetectionDetector
    implements LocalAiDetector<ObjectDetectionObservation> {
  ObjectDetectionDetector({this.enabled = true});

  final bool enabled;

  @override
  String get detectorId => 'object_detection_detector';

  @override
  bool get isEnabled => enabled;

  @override
  Future<List<LocalAiEvent>> analyze(ObjectDetectionObservation input) async {
    if (input.isAllowedByPolicy) return const <LocalAiEvent>[];

    final normalized = input.label.trim().toLowerCase();
    final isPhone =
        normalized.contains('phone') ||
        normalized.contains('mobile') ||
        normalized.contains('smartphone');

    final eventType = isPhone
        ? LocalAiEventType.phoneDetected
        : LocalAiEventType.prohibitedMaterialDetected;

    final reviewPolicy = input.metadata['reviewPolicy']?.toString();
    final manualReview = reviewPolicy == 'manualReview';
    final points = manualReview ? 0 : (isPhone ? 30 : 25);

    return <LocalAiEvent>[
      LocalAiEvent(
        type: eventType,
        severity: manualReview ? LocalAiSeverity.medium : LocalAiSeverity.high,
        timestamp: input.timestamp,
        riskPoints: points,
        confidence: input.confidence,
        message: manualReview
            ? 'Manual review required for visible exam material: ${input.label}.'
            : isPhone
            ? 'Phone detected in camera view.'
            : 'Prohibited material detected: ${input.label}.',
        metadata: <String, Object?>{
          'label': input.label,
          'boundingBox': input.boundingBox,
          'isAllowedByPolicy': input.isAllowedByPolicy,
          'requiresHumanDecision': manualReview,
          ...input.metadata,
        },
      ),
    ];
  }
}
