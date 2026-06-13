import '../models/notice_model.dart';
import '../models/student_profile_model.dart';

class NoticeVisibilityPolicy {
  const NoticeVisibilityPolicy._();

  static bool isGeneralNotice(NoticeModel notice) {
    final hasNoAcademicTarget = notice.schoolId == null &&
        notice.departmentId == null &&
        notice.programmeId == null &&
        notice.targetLevel == null &&
        notice.targetSemester == null &&
        notice.targetCohortKey == null &&
        notice.courseCode == null;
    return hasNoAcademicTarget &&
        (notice.scope == NoticeScope.school || notice.scope == NoticeScope.exam);
  }

  static bool isVisibleToStudent({
    required NoticeModel notice,
    required StudentProfileModel? profile,
  }) {
    if (!notice.isPublished || notice.isExpired) return false;
    if (notice.audience != NoticeAudience.students &&
        notice.audience != NoticeAudience.all) {
      return false;
    }

    if (isGeneralNotice(notice)) return true;
    if (profile == null) return false;

    if (notice.schoolId != null && notice.schoolId != profile.schoolId) {
      return false;
    }

    if (!notice.matchesAcademicTarget(
      level: profile.level,
      semester: profile.semester,
      departmentId: profile.departmentId,
      programmeId: profile.programmeId,
      cohortKey: profile.studentCategoryKey,
    )) {
      return false;
    }

    if (notice.scope == NoticeScope.course && notice.courseCode != null) {
      return profile.selectedCourses.contains(notice.courseCode);
    }

    return true;
  }
}
