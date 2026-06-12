enum StudentAccessMode { distance }

enum StudentCategory { distanceUndergraduate, distancePostgraduate }

extension StudentCategoryX on StudentCategory {
  String get storageKey {
    switch (this) {
      case StudentCategory.distanceUndergraduate:
        return 'distance_undergraduate';
      case StudentCategory.distancePostgraduate:
        return 'distance_postgraduate';
    }
  }

  String get label {
    switch (this) {
      case StudentCategory.distanceUndergraduate:
        return 'Distance Learner';
      case StudentCategory.distancePostgraduate:
        return 'Distance Learning Postgraduate Student';
    }
  }

  String get shortLabel {
    switch (this) {
      case StudentCategory.distanceUndergraduate:
        return 'Distance';
      case StudentCategory.distancePostgraduate:
        return 'PG Distance';
    }
  }

  String get programLineLabel {
    switch (this) {
      case StudentCategory.distanceUndergraduate:
        return 'B.Sc. Computer Science · Distance Learner';
      case StudentCategory.distancePostgraduate:
        return 'M.Sc. Computer Science · Distance Learning Postgraduate Student';
    }
  }

  StudentAccessMode get accessMode => StudentAccessMode.distance;

  bool get isDistance => true;

  bool get requiresIntegritySync => true;

  bool get canAccessExamSuite => true;

  bool get canAccessAssessmentSuite => true;

  String get pathTitle {
    switch (this) {
      case StudentCategory.distanceUndergraduate:
        return 'Remote-first lecture path';
      case StudentCategory.distancePostgraduate:
        return 'Remote postgraduate seminar path';
    }
  }

  String get lectureDeliverySummary {
    switch (this) {
      case StudentCategory.distanceUndergraduate:
        return 'Videos are the primary classroom path and should stay available on demand.';
      case StudentCategory.distancePostgraduate:
        return 'Videos replace face-to-face seminars and carry the main teaching flow.';
    }
  }

  String get watchExpectation {
    switch (this) {
      case StudentCategory.distanceUndergraduate:
        return 'Students should complete each recording in sequence and keep watched status up to date.';
      case StudentCategory.distancePostgraduate:
        return 'Students should watch full seminar recordings and mark completion for participation tracking.';
    }
  }

  String get attendanceRule {
    switch (this) {
      case StudentCategory.distanceUndergraduate:
        return 'Watched progress and remote participation are part of the main attendance trail.';
      case StudentCategory.distancePostgraduate:
        return 'Remote attendance depends on lecture completion and seminar interaction.';
    }
  }
}

StudentCategory studentCategoryFromStorage(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'distance_postgraduate':
      return StudentCategory.distancePostgraduate;
    case 'distance_undergraduate':
    default:
      return StudentCategory.distanceUndergraduate;
  }
}

StudentCategory inferStudentCategoryFromProgramLine(String? programLine) {
  final value = (programLine ?? '').trim().toLowerCase();
  final isPostgraduate =
      value.contains('postgraduate') ||
      value.contains('m.sc') ||
      value.contains('msc') ||
      value.contains('pgd') ||
      value.contains('mba');

  if (isPostgraduate) return StudentCategory.distancePostgraduate;
  return StudentCategory.distanceUndergraduate;
}
