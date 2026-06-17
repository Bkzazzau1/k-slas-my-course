import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:my_courses/features/local_ai/object_ai/tflite_object_detection_source.dart';

void main() {
  const manifestPath = 'assets/local_ai_calibration_samples/manifest.json';

  test('calibration manifest defines expected scenarios', () {
    final manifest = _readManifest(manifestPath);
    final scenarios = (manifest['scenarios'] as List)
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

    expect(scenarios.map((entry) => entry['id']), contains('clean_room'));
    expect(scenarios.map((entry) => entry['id']), contains('phone_on_desk'));
    expect(scenarios.map((entry) => entry['id']), contains('dark_room'));
    expect(scenarios.map((entry) => entry['id']), contains('vehicle'));

    for (final scenario in scenarios) {
      expect(scenario['id'], isA<String>());
      expect(scenario['expectedLabels'], isA<List>());
      expect(scenario['expectedDecision'], isA<String>());
      expect(scenario['images'], isA<List>());
    }
  });

  test('listed calibration images can run through RGB object detector', () async {
    final manifest = _readManifest(manifestPath);
    final scenarios = (manifest['scenarios'] as List)
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final imageEntries = <_CalibrationImageEntry>[];
    for (final scenario in scenarios) {
      final images = (scenario['images'] as List).map((entry) => '$entry');
      for (final imagePath in images) {
        imageEntries.add(
          _CalibrationImageEntry(
            scenarioId: '${scenario['id']}',
            path: 'assets/local_ai_calibration_samples/$imagePath',
            expectedLabels: (scenario['expectedLabels'] as List)
                .map((entry) => '$entry')
                .toList(),
          ),
        );
      }
    }

    if (imageEntries.isEmpty) {
      markTestSkipped('No calibration images listed yet.');
      return;
    }

    final source = TfliteObjectDetectionSource();
    addTearDown(source.dispose);

    for (final entry in imageEntries) {
      final file = File(entry.path);
      expect(file.existsSync(), true, reason: 'Missing ${entry.path}');
      final decoded = img.decodeImage(await file.readAsBytes());
      expect(decoded, isNotNull, reason: 'Could not decode ${entry.path}');

      final observations = await source.analyzeImage(
        image: decoded!,
        timestamp: DateTime.now(),
      );
      final labels = observations.map((item) => item.label.toLowerCase());
      for (final expected in entry.expectedLabels) {
        expect(
          labels.any((label) => label.contains(expected.toLowerCase())),
          true,
          reason:
              '${entry.scenarioId} expected "$expected" in ${entry.path}; got ${labels.join(', ')}',
        );
      }
    }
  });
}

Map<String, dynamic> _readManifest(String path) {
  final file = File(path);
  expect(file.existsSync(), true);
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

class _CalibrationImageEntry {
  const _CalibrationImageEntry({
    required this.scenarioId,
    required this.path,
    required this.expectedLabels,
  });

  final String scenarioId;
  final String path;
  final List<String> expectedLabels;
}
