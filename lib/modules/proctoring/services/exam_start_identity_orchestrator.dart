import 'package:camera/camera.dart';

import '../../../data/services/integrity_ledger_service.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../features/identity_trust/identity_trust.dart';

class ExamStartIdentityRequest {
  const ExamStartIdentityRequest({
    required this.examId,
    required this.sessionId,
    required this.isHighStakesExam,
    required this.cameraController,
    this.studentId,
  });

  final String examId;
  final String sessionId;
  final bool isHighStakesExam;
  final CameraController cameraController;
  final String? studentId;
}

class ExamStartIdentityOrchestrator {
  ExamStartIdentityOrchestrator({
    required IdentityTrustRepository repository,
    required FaceEmbeddingConnector connector,
    ExamStartTrustService? trustService,
  }) : _repository = repository,
       _connector = connector,
       _trustService = trustService;

  final IdentityTrustRepository _repository;
  final FaceEmbeddingConnector _connector;
  final ExamStartTrustService? _trustService;

  Future<ExamStartTrustDecision> verify(
    ExamStartIdentityRequest request,
  ) async {
    final studentId = request.studentId ?? _resolveStudentId();
    if (studentId.trim().isEmpty) {
      return const ExamStartTrustDecision(
        result: FaceVerificationResult(
          status: FaceVerificationStatus.notEnrolled,
          similarityScore: 0,
          threshold: 0.75,
          reviewRequired: true,
          message: 'Student identity could not be resolved from local profile.',
        ),
        device: null,
        message: 'Student identity could not be resolved from local profile.',
      );
    }

    final liveSource = ModelLiveFaceEmbeddingSource(
      connector: _connector,
      inputProvider: PreprocessedCameraFaceEmbeddingInputProvider(
        cameraController: request.cameraController,
      ),
    );

    final trustService =
        _trustService ??
        ExamStartTrustService(
          repository: _repository,
          liveFaceEmbeddingSource: liveSource,
        );

    return trustService.verifyBeforeStart(
      ExamStartTrustRequest(
        studentId: studentId,
        examId: request.examId,
        sessionId: request.sessionId,
        isHighStakesExam: request.isHighStakesExam,
      ),
    );
  }

  String _resolveStudentId() {
    final profile = StudentProfileStorage.load();
    final matricNo = profile?.matricNo?.trim() ?? '';
    if (matricNo.isNotEmpty) return matricNo;

    final email = profile?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return IntegrityLedgerService.defaultStudentId;
  }
}
