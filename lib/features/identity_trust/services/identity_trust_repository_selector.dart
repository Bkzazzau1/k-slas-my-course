import '../../../data/services/course_catalog_service.dart';
import '../../../data/services/live_session_runtime_mode_service.dart';
import 'api_identity_trust_repository.dart';
import 'demo_identity_trust_repository.dart';
import 'identity_trust_repository.dart';

class IdentityTrustRepositorySelector {
  const IdentityTrustRepositorySelector({
    this.demoRepository,
    this.apiRepository,
    this.config,
    this.runtimeMode,
  });

  final IdentityTrustRepository? demoRepository;
  final ApiIdentityTrustRepository? apiRepository;
  final CourseCatalogBackendConfig? config;
  final LiveSessionRuntimeMode? runtimeMode;

  IdentityTrustRepository select() {
    final mode = runtimeMode ?? LiveSessionRuntimeModeStore.load();
    if (mode != LiveSessionRuntimeMode.production) {
      return demoRepository ?? DemoIdentityTrustRepository();
    }

    final api = apiRepository ?? ApiIdentityTrustRepository(config: config);
    if (api.isConfigured) return api;

    return demoRepository ?? DemoIdentityTrustRepository();
  }

  String get providerLabel {
    final mode = runtimeMode ?? LiveSessionRuntimeModeStore.load();
    if (mode != LiveSessionRuntimeMode.production) {
      return 'Demo identity trust repository';
    }

    final api = apiRepository ?? ApiIdentityTrustRepository(config: config);
    if (api.isConfigured) return 'K-SLAS identity trust API';

    return 'Demo identity trust repository fallback';
  }
}
