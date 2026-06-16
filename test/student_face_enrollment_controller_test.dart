import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/services/camera_face_enrollment_sampler.dart';
import 'package:my_courses/features/identity_trust/services/demo_identity_trust_repository.dart';
import 'package:my_courses/features/identity_trust/services/static_face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/student_face_enrollment_controller.dart';

void main() {
  test('enrollment completes after required demo samples', () async {
    final controller = StudentFaceEnrollmentController(
      repository: DemoIdentityTrustRepository(),
      studentId: 'student-001',
    );

    await controller.load();
    await controller.addDemoSample();
    await controller.addDemoSample();
    final snapshot = await controller.addDemoSample();

    expect(snapshot.isComplete, true);
    expect(snapshot.profile?.studentId, 'student-001');
    expect(snapshot.profile?.captureCount, 3);
  });

  test('camera enrollment sample is accepted and saved', () async {
    final controller = StudentFaceEnrollmentController(
      repository: DemoIdentityTrustRepository(),
      studentId: 'student-camera',
      requiredSamples: 1,
    );

    await controller.load();
    final snapshot = await controller.addCameraSample(_FakeCameraSampler());

    expect(snapshot.isComplete, true);
    expect(snapshot.profile?.studentId, 'student-camera');
    expect(snapshot.profile?.captureCount, 1);
    expect(snapshot.profile?.modelVersion, 'fake-camera-v1');
    expect(snapshot.profile?.faceEmbedding, <double>[0.8, 0.2, 0]);
    expect(snapshot.lastQualityScore, 0.92);
  });
}

class _FakeCameraSampler extends CameraFaceEnrollmentSampler {
  _FakeCameraSampler()
      : super(
          cameraController: CameraController(
            const CameraDescription(
              name: 'test-front-camera',
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 0,
            ),
            ResolutionPreset.low,
            enableAudio: false,
          ),
          connector: StaticFaceEmbeddingConnector(
            embedding: const <double>[0.8, 0.2, 0],
            version: 'fake-camera-v1',
          ),
        );

  @override
  Future<CameraFaceEnrollmentSample> captureSample({
    required String studentId,
  }) async {
    return const CameraFaceEnrollmentSample(
      embedding: <double>[0.8, 0.2, 0],
      modelVersion: 'fake-camera-v1',
      qualityScore: 0.92,
      inferenceTimeMs: 12,
    );
  }
}
