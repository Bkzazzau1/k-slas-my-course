import '../models/face_verification_log.dart';
import '../models/student_face_profile.dart';
import '../models/student_trusted_device.dart';

abstract class IdentityTrustRepository {
  Future<StudentFaceProfile?> getFaceProfile(String studentId);

  Future<StudentTrustedDevice?> getTrustedDevice({
    required String studentId,
    required String deviceId,
  });

  Future<void> saveFaceProfile(StudentFaceProfile profile);

  Future<void> saveTrustedDevice(StudentTrustedDevice device);

  Future<void> saveFaceVerificationLog(FaceVerificationLog log);
}
