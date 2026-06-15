import 'face_verification_result.dart';

class FaceVerificationLog {
  const FaceVerificationLog({
    required this.id,
    required this.studentId,
    required this.deviceId,
    required this.similarityScore,
    required this.status,
    required this.verifiedAt,
    required this.reviewRequired,
    this.examId,
    this.sessionId,
  });

  final String id;
  final String studentId;
  final String deviceId;
  final String? examId;
  final String? sessionId;
  final double similarityScore;
  final FaceVerificationStatus status;
  final DateTime verifiedAt;
  final bool reviewRequired;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'studentId': studentId,
        'deviceId': deviceId,
        'examId': examId,
        'sessionId': sessionId,
        'similarityScore': similarityScore,
        'status': status.name,
        'verifiedAt': verifiedAt.toIso8601String(),
        'reviewRequired': reviewRequired,
      };
}
