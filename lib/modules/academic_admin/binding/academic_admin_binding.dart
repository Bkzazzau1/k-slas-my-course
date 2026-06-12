import 'package:get/get.dart';

import '../controller/academic_admin_controller.dart';

class AcademicAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AcademicAdminController>(AcademicAdminController.new);
  }
}
