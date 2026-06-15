import 'package:uuid/uuid.dart';

import '../models/student_trusted_device.dart';
import 'device_fingerprint_service.dart';

class TrustedDeviceService {
  TrustedDeviceService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  StudentTrustedDevice registerOrRefreshDevice({
    required String studentId,
    required DeviceFingerprint fingerprint,
    double? lastFaceMatchScore,
    String trustStatus = 'trusted',
    StudentTrustedDevice? existingDevice,
  }) {
    final now = DateTime.now();
    return StudentTrustedDevice(
      id: existingDevice?.id ?? _uuid.v4(),
      studentId: studentId,
      deviceId: fingerprint.deviceId,
      deviceType: fingerprint.deviceType,
      osName: fingerprint.osName,
      osVersion: null,
      appVersion: fingerprint.appVersion,
      firstSeenAt: existingDevice?.firstSeenAt ?? now,
      lastSeenAt: now,
      trustStatus: trustStatus,
      lastFaceMatchScore: lastFaceMatchScore,
    );
  }

  bool isDeviceAllowedForHighStakesExam(StudentTrustedDevice device) {
    if (device.isBlocked) return false;
    return device.deviceType == 'desktop_or_laptop' ||
        device.deviceType == 'mobile_or_tablet';
  }

  bool isDeviceAllowedForGradedAssessment(StudentTrustedDevice device) {
    return !device.isBlocked;
  }
}
