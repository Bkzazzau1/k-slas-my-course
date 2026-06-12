import 'package:get/get.dart';

import '../../../data/models/student_category.dart';
import '../../../data/models/video_lecture_models.dart';
import '../../../data/services/video_lecture_service.dart';

class VideoLecturesController extends GetxController {
  VideoLecturesController({VideoLectureCatalogService? service})
    : _service = service ?? LocalVideoLectureCatalogService.instance;

  final VideoLectureCatalogService _service;

  final lectures = <VideoLectureModel>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadLectures();
  }

  Future<void> loadLectures({
    String? courseCode,
    StudentCategory? category,
  }) async {
    isLoading.value = true;
    try {
      final items = await _service.fetchLectures(
        courseCode: courseCode,
        category: category,
      );
      lectures.assignAll(items);
      error.value = null;
    } catch (err) {
      lectures.clear();
      error.value = err.toString();
    } finally {
      isLoading.value = false;
    }
  }

  List<VideoLectureModel> lecturesForCourse(
    String courseCode, {
    StudentCategory? category,
  }) {
    final code = courseCode.trim().toUpperCase();
    final items = lectures.where((lecture) {
      final matchesCourse = lecture.courseCode.toUpperCase() == code;
      final matchesCategory =
          category == null || lecture.isVisibleTo(category);
      return matchesCourse && matchesCategory;
    }).toList()
      ..sort((a, b) {
        final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return items;
  }

  Future<void> publishLecture({
    required String courseCode,
    required String courseTitle,
    required String title,
    required String subtitle,
    required String description,
    required String lecturerName,
    required String videoUrl,
    required int durationMinutes,
    required List<StudentCategory> audiences,
    required bool allowDownloads,
    List<String> tags = const [],
  }) async {
    final lecture = VideoLectureModel(
      id: '',
      courseCode: courseCode,
      courseTitle: courseTitle,
      title: title.trim(),
      subtitle: subtitle.trim(),
      description: description.trim(),
      lecturerName: lecturerName.trim(),
      videoUrl: videoUrl.trim(),
      durationMinutes: durationMinutes,
      audienceKeys: audiences.map((item) => item.storageKey).toList(),
      tags: tags.where((item) => item.trim().isNotEmpty).toList(),
      allowDownloads: allowDownloads,
      requireWatchedMark: true,
      publishedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final saved = await _service.saveLecture(lecture);
    _upsert(saved);
  }

  Future<void> markLectureWatched({
    required String lectureId,
    required String studentId,
    required bool watched,
  }) async {
    final updated = await _service.markWatched(
      lectureId: lectureId,
      studentId: studentId,
      watched: watched,
    );
    _upsert(updated);
  }

  Future<void> deleteLecture(String lectureId) async {
    await _service.deleteLecture(lectureId);
    lectures.removeWhere((lecture) => lecture.id == lectureId);
  }

  void _upsert(VideoLectureModel lecture) {
    final index = lectures.indexWhere((item) => item.id == lecture.id);
    if (index >= 0) {
      lectures[index] = lecture;
      lectures.refresh();
      return;
    }
    lectures.insert(0, lecture);
  }
}
