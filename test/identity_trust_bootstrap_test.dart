import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_courses/data/services/live_session_runtime_mode_service.dart';
import 'package:my_courses/features/identity_trust/services/face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/identity_trust_bootstrap.dart';
import 'package:my_courses/features/identity_trust/services/identity_trust_repository.dart';

void main() {
  tearDown(() {
    Get.reset();
  });

  test('identity trust bootstrap registers repository and connector', () {
    IdentityTrustBootstrap.register(runtimeMode: LiveSessionRuntimeMode.demo);

    expect(Get.isRegistered<IdentityTrustRepository>(), true);
    expect(Get.isRegistered<FaceEmbeddingConnector>(), true);
  });
}
