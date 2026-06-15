import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceFingerprint {
  const DeviceFingerprint({
    required this.deviceId,
    required this.deviceType,
    required this.osName,
    required this.appVersion,
  });

  final String deviceId;
  final String deviceType;
  final String osName;
  final String appVersion;

  Map<String, Object?> toJson() => <String, Object?>{
        'deviceId': deviceId,
        'deviceType': deviceType,
        'osName': osName,
        'appVersion': appVersion,
      };
}

class DeviceFingerprintService {
  DeviceFingerprintService({GetStorage? storage})
      : _storage = storage ?? GetStorage();

  static const String _deviceIdKey = 'k_slas_trusted_device_id';

  final GetStorage _storage;
  final Uuid _uuid = const Uuid();

  Future<DeviceFingerprint> getOrCreateFingerprint({
    String appVersion = '1.0.0',
  }) async {
    var deviceId = _storage.read<String>(_deviceIdKey);
    if (deviceId == null || deviceId.trim().isEmpty) {
      deviceId = _uuid.v4();
      await _storage.write(_deviceIdKey, deviceId);
    }

    return DeviceFingerprint(
      deviceId: deviceId,
      deviceType: _deviceType(),
      osName: _osName(),
      appVersion: appVersion,
    );
  }

  String _deviceType() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'mobile_or_tablet';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'desktop_or_laptop';
      case TargetPlatform.fuchsia:
        return 'unknown';
    }
  }

  String _osName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
