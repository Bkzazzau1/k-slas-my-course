import 'package:get/get.dart';

import 'demo_identity_trust_repository.dart';
import 'face_embedding_connector.dart';
import 'identity_trust_repository.dart';
import 'static_face_embedding_connector.dart';

class IdentityTrustDemoBootstrap {
  IdentityTrustDemoBootstrap._();

  static void register() {
    if (!Get.isRegistered<IdentityTrustRepository>()) {
      Get.put<IdentityTrustRepository>(DemoIdentityTrustRepository(), permanent: true);
    }

    if (!Get.isRegistered<FaceEmbeddingConnector>()) {
      Get.put<FaceEmbeddingConnector>(
        StaticFaceEmbeddingConnector(
          embedding: const <double>[1, 0, 0],
          version: 'demo-static-face-v1',
        ),
        permanent: true,
      );
    }
  }
}
