enum FaceVerificationStatus {
  passed,
  uncertain,
  failed,
  notEnrolled,
  deviceBlocked,
  deviceNotAllowed,
  modelUnavailable,
}

class FaceVerificationResult {
  const FaceVerificationResult({
    required this.status,
    required this.similarityScore,
    required this.threshold,
    required this.reviewRequired,
    required this.message,
  });

  final FaceVerificationStatus status;
  final double similarityScore;
  final double threshold;
  final bool reviewRequired;
  final String message;

  bool get canStartExam => status == FaceVerificationStatus.passed;

  Map<String, Object?> toJson() => <String, Object?>{
        'status': status.name,
        'similarityScore': similarityScore,
        'threshold': threshold,
        'reviewRequired': reviewRequired,
        'message': message,
      };

  factory FaceVerificationResult.passed({
    required double similarityScore,
    required double threshold,
  }) {
    return FaceVerificationResult(
      status: FaceVerificationStatus.passed,
      similarityScore: similarityScore,
      threshold: threshold,
      reviewRequired: false,
      message: 'Face verification passed.',
    );
  }

  factory FaceVerificationResult.uncertain({
    required double similarityScore,
    required double threshold,
  }) {
    return FaceVerificationResult(
      status: FaceVerificationStatus.uncertain,
      similarityScore: similarityScore,
      threshold: threshold,
      reviewRequired: true,
      message: 'Face verification is uncertain and requires human review.',
    );
  }

  factory FaceVerificationResult.failed({
    required double similarityScore,
    required double threshold,
  }) {
    return FaceVerificationResult(
      status: FaceVerificationStatus.failed,
      similarityScore: similarityScore,
      threshold: threshold,
      reviewRequired: true,
      message: 'Face verification failed.',
    );
  }
}
