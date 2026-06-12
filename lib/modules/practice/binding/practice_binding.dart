import 'package:get/get.dart';

import '../controller/practice_controller.dart';

class PracticeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PracticeController());
  }
}
