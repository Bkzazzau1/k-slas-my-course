import 'package:get/get.dart';

import '../../../data/services/live_session_runtime_mode_service.dart';
import 'face_embedding_connector.dart';
import 'face_embedding_connector_selector.dart';
import 'identity_trust_repository.dart';
import 'identity_trust_repository_selector.dart';

class IdentityTrustBootstrap {
  IdentityTrustBootstrap._();

  static void register({
    FaceEmbeddingRuntimeTarget connectorTarget = FaceEmbeddingRuntimeTarget.demo,
    LiveSessionRuntimeMode? runtimeMode,
  }) {
    if (!Get.isRegistered<IdentityTrustRepository>()) {
      Get.put<IdentityTrustRepository>(
        IdentityTrustRepositorySelector(runtimeMode: runtimeMode).select(),
        permanent: true,
      );
    }

    if (!Get.isRegistered<FaceEmbeddingConnector>()) {
      Get.put<FaceEmbeddingConnector>(
        FaceEmbeddingConnectorSelector(
          target: connectorTarget,
          runtimeMode: runtimeMode,
        ).select(),
        permanent: true,
      );
    }
  }
}
