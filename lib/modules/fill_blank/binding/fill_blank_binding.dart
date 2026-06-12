import 'package:get/get.dart';

import '../controller/fill_blank_controller.dart';

class FillBlankBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(FillBlankController());
  }
}
