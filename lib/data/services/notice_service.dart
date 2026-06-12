import 'package:my_courses/data/models/notice_model.dart';

import 'student_profile_storage.dart';

class NoticeService {
  // Later: fetch from backend using profile school/dept/level/courses
  static List<NoticeModel> loadCuratedNotices() {
    final p = StudentProfileStorage.load();
    final now = DateTime.now();

    final course = (p?.selectedCourses.isNotEmpty ?? false)
        ? p!.selectedCourses.first
        : "CSC 305";

    return [
      NoticeModel(
        id: "n1",
        title: "Exam coverage update",
        body:
            "The exam will cover Chapters 1–5 only. Focus on Trees, Graphs, and Sorting.",
        scope: NoticeScope.course,
        courseCode: course,
        source: "Lecturer",
        createdAt: now.subtract(const Duration(hours: 6)),
        priority: 1,
      ),
      NoticeModel(
        id: "n2",
        title: "Assignment submission",
        body:
            "Submit your assignment on Graphs by Friday 5pm. No late submissions.",
        scope: NoticeScope.course,
        courseCode: course,
        source: "Class Rep",
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NoticeModel(
        id: "n3",
        title: "School announcement",
        body: "Library hours have been extended for exams week (8am–10pm).",
        scope: NoticeScope.school,
        source: "School Portal",
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
