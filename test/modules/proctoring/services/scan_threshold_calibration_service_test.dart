import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_courses/modules/proctoring/services/scan_threshold_calibration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return Directory.systemTemp
                .createTempSync('scan_threshold_storage_test_')
                .path;
          }
          return null;
        });
    await GetStorage.init();
  });

  setUp(() async {
    Get.testMode = true;
    await ScanThresholdCalibrationService(storage: GetStorage()).reset();
  });

  test('loads default scan thresholds', () {
    final service = ScanThresholdCalibrationService(storage: GetStorage());
    final calibration = service.load();

    expect(calibration.movementThreshold, 0.010);
    expect(calibration.minimumSceneChangeScore, 0.032);
    expect(calibration.targetMotionRequired, 0.075);
    expect(calibration.targetMovingFramesRequired, 3);
    expect(calibration.stillCaptureIntervalMs, 1400);
  });

  test('saves and loads device scan thresholds', () async {
    final storage = GetStorage();
    final service = ScanThresholdCalibrationService(storage: storage);

    await service.save(
      const ScanThresholdCalibration(
        movementThreshold: 0.02,
        minimumSceneChangeScore: 0.05,
        targetMotionRequired: 0.1,
        targetMovingFramesRequired: 4,
        stillCaptureIntervalMs: 1800,
        minimumLightingScore: 0.7,
      ),
    );

    final calibration = service.load();

    expect(calibration.movementThreshold, 0.02);
    expect(calibration.minimumSceneChangeScore, 0.05);
    expect(calibration.targetMotionRequired, 0.1);
    expect(calibration.targetMovingFramesRequired, 4);
    expect(calibration.stillCaptureIntervalMs, 1800);
    expect(calibration.minimumLightingScore, 0.7);
  });
}
