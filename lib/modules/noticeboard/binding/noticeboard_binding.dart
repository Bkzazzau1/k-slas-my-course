import 'package:get/get.dart';

import '../controller/noticeboard_controller.dart';

class NoticeboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NoticeboardController(), permanent: true);
  }
}
