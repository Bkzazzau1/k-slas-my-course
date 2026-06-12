import 'package:get/get.dart';

import '../../../data/services/live_session_media_service.dart';
import '../../../data/services/live_session_remote_backend_service.dart';
import '../controller/live_sessions_controller.dart';

class LiveSessionsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LiveSessionsController>()) {
      Get.put(
        LiveSessionsController(
          gateway: RemoteLiveSessionBackendGateway(),
          mediaService: LiveSessionMediaService(),
        ),
        permanent: true,
      );
    }
  }
}
