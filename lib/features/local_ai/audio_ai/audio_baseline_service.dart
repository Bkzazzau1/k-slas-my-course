import '../core/local_ai_event.dart';

class AudioBaselineProfile {
  const AudioBaselineProfile({
    required this.startedAt,
    required this.durationSeconds,
    required this.averageRms,
    required this.peakRms,
    required this.environmentLabel,
  });

  final DateTime startedAt;
  final int durationSeconds;
  final double averageRms;
  final double peakRms;
  final String environmentLabel;

  Map<String, Object?> toJson() => <String, Object?>{
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'averageRms': averageRms,
        'peakRms': peakRms,
        'environmentLabel': environmentLabel,
      };

  LocalAiEvent toEvent({String? sessionId, String? studentId}) {
    return LocalAiEvent(
      type: LocalAiEventType.audioBaselineCaptured,
      severity: LocalAiSeverity.info,
      timestamp: startedAt,
      riskPoints: 0,
      sessionId: sessionId,
      studentId: studentId,
      message: 'Audio baseline captured: $environmentLabel.',
      metadata: toJson(),
    );
  }
}

class AudioBaselineService {
  AudioBaselineProfile buildProfile({
    required DateTime startedAt,
    required int durationSeconds,
    required List<double> rmsSamples,
  }) {
    final safeSamples = rmsSamples.isEmpty ? const <double>[0] : rmsSamples;
    final total = safeSamples.fold<double>(0, (sum, value) => sum + value);
    final average = total / safeSamples.length;
    final peak = safeSamples.reduce((a, b) => a > b ? a : b);

    return AudioBaselineProfile(
      startedAt: startedAt,
      durationSeconds: durationSeconds,
      averageRms: average,
      peakRms: peak,
      environmentLabel: _labelFor(averageRms: average, peakRms: peak),
    );
  }

  String _labelFor({required double averageRms, required double peakRms}) {
    if (peakRms > 0.75) return 'very_noisy_environment';
    if (averageRms > 0.45) return 'noisy_environment';
    if (averageRms > 0.20) return 'moderate_environment';
    return 'quiet_environment';
  }
}
