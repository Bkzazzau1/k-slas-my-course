import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';

import 'camera_face_source.dart';
import 'face_model_connector.dart';
import 'face_presence_detector.dart';

class FrameHeuristicFaceSource implements CameraFaceSource {
  const FrameHeuristicFaceSource({
    this.analyzer = const FrameHeuristicFaceAnalyzer(),
  });

  final FrameHeuristicFaceAnalyzer analyzer;

  @override
  Future<FacePresenceObservation> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
    required int faceMissingDurationSeconds,
  }) async {
    final plane = image.planes.first;
    final output = analyzer.analyzeLuma(
      lumaBytes: plane.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: plane.bytesPerRow,
    );

    return FacePresenceObservation(
      timestamp: timestamp,
      faceCount: output.faceCount,
      primaryFaceConfidence: output.primaryFaceConfidence,
      faceMissingDurationSeconds: faceMissingDurationSeconds,
      metadata: <String, Object?>{
        'source': 'frame_heuristic_face_source',
        ...output.toJson(),
      },
    );
  }
}

class FrameHeuristicFaceAnalyzer {
  const FrameHeuristicFaceAnalyzer({
    this.gridWidth = 64,
    this.gridHeight = 48,
    this.minimumConfidence = 0.42,
    this.minimumComponentRatio = 0.012,
    this.maximumComponentRatio = 0.38,
  });

  final int gridWidth;
  final int gridHeight;
  final double minimumConfidence;
  final double minimumComponentRatio;
  final double maximumComponentRatio;

  FaceDetectionOutput analyzeLuma({
    required Uint8List lumaBytes,
    required int width,
    required int height,
    required int bytesPerRow,
  }) {
    final startedAt = DateTime.now();
    if (lumaBytes.isEmpty || width <= 0 || height <= 0) {
      return FaceDetectionOutput(
        faces: const <FaceDetectionBox>[],
        imageWidth: width,
        imageHeight: height,
        inferenceTimeMs: 0,
      );
    }

    final sampleWidth = gridWidth.clamp(16, math.max(16, width)).toInt();
    final sampleHeight = gridHeight.clamp(12, math.max(12, height)).toInt();
    final values = Float32List(sampleWidth * sampleHeight);

    var total = 0.0;
    for (var gy = 0; gy < sampleHeight; gy++) {
      final srcY = ((gy + 0.5) * height / sampleHeight).floor().clamp(0, height - 1);
      final rowOffset = srcY * bytesPerRow;
      for (var gx = 0; gx < sampleWidth; gx++) {
        final srcX = ((gx + 0.5) * width / sampleWidth).floor().clamp(0, width - 1);
        final index = (rowOffset + srcX).clamp(0, lumaBytes.length - 1).toInt();
        final value = lumaBytes[index].toDouble();
        values[gy * sampleWidth + gx] = value;
        total += value;
      }
    }

    final mean = total / values.length;
    var varianceTotal = 0.0;
    for (final value in values) {
      final delta = value - mean;
      varianceTotal += delta * delta;
    }
    final stdDev = math.sqrt(varianceTotal / values.length);

    final threshold = math.max(14.0, stdDev * 0.62);
    final minArea = math.max(8, (values.length * minimumComponentRatio).round());
    final maxArea = math.max(minArea + 1, (values.length * maximumComponentRatio).round());
    final mask = List<bool>.filled(values.length, false);

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final contrast = (value - mean).abs();
      final usableLuma = value > 24 && value < 238;
      mask[i] = usableLuma && contrast >= threshold;
    }

    final visited = List<bool>.filled(values.length, false);
    final candidates = <_FaceCandidate>[];

    for (var index = 0; index < values.length; index++) {
      if (!mask[index] || visited[index]) continue;
      final component = _collectComponent(
        startIndex: index,
        mask: mask,
        visited: visited,
        width: sampleWidth,
        height: sampleHeight,
      );
      if (component.area < minArea || component.area > maxArea) continue;

      final confidence = _scoreComponent(
        component: component,
        sampleWidth: sampleWidth,
        sampleHeight: sampleHeight,
        mean: mean,
        stdDev: stdDev,
      );
      if (confidence < minimumConfidence) continue;

      candidates.add(component.toCandidate(
        confidence: confidence,
        imageWidth: width,
        imageHeight: height,
        sampleWidth: sampleWidth,
        sampleHeight: sampleHeight,
      ));
    }

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final faces = _nonOverlapping(candidates)
        .map(
          (candidate) => FaceDetectionBox(
            left: candidate.left,
            top: candidate.top,
            width: candidate.width,
            height: candidate.height,
            confidence: candidate.confidence,
          ),
        )
        .toList();

    return FaceDetectionOutput(
      faces: faces,
      imageWidth: width,
      imageHeight: height,
      inferenceTimeMs: DateTime.now().difference(startedAt).inMilliseconds,
    );
  }

  _Component _collectComponent({
    required int startIndex,
    required List<bool> mask,
    required List<bool> visited,
    required int width,
    required int height,
  }) {
    final queue = Queue<int>()..add(startIndex);
    visited[startIndex] = true;

    var area = 0;
    var minX = width;
    var maxX = 0;
    var minY = height;
    var maxY = 0;

    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      final x = index % width;
      final y = index ~/ width;
      area += 1;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      for (final next in _neighbors(index, x, y, width, height)) {
        if (visited[next] || !mask[next]) continue;
        visited[next] = true;
        queue.add(next);
      }
    }

    return _Component(
      area: area,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  Iterable<int> _neighbors(int index, int x, int y, int width, int height) sync* {
    if (x > 0) yield index - 1;
    if (x < width - 1) yield index + 1;
    if (y > 0) yield index - width;
    if (y < height - 1) yield index + width;
  }

  double _scoreComponent({
    required _Component component,
    required int sampleWidth,
    required int sampleHeight,
    required double mean,
    required double stdDev,
  }) {
    final boxWidth = math.max(1, component.maxX - component.minX + 1);
    final boxHeight = math.max(1, component.maxY - component.minY + 1);
    final aspect = boxWidth / boxHeight;
    final areaRatio = component.area / (sampleWidth * sampleHeight);
    final centerX = (component.minX + component.maxX) / 2.0 / sampleWidth;
    final centerY = (component.minY + component.maxY) / 2.0 / sampleHeight;

    final aspectScore = (1.0 - ((aspect - 0.78).abs() / 0.78)).clamp(0.0, 1.0);
    final areaScore = (areaRatio / 0.10).clamp(0.0, 1.0);
    final horizontalScore = (1.0 - ((centerX - 0.5).abs() / 0.5)).clamp(0.0, 1.0);
    final verticalScore = (1.0 - ((centerY - 0.42).abs() / 0.58)).clamp(0.0, 1.0);
    final contrastScore = (stdDev / 42.0).clamp(0.0, 1.0);

    return (aspectScore * 0.26) +
        (areaScore * 0.24) +
        (horizontalScore * 0.20) +
        (verticalScore * 0.18) +
        (contrastScore * 0.12);
  }

  List<_FaceCandidate> _nonOverlapping(List<_FaceCandidate> candidates) {
    final kept = <_FaceCandidate>[];
    for (final candidate in candidates) {
      final overlaps = kept.any((face) => _iou(face, candidate) > 0.35);
      if (!overlaps) kept.add(candidate);
      if (kept.length >= 4) break;
    }
    return kept;
  }

  double _iou(_FaceCandidate a, _FaceCandidate b) {
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.left + a.width, b.left + b.width);
    final bottom = math.min(a.top + a.height, b.top + b.height);
    final intersectionWidth = math.max(0.0, right - left);
    final intersectionHeight = math.max(0.0, bottom - top);
    final intersection = intersectionWidth * intersectionHeight;
    final union = (a.width * a.height) + (b.width * b.height) - intersection;
    if (union <= 0) return 0;
    return intersection / union;
  }
}

class _Component {
  const _Component({
    required this.area,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final int area;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  _FaceCandidate toCandidate({
    required double confidence,
    required int imageWidth,
    required int imageHeight,
    required int sampleWidth,
    required int sampleHeight,
  }) {
    final scaleX = imageWidth / sampleWidth;
    final scaleY = imageHeight / sampleHeight;
    return _FaceCandidate(
      left: minX * scaleX,
      top: minY * scaleY,
      width: (maxX - minX + 1) * scaleX,
      height: (maxY - minY + 1) * scaleY,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
    );
  }
}

class _FaceCandidate {
  const _FaceCandidate({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double confidence;
}
