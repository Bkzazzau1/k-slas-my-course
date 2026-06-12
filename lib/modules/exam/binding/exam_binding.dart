import 'package:get/get.dart';

import '../controller/exam_controller.dart';

class ExamBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ExamController());
  }
}
