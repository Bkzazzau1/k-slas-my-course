import '../models/cohort_model.dart';
import '../models/student_profile_model.dart';

class StudentCohortTargetingService {
  const StudentCohortTargetingService._();

  static String temporaryCohortKey(StudentProfileModel profile) {
    final category = profile.studentCategoryKey ?? CohortMode.regular.toLowerCase();
    return [
      profile.schoolId,
      profile.departmentId,
      profile.level.toString(),
      profile.semester.toString(),
      category,
    ].map(_slug).join('-');
  }

  static CohortModel provisionalCohortFromProfile(StudentProfileModel profile) {
    final mode = _modeFromCategory(profile.studentCategoryKey);
    final now = DateTime.now();
    final intakeYear = _inferIntakeYear(level: profile.level, currentYear: now.year);
    return CohortModel(
      id: temporaryCohortKey(profile),
      name: '${profile.departmentName} $intakeYear ${CohortModel.modeLabel(mode)}',
      schoolId: profile.schoolId,
      departmentId: profile.departmentId,
      departmentName: profile.departmentName,
      programmeId: profile.departmentId,
      programmeName: profile.departmentName,
      intakeYear: intakeYear,
      mode: mode,
      level: profile.level,
      semester: profile.semester,
      academicSession: _academicSession(now),
    );
  }

  static bool profileMatchesCohort({
    required StudentProfileModel profile,
    required CohortModel cohort,
  }) {
    return cohort.isActive &&
        cohort.schoolId == profile.schoolId &&
        cohort.departmentId == profile.departmentId &&
        (cohort.level == null || cohort.level == profile.level) &&
        (cohort.semester == null || cohort.semester == profile.semester);
  }

  static String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _modeFromCategory(String? category) {
    final key = (category ?? '').toLowerCase();
    if (key.contains('part')) return CohortMode.partTime;
    if (key.contains('dl') || key.contains('distance')) {
      return CohortMode.distanceLearning;
    }
    if (key.contains('sandwich')) return CohortMode.sandwich;
    if (key.contains('pg') || key.contains('post')) return CohortMode.postgraduate;
    return CohortMode.regular;
  }

  static int _inferIntakeYear({required int level, required int currentYear}) {
    final yearsCompleted = (level ~/ 100) - 1;
    if (yearsCompleted <= 0) return currentYear;
    return currentYear - yearsCompleted;
  }

  static String _academicSession(DateTime date) {
    final startYear = date.month >= 9 ? date.year : date.year - 1;
    return '$startYear/${startYear + 1}';
  }
}
