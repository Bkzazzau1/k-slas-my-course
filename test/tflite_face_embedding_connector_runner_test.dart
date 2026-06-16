import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/services/face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/local_face_embedding_runner.dart';
import 'package:my_courses/features/identity_trust/services/tflite_face_embedding_connector.dart';

class FakeLocalFaceEmbeddingRunner implements LocalFaceEmbeddingRunner {
  bool loaded = false;
  LocalFaceEmbeddingRunnerInput? lastInput;

  @override
  Future<void> load(String modelAssetPath) async {
    loaded = true;
  }

  @override
  Future<List<double>> run(LocalFaceEmbeddingRunnerInput input) async {
    lastInput = input;
    return const <double>[3, 4];
  }

  @override
  Future<void> dispose() async {
    loaded = false;
  }
}

void main() {
  test('TFLite connector normalizes input and runner embedding', () async {
    final runner = FakeLocalFaceEmbeddingRunner();
    final connector = TfliteFaceEmbeddingConnector(runner: runner);
    final length = 112 * 112 * 3;

    final output = await connector.run(
      FaceEmbeddingInput(
        values: List<int>.filled(length, 128),
        width: 112,
        height: 112,
        format: 'rgb',
      ),
    );

    expect(runner.loaded, true);
    expect(runner.lastInput?.width, 112);
    expect(runner.lastInput?.height, 112);
    expect(runner.lastInput?.channels, 3);
    expect(output.embedding.length, 2);
    expect(output.embedding.first, closeTo(0.6, 0.0001));
    expect(output.embedding.last, closeTo(0.8, 0.0001));
    expect(output.isUsable, true);
  });

  test('TFLite connector rejects invalid input', () async {
    final connector = TfliteFaceEmbeddingConnector(
      runner: FakeLocalFaceEmbeddingRunner(),
    );

    final output = await connector.run(
      const FaceEmbeddingInput(
        values: <int>[],
        width: 0,
        height: 0,
        format: 'jpeg',
      ),
    );

    expect(output.embedding, isEmpty);
    expect(output.isUsable, false);
  });
}
