import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/identity_trust.dart';

void main() {
  test('face enrollment averages multiple embeddings', () {
    final service = FaceEnrollmentService();

    final profile = service.enroll(
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

    expect(profile.studentId, 'KASU/CSC/001');
    expect(profile.captureCount, 3);
    expect(profile.faceEmbedding, <double>[1, 0, 0]);
    expect(profile.isActive, true);
  });

  test('face similarity returns high score for same direction vectors', () {
    const service = FaceSimilarityService();
    final score = service.cosineSimilarity(<double>[1, 0, 0], <double>[1, 0, 0]);
    expect(score, closeTo(1, 0.0001));
  });

  test('face verification passes trusted student with high similarity', () {
    final profile = StudentFaceProfile(
      id: 'profile-1',
      studentId: 'KASU/CSC/001',
      faceEmbedding: const <double>[1, 0, 0],
      modelVersion: 'mobilefacenet-v1',
      captureCount: 3,
      enrollmentStatus: 'active',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final device = StudentTrustedDevice(
      id: 'device-1',
      studentId: 'KASU/CSC/001',
      deviceId: 'abc-device',
      deviceType: 'desktop_or_laptop',
      osName: 'windows',
      appVersion: '1.0.0',
      firstSeenAt: DateTime(2026, 1, 1),
      lastSeenAt: DateTime(2026, 1, 1),
      trustStatus: 'trusted',
    );

    final decision = FaceVerificationService().verify(
      profile: profile,
      device: device,
      liveEmbedding: const <double>[1, 0, 0],
      examId: 'exam-1',
      sessionId: 'session-1',
    );

    expect(decision.result.status, FaceVerificationStatus.passed);
    expect(decision.result.canStartExam, true);
    expect(decision.log.examId, 'exam-1');
  });
}
