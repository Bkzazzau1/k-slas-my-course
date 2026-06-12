import 'package:get/get.dart';

import '../controller/weak_areas_controller.dart';

class WeakAreasBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WeakAreasController>()) {
      Get.lazyPut<WeakAreasController>(() => WeakAreasController());
    }
  }
}
