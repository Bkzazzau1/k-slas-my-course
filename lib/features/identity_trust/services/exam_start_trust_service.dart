import '../models/face_verification_result.dart';
import '../models/student_trusted_device.dart';
import 'device_fingerprint_service.dart';
import 'face_verification_service.dart';
import 'identity_trust_repository.dart';
import 'live_face_embedding_source.dart';
import 'trusted_device_service.dart';

class ExamStartTrustRequest {
  const ExamStartTrustRequest({
    required this.studentId,
    required this.examId,
    required this.sessionId,
    required this.isHighStakesExam,
  });

  final String studentId;
  final String examId;
  final String sessionId;
  final bool isHighStakesExam;
}

class ExamStartTrustDecision {
  const ExamStartTrustDecision({
    required this.result,
    required this.device,
    required this.message,
  });

  final FaceVerificationResult result;
  final StudentTrustedDevice? device;
  final String message;

  bool get canStartExam => result.canStartExam;
  bool get reviewRequired => result.reviewRequired;
}

class ExamStartTrustService {
  ExamStartTrustService({
    required IdentityTrustRepository repository,
    required LiveFaceEmbeddingSource liveFaceEmbeddingSource,
    DeviceFingerprintService? deviceFingerprintService,
    TrustedDeviceService? trustedDeviceService,
    FaceVerificationService? faceVerificationService,
  })  : _repository = repository,
        _liveFaceEmbeddingSource = liveFaceEmbeddingSource,
        _deviceFingerprintService =
            deviceFingerprintService ?? DeviceFingerprintService(),
        _trustedDeviceService = trustedDeviceService ?? TrustedDeviceService(),
        _faceVerificationService =
            faceVerificationService ?? FaceVerificationService();

  final IdentityTrustRepository _repository;
  final LiveFaceEmbeddingSource _liveFaceEmbeddingSource;
  final DeviceFingerprintService _deviceFingerprintService;
  final TrustedDeviceService _trustedDeviceService;
  final FaceVerificationService _faceVerificationService;

  Future<ExamStartTrustDecision> verifyBeforeStart(
    ExamStartTrustRequest request,
  ) async {
    final profile = await _repository.getFaceProfile(request.studentId);
    if (profile == null) {
      return ExamStartTrustDecision(
        result: const FaceVerificationResult(
          status: FaceVerificationStatus.notEnrolled,
          similarityScore: 0,
          threshold: 0.75,
          reviewRequired: true,
          message: 'Student face profile has not been enrolled.',
        ),
        device: null,
        message: 'Student face profile has not been enrolled.',
      );
    }

    final fingerprint = await _deviceFingerprintService.getOrCreateFingerprint();
    final existingDevice = await _repository.getTrustedDevice(
      studentId: request.studentId,
      deviceId: fingerprint.deviceId,
    );

    final pendingDevice = _trustedDeviceService.registerOrRefreshDevice(
      studentId: request.studentId,
      fingerprint: fingerprint,
      existingDevice: existingDevice,
      trustStatus: existingDevice?.trustStatus ?? 'pending',
    );

    final deviceAllowed = request.isHighStakesExam
        ? _trustedDeviceService.isDeviceAllowedForHighStakesExam(pendingDevice)
        : _trustedDeviceService.isDeviceAllowedForGradedAssessment(pendingDevice);

    if (!deviceAllowed) {
      return ExamStartTrustDecision(
        result: const FaceVerificationResult(
          status: FaceVerificationStatus.deviceNotAllowed,
          similarityScore: 0,
          threshold: 0.75,
          reviewRequired: true,
          message: 'This device is not allowed for this exam type.',
        ),
        device: pendingDevice,
        message: 'This device is not allowed for this exam type.',
      );
    }

    final liveEmbedding = await _liveFaceEmbeddingSource.getLiveEmbedding(
      studentId: request.studentId,
      purpose: 'exam_start_verification',
    );

    final decision = _faceVerificationService.verify(
      profile: profile,
      device: pendingDevice,
      liveEmbedding: liveEmbedding,
      examId: request.examId,
      sessionId: request.sessionId,
    );

    await _repository.saveFaceVerificationLog(decision.log);

    StudentTrustedDevice? trustedDevice = pendingDevice;
    if (decision.result.canStartExam) {
      trustedDevice = _trustedDeviceService.registerOrRefreshDevice(
        studentId: request.studentId,
        fingerprint: fingerprint,
        existingDevice: pendingDevice,
        trustStatus: 'trusted',
        lastFaceMatchScore: decision.result.similarityScore,
      );
      await _repository.saveTrustedDevice(trustedDevice);
    } else {
      await _repository.saveTrustedDevice(pendingDevice);
    }

    return ExamStartTrustDecision(
      result: decision.result,
      device: trustedDevice,
      message: decision.result.message,
    );
  }
}
