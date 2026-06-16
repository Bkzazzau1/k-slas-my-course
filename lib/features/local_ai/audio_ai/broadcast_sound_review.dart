class BroadcastSoundReviewInput {
  const BroadcastSoundReviewInput({
    required this.averageRms,
    required this.peakRms,
    required this.spectralCentroidHz,
    required this.steadySpeechLikePattern,
  });

  final double averageRms;
  final double peakRms;
  final double spectralCentroidHz;
  final bool steadySpeechLikePattern;
}

class BroadcastSoundReviewResult {
  const BroadcastSoundReviewResult({
    required this.hasBroadcastSound,
    required this.label,
    required this.riskPoints,
    required this.message,
  });

  final bool hasBroadcastSound;
  final String label;
  final int riskPoints;
  final String message;
}

class BroadcastSoundReview {
  const BroadcastSoundReview();

  BroadcastSoundReviewResult review(BroadcastSoundReviewInput input) {
    final likelyMediaSound = input.steadySpeechLikePattern &&
        input.averageRms >= 0.20 &&
        input.peakRms >= 0.35 &&
        input.spectralCentroidHz >= 600 &&
        input.spectralCentroidHz <= 4000;

    if (likelyMediaSound) {
      return const BroadcastSoundReviewResult(
        hasBroadcastSound: true,
        label: 'radio or television sound',
        riskPoints: 25,
        message: 'Radio or television sound is not allowed during the exam.',
      );
    }

    return const BroadcastSoundReviewResult(
      hasBroadcastSound: false,
      label: 'no radio or television sound',
      riskPoints: 0,
      message: 'No radio or television sound pattern was found.',
    );
  }
}
