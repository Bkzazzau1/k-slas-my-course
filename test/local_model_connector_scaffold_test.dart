import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/identity_trust.dart';

void main() {
  test('local model connectors expose config and readiness', () async {
    final tflite = TfliteFaceEmbeddingConnector();
    final onnx = OnnxFaceEmbeddingConnector();

    expect(tflite.connectorId, 'tflite_face_embedding_connector');
    expect(onnx.connectorId, 'onnx_face_embedding_connector');

    await tflite.load();
    await onnx.load();

    expect(tflite.isReady, true);
    expect(onnx.isReady, true);
  });
}
