import '../models/face_verification_log.dart';
import '../models/student_face_profile.dart';
import '../models/student_trusted_device.dart';
import 'identity_trust_repository.dart';

class InMemoryIdentityTrustRepository implements IdentityTrustRepository {
  final Map<String, StudentFaceProfile> _profiles = <String, StudentFaceProfile>{};
  final Map<String, StudentTrustedDevice> _devices = <String, StudentTrustedDevice>{};
  final List<FaceVerificationLog> _logs = <FaceVerificationLog>[];

  List<FaceVerificationLog> get logs => List<FaceVerificationLog>.unmodifiable(_logs);

  @override
  Future<StudentFaceProfile?> getFaceProfile(String studentId) async {
    return _profiles[studentId];
  }

  @override
  Future<StudentTrustedDevice?> getTrustedDevice({
    required String studentId,
    required String deviceId,
  }) async {
    return _devices[_deviceKey(studentId, deviceId)];
  }

  @override
  Future<void> saveFaceProfile(StudentFaceProfile profile) async {
    _profiles[profile.studentId] = profile;
  }

  @override
  Future<void> saveTrustedDevice(StudentTrustedDevice device) async {
    _devices[_deviceKey(device.studentId, device.deviceId)] = device;
  }

  @override
  Future<void> saveFaceVerificationLog(FaceVerificationLog log) async {
    _logs.add(log);
  }

  String _deviceKey(String studentId, String deviceId) => '$studentId::$deviceId';
}
