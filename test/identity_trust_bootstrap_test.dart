import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_courses/features/identity_trust/services/face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/identity_trust_bootstrap.dart';
import 'package:my_courses/features/identity_trust/services/identity_trust_repository.dart';

void main() {
  setUpAll(() async {
    await GetStorage.init();
  });

  tearDown(() {
    Get.reset();
  });

  test('identity trust bootstrap registers repository and connector', () {
    IdentityTrustBootstrap.register();

    expect(Get.isRegistered<IdentityTrustRepository>(), true);
    expect(Get.isRegistered<FaceEmbeddingConnector>(), true);
  });
}
