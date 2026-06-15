import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/identity_trust.dart';

void main() {
  test('model live face embedding source returns connector embedding', () async {
    final source = ModelLiveFaceEmbeddingSource(
      connector: StaticFaceEmbeddingConnector(
        embedding: const <double>[0.1, 0.2, 0.3],
      ),
      inputProvider: const StaticFaceEmbeddingInputProvider(),
    );

    final embedding = await source.getLiveEmbedding(
      studentId: 'KASU/CSC/001',
      purpose: 'exam_start_verification',
    );

    expect(embedding, const <double>[0.1, 0.2, 0.3]);
  });

  test('exam start trust can use model backed live embedding source', () async {
    final repository = InMemoryIdentityTrustRepository();
    final profile = FaceEnrollmentService().enroll(
      const FaceEnrollmentInput(
        studentId: 'KASU/CSC/002',
        modelVersion: 'static-embedding-v1',
        embeddings: <List<double>>[
          <double>[1, 0, 0],
          <double>[1, 0, 0],
          <double>[1, 0, 0],
        ],
      ),
    );
    await repository.saveFaceProfile(profile);

    final liveSource = ModelLiveFaceEmbeddingSource(
      connector: StaticFaceEmbeddingConnector(
        embedding: const <double>[1, 0, 0],
      ),
      inputProvider: const StaticFaceEmbeddingInputProvider(),
    );

    final trustService = ExamStartTrustService(
      repository: repository,
      liveFaceEmbeddingSource: liveSource,
    );

    final decision = await trustService.verifyBeforeStart(
      const ExamStartTrustRequest(
        studentId: 'KASU/CSC/002',
        examId: 'CSC402',
        sessionId: 'session-002',
        isHighStakesExam: true,
      ),
    );

    expect(decision.canStartExam, true);
    expect(decision.result.status, FaceVerificationStatus.passed);
  });
}
