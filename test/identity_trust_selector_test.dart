import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_courses/data/services/course_catalog_service.dart';
import 'package:my_courses/data/services/live_session_runtime_mode_service.dart';
import 'package:my_courses/features/identity_trust/services/api_identity_trust_repository.dart';
import 'package:my_courses/features/identity_trust/services/demo_identity_trust_repository.dart';
import 'package:my_courses/features/identity_trust/services/identity_trust_repository_selector.dart';

void main() {
  setUpAll(() async {
    await GetStorage.init();
  });

  test('identity trust selector chooses demo or API repository', () async {
    await LiveSessionRuntimeModeStore.save(LiveSessionRuntimeMode.demo);
    var selected = const IdentityTrustRepositorySelector().select();
    expect(selected, isA<DemoIdentityTrustRepository>());

    await LiveSessionRuntimeModeStore.save(LiveSessionRuntimeMode.production);
    selected = const IdentityTrustRepositorySelector(
      config: CourseCatalogBackendConfig(
        apiBaseUrl: 'https://api.example.test',
        accessToken: 'token',
      ),
    ).select();
    expect(selected, isA<ApiIdentityTrustRepository>());
  });
}
