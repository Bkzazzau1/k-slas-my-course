class CourseType {
  static const String core = 'CORE';
  static const String elective = 'ELECTIVE';
}

class CourseStatus {
  static const String enrolled = 'ENROLLED';
  static const String completed = 'COMPLETED';
}

class CourseRegistrationKind {
  static const String normal = 'NORMAL';
  static const String carryover = 'CARRYOVER';
  static const String repeat = 'REPEAT';
  static const String special = 'SPECIAL';
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
    this.registrationKind = CourseRegistrationKind.normal,
    this.previousGrade,
    this.repeatReason,
    this.requiresApproval = false,
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
  final String registrationKind;
  final String? previousGrade;
  final String? repeatReason;
  final bool requiresApproval;

  bool get isCore => type == CourseType.core;
  bool get isElective => type == CourseType.elective;
  bool get isCompleted => status == CourseStatus.completed;
  bool get isEnrolled => status == CourseStatus.enrolled;
  bool get isCarryover => registrationKind == CourseRegistrationKind.carryover;
  bool get isRepeat => registrationKind == CourseRegistrationKind.repeat;
  bool get isSpecialRegistration => registrationKind == CourseRegistrationKind.special;

  double get qualityPoints => (gradePoint ?? 0) * creditUnits;
}
