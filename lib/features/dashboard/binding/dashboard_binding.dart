import 'package:get/get.dart';

import '../controller/dashboard_controller.dart';
import '../../../modules/timetable/controller/timetable_controller.dart';
import '../../../modules/weak_areas/controller/weak_areas_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TimetableController(), permanent: true);
    Get.put(WeakAreasController(), permanent: true);
    Get.put(DashboardController(), permanent: true);
  }
}
