import 'package:get_storage/get_storage.dart';

import '../models/assignment_model.dart';

class AssignmentLecturerStorage {
  AssignmentLecturerStorage._();

  static final _box = GetStorage();
  static const _assignmentsKey = 'assignment.lecturer.created';
  static const _gradesKey = 'assignment.lecturer.grades';

  static List<AssignmentModel> loadCreatedAssignments() {
    final raw = _box.read(_assignmentsKey);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => AssignmentModel.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.trim().isNotEmpty)
        .toList();
  }

  static Future<void> saveCreatedAssignment(AssignmentModel assignment) async {
    final items = loadCreatedAssignments();
    final next = [
      assignment,
      ...items.where((item) => item.id != assignment.id),
    ];
    await _box.write(
      _assignmentsKey,
      next.map((item) => item.toMap()).toList(),
    );
  }

  static List<AssignmentGradeModel> loadGrades() {
    final raw = _box.read(_gradesKey);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              AssignmentGradeModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.assignmentId.trim().isNotEmpty)
        .toList();
  }

  static AssignmentGradeModel? loadGrade({
    required String assignmentId,
    required String submissionId,
  }) {
    for (final grade in loadGrades()) {
      if (grade.assignmentId == assignmentId &&
          grade.submissionId == submissionId) {
        return grade;
      }
    }
    return null;
  }

  static Future<void> saveGrade(AssignmentGradeModel grade) async {
    final items = loadGrades();
    final next = [
      grade,
      ...items.where(
        (item) =>
            item.assignmentId != grade.assignmentId ||
            item.submissionId != grade.submissionId,
      ),
    ];
    await _box.write(_gradesKey, next.map((item) => item.toMap()).toList());
  }
}
