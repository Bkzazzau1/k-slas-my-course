import 'package:tflite_flutter/tflite_flutter.dart';

import 'flutter_face_embedding_runner.dart';

class ExternalFaceInterpreterBridge implements FlutterFaceInterpreterBridge {
  ExternalFaceInterpreterBridge({
    this.embeddingSize = 192,
    InterpreterOptions? options,
  }) : _options = options;

  final int embeddingSize;
  final InterpreterOptions? _options;
  Interpreter? _interpreter;

  @override
  Future<void> loadAsset(String modelAssetPath) async {
    _interpreter ??= await Interpreter.fromAsset(
      modelAssetPath,
      options: _options,
    );
  }

  @override
  Future<List<double>> runFloatModel({
    required List<double> input,
    required int width,
    required int height,
    required int channels,
  }) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('External face interpreter bridge is not loaded.');
    }

    final shapedInput = _shapeInput(
      input: input,
      width: width,
      height: height,
      channels: channels,
    );
    final output = List<double>.filled(embeddingSize, 0).reshape(<int>[1, embeddingSize]);
    interpreter.run(shapedInput, output);

    final firstRow = output.first;
    return List<double>.from(firstRow);
  }

  @override
  Future<void> close() async {
    _interpreter?.close();
    _interpreter = null;
  }

  List<List<List<List<double>>>> _shapeInput({
    required List<double> input,
    required int width,
    required int height,
    required int channels,
  }) {
    final expectedLength = width * height * channels;
    if (input.length < expectedLength) {
      throw ArgumentError('Face model input length is smaller than expected.');
    }

    var index = 0;
    return <List<List<List<double>>>>[
      List<List<List<double>>>.generate(
        height,
        (_) => List<List<double>>.generate(
          width,
          (_) => List<double>.generate(
            channels,
            (_) => input[index++],
            growable: false,
          ),
          growable: false,
        ),
        growable: false,
      ),
    ];
  }
}
