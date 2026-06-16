import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/camera_ai/frame_heuristic_face_source.dart';

void main() {
  const analyzer = FrameHeuristicFaceAnalyzer(
    gridWidth: 64,
    gridHeight: 48,
    minimumConfidence: 0.42,
  );

  test('analyzeLuma should return zero faces on flat empty frame', () {
    final frame = Uint8List.fromList(List<int>.filled(640 * 480, 96));

    final output = analyzer.analyzeLuma(
      lumaBytes: frame,
      width: 640,
      height: 480,
      bytesPerRow: 640,
    );

    expect(output.faceCount, 0);
    expect(output.primaryFaceConfidence, isNull);
  });

  test('analyzeLuma should detect one face-like bright oval', () {
    final frame = _frameWithOvals(
      width: 640,
      height: 480,
      ovals: const <_Oval>[
        _Oval(centerX: 320, centerY: 205, radiusX: 70, radiusY: 92),
      ],
    );

    final output = analyzer.analyzeLuma(
      lumaBytes: frame,
      width: 640,
      height: 480,
      bytesPerRow: 640,
    );

    expect(output.faceCount, 1);
    expect(output.primaryFaceConfidence, isNotNull);
    expect(output.primaryFaceConfidence!, greaterThan(0.42));
  });

  test('analyzeLuma should detect two separated face-like ovals', () {
    final frame = _frameWithOvals(
      width: 640,
      height: 480,
      ovals: const <_Oval>[
        _Oval(centerX: 235, centerY: 205, radiusX: 48, radiusY: 68),
        _Oval(centerX: 420, centerY: 210, radiusX: 48, radiusY: 68),
      ],
    );

    final output = analyzer.analyzeLuma(
      lumaBytes: frame,
      width: 640,
      height: 480,
      bytesPerRow: 640,
    );

    expect(output.faceCount, 2);
  });
}

Uint8List _frameWithOvals({
  required int width,
  required int height,
  required List<_Oval> ovals,
}) {
  final bytes = Uint8List.fromList(List<int>.filled(width * height, 88));

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      for (final oval in ovals) {
        final normalized = math.pow((x - oval.centerX) / oval.radiusX, 2) +
            math.pow((y - oval.centerY) / oval.radiusY, 2);
        if (normalized <= 1) {
          bytes[y * width + x] = 166;
        }
      }
    }
  }

  return bytes;
}

class _Oval {
  const _Oval({
    required this.centerX,
    required this.centerY,
    required this.radiusX,
    required this.radiusY,
  });

  final int centerX;
  final int centerY;
  final int radiusX;
  final int radiusY;
}
