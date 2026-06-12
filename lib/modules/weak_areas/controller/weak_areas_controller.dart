import 'package:get/get.dart';

import '../../../data/models/weak_area_models.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../data/services/weak_areas_service.dart';

class WeakAreasController extends GetxController {
  final summary = Rxn<WeakAreasSummary>();
  final isLoading = false.obs;

  Future<void> load({String? courseCode}) async {
    isLoading.value = true;
    try {
      final profile = StudentProfileStorage.load();
      final cc =
          courseCode ??
          (profile?.selectedCourses.isNotEmpty == true
              ? profile!.selectedCourses.first
              : "CSC 305");

      summary.value = WeakAreasService.compute(courseCode: cc);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    load();
    super.onInit();
  }
}
