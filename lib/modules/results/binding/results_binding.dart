import 'package:get/get.dart';

import '../controller/results_controller.dart';

class ResultsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResultsController>(ResultsController.new);
  }
}
