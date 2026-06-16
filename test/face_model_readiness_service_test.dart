import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/services/external_face_interpreter_bridge.dart';
import 'package:my_courses/features/identity_trust/services/face_model_readiness_service.dart';
import 'package:my_courses/features/identity_trust/services/flutter_face_embedding_runner.dart';
import 'package:my_courses/features/identity_trust/services/static_face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/tflite_face_embedding_connector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('readiness service accepts static demo connector', () async {
    final service = const FaceModelReadinessService();
    final result = await service.check(
      StaticFaceEmbeddingConnector(
        embedding: const <double>[1, 0, 0],
        version: 'demo-static-face-v1',
      ),
    );

    expect(result.connectorReady, true);
    expect(result.canProduceEmbedding, true);
  });

  test('readiness service reports empty external bridge output', () async {
    final service = const FaceModelReadinessService(
      modelAssetPath: 'assets/ml_models/mobilefacenet.tflite',
    );
    final result = await service.check(
      TfliteFaceEmbeddingConnector(
        runner: FlutterFaceEmbeddingRunner(
          bridge: ExternalFaceInterpreterBridge(),
        ),
      ),
    );

    expect(result.ready, false);
  });
}
