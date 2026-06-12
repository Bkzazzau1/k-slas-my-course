import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/exam_models.dart';
import '../models/timetable_models.dart';

class TimetableStorage {
  TimetableStorage._();
  static final box = GetStorage();

  static const String kClassEvents = "timetable.classEvents";
  static const String kExamEvents = "timetable.examEvents";

  static List<TimetableEventModel> loadClasses() => _load(kClassEvents);
  static List<TimetableEventModel> loadExams() => _load(kExamEvents);

  static Future<void> saveClasses(List<TimetableEventModel> items) =>
      _save(kClassEvents, items);
  static Future<void> saveExams(List<TimetableEventModel> items) =>
      _save(kExamEvents, items);

  static List<TimetableEventModel> _load(String key) {
    final raw = box.read(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(String key, List<TimetableEventModel> items) async {
    final raw = jsonEncode(items.map(_toJson).toList());
    await box.write(key, raw);
  }

  static Map<String, dynamic> _toJson(TimetableEventModel e) => {
    "id": e.id,
    "type": e.type,
    "courseCode": e.courseCode,
    "title": e.title,
    "start": e.start.toIso8601String(),
    "end": e.end.toIso8601String(),
    "location": e.location,
    "deliveryMode": e.deliveryMode.raw,
    "dayOfWeek": e.dayOfWeek,
    "isReadOnly": e.isReadOnly,
  };

  static TimetableEventModel _fromJson(Map<String, dynamic> m) =>
      TimetableEventModel(
        id: m["id"] ?? "",
        type: m["type"] ?? TimetableType.classes,
        courseCode: m["courseCode"] ?? "",
        title: m["title"] ?? "",
        start: DateTime.tryParse(m["start"] ?? "") ?? DateTime.now(),
        end:
            DateTime.tryParse(m["end"] ?? "") ??
            DateTime.now().add(const Duration(hours: 1)),
        location: m["location"] ?? "",
        deliveryMode: ExamDeliveryModeX.fromRaw(m["deliveryMode"]?.toString()),
        dayOfWeek: m["dayOfWeek"],
        isReadOnly: m["isReadOnly"] ?? true,
      );
}
