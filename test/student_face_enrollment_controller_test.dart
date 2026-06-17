import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_courses/data/services/integrity_ledger_service.dart';
import 'package:my_courses/data/services/student_profile_storage.dart';
import 'package:my_courses/features/identity_trust/services/camera_face_enrollment_sampler.dart';
import 'package:my_courses/features/identity_trust/services/demo_identity_trust_repository.dart';
import 'package:my_courses/features/identity_trust/services/static_face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/student_face_enrollment_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return Directory.systemTemp
                .createTempSync('get_storage_test_')
                .path;
          }
          return null;
        });
    await GetStorage.init();
  });

  setUp(() async {
    Get.testMode = true;
    await StudentProfileStorage.clear();
  });

  tearDown(() {
    Get.reset();
  });

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
    );

    await controller.load();
    await controller.addCameraSample(_FakeCameraSampler());
    await controller.addCameraSample(_FakeCameraSampler());
    final snapshot = await controller.addCameraSample(_FakeCameraSampler());

    expect(snapshot.isComplete, true);
    expect(snapshot.profile?.studentId, 'student-camera');
    expect(snapshot.profile?.captureCount, 3);
    expect(snapshot.profile?.modelVersion, 'fake-camera-v1');
    expect(snapshot.profile?.faceEmbedding[0], closeTo(0.8, 0.0001));
    expect(snapshot.profile?.faceEmbedding[1], closeTo(0.2, 0.0001));
    expect(snapshot.profile?.faceEmbedding[2], closeTo(0, 0.0001));
    expect(snapshot.lastQualityScore, 0.92);
  });

  test('capture works with local student when profile is missing', () async {
    final controller = StudentFaceEnrollmentController(
      repository: DemoIdentityTrustRepository(),
    );

    final initial = await controller.load();
    expect(initial.studentId, IntegrityLedgerService.defaultStudentId);
    expect(initial.isComplete, false);

    final snapshot = await controller.addDemoSample();

    expect(snapshot.studentId, IntegrityLedgerService.defaultStudentId);
    expect(snapshot.capturedSamples, 1);
    expect(snapshot.statusText, contains('Sample 1 of 3 captured'));
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
