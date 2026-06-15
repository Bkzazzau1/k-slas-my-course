import 'package:camera/camera.dart';
import 'package:get/get.dart';

import '../../../features/identity_trust/identity_trust.dart';
import '../controller/proctoring_controller.dart';
import 'exam_start_identity_orchestrator.dart';

class EnvironmentIdentityTrustGateResult {
  const EnvironmentIdentityTrustGateResult({
    required this.allowed,
    required this.configured,
    required this.message,
    this.decision,
  });

  final bool allowed;
  final bool configured;
  final String message;
  final ExamStartTrustDecision? decision;
}

class EnvironmentIdentityTrustGate {
  const EnvironmentIdentityTrustGate();

  bool get isConfigured {
    return Get.isRegistered<IdentityTrustRepository>() &&
        Get.isRegistered<FaceEmbeddingConnector>();
  }

  Future<EnvironmentIdentityTrustGateResult> verify({
    required ProctoringController proctoring,
    required CameraController cameraController,
  }) async {
    if (!cameraController.value.isInitialized) {
      return const EnvironmentIdentityTrustGateResult(
        allowed: false,
        configured: true,
        message: 'Camera is not ready for student identity verification.',
      );
    }

    if (!isConfigured) {
      return const EnvironmentIdentityTrustGateResult(
        allowed: true,
        configured: false,
        message: 'Face identity trust service is not configured yet; room scan verification will continue.',
      );
    }

    final orchestrator = ExamStartIdentityOrchestrator(
      repository: Get.find<IdentityTrustRepository>(),
      connector: Get.find<FaceEmbeddingConnector>(),
    );

    final activeSessionId = proctoring.activeSessionId.value.trim();
    final decision = await orchestrator.verify(
      ExamStartIdentityRequest(
        examId: activeSessionId.isEmpty ? 'active-exam' : activeSessionId,
        sessionId: activeSessionId.isEmpty ? 'active-session' : activeSessionId,
        isHighStakesExam:
            proctoring.currentLevel.value == AssessmentIntegrityLevel.highStakesExam,
        cameraController: cameraController,
      ),
    );

    if (!decision.canStartExam) {
      proctoring.registerViolation(
        'Face identity trust failed: ${decision.message}',
        penalty: decision.reviewRequired ? 20 : 25,
        alert: true,
      );
    }

    return EnvironmentIdentityTrustGateResult(
      allowed: decision.canStartExam,
      configured: true,
      message: decision.message,
      decision: decision,
    );
  }
}
