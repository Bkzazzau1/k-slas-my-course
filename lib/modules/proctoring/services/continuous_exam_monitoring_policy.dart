import '../../../features/local_ai/audio_ai/broadcast_sound_review.dart';
import '../../../features/local_ai/audio_ai/environment_sound_classifier.dart';

class GazePolicyResult {
  const GazePolicyResult({
    required this.warningCount,
    required this.allowedToContinue,
    required this.message,
    required this.riskPoints,
  });

  final int warningCount;
  final bool allowedToContinue;
  final String message;
  final int riskPoints;
}

class AudioPolicyResult {
  const AudioPolicyResult({
    required this.allowedToContinue,
    required this.label,
    required this.message,
    required this.riskPoints,
  });

  final bool allowedToContinue;
  final String label;
  final String message;
  final int riskPoints;
}

class ContinuousExamMonitoringPolicy {
  const ContinuousExamMonitoringPolicy({
    this.maxLookAwayWarnings = 5,
  });

  final int maxLookAwayWarnings;

  bool get cameraMustRemainOn => true;
  bool get audioMustRemainOn => true;
  bool get identityChecksContinueDuringExam => true;
  bool get soundChecksContinueDuringExam => true;
  bool get screenFocusChecksContinueDuringExam => true;

  GazePolicyResult evaluateGaze({
    required bool lookingAtScreen,
    required int currentWarnings,
  }) {
    if (lookingAtScreen) {
      return const GazePolicyResult(
        warningCount: 0,
        allowedToContinue: true,
        message: 'Student is looking at the screen.',
        riskPoints: 0,
      );
    }

    final nextWarning = currentWarnings + 1;
    final allowed = nextWarning < maxLookAwayWarnings;
    return GazePolicyResult(
      warningCount: nextWarning,
      allowedToContinue: allowed,
      message: allowed
          ? 'Look-away warning $nextWarning of $maxLookAwayWarnings. Please face the screen.'
          : 'Look-away warning limit reached. Student must face the screen to continue.',
      riskPoints: allowed ? 10 : 25,
    );
  }

  AudioPolicyResult evaluateAudio({
    required EnvironmentSoundObservation observation,
    bool steadySpeechLikePattern = false,
  }) {
    final broadcast = const BroadcastSoundReview().review(
      BroadcastSoundReviewInput(
        averageRms: observation.averageRms,
        peakRms: observation.peakRms,
        spectralCentroidHz: observation.spectralCentroidHz,
        steadySpeechLikePattern: steadySpeechLikePattern,
      ),
    );

    if (broadcast.hasBroadcastSound) {
      return AudioPolicyResult(
        allowedToContinue: false,
        label: broadcast.label,
        message: broadcast.message,
        riskPoints: broadcast.riskPoints,
      );
    }

    final sound = const EnvironmentSoundClassifier().classify(observation);
    return AudioPolicyResult(
      allowedToContinue: sound.riskPoints < 25,
      label: sound.label,
      message: sound.message,
      riskPoints: sound.riskPoints,
    );
  }
}
