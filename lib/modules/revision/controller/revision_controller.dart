import 'package:get/get.dart';

import '../../../data/models/exam_models.dart';
import '../../../data/models/revision_models.dart';
import '../../../data/services/exam_revision_plan_service.dart';
import '../../../data/services/revision_plan_service.dart';
import '../../../data/services/revision_plan_storage.dart';
import '../../../data/services/student_profile_storage.dart';

class RevisionPlanController extends GetxController {
  final plan = Rxn<DailyRevisionPlan>();

  @override
  void onInit() {
    loadFromStorage();
    // If nothing in storage, build a fresh plan for the first selected course.
    if (plan.value == null) {
      final profile = StudentProfileStorage.load();
      final courseCode =
          profile?.selectedCourses.isNotEmpty == true
              ? profile!.selectedCourses.first
              : "CSC 305";
      loadForCourse(courseCode);
    }
    super.onInit();
  }

  void loadForCourse(String courseCode) {
    plan.value = RevisionPlanService.buildPlan(courseCode);
    RevisionPlanStorage.save(plan.value!);
  }

  void loadFromStorage() {
    plan.value = RevisionPlanStorage.load();
  }

  void applyExamResult(ExamResult res) {
    final p = ExamRevisionPlanService.fromExam(res);
    plan.value = p;
    RevisionPlanStorage.save(p);
  }
}
