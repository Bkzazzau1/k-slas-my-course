import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/services/demo_identity_trust_repository.dart';
import 'package:my_courses/features/identity_trust/services/student_face_enrollment_controller.dart';

void main() {
  test('enrollment completes after required samples', () async {
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
}
