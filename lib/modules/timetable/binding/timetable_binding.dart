import 'package:get/get.dart';

import '../controller/timetable_controller.dart';

class TimetableBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TimetableController(), permanent: true);
  }
}
