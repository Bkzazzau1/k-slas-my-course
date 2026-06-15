import '../core/local_ai_config.dart';
import '../core/local_ai_detector.dart';
import '../core/local_ai_event.dart';

class VoiceActivityObservation {
  const VoiceActivityObservation({
    required this.timestamp,
    required this.hasHumanVoice,
    required this.durationSeconds,
    required this.confidence,
    this.mouthMoving,
    this.sourceLabel,
  });

  final DateTime timestamp;
  final bool hasHumanVoice;
  final int durationSeconds;
  final double confidence;
  final bool? mouthMoving;
  final String? sourceLabel;
}

class VoiceActivityDetector
    implements LocalAiDetector<VoiceActivityObservation> {
  VoiceActivityDetector({
    this.config = const LocalAiConfig(),
    this.enabled = true,
  });

  final LocalAiConfig config;
  final bool enabled;

  @override
  String get detectorId => 'voice_activity_detector';

  @override
  bool get isEnabled => enabled;

  @override
  Future<List<LocalAiEvent>> analyze(VoiceActivityObservation input) async {
    if (!input.hasHumanVoice) return const <LocalAiEvent>[];

    final mouthMoving = input.mouthMoving;
    final voiceWhileMouthNotMoving = mouthMoving == false;
    final longVoice = input.durationSeconds >= config.voiceLongSeconds;
    final mediumVoice = input.durationSeconds >= config.voiceShortSeconds;

    final points = voiceWhileMouthNotMoving
        ? 25
        : longVoice
            ? 20
            : mediumVoice
                ? 10
                : 5;

    final severity = voiceWhileMouthNotMoving || longVoice
        ? LocalAiSeverity.high
        : mediumVoice
            ? LocalAiSeverity.medium
            : LocalAiSeverity.low;

    return <LocalAiEvent>[
      LocalAiEvent(
        type: voiceWhileMouthNotMoving
            ? LocalAiEventType.voiceSourceEstimated
            : LocalAiEventType.humanVoiceDetected,
        severity: severity,
        timestamp: input.timestamp,
        riskPoints: points,
        confidence: input.confidence,
        message: voiceWhileMouthNotMoving
            ? 'Human voice detected while student mouth was not moving.'
            : 'Human voice detected for ${input.durationSeconds}s.',
        metadata: <String, Object?>{
          'durationSeconds': input.durationSeconds,
          'mouthMoving': input.mouthMoving,
          'sourceLabel': input.sourceLabel,
        },
      ),
    ];
  }
}
