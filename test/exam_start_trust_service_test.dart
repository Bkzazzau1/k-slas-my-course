import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/identity_trust.dart';

void main() {
  test('exam start trust service verifies face and trusts device', () async {
    final repository = InMemoryIdentityTrustRepository();
    final profile = FaceEnrollmentService().enroll(
      const FaceEnrollmentInput(
        studentId: 'KASU/CSC/001',
        modelVersion: 'mobilefacenet-v1',
        embeddings: <List<double>>[
          <double>[1, 0, 0],
          <double>[1, 0, 0],
          <double>[1, 0, 0],
        ],
      ),
    );
    await repository.saveFaceProfile(profile);

    final service = ExamStartTrustService(
      repository: repository,
      liveFaceEmbeddingSource: const StaticLiveFaceEmbeddingSource(
        embedding: <double>[1, 0, 0],
      ),
    );

    final decision = await service.verifyBeforeStart(
      const ExamStartTrustRequest(
        studentId: 'KASU/CSC/001',
        examId: 'CSC401',
        sessionId: 'session-001',
        isHighStakesExam: true,
      ),
    );

    expect(decision.canStartExam, true);
    expect(decision.result.status, FaceVerificationStatus.passed);
    expect(decision.device?.isTrusted, true);
    expect(repository.logs, hasLength(1));
  });
}
