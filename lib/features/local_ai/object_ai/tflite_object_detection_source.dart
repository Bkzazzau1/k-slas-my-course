import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'camera_object_source.dart';
import 'object_detection_detector.dart';

class TfliteObjectDetectionConfig {
  const TfliteObjectDetectionConfig({
    this.assetPath = 'assets/ml_models/prohibited_object_detector.tflite',
    this.inputWidth = 320,
    this.inputHeight = 320,
    this.inputChannels = 3,
    this.inputMinimum = -1.0,
    this.inputMaximum = 1.0,
    this.confidenceThreshold = 0.55,
    this.maximumObjects = 8,
    this.outputBoxIndex = 0,
    this.outputClassIndex = 1,
    this.outputScoreIndex = 2,
    this.outputCountIndex = 3,
    this.labels = const <String>[
      'background',
      'cell phone',
      'book',
      'laptop',
      'calculator',
      'tablet',
      'earphones',
      'headphones',
      'paper notes',
      'extra screen',
    ],
    this.allowedLabels = const <String>{'background', 'none', 'clean'},
  });

  final String assetPath;
  final int inputWidth;
  final int inputHeight;
  final int inputChannels;
  final double inputMinimum;
  final double inputMaximum;
  final double confidenceThreshold;
  final int maximumObjects;
  final int outputBoxIndex;
  final int outputClassIndex;
  final int outputScoreIndex;
  final int outputCountIndex;
  final List<String> labels;
  final Set<String> allowedLabels;
}

class TfliteObjectDetectionSource implements CameraObjectSource {
  TfliteObjectDetectionSource({
    this.config = const TfliteObjectDetectionConfig(),
    Interpreter? interpreter,
  }) : _interpreter = interpreter;

  final TfliteObjectDetectionConfig config;
  Interpreter? _interpreter;

  bool get isReady => _interpreter != null;

  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(config.assetPath);
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
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

    final input = _buildInput(image);
    final boxShape = interpreter.getOutputTensor(config.outputBoxIndex).shape;
    final classShape = interpreter.getOutputTensor(config.outputClassIndex).shape;
    final scoreShape = interpreter.getOutputTensor(config.outputScoreIndex).shape;

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
      labels: config.labels,
      imageWidth: image.width,
      imageHeight: image.height,
      timestamp: timestamp,
      confidenceThreshold: config.confidenceThreshold,
      maximumObjects: config.maximumObjects,
      allowedLabels: config.allowedLabels,
    );
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
          (_) => List<double>.filled(config.inputChannels, 0),
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
        final index = (rowOffset + srcX).clamp(0, plane.bytes.length - 1).toInt();
        final unit = plane.bytes[index] / 255.0;
        final normalized =
            config.inputMinimum + unit * (config.inputMaximum - config.inputMinimum);
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
    required int maximumObjects,
    required Set<String> allowedLabels,
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
      if (label.isEmpty || allowedLabels.contains(label.toLowerCase())) continue;
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
          },
        ),
      );
    }

    observations.sort((a, b) => b.confidence.compareTo(a.confidence));
    return observations.take(maximumObjects).toList(growable: false);
  }
}
