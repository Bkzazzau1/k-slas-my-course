import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/services/external_face_interpreter_bridge.dart';
import 'package:my_courses/features/identity_trust/services/face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/flutter_face_embedding_runner.dart';
import 'package:my_courses/features/identity_trust/services/tflite_face_embedding_connector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TFLite face embedding connector produces a real embedding', () async {
    final connector = TfliteFaceEmbeddingConnector(
      runner: FlutterFaceEmbeddingRunner(
        bridge: ExternalFaceInterpreterBridge(),
      ),
    );

    final output = await connector.run(
      FaceEmbeddingInput(
        values: List<int>.filled(112 * 112 * 3, 128),
        width: 112,
        height: 112,
        format: 'rgb',
      ),
    );

    expect(output.embedding, isNotEmpty);
    expect(output.embedding.length, 192);
    expect(output.isUsable, true);
  });
}
