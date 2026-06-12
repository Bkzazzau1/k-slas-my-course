import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class VideoLectureOfflineStorage {
  VideoLectureOfflineStorage._();

  static final GetStorage _box = GetStorage();
  static const String _key = 'student.video.lecture.offline.ids';

  static Set<String> loadIds() {
    final raw = _box.read(_key);
    if (raw == null) return <String>{};
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((item) => item.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static bool isSaved(String lectureId) => loadIds().contains(lectureId);

  static Future<void> saveLecture(String lectureId) async {
    final ids = loadIds()..add(lectureId);
    await _box.write(_key, jsonEncode(ids.toList()));
  }

  static Future<void> removeLecture(String lectureId) async {
    final ids = loadIds()..remove(lectureId);
    await _box.write(_key, jsonEncode(ids.toList()));
  }
}
