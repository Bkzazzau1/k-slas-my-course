import 'package:my_courses/data/models/notice_model.dart';

import 'notice_storage.dart';
import 'notice_visibility_policy.dart';
import 'student_profile_storage.dart';

class NoticeService {
  // Later: fetch from backend using authenticated profile-based targeting.
  static List<NoticeModel> loadCuratedNotices() {
    final p = StudentProfileStorage.load();
    final now = DateTime.now();

    final course = (p?.selectedCourses.isNotEmpty ?? false)
        ? p!.selectedCourses.first
        : 'CSC 305';

    final demo = [
      NoticeModel(
        id: 'n1',
        title: 'Exam coverage update',
        body:
            'The exam will cover Chapters 1–5 only. Focus on Trees, Graphs, and Sorting.',
        scope: NoticeScope.course,
        courseCode: course,
        source: 'Lecturer',
        createdAt: now.subtract(const Duration(hours: 6)),
        priority: 1,
        pinned: true,
        requiresAcknowledgement: true,
        departmentId: p?.departmentId,
        programmeId: p?.programmeId,
        targetLevel: p?.level,
        targetSemester: p?.semester,
        targetCohortKey: p?.studentCategoryKey,
      ),
      NoticeModel(
        id: 'n2',
        title: 'Assignment submission',
        body:
            'Submit your assignment on Graphs by Friday 5pm. No late submissions.',
        scope: NoticeScope.course,
        courseCode: course,
        source: 'Class Rep',
        createdAt: now.subtract(const Duration(days: 1)),
        departmentId: p?.departmentId,
        programmeId: p?.programmeId,
        targetLevel: p?.level,
      ),
      NoticeModel(
        id: 'n3',
        title: 'School announcement',
        body: 'Library hours have been extended for exams week (8am–10pm).',
        scope: NoticeScope.school,
        source: 'School Portal',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    final published = NoticeStorage.loadPublishedNotices()
        .where((notice) => _isVisibleToCurrentStudent(notice, p))
        .toList();

    final merged = <String, NoticeModel>{};
    for (final notice in [...published, ...demo]) {
      merged[notice.id] = notice;
    }
    final result = merged.values
        .where((notice) => _isVisibleToCurrentStudent(notice, p))
        .toList();
    result.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  static bool _isVisibleToCurrentStudent(NoticeModel notice, dynamic profile) {
    return NoticeVisibilityPolicy.isVisibleToStudent(
      notice: notice,
      profile: profile,
    );
  }
}
