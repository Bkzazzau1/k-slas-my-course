import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class CourseUiPreferencesService {
  CourseUiPreferencesService._();

  static final GetStorage _box = GetStorage();
  static const String _key = 'student.course.ui.preferences';

  static Map<String, dynamic> _readAll() {
    final raw = _box.read(_key);
    if (raw == null) return <String, dynamic>{};
    try {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> _writeAll(Map<String, dynamic> data) async {
    await _box.write(_key, jsonEncode(data));
  }

  static String _courseKey(String courseCode) => courseCode.trim().toUpperCase();

  static bool isCoursePanelCollapsed(String courseCode) {
    final data = _readAll();
    final course = data[_courseKey(courseCode)];
    if (course is Map<String, dynamic>) {
      return course['coursePanelCollapsed'] == true;
    }
    if (course is Map) {
      return course['coursePanelCollapsed'] == true;
    }
    return false;
  }

  static Future<void> setCoursePanelCollapsed({
    required String courseCode,
    required bool collapsed,
  }) async {
    final data = _readAll();
    final key = _courseKey(courseCode);
    final current = data[key];
    final course = current is Map<String, dynamic>
        ? Map<String, dynamic>.from(current)
        : current is Map
            ? Map<String, dynamic>.from(current)
            : <String, dynamic>{};

    course['coursePanelCollapsed'] = collapsed;
    course['updatedAt'] = DateTime.now().toIso8601String();
    data[key] = course;
    await _writeAll(data);
  }
}
