import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'face_model_connector.dart';

class TfliteFaceModelConfig {
  const TfliteFaceModelConfig({
    this.assetPath = 'assets/ml_models/face_detector.tflite',
    this.inputWidth = 128,
    this.inputHeight = 128,
    this.inputChannels = 1,
    this.confidenceThreshold = 0.55,
    this.maximumFaces = 4,
    this.outputBoxIndex = 0,
    this.outputScoreIndex = 1,
    this.outputCountIndex,
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
    final boxes = List.generate(
      1,
      (_) => List.generate(
        config.maximumFaces,
        (_) => List<double>.filled(4, 0),
      ),
    );
    final scores = List.generate(
      1,
      (_) => List<double>.filled(config.maximumFaces, 0),
    );
    final outputs = <int, Object>{
      config.outputBoxIndex: boxes,
      config.outputScoreIndex: scores,
      if (config.outputCountIndex != null)
        config.outputCountIndex!: List<double>.filled(1, 0),
    };

    interpreter.runForMultipleInputs(<Object>[input], outputs);

    final faces = FaceModelOutputDecoder.decode(
      boxes: boxes.first,
      scores: scores.first,
      imageWidth: image.width,
      imageHeight: image.height,
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
      final srcY = ((y + 0.5) * height / config.inputHeight)
          .floor()
          .clamp(0, height - 1);
      final rowOffset = srcY * plane.bytesPerRow;
      for (var x = 0; x < config.inputWidth; x++) {
        final srcX = ((x + 0.5) * width / config.inputWidth)
            .floor()
            .clamp(0, width - 1);
        final index = (rowOffset + srcX).clamp(0, plane.bytes.length - 1).toInt();
        final normalized = plane.bytes[index] / 255.0;
        final pixel = input[0][y][x];
        for (var c = 0; c < pixel.length; c++) {
          pixel[c] = normalized;
        }
      }
    }

    return input;
  }
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
