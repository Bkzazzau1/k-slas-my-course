import 'package:get_storage/get_storage.dart';

class CourseRegistrationStorage {
  CourseRegistrationStorage._();

  static final box = GetStorage();
  static const _selectedElectivesKey = 'course.registration.selectedElectives';
  static const _selectedCarryoversKey = 'course.registration.selectedCarryovers';
  static const _submittedCoursesKey = 'course.registration.submittedCourses';
  static const _submittedAtKey = 'course.registration.submittedAt';

  static Set<String> loadSelectedElectives() {
    final raw = box.read(_selectedElectivesKey);
    if (raw is! List) return <String>{};
    return raw.map((item) => item.toString()).toSet();
  }

  static Future<void> saveSelectedElectives(Set<String> courseCodes) {
    return box.write(_selectedElectivesKey, courseCodes.toList()..sort());
  }

  static Set<String> loadSelectedCarryovers() {
    final raw = box.read(_selectedCarryoversKey);
    if (raw is! List) return <String>{};
    return raw.map((item) => item.toString()).toSet();
  }

  static Future<void> saveSelectedCarryovers(Set<String> courseCodes) {
    return box.write(_selectedCarryoversKey, courseCodes.toList()..sort());
  }

  static List<String> loadSubmittedCourses() {
    final raw = box.read(_submittedCoursesKey);
    if (raw is! List) return const [];
    return raw.map((item) => item.toString()).toList();
  }

  static DateTime? loadSubmittedAt() {
    final raw = box.read(_submittedAtKey)?.toString() ?? '';
    return DateTime.tryParse(raw);
  }

  static Future<void> submitRegistration(List<String> courseCodes) async {
    await box.write(_submittedCoursesKey, courseCodes);
    await box.write(_submittedAtKey, DateTime.now().toIso8601String());
  }

  static Future<void> clearDraft() async {
    await box.remove(_selectedElectivesKey);
    await box.remove(_selectedCarryoversKey);
  }
}
