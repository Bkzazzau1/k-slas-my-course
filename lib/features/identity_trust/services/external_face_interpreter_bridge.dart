import 'flutter_face_embedding_runner.dart';

class ExternalFaceInterpreterBridge implements FlutterFaceInterpreterBridge {
  ExternalFaceInterpreterBridge({
    this.embeddingSize = 192,
  });

  final int embeddingSize;
  bool _loaded = false;

  @override
  Future<void> loadAsset(String modelAssetPath) async {
    _loaded = true;
  }

  @override
  Future<List<double>> runFloatModel({
    required List<double> input,
    required int width,
    required int height,
    required int channels,
  }) async {
    if (!_loaded) {
      throw StateError('External face interpreter bridge is not loaded.');
    }

    return const <double>[];
  }

  @override
  Future<void> close() async {
    _loaded = false;
  }
}
