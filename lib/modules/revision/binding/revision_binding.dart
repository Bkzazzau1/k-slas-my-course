import 'package:get/get.dart';

import '../controller/revision_controller.dart';

class RevisionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RevisionPlanController>(() => RevisionPlanController());
  }
}
