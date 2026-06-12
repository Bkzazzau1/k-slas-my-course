import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class WeeklyNotePersonalRecord {
  const WeeklyNotePersonalRecord({
    required this.courseCode,
    required this.week,
    required this.noteText,
    required this.highlights,
    required this.updatedAt,
  });

  final String courseCode;
  final int week;
  final String noteText;
  final List<String> highlights;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'courseCode': courseCode,
        'week': week,
        'noteText': noteText,
        'highlights': highlights,
        'updatedAt': updatedAt.toIso8601String(),
      };

  WeeklyNotePersonalRecord copyWith({
    String? noteText,
    List<String>? highlights,
    DateTime? updatedAt,
  }) {
    return WeeklyNotePersonalRecord(
      courseCode: courseCode,
      week: week,
      noteText: noteText ?? this.noteText,
      highlights: highlights ?? this.highlights,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static WeeklyNotePersonalRecord fromJson(Map<String, dynamic> json) {
    return WeeklyNotePersonalRecord(
      courseCode: json['courseCode']?.toString() ?? '',
      week: _asInt(json['week']),
      noteText: json['noteText']?.toString() ?? '',
      highlights: (json['highlights'] as List? ?? const []).map((e) => e.toString()).toList(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class WeeklyNotePersonalStorage {
  WeeklyNotePersonalStorage._();

  static final GetStorage _box = GetStorage();
  static const String _prefix = 'student.weekly.note.personal';

  static String _key(String courseCode, int week) =>
      '$_prefix.${courseCode.trim().toUpperCase()}.$week';

  static WeeklyNotePersonalRecord load({
    required String courseCode,
    required int week,
  }) {
    final raw = _box.read(_key(courseCode, week));
    if (raw == null) {
      return WeeklyNotePersonalRecord(
        courseCode: courseCode.trim().toUpperCase(),
        week: week,
        noteText: '',
        highlights: const [],
        updatedAt: DateTime.now(),
      );
    }
    try {
      return WeeklyNotePersonalRecord.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      return WeeklyNotePersonalRecord(
        courseCode: courseCode.trim().toUpperCase(),
        week: week,
        noteText: '',
        highlights: const [],
        updatedAt: DateTime.now(),
      );
    }
  }

  static Future<void> save(WeeklyNotePersonalRecord record) async {
    await _box.write(_key(record.courseCode, record.week), jsonEncode(record.toJson()));
  }

  static Future<void> saveNote({
    required String courseCode,
    required int week,
    required String noteText,
  }) async {
    final current = load(courseCode: courseCode, week: week);
    await save(current.copyWith(noteText: noteText, updatedAt: DateTime.now()));
  }

  static Future<void> addHighlight({
    required String courseCode,
    required int week,
    required String highlight,
  }) async {
    final clean = highlight.trim();
    if (clean.isEmpty) return;
    final current = load(courseCode: courseCode, week: week);
    final highlights = [clean, ...current.highlights.where((item) => item != clean)].take(20).toList();
    await save(current.copyWith(highlights: highlights, updatedAt: DateTime.now()));
  }

  static Future<void> removeHighlight({
    required String courseCode,
    required int week,
    required String highlight,
  }) async {
    final current = load(courseCode: courseCode, week: week);
    final highlights = current.highlights.where((item) => item != highlight).toList();
    await save(current.copyWith(highlights: highlights, updatedAt: DateTime.now()));
  }
}
