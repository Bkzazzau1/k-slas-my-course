class CourseType {
  static const String core = 'CORE';
  static const String elective = 'ELECTIVE';
}

class CourseStatus {
  static const String enrolled = 'ENROLLED';
  static const String completed = 'COMPLETED';
}

class CourseModel {
  const CourseModel(
    this.code,
    this.title, {
    this.id,
    this.notes = false,
    this.pastQuestions = false,
    this.progress = 0,
    this.creditUnits = 3,
    this.type = CourseType.core,
    this.status = CourseStatus.enrolled,
    this.level,
    this.semester,
    this.academicSession,
    this.grade,
    this.gradePoint,
  });

  final int? id;
  final String code;
  final String title;
  final bool notes;
  final bool pastQuestions;
  final int progress;
  final int creditUnits;
  final String type;
  final String status;
  final int? level;
  final int? semester;
  final String? academicSession;
  final String? grade;
  final double? gradePoint;

  bool get isCore => type == CourseType.core;
  bool get isElective => type == CourseType.elective;
  bool get isCompleted => status == CourseStatus.completed;
  bool get isEnrolled => status == CourseStatus.enrolled;

  double get qualityPoints => (gradePoint ?? 0) * creditUnits;
}
