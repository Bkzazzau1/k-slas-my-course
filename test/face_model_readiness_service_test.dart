import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/identity_trust/services/face_model_readiness_service.dart';
import 'package:my_courses/features/identity_trust/services/static_face_embedding_connector.dart';

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
}
