import 'package:get/get.dart';

import '../../../data/services/course_catalog_service.dart';
import '../../live_sessions/binding/live_sessions_binding.dart';
import '../../video_lectures/controller/video_lectures_controller.dart';
import '../controller/courses_controller.dart';

class CoursesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CoursesController>()) {
      Get.lazyPut<CoursesController>(
        () => CoursesController(gateway: RemoteCourseCatalogGateway()),
      );
    }
    if (!Get.isRegistered<VideoLecturesController>()) {
      Get.lazyPut<VideoLecturesController>(() => VideoLecturesController());
    }
    LiveSessionsBinding().dependencies();
  }
}
