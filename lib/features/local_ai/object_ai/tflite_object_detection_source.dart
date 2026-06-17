import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'camera_object_source.dart';
import 'object_detection_detector.dart';

class TfliteObjectDetectionConfig {
  const TfliteObjectDetectionConfig({
    this.assetPath = 'assets/ml_models/prohibited_object_detector.tflite',
    this.labelsAssetPath = 'assets/ml_models/prohibited_object_labels.txt',
    this.inputWidth = 320,
    this.inputHeight = 320,
    this.inputChannels = 3,
    this.inputMinimum = 0.0,
    this.inputMaximum = 255.0,
    this.confidenceThreshold = 0.45,
    this.phoneBlockConfidence = 0.65,
    this.manualReviewConfidence = 0.45,
    this.maximumObjects = 8,
    this.outputBoxIndex = 0,
    this.outputClassIndex = 1,
    this.outputScoreIndex = 2,
    this.outputCountIndex = 3,
    this.labels = const <String>[],
    this.prohibitedLabels = const <String>{'cell phone'},
    this.manualReviewLabels = const <String>{
      'backpack',
      'book',
      'keyboard',
      'laptop',
      'mouse',
      'remote',
      'tv',
      'handbag',
      'suitcase',
      'bottle',
      'cup',
      'scissors',
    },
    this.allowedLabels = const <String>{
      '???',
      'background',
      'none',
      'clean',
      'person',
      'chair',
      'dining table',
    },
  });

  final String assetPath;
  final String labelsAssetPath;
  final int inputWidth;
  final int inputHeight;
  final int inputChannels;
  final double inputMinimum;
  final double inputMaximum;
  final double confidenceThreshold;
  final double phoneBlockConfidence;
  final double manualReviewConfidence;
  final int maximumObjects;
  final int outputBoxIndex;
  final int outputClassIndex;
  final int outputScoreIndex;
  final int outputCountIndex;
  final List<String> labels;
  final Set<String> prohibitedLabels;
  final Set<String> manualReviewLabels;
  final Set<String> allowedLabels;
}

class TfliteObjectDetectionSource implements CameraObjectSource {
  TfliteObjectDetectionSource({
    this.config = const TfliteObjectDetectionConfig(),
    Interpreter? interpreter,
  }) : _interpreter = interpreter;

  final TfliteObjectDetectionConfig config;
  Interpreter? _interpreter;
  List<String>? _labels;

  bool get isReady => _interpreter != null;

  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(config.assetPath);
    _labels ??= config.labels.isNotEmpty
        ? config.labels
        : await _loadLabels(config.labelsAssetPath);
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }

  @override
  Future<List<ObjectDetectionObservation>> analyzeFrame({
    required CameraImage image,
    required DateTime timestamp,
  }) async {
    await load();
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('TFLite object model has not been loaded.');
    }

    final input = _buildInput(image, interpreter);
    final boxShape = interpreter.getOutputTensor(config.outputBoxIndex).shape;
    final classShape = interpreter
        .getOutputTensor(config.outputClassIndex)
        .shape;
    final scoreShape = interpreter
        .getOutputTensor(config.outputScoreIndex)
        .shape;

    final boxes = _zeros3d(boxShape);
    final classes = _zeros2d(classShape);
    final scores = _zeros2d(scoreShape);
    final counts = List<double>.filled(1, 0);
    final outputs = <int, Object>{
      config.outputBoxIndex: boxes,
      config.outputClassIndex: classes,
      config.outputScoreIndex: scores,
      config.outputCountIndex: counts,
    };

    interpreter.runForMultipleInputs(<Object>[input], outputs);

    return TfliteObjectOutputDecoder.decode(
      rawBoxes: boxes.first,
      rawClasses: classes.first,
      rawScores: scores.first,
      rawCount: counts.first,
      labels: _labels ?? config.labels,
      imageWidth: image.width,
      imageHeight: image.height,
      timestamp: timestamp,
      confidenceThreshold: config.confidenceThreshold,
      phoneBlockConfidence: config.phoneBlockConfidence,
      manualReviewConfidence: config.manualReviewConfidence,
      maximumObjects: config.maximumObjects,
      allowedLabels: config.allowedLabels,
      prohibitedLabels: config.prohibitedLabels,
      manualReviewLabels: config.manualReviewLabels,
    );
  }

  Future<List<ObjectDetectionObservation>> analyzeImage({
    required img.Image image,
    required DateTime timestamp,
  }) async {
    await load();
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('TFLite object model has not been loaded.');
    }

    final input = _buildImageInput(image, interpreter);
    final boxShape = interpreter.getOutputTensor(config.outputBoxIndex).shape;
    final classShape = interpreter
        .getOutputTensor(config.outputClassIndex)
        .shape;
    final scoreShape = interpreter
        .getOutputTensor(config.outputScoreIndex)
        .shape;

    final boxes = _zeros3d(boxShape);
    final classes = _zeros2d(classShape);
    final scores = _zeros2d(scoreShape);
    final counts = List<double>.filled(1, 0);
    final outputs = <int, Object>{
      config.outputBoxIndex: boxes,
      config.outputClassIndex: classes,
      config.outputScoreIndex: scores,
      config.outputCountIndex: counts,
    };

    interpreter.runForMultipleInputs(<Object>[input], outputs);

    return TfliteObjectOutputDecoder.decode(
      rawBoxes: boxes.first,
      rawClasses: classes.first,
      rawScores: scores.first,
      rawCount: counts.first,
      labels: _labels ?? config.labels,
      imageWidth: image.width,
      imageHeight: image.height,
      timestamp: timestamp,
      confidenceThreshold: config.confidenceThreshold,
      phoneBlockConfidence: config.phoneBlockConfidence,
      manualReviewConfidence: config.manualReviewConfidence,
      maximumObjects: config.maximumObjects,
      allowedLabels: config.allowedLabels,
      prohibitedLabels: config.prohibitedLabels,
      manualReviewLabels: config.manualReviewLabels,
    );
  }

  Future<List<String>> _loadLabels(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return raw
        .split(RegExp(r'\r?\n'))
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
  }

  Object _buildInput(CameraImage image, Interpreter interpreter) {
    final plane = image.planes.first;
    final width = image.width;
    final height = image.height;
    final useUint8 = interpreter
        .getInputTensor(0)
        .type
        .toString()
        .toLowerCase()
        .contains('uint8');
    final input = List.generate(
      1,
      (_) => List.generate(
        config.inputHeight,
        (_) => List.generate(
          config.inputWidth,
          (_) => List<num>.filled(config.inputChannels, 0),
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
          pixel[c] = useUint8 ? normalized.round().clamp(0, 255) : normalized;
        }
      }
    }

    return input;
  }

  Object _buildImageInput(img.Image image, Interpreter interpreter) {
    final useUint8 = interpreter
        .getInputTensor(0)
        .type
        .toString()
        .toLowerCase()
        .contains('uint8');
    final input = List.generate(
      1,
      (_) => List.generate(
        config.inputHeight,
        (_) => List.generate(
          config.inputWidth,
          (_) => List<num>.filled(config.inputChannels, 0),
        ),
      ),
    );

    for (var y = 0; y < config.inputHeight; y++) {
      final srcY = ((y + 0.5) * image.height / config.inputHeight)
          .floor()
          .clamp(0, image.height - 1);
      for (var x = 0; x < config.inputWidth; x++) {
        final srcX = ((x + 0.5) * image.width / config.inputWidth)
            .floor()
            .clamp(0, image.width - 1);
        final sourcePixel = image.getPixel(srcX, srcY);
        final values = <double>[
          sourcePixel.r / 255.0,
          sourcePixel.g / 255.0,
          sourcePixel.b / 255.0,
        ];
        final pixel = input[0][y][x];
        for (var c = 0; c < pixel.length; c++) {
          final value = values[c.clamp(0, values.length - 1)];
          final normalized =
              config.inputMinimum +
              value * (config.inputMaximum - config.inputMinimum);
          pixel[c] = useUint8 ? normalized.round().clamp(0, 255) : normalized;
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
    throw StateError('Unsupported object box output tensor shape: $shape');
  }

  List<List<double>> _zeros2d(List<int> shape) {
    if (shape.length == 2) {
      return List.generate(shape[0], (_) => List<double>.filled(shape[1], 0));
    }
    if (shape.length == 1) {
      return List.generate(1, (_) => List<double>.filled(shape[0], 0));
    }
    throw StateError('Unsupported object output tensor shape: $shape');
  }
}

class TfliteObjectOutputDecoder {
  const TfliteObjectOutputDecoder._();

  static List<ObjectDetectionObservation> decode({
    required List<List<double>> rawBoxes,
    required List<double> rawClasses,
    required List<double> rawScores,
    required double rawCount,
    required List<String> labels,
    required int imageWidth,
    required int imageHeight,
    required DateTime timestamp,
    required double confidenceThreshold,
    required double phoneBlockConfidence,
    required double manualReviewConfidence,
    required int maximumObjects,
    required Set<String> allowedLabels,
    Set<String> prohibitedLabels = const <String>{},
    Set<String> manualReviewLabels = const <String>{},
  }) {
    final count = rawCount > 0
        ? rawCount.round().clamp(0, rawScores.length)
        : rawScores.length;
    final observations = <ObjectDetectionObservation>[];

    for (var i = 0; i < count && i < rawBoxes.length; i++) {
      final score = rawScores[i];
      if (score < confidenceThreshold) continue;

      final classIndex = rawClasses[i].round();
      if (classIndex < 0 || classIndex >= labels.length) continue;
      final label = labels[classIndex].trim();
      final normalizedLabel = label.toLowerCase();
      if (label.isEmpty || allowedLabels.contains(normalizedLabel)) continue;
      final isProhibited = prohibitedLabels.contains(normalizedLabel);
      final isManualReview = manualReviewLabels.contains(normalizedLabel);
      if (prohibitedLabels.isNotEmpty && !isProhibited && !isManualReview) {
        continue;
      }
      final reviewPolicy = isProhibited && score >= phoneBlockConfidence
          ? 'prohibited'
          : score >= manualReviewConfidence
          ? 'manualReview'
          : 'ignored';
      if (reviewPolicy == 'ignored') continue;
      final box = rawBoxes[i];
      if (box.length < 4) continue;

      final ymin = box[0].clamp(0.0, 1.0);
      final xmin = box[1].clamp(0.0, 1.0);
      final ymax = box[2].clamp(0.0, 1.0);
      final xmax = box[3].clamp(0.0, 1.0);
      final width = (xmax - xmin) * imageWidth;
      final height = (ymax - ymin) * imageHeight;
      if (width <= 1 || height <= 1) continue;

      observations.add(
        ObjectDetectionObservation(
          timestamp: timestamp,
          label: label,
          confidence: score,
          boundingBox: <String, num>{
            'x': xmin * imageWidth,
            'y': ymin * imageHeight,
            'width': width,
            'height': height,
          },
          metadata: <String, Object?>{
            'source': 'tflite_object_detection_source',
            'classIndex': classIndex,
            'reviewPolicy': reviewPolicy,
            'requiresHumanDecision': reviewPolicy == 'manualReview',
          },
        ),
      );
    }

    observations.sort((a, b) => b.confidence.compareTo(a.confidence));
    return observations.take(maximumObjects).toList(growable: false);
  }
}
