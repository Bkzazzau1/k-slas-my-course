import 'face_embedding_connector_selector.dart';
import 'identity_trust_bootstrap.dart';

class IdentityTrustDemoBootstrap {
  IdentityTrustDemoBootstrap._();

  static void register({
    FaceEmbeddingRuntimeTarget connectorTarget = FaceEmbeddingRuntimeTarget.demo,
  }) {
    IdentityTrustBootstrap.register(connectorTarget: connectorTarget);
  }
}
