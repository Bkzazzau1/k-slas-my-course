import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_courses/data/models/student_profile_model.dart';
import 'package:my_courses/data/services/student_profile_storage.dart';
import 'package:my_courses/features/identity_trust/services/demo_identity_trust_repository.dart';
import 'package:my_courses/features/identity_trust/services/student_face_enrollment_controller.dart';

void main() {
  setUpAll(() async {
    await GetStorage.init();
  });

  tearDown(() async {
    await GetStorage().erase();
  });

  test('student face enrollment completes after required samples', () async {
    await StudentProfileStorage.save(
      StudentProfileModel(
        schoolId: 'kslas',
        schoolName: 'K-SLAS',
        departmentId: 'csc',
        departmentName: 'Computer Science',
        programmeId: 'bsc-csc',
        programmeName: 'Computer Science',
        level: 300,
        semester: 1,
        selectedCourses: <String>[],
        fullName: 'Demo Student',
        matricNo: 'KASU/CSC/001',
      ),
    );

    final repository = DemoIdentityTrustRepository();
    final controller = StudentFaceEnrollmentController(
      repository: repository,
      requiredSamples: 3,
    );

    await controller.load();
    await controller.addDemoSample();
    await controller.addDemoSample();
    final snapshot = await controller.addDemoSample();

    expect(snapshot.isComplete, true);
    expect(snapshot.profile?.studentId, 'KASU/CSC/001');
    expect(snapshot.profile?.captureCount, 3);
  });
}
