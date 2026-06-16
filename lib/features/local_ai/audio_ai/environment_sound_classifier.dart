import '../core/local_ai_event.dart';

enum EnvironmentSoundType {
  quiet,
  fanOrAirConditioner,
  keyboardOrMouse,
  trafficOrCar,
  humanVoice,
  multipleVoices,
  phoneRingtone,
  unknownNoise,
}

class EnvironmentSoundObservation {
  const EnvironmentSoundObservation({
    required this.timestamp,
    required this.averageRms,
    required this.peakRms,
    required this.dominantFrequencyHz,
    required this.spectralCentroidHz,
    required this.voiceConfidence,
    this.voiceCount = 0,
    this.durationSeconds = 3,
  });

  final DateTime timestamp;
  final double averageRms;
  final double peakRms;
  final double dominantFrequencyHz;
  final double spectralCentroidHz;
  final double voiceConfidence;
  final int voiceCount;
  final int durationSeconds;
}

class EnvironmentSoundClassification {
  const EnvironmentSoundClassification({
    required this.type,
    required this.label,
    required this.confidence,
    required this.riskPoints,
    required this.message,
  });

  final EnvironmentSoundType type;
  final String label;
  final double confidence;
  final int riskPoints;
  final String message;

  bool get allowedAtExamStart => riskPoints < 25;

  Map<String, Object?> toJson() => <String, Object?>{
        'type': type.name,
        'label': label,
        'confidence': confidence,
        'riskPoints': riskPoints,
        'message': message,
      };

  LocalAiEvent toEvent({String? sessionId, String? studentId}) {
    return LocalAiEvent(
      type: riskPoints > 0
          ? LocalAiEventType.environmentSoundClassified
          : LocalAiEventType.audioBaselineCaptured,
      severity: _severity,
      timestamp: DateTime.now(),
      riskPoints: riskPoints,
      confidence: confidence,
      sessionId: sessionId,
      studentId: studentId,
      message: message,
      metadata: toJson(),
    );
  }

  LocalAiSeverity get _severity {
    if (riskPoints >= 35) return LocalAiSeverity.critical;
    if (riskPoints >= 25) return LocalAiSeverity.high;
    if (riskPoints >= 10) return LocalAiSeverity.medium;
    if (riskPoints > 0) return LocalAiSeverity.low;
    return LocalAiSeverity.info;
  }
}

class EnvironmentSoundClassifier {
  const EnvironmentSoundClassifier();

  EnvironmentSoundClassification classify(EnvironmentSoundObservation input) {
    if (input.voiceCount >= 2) {
      return const EnvironmentSoundClassification(
        type: EnvironmentSoundType.multipleVoices,
        label: 'multiple voices',
        confidence: 0.90,
        riskPoints: 35,
        message: 'Multiple voices detected in the environment.',
      );
    }

    if (input.voiceConfidence >= 0.70) {
      return const EnvironmentSoundClassification(
        type: EnvironmentSoundType.humanVoice,
        label: 'human voice',
        confidence: 0.86,
        riskPoints: 20,
        message: 'Human voice detected during audio environment check.',
      );
    }

    if (input.dominantFrequencyHz >= 700 &&
        input.dominantFrequencyHz <= 1800 &&
        input.peakRms > 0.50) {
      return const EnvironmentSoundClassification(
        type: EnvironmentSoundType.phoneRingtone,
        label: 'phone ringtone or alert tone',
        confidence: 0.78,
        riskPoints: 25,
        message: 'Phone ringtone or alert tone detected.',
      );
    }

    if (input.dominantFrequencyHz >= 30 &&
        input.dominantFrequencyHz <= 180 &&
        input.spectralCentroidHz < 500 &&
        input.averageRms >= 0.10) {
      return const EnvironmentSoundClassification(
        type: EnvironmentSoundType.fanOrAirConditioner,
        label: 'fan or air conditioner',
        confidence: 0.72,
        riskPoints: 0,
        message: 'Fan or air conditioner noise detected and accepted as background sound.',
      );
    }

    if (input.spectralCentroidHz >= 2500 &&
        input.peakRms >= 0.35 &&
        input.averageRms < 0.45) {
      return const EnvironmentSoundClassification(
        type: EnvironmentSoundType.keyboardOrMouse,
        label: 'keyboard or mouse clicking',
        confidence: 0.70,
        riskPoints: 10,
        message: 'Keyboard or mouse clicking sound detected.',
      );
    }

    if (input.dominantFrequencyHz >= 80 &&
        input.dominantFrequencyHz <= 400 &&
        input.averageRms >= 0.35) {
      return const EnvironmentSoundClassification(
        type: EnvironmentSoundType.trafficOrCar,
        label: 'traffic or car noise',
        confidence: 0.68,
        riskPoints: 5,
        message: 'Traffic or car noise detected in the background.',
      );
    }

    if (input.averageRms < 0.12 && input.peakRms < 0.25) {
      return const EnvironmentSoundClassification(
        type: EnvironmentSoundType.quiet,
        label: 'quiet environment',
        confidence: 0.85,
        riskPoints: 0,
        message: 'Quiet environment detected.',
      );
    }

    return EnvironmentSoundClassification(
      type: EnvironmentSoundType.unknownNoise,
      label: 'unknown environmental noise',
      confidence: 0.55,
      riskPoints: input.peakRms > 0.70 ? 20 : 10,
      message: 'Unknown environmental sound detected. Keep the room quiet before starting.',
    );
  }
}
