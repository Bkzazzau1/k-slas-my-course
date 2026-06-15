import 'package:get/get.dart';

import 'face_embedding_connector.dart';
import 'face_embedding_connector_selector.dart';
import 'identity_trust_repository.dart';
import 'identity_trust_repository_selector.dart';

class IdentityTrustDemoBootstrap {
  IdentityTrustDemoBootstrap._();

  static void register({
    FaceEmbeddingRuntimeTarget connectorTarget = FaceEmbeddingRuntimeTarget.demo,
  }) {
    if (!Get.isRegistered<IdentityTrustRepository>()) {
      Get.put<IdentityTrustRepository>(
        const IdentityTrustRepositorySelector().select(),
        permanent: true,
      );
    }

    if (!Get.isRegistered<FaceEmbeddingConnector>()) {
      Get.put<FaceEmbeddingConnector>(
        FaceEmbeddingConnectorSelector(target: connectorTarget).select(),
        permanent: true,
      );
    }
  }
}
