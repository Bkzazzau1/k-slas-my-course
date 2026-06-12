import 'package:get/get.dart';

import '../controller/theory_rewrite_controller.dart';

class TheoryRewriteBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TheoryRewriteController());
  }
}
