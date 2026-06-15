import '../models/face_verification_log.dart';
import '../models/student_face_profile.dart';
import '../models/student_trusted_device.dart';
import 'identity_trust_repository.dart';

class DemoIdentityTrustRepository implements IdentityTrustRepository {
  DemoIdentityTrustRepository({
    this.demoEmbedding = const <double>[1, 0, 0],
    this.modelVersion = 'demo-static-face-v1',
  });

  final List<double> demoEmbedding;
  final String modelVersion;
  final Map<String, StudentFaceProfile> _profiles = <String, StudentFaceProfile>{};
  final Map<String, StudentTrustedDevice> _devices = <String, StudentTrustedDevice>{};
  final List<FaceVerificationLog> _logs = <FaceVerificationLog>[];

  List<FaceVerificationLog> get logs => List<FaceVerificationLog>.unmodifiable(_logs);

  @override
  Future<StudentFaceProfile?> getFaceProfile(String studentId) async {
    final normalized = studentId.trim();
    if (normalized.isEmpty) return null;
    return _profiles.putIfAbsent(normalized, () {
      final now = DateTime.now();
      return StudentFaceProfile(
        id: 'demo-face-$normalized',
        studentId: normalized,
        faceEmbedding: demoEmbedding,
        modelVersion: modelVersion,
        captureCount: 3,
        enrollmentStatus: 'active',
        createdAt: now,
        updatedAt: now,
      );
    });
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
