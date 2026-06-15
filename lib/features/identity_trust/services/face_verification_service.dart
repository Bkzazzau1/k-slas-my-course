import 'package:uuid/uuid.dart';

import '../models/face_verification_log.dart';
import '../models/face_verification_result.dart';
import '../models/student_face_profile.dart';
import '../models/student_trusted_device.dart';
import 'face_similarity_service.dart';

class FaceVerificationDecision {
  const FaceVerificationDecision({
    required this.result,
    required this.log,
  });

  final FaceVerificationResult result;
  final FaceVerificationLog log;
}

class FaceVerificationService {
  FaceVerificationService({
    FaceSimilarityService similarityService = const FaceSimilarityService(),
    Uuid? uuid,
    this.passThreshold = 0.75,
    this.uncertainThreshold = 0.60,
  })  : _similarityService = similarityService,
        _uuid = uuid ?? const Uuid();

  final FaceSimilarityService _similarityService;
  final Uuid _uuid;
  final double passThreshold;
  final double uncertainThreshold;

  FaceVerificationDecision verify({
    required StudentFaceProfile profile,
    required StudentTrustedDevice device,
    required List<double> liveEmbedding,
    String? examId,
    String? sessionId,
  }) {
    if (!profile.isActive) {
      return _decision(
        profile: profile,
        device: device,
        status: FaceVerificationStatus.notEnrolled,
        score: 0,
        message: 'Student does not have an active face profile.',
        examId: examId,
        sessionId: sessionId,
        reviewRequired: true,
      );
    }

    if (device.isBlocked) {
      return _decision(
        profile: profile,
        device: device,
        status: FaceVerificationStatus.deviceBlocked,
        score: 0,
        message: 'Device is blocked for examination use.',
        examId: examId,
        sessionId: sessionId,
        reviewRequired: true,
      );
    }

    final score = _similarityService.cosineSimilarity(
      profile.faceEmbedding,
      liveEmbedding,
    );

    if (score >= passThreshold) {
      return _decision(
        profile: profile,
        device: device,
        status: FaceVerificationStatus.passed,
        score: score,
        message: 'Face verification passed.',
        examId: examId,
        sessionId: sessionId,
        reviewRequired: false,
      );
    }

    if (score >= uncertainThreshold) {
      return _decision(
        profile: profile,
        device: device,
        status: FaceVerificationStatus.uncertain,
        score: score,
        message: 'Face verification is uncertain and requires human review.',
        examId: examId,
        sessionId: sessionId,
        reviewRequired: true,
      );
    }

    return _decision(
      profile: profile,
      device: device,
      status: FaceVerificationStatus.failed,
      score: score,
      message: 'Face verification failed.',
      examId: examId,
      sessionId: sessionId,
      reviewRequired: true,
    );
  }

  FaceVerificationDecision _decision({
    required StudentFaceProfile profile,
    required StudentTrustedDevice device,
    required FaceVerificationStatus status,
    required double score,
    required String message,
    required bool reviewRequired,
    String? examId,
    String? sessionId,
  }) {
    final result = FaceVerificationResult(
      status: status,
      similarityScore: score,
      threshold: passThreshold,
      reviewRequired: reviewRequired,
      message: message,
    );

    final log = FaceVerificationLog(
      id: _uuid.v4(),
      studentId: profile.studentId,
      deviceId: device.deviceId,
      examId: examId,
      sessionId: sessionId,
      similarityScore: score,
      status: status,
      verifiedAt: DateTime.now(),
      reviewRequired: reviewRequired,
    );

    return FaceVerificationDecision(result: result, log: log);
  }
}
