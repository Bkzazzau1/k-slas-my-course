import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'face_model_connector.dart';

class TfliteFaceModelConfig {
  const TfliteFaceModelConfig({
    this.assetPath = 'assets/ml_models/face_detector.tflite',
    this.inputWidth = 128,
    this.inputHeight = 128,
    this.inputChannels = 3,
    this.confidenceThreshold = 0.55,
    this.maximumFaces = 4,
    this.outputBoxIndex = 0,
    this.outputScoreIndex = 1,
    this.outputCountIndex,
    this.inputMinimum = -1.0,
    this.inputMaximum = 1.0,
  });

  final String assetPath;
  final int inputWidth;
  final int inputHeight;
  final int inputChannels;
  final double confidenceThreshold;
  final int maximumFaces;
  final int outputBoxIndex;
  final int outputScoreIndex;
  final int? outputCountIndex;
  final double inputMinimum;
  final double inputMaximum;
}

class TfliteFaceModelConnector implements FaceModelConnector {
  TfliteFaceModelConnector({
    this.config = const TfliteFaceModelConfig(),
    Interpreter? interpreter,
  }) : _interpreter = interpreter;

  final TfliteFaceModelConfig config;
  Interpreter? _interpreter;

  @override
  String get connectorId => 'tflite_face_model_connector';

  @override
  bool get isReady => _interpreter != null;

  @override
  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(config.assetPath);
  }

  @override
  Future<FaceDetectionOutput> detectFaces(CameraImage image) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('TFLite face model has not been loaded.');
    }

    final startedAt = DateTime.now();
    final input = _buildInput(image);
    final boxShape = interpreter.getOutputTensor(config.outputBoxIndex).shape;
    final scoreShape = interpreter
        .getOutputTensor(config.outputScoreIndex)
        .shape;
    final boxes = _zeros3d(boxShape);
    final scores = _zeros3d(scoreShape);
    final outputs = <int, Object>{
      config.outputBoxIndex: boxes,
      config.outputScoreIndex: scores,
      if (config.outputCountIndex != null)
        config.outputCountIndex!: List<double>.filled(1, 0),
    };

    interpreter.runForMultipleInputs(<Object>[input], outputs);

    final faces = MediaPipeFaceOutputDecoder.decode(
      rawBoxes: boxes.first,
      rawScores: scores.first,
      imageWidth: image.width,
      imageHeight: image.height,
      inputWidth: config.inputWidth,
      inputHeight: config.inputHeight,
      confidenceThreshold: config.confidenceThreshold,
      maximumFaces: config.maximumFaces,
    );

    return FaceDetectionOutput(
      faces: faces,
      imageWidth: image.width,
      imageHeight: image.height,
      inferenceTimeMs: DateTime.now().difference(startedAt).inMilliseconds,
    );
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }

  Object _buildInput(CameraImage image) {
    final plane = image.planes.first;
    final width = image.width;
    final height = image.height;
    final input = List.generate(
      1,
      (_) => List.generate(
        config.inputHeight,
        (_) => List.generate(
          config.inputWidth,
          (_) => config.inputChannels == 1
              ? List<double>.filled(1, 0)
              : List<double>.filled(config.inputChannels, 0),
        ),
      ),
    );

    for (var y = 0; y < config.inputHeight; y++) {
      final srcY = ((y + 0.5) * height / config.inputHeight).floor().clamp(
        0,
        height - 1,
      );
      final rowOffset = srcY * plane.bytesPerRow;
      for (var x = 0; x < config.inputWidth; x++) {
        final srcX = ((x + 0.5) * width / config.inputWidth).floor().clamp(
          0,
          width - 1,
        );
        final index = (rowOffset + srcX)
            .clamp(0, plane.bytes.length - 1)
            .toInt();
        final unit = plane.bytes[index] / 255.0;
        final normalized =
            config.inputMinimum +
            unit * (config.inputMaximum - config.inputMinimum);
        final pixel = input[0][y][x];
        for (var c = 0; c < pixel.length; c++) {
          pixel[c] = normalized;
        }
      }
    }

    return input;
  }

  List<List<List<double>>> _zeros3d(List<int> shape) {
    if (shape.length == 3) {
      return List.generate(
        shape[0],
        (_) => List.generate(shape[1], (_) => List<double>.filled(shape[2], 0)),
      );
    }
    if (shape.length == 2) {
      return List.generate(
        1,
        (_) => List.generate(shape[0], (_) => List<double>.filled(shape[1], 0)),
      );
    }
    throw StateError('Unsupported face model output tensor shape: $shape');
  }
}

class MediaPipeFaceOutputDecoder {
  const MediaPipeFaceOutputDecoder._();

  static const double _rawScoreLimit = 80;
  static const double _nmsThreshold = 0.30;

  static List<FaceDetectionBox> decode({
    required List<List<double>> rawBoxes,
    required List<List<double>> rawScores,
    required int imageWidth,
    required int imageHeight,
    required int inputWidth,
    required int inputHeight,
    required double confidenceThreshold,
    required int maximumFaces,
  }) {
    final anchors = _generateAnchors(
      inputWidth: inputWidth,
      inputHeight: inputHeight,
    );
    final count = math.min(
      math.min(rawBoxes.length, rawScores.length),
      anchors.length,
    );
    final candidates = <FaceDetectionBox>[];

    for (var i = 0; i < count; i++) {
      final rawScore = rawScores[i].isEmpty ? 0.0 : rawScores[i].first;
      final score = _sigmoid(rawScore.clamp(-_rawScoreLimit, _rawScoreLimit));
      if (score < confidenceThreshold) continue;

      final box = rawBoxes[i];
      if (box.length < 4) continue;

      final anchor = anchors[i];
      final xCenter = (box[0] / inputWidth) + anchor.x;
      final yCenter = (box[1] / inputHeight) + anchor.y;
      final width = box[2] / inputWidth;
      final height = box[3] / inputHeight;

      final left = (xCenter - width / 2).clamp(0.0, 1.0);
      final top = (yCenter - height / 2).clamp(0.0, 1.0);
      final right = (xCenter + width / 2).clamp(0.0, 1.0);
      final bottom = (yCenter + height / 2).clamp(0.0, 1.0);
      final pixelWidth = (right - left) * imageWidth;
      final pixelHeight = (bottom - top) * imageHeight;
      if (pixelWidth <= 1 || pixelHeight <= 1) continue;

      candidates.add(
        FaceDetectionBox(
          left: left * imageWidth,
          top: top * imageHeight,
          width: pixelWidth,
          height: pixelHeight,
          confidence: score,
        ),
      );
    }

    candidates.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
    return _nonMaxSuppression(candidates).take(maximumFaces).toList();
  }

  static List<_Anchor> _generateAnchors({
    required int inputWidth,
    required int inputHeight,
  }) {
    const strides = <int>[8, 16, 16, 16];
    const anchorOffsetX = 0.5;
    const anchorOffsetY = 0.5;
    final anchors = <_Anchor>[];
    var layerId = 0;

    while (layerId < strides.length) {
      var lastSameStrideLayer = layerId;
      var repeats = 0;
      while (lastSameStrideLayer < strides.length &&
          strides[lastSameStrideLayer] == strides[layerId]) {
        lastSameStrideLayer += 1;
        repeats += 2;
      }

      final stride = strides[layerId];
      final featureMapHeight = inputHeight ~/ stride;
      final featureMapWidth = inputWidth ~/ stride;
      for (var y = 0; y < featureMapHeight; y++) {
        final yCenter = (y + anchorOffsetY) / featureMapHeight;
        for (var x = 0; x < featureMapWidth; x++) {
          final xCenter = (x + anchorOffsetX) / featureMapWidth;
          for (var i = 0; i < repeats; i++) {
            anchors.add(_Anchor(xCenter, yCenter));
          }
        }
      }

      layerId = lastSameStrideLayer;
    }

    return anchors;
  }

  static double _sigmoid(num value) {
    return 1 / (1 + math.exp(-value));
  }

  static List<FaceDetectionBox> _nonMaxSuppression(
    List<FaceDetectionBox> candidates,
  ) {
    final selected = <FaceDetectionBox>[];
    for (final candidate in candidates) {
      final overlaps = selected.any(
        (existing) =>
            _intersectionOverUnion(candidate, existing) > _nmsThreshold,
      );
      if (!overlaps) selected.add(candidate);
    }
    return selected;
  }

  static double _intersectionOverUnion(FaceDetectionBox a, FaceDetectionBox b) {
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.left + a.width, b.left + b.width);
    final bottom = math.min(a.top + a.height, b.top + b.height);
    final intersection =
        math.max(0.0, right - left) * math.max(0.0, bottom - top);
    if (intersection <= 0) return 0;
    final union = a.width * a.height + b.width * b.height - intersection;
    if (union <= 0) return 0;
    return intersection / union;
  }
}

class _Anchor {
  const _Anchor(this.x, this.y);

  final double x;
  final double y;
}

class FaceModelOutputDecoder {
  const FaceModelOutputDecoder._();

  static List<FaceDetectionBox> decode({
    required List<List<double>> boxes,
    required List<double> scores,
    required int imageWidth,
    required int imageHeight,
    required double confidenceThreshold,
    required int maximumFaces,
  }) {
    final faces = <FaceDetectionBox>[];
    final count = math.min(math.min(boxes.length, scores.length), maximumFaces);

    for (var i = 0; i < count; i++) {
      final score = scores[i];
      if (score < confidenceThreshold) continue;
      final box = boxes[i];
      if (box.length < 4) continue;

      final normalized = _normalizeBox(box);
      final ymin = normalized[0].clamp(0.0, 1.0);
      final xmin = normalized[1].clamp(0.0, 1.0);
      final ymax = normalized[2].clamp(0.0, 1.0);
      final xmax = normalized[3].clamp(0.0, 1.0);
      final width = math.max(0.0, xmax - xmin) * imageWidth;
      final height = math.max(0.0, ymax - ymin) * imageHeight;
      if (width <= 1 || height <= 1) continue;

      faces.add(
        FaceDetectionBox(
          left: xmin * imageWidth,
          top: ymin * imageHeight,
          width: width,
          height: height,
          confidence: score.clamp(0.0, 1.0),
        ),
      );
    }

    faces.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
    return faces;
  }

  static List<double> _normalizeBox(List<double> box) {
    final looksLikePixels = box.any((value) => value.abs() > 2.0);
    if (!looksLikePixels) return box;
    final maxValue = box.map((value) => value.abs()).fold<double>(0, math.max);
    if (maxValue <= 0) return box;
    return box.map((value) => value / maxValue).toList();
  }
}
