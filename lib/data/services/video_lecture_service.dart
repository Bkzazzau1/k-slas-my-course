import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/student_category.dart';
import '../models/video_lecture_models.dart';

abstract class VideoLectureCatalogService {
  Future<List<VideoLectureModel>> fetchLectures({
    String? courseCode,
    StudentCategory? category,
  });

  Future<VideoLectureModel> saveLecture(VideoLectureModel lecture);

  Future<void> deleteLecture(String lectureId);

  Future<VideoLectureModel> markWatched({
    required String lectureId,
    required String studentId,
    required bool watched,
  });
}

class LocalVideoLectureCatalogService implements VideoLectureCatalogService {
  LocalVideoLectureCatalogService._();

  static final LocalVideoLectureCatalogService instance =
      LocalVideoLectureCatalogService._();

  static final GetStorage _box = GetStorage();
  static const Uuid _uuid = Uuid();
  static const String _kLectures = 'videoLectures.catalog';
  static const String _sampleVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  @override
  Future<List<VideoLectureModel>> fetchLectures({
    String? courseCode,
    StudentCategory? category,
  }) async {
    _ensureSeeded();
    final code = courseCode?.trim().toUpperCase();
    final items =
        _loadLectures().where((lecture) {
          final matchesCourse =
              code == null || lecture.courseCode.toUpperCase() == code;
          final matchesCategory =
              category == null || lecture.isVisibleTo(category);
          return matchesCourse && matchesCategory;
        }).toList()..sort((a, b) {
          final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
    return items;
  }

  @override
  Future<VideoLectureModel> saveLecture(VideoLectureModel lecture) async {
    _ensureSeeded();
    final now = DateTime.now();
    final normalized = lecture.copyWith(
      id: lecture.id.trim().isEmpty ? _uuid.v4() : lecture.id,
      publishedAt: lecture.publishedAt ?? now,
      updatedAt: now,
    );

    final items = _loadLectures();
    final index = items.indexWhere((item) => item.id == normalized.id);
    if (index >= 0) {
      items[index] = normalized;
    } else {
      items.add(normalized);
    }
    await _saveLectures(items);
    return normalized;
  }

  @override
  Future<void> deleteLecture(String lectureId) async {
    _ensureSeeded();
    final items = _loadLectures()
      ..removeWhere((lecture) => lecture.id == lectureId);
    await _saveLectures(items);
  }

  @override
  Future<VideoLectureModel> markWatched({
    required String lectureId,
    required String studentId,
    required bool watched,
  }) async {
    _ensureSeeded();
    final normalizedStudentId = studentId.trim().toLowerCase();
    final items = _loadLectures();
    final index = items.indexWhere((lecture) => lecture.id == lectureId);
    if (index < 0) {
      throw StateError('Video lecture not found: $lectureId');
    }

    final lecture = items[index];
    final watchedBy = Map<String, String>.from(lecture.watchedBy);
    if (normalizedStudentId.isNotEmpty) {
      if (watched) {
        watchedBy[normalizedStudentId] = DateTime.now().toIso8601String();
      } else {
        watchedBy.remove(normalizedStudentId);
      }
    }

    final updated = lecture.copyWith(
      watchedBy: watchedBy,
      updatedAt: DateTime.now(),
    );
    items[index] = updated;
    await _saveLectures(items);
    return updated;
  }

  void _ensureSeeded() {
    if (_box.read(_kLectures) != null) return;
    _saveLectures(_seedLectures());
  }

  List<VideoLectureModel> _loadLectures() {
    final raw = _box.read(_kLectures);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                VideoLectureModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLectures(List<VideoLectureModel> lectures) async {
    final raw = jsonEncode(
      lectures.map((lecture) => lecture.toJson()).toList(),
    );
    await _box.write(_kLectures, raw);
  }

  List<VideoLectureModel> _seedLectures() {
    final now = DateTime.now();

    return [
      VideoLectureModel(
        id: 'video-csc305-graph-core',
        courseCode: 'CSC 305',
        courseTitle: 'Data Structures',
        title: 'Graph Traversal Core Lecture',
        subtitle: 'Main lecturer upload for the graph traversal week',
        description:
            'Introduces BFS, DFS, adjacency lists, and the key checks students must clear before the next tutorial.',
        lecturerName: 'Dr. Musa Ibrahim',
        videoUrl: _sampleVideoUrl,
        durationMinutes: 34,
        audienceKeys: const ['distance_undergraduate'],
        tags: const ['Core lecture', 'Week 6', 'Revision ready'],
        allowDownloads: true,
        publishedAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      VideoLectureModel(
        id: 'video-csc305-weekend-recap',
        courseCode: 'CSC 305',
        courseTitle: 'Data Structures',
        title: 'Weekend Catch-Up Replay',
        subtitle: 'Compressed replay for distance learners',
        description:
            'A shorter recap focused on the pieces distance students need before the next graded activity.',
        lecturerName: 'Dr. Musa Ibrahim',
        videoUrl: _sampleVideoUrl,
        durationMinutes: 21,
        audienceKeys: const ['distance_undergraduate', 'distance_postgraduate'],
        tags: const ['Catch-up', 'Replay', 'Attendance support'],
        allowDownloads: true,
        publishedAt: now.subtract(const Duration(days: 1, hours: 6)),
        updatedAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),
      VideoLectureModel(
        id: 'video-mth202-eigen-drill',
        courseCode: 'MTH 202',
        courseTitle: 'Linear Algebra',
        title: 'Eigenvalues Drill Video',
        subtitle: 'Worked examples for pre-class review',
        description:
            'Walks through the core matrix steps students should understand before the live drill room.',
        lecturerName: 'Dr. Rose Etim',
        videoUrl: _sampleVideoUrl,
        durationMinutes: 29,
        audienceKeys: const ['distance_undergraduate'],
        tags: const ['Worked examples', 'Prep video'],
        allowDownloads: true,
        publishedAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      VideoLectureModel(
        id: 'video-gst201-writing-module',
        courseCode: 'GST 201',
        courseTitle: 'Use of English',
        title: 'Writing Module Clinic',
        subtitle: 'Short modular lesson for fast completion',
        description:
            'A modular upload that distance learners can clear in one sitting and mark watched.',
        lecturerName: 'Mrs. Halima Yusuf',
        videoUrl: _sampleVideoUrl,
        durationMinutes: 18,
        audienceKeys: const ['distance_undergraduate', 'distance_postgraduate'],
        tags: const ['Module', 'Quick completion'],
        allowDownloads: false,
        publishedAt: now.subtract(const Duration(hours: 14)),
        updatedAt: now.subtract(const Duration(hours: 14)),
      ),
    ];
  }
}
