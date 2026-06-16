import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/object_ai/tflite_object_detection_source.dart';

void main() {
  test('decoder keeps high confidence prohibited objects', () {
    final timestamp = DateTime.now();

    final observations = TfliteObjectOutputDecoder.decode(
      rawBoxes: const <List<double>>[
        <double>[0.10, 0.20, 0.40, 0.60],
        <double>[0.50, 0.10, 0.80, 0.45],
      ],
      rawClasses: const <double>[1, 2],
      rawScores: const <double>[0.88, 0.74],
      rawCount: 2,
      labels: const <String>['background', 'cell phone', 'book'],
      imageWidth: 1000,
      imageHeight: 500,
      timestamp: timestamp,
      confidenceThreshold: 0.55,
      maximumObjects: 8,
      allowedLabels: const <String>{'background'},
    );

    expect(observations, hasLength(2));
    expect(observations.first.label, 'cell phone');
    expect(observations.first.confidence, 0.88);
    expect(observations.first.boundingBox?['x'], 200);
    expect(observations.first.boundingBox?['y'], 50);
    expect(observations.first.boundingBox?['width'], 400);
    expect(observations.first.boundingBox?['height'], 150);
  });

  test('decoder filters low confidence and allowed labels', () {
    final observations = TfliteObjectOutputDecoder.decode(
      rawBoxes: const <List<double>>[
        <double>[0.10, 0.20, 0.40, 0.60],
        <double>[0.50, 0.10, 0.80, 0.45],
      ],
      rawClasses: const <double>[0, 2],
      rawScores: const <double>[0.91, 0.20],
      rawCount: 2,
      labels: const <String>['background', 'cell phone', 'book'],
      imageWidth: 1000,
      imageHeight: 500,
      timestamp: DateTime.now(),
      confidenceThreshold: 0.55,
      maximumObjects: 8,
      allowedLabels: const <String>{'background'},
    );

    expect(observations, isEmpty);
  });

  test('decoder respects maximumObjects and sorts by confidence', () {
    final observations = TfliteObjectOutputDecoder.decode(
      rawBoxes: const <List<double>>[
        <double>[0.10, 0.10, 0.30, 0.30],
        <double>[0.20, 0.20, 0.50, 0.50],
        <double>[0.30, 0.30, 0.70, 0.70],
      ],
      rawClasses: const <double>[1, 2, 3],
      rawScores: const <double>[0.70, 0.95, 0.80],
      rawCount: 3,
      labels: const <String>['background', 'cell phone', 'book', 'calculator'],
      imageWidth: 100,
      imageHeight: 100,
      timestamp: DateTime.now(),
      confidenceThreshold: 0.55,
      maximumObjects: 2,
      allowedLabels: const <String>{'background'},
    );

    expect(observations, hasLength(2));
    expect(observations.first.label, 'book');
    expect(observations.last.label, 'calculator');
  });
}
