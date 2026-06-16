import 'local_face_embedding_runner.dart';

abstract class FlutterFaceInterpreterBridge {
  Future<void> loadAsset(String modelAssetPath);

  Future<List<double>> runFloatModel({
    required List<double> input,
    required int width,
    required int height,
    required int channels,
  });

  Future<void> close();
}

class FlutterFaceEmbeddingRunner implements LocalFaceEmbeddingRunner {
  FlutterFaceEmbeddingRunner({required FlutterFaceInterpreterBridge bridge})
      : _bridge = bridge;

  final FlutterFaceInterpreterBridge _bridge;
  bool _loaded = false;

  @override
  Future<void> load(String modelAssetPath) async {
    if (_loaded) return;
    await _bridge.loadAsset(modelAssetPath);
    _loaded = true;
  }

  @override
  Future<List<double>> run(LocalFaceEmbeddingRunnerInput input) async {
    if (!_loaded) {
      throw StateError('Face embedding runner is not loaded.');
    }

    return _bridge.runFloatModel(
      input: input.values,
      width: input.width,
      height: input.height,
      channels: input.channels,
    );
  }

  @override
  Future<void> dispose() async {
    await _bridge.close();
    _loaded = false;
  }
}
