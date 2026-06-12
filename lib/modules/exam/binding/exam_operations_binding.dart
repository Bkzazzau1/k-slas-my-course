import 'package:get/get.dart';

import '../controller/exam_operations_controller.dart';

class ExamOperationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ExamOperationsController());
  }
}
