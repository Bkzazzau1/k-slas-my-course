import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_courses/features/identity_trust/services/demo_identity_trust_repository.dart';
import 'package:my_courses/features/identity_trust/services/face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/identity_trust_demo_bootstrap.dart';
import 'package:my_courses/features/identity_trust/services/identity_trust_repository.dart';

void main() {
  tearDown(() {
    Get.reset();
  });

  test('demo identity trust bootstrap registers repository and connector', () async {
    IdentityTrustDemoBootstrap.register();

    expect(Get.isRegistered<IdentityTrustRepository>(), true);
    expect(Get.isRegistered<FaceEmbeddingConnector>(), true);

    final repository = Get.find<IdentityTrustRepository>();
    expect(repository, isA<DemoIdentityTrustRepository>());

    final profile = await repository.getFaceProfile('KASU/CSC/001');
    expect(profile?.isActive, true);
    expect(profile?.faceEmbedding, const <double>[1, 0, 0]);
  });
}
