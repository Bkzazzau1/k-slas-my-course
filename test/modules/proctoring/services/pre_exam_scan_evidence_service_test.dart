import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:my_courses/modules/proctoring/services/pre_exam_scan_evidence_service.dart';

void main() {
  test('saves target photo, calibration log, and manifest', () async {
    final directory = await Directory.systemTemp.createTemp(
      'pre_exam_scan_evidence_test_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final service = PreExamScanEvidenceService(outputDirectory: directory);
    await service.startScan();

    final image = img.Image(width: 8, height: 8);
    img.fill(image, color: img.ColorRgb8(120, 120, 120));

    final target = await service.saveDecodedTarget(
      target: 'desk surface',
      image: image,
      labels: const <String>['phone'],
      lightingScore: 0.72,
      movementScore: 0.08,
      sceneDiversityScore: 0.05,
    );

    await service.logCalibrationEntry(
      target: 'desk surface',
      frameSourceMode: 'still-frame',
      lightingScore: 0.72,
      movementScore: 0.08,
      sceneDiversityScore: 0.05,
      detectedLabels: const <String>['phone'],
      forbiddenLabels: const <String>['phone'],
      environmentDecision: 'unknown',
      framePath: target.path,
      note: 'accepted_target',
    );

    final manifest = await service.saveManifest(
      environmentType: 'unknown',
      overallStatus: 'pending_review',
    );

    expect(File.fromUri(Uri.parse(target.path)).existsSync(), true);
    expect(File.fromUri(Uri.parse(manifest.path)).existsSync(), true);
    expect(
      File.fromUri(Uri.parse(manifest.calibrationLogPath)).existsSync(),
      true,
    );

    final payload =
        jsonDecode(File.fromUri(Uri.parse(manifest.path)).readAsStringSync())
            as Map<String, dynamic>;
    expect(payload['overall_status'], 'pending_review');
    expect(payload['targets'], isA<List<dynamic>>());
    expect(payload['calibration_log_path'], manifest.calibrationLogPath);
  });
}
