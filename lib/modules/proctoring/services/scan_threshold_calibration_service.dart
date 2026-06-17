import 'package:get_storage/get_storage.dart';

class ScanThresholdCalibration {
  const ScanThresholdCalibration({
    this.movementThreshold = 0.010,
    this.minimumSceneChangeScore = 0.032,
    this.targetMotionRequired = 0.075,
    this.targetMovingFramesRequired = 3,
    this.stillCaptureIntervalMs = 1400,
    this.minimumLightingScore,
  });

  final double movementThreshold;
  final double minimumSceneChangeScore;
  final double targetMotionRequired;
  final int targetMovingFramesRequired;
  final int stillCaptureIntervalMs;
  final double? minimumLightingScore;

  Map<String, Object?> toJson() => <String, Object?>{
    'movementThreshold': movementThreshold,
    'minimumSceneChangeScore': minimumSceneChangeScore,
    'targetMotionRequired': targetMotionRequired,
    'targetMovingFramesRequired': targetMovingFramesRequired,
    'stillCaptureIntervalMs': stillCaptureIntervalMs,
    'minimumLightingScore': minimumLightingScore,
  };

  factory ScanThresholdCalibration.fromJson(Map<String, dynamic> json) {
    return ScanThresholdCalibration(
      movementThreshold: _readDouble(json['movementThreshold'], 0.010),
      minimumSceneChangeScore: _readDouble(
        json['minimumSceneChangeScore'],
        0.032,
      ),
      targetMotionRequired: _readDouble(json['targetMotionRequired'], 0.075),
      targetMovingFramesRequired: _readInt(
        json['targetMovingFramesRequired'],
        3,
      ),
      stillCaptureIntervalMs: _readInt(json['stillCaptureIntervalMs'], 1400),
      minimumLightingScore: json['minimumLightingScore'] == null
          ? null
          : _readDouble(json['minimumLightingScore'], 0.62),
    );
  }

  static double _readDouble(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _readInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class ScanThresholdCalibrationService {
  ScanThresholdCalibrationService({GetStorage? storage})
    : _storage = storage ?? GetStorage();

  static const _key = 'proctoring.scanThresholdCalibration';

  final GetStorage _storage;

  ScanThresholdCalibration load() {
    final raw = _storage.read(_key);
    if (raw is Map) {
      return ScanThresholdCalibration.fromJson(Map<String, dynamic>.from(raw));
    }
    return const ScanThresholdCalibration();
  }

  Future<void> save(ScanThresholdCalibration calibration) async {
    await _storage.write(_key, calibration.toJson());
  }

  Future<void> reset() async {
    await _storage.remove(_key);
  }
}
