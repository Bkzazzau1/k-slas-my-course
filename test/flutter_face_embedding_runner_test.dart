import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/services/flutter_face_embedding_runner.dart';
import 'package:my_courses/features/identity_trust/services/local_face_embedding_runner.dart';

class FakeFlutterFaceInterpreterBridge implements FlutterFaceInterpreterBridge {
  String? loadedAsset;
  bool closed = false;
  LocalFaceEmbeddingRunnerInput? lastInput;

  @override
  Future<void> loadAsset(String modelAssetPath) async {
    loadedAsset = modelAssetPath;
  }

  @override
  Future<List<double>> runFloatModel({
    required List<double> input,
    required int width,
    required int height,
    required int channels,
  }) async {
    lastInput = LocalFaceEmbeddingRunnerInput(
      values: input,
      width: width,
      height: height,
      channels: channels,
    );
    return const <double>[1, 2, 3];
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

void main() {
  test('Flutter face embedding runner delegates to bridge', () async {
    final bridge = FakeFlutterFaceInterpreterBridge();
    final runner = FlutterFaceEmbeddingRunner(bridge: bridge);

    await runner.load('assets/ml_models/mobilefacenet.tflite');
    final output = await runner.run(
      const LocalFaceEmbeddingRunnerInput(
        values: <double>[0.1, 0.2, 0.3],
        width: 1,
        height: 1,
        channels: 3,
      ),
    );
    await runner.dispose();

    expect(bridge.loadedAsset, 'assets/ml_models/mobilefacenet.tflite');
    expect(bridge.lastInput?.width, 1);
    expect(bridge.lastInput?.height, 1);
    expect(bridge.lastInput?.channels, 3);
    expect(output, const <double>[1, 2, 3]);
    expect(bridge.closed, true);
  });
}
