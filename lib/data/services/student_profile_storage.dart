import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/student_profile_model.dart';

class StudentProfileStorage {
  StudentProfileStorage._();
  static final box = GetStorage();
  static const kProfile = "student.profile";

  static StudentProfileModel? load() {
    final raw = box.read(kProfile);
    if (raw == null) return null;

    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return StudentProfileModel(
        schoolId: m["schoolId"],
        schoolName: m["schoolName"],
        departmentId: m["departmentId"],
        departmentName: m["departmentName"],
        programmeId: m["programmeId"],
        programmeName: m["programmeName"],
        level: m["level"],
        semester: m["semester"],
        selectedCourses: (m["selectedCourses"] as List)
            .map((x) => x.toString())
            .toList(),
        fullName: m["fullName"],
        matricNo: m["matricNo"],
        email: m["email"],
        phone: m["phone"],
        studentCategoryKey: m["studentCategoryKey"],
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(StudentProfileModel p) async {
    final raw = jsonEncode({
      "schoolId": p.schoolId,
      "schoolName": p.schoolName,
      "departmentId": p.departmentId,
      "departmentName": p.departmentName,
      "programmeId": p.programmeId,
      "programmeName": p.programmeName,
      "level": p.level,
      "semester": p.semester,
      "selectedCourses": p.selectedCourses,
      "fullName": p.fullName,
      "matricNo": p.matricNo,
      "email": p.email,
      "phone": p.phone,
      "studentCategoryKey": p.studentCategoryKey,
    });
    await box.write(kProfile, raw);
  }

  static Future<void> clear() => box.remove(kProfile);
}
