import 'package:get/get.dart';

import '../../../data/models/notice_model.dart';
import '../../../data/services/notice_service.dart';
import '../../../data/services/notice_storage.dart';
import '../../../data/services/student_profile_storage.dart';

class NoticeboardController extends GetxController {
  final notices = <NoticeModel>[].obs;

  final filterCourseCode = RxnString();
  final showBookmarkedOnly = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    final list = NoticeService.loadCuratedNotices();
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      return b.createdAt.compareTo(a.createdAt);
    });
    notices.assignAll(list);

    final p = StudentProfileStorage.load();
    if (p != null && p.selectedCourses.isNotEmpty) {
      filterCourseCode.value = null;
    }
  }

  List<NoticeModel> get visible {
    final course = filterCourseCode.value;
    final bmOnly = showBookmarkedOnly.value;

    return notices.where((n) {
      if (n.isExpired || !n.isPublished) return false;

      final matchCourse = course == null
          ? true
          : n.scope != NoticeScope.course || n.courseCode == course;
      if (!matchCourse) return false;

      if (bmOnly && !NoticeStorage.isBookmarked(n.id)) return false;
      return true;
    }).toList();
  }

  bool isRead(String id) => NoticeStorage.isRead(id);
  bool isBookmarked(String id) => NoticeStorage.isBookmarked(id);
  bool isAcknowledged(String id) => NoticeStorage.isAcknowledged(id);

  Future<void> toggleRead(String id) async {
    final v = !NoticeStorage.isRead(id);
    await NoticeStorage.setRead(id, v);
    update();
  }

  Future<void> toggleBookmark(String id) async {
    final v = !NoticeStorage.isBookmarked(id);
    await NoticeStorage.setBookmarked(id, v);
    update();
  }

  Future<void> acknowledge(String id) async {
    await NoticeStorage.setAcknowledged(id, true);
    await NoticeStorage.setRead(id, true);
    update();
  }
}
