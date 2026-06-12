import 'package:get/get.dart';

import '../controller/cbt_controller.dart';

class CBTBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CBTController());
  }
}
