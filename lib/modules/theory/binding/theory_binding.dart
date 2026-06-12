import 'package:get/get.dart';

import '../controller/theory_controller.dart';

class TheoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TheoryController());
  }
}
