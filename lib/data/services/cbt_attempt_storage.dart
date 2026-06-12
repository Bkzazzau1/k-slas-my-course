import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/cbt_models.dart';
import '../models/exam_models.dart';

class CBTAttemptStorage {
  CBTAttemptStorage._();
  static final box = GetStorage();

  static String _key(String courseCode) => "cbt.attempts.$courseCode";

  static List<CBTAttemptModel> loadAttempts(String courseCode) {
    final raw = box.read(_key(courseCode));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAttempt(String courseCode, CBTAttemptModel a) async {
    final list = loadAttempts(courseCode);
    list.insert(0, a);

    // keep last 20
    final trimmed = list.take(20).toList();

    await box.write(
      _key(courseCode),
      jsonEncode(trimmed.map(_toJson).toList()),
    );
  }

  static Map<String, dynamic> _toJson(CBTAttemptModel a) => {
    "id": a.id,
    "courseCode": a.courseCode,
    "sessionType": a.sessionType,
    "gradingType": a.gradingType,
    "mode": a.mode,
    "totalQuestions": a.totalQuestions,
    "correct": a.correct,
    "startedAt": a.startedAt.toIso8601String(),
    "endedAt": a.endedAt.toIso8601String(),
    "topic": a.topic,
    "durationMinutes": a.durationMinutes,
    "topicStats": a.topicStats,
    "deliveryMode": a.deliveryMode.raw,
    "whiteboardEnabled": a.whiteboardEnabled,
    "whiteboardRequired": a.whiteboardRequired,
    "whiteboardStrokeCount": a.whiteboardStrokeCount,
    "whiteboardPrompt": a.whiteboardPrompt,
  };

  static CBTAttemptModel _fromJson(Map<String, dynamic> m) {
    final ts = m["topicStats"];
    Map<String, Map<String, int>>? parsed;
    if (ts is Map) {
      parsed = ts.map((k, v) {
        if (v is Map) {
          final correct = _asInt(v["correct"]);
          final wrong = _asInt(v["wrong"]);
          final total = _asInt(v["total"]);
          final scorePct = _asInt(v["scorePct"]);
          return MapEntry(k.toString(), {
            "correct": correct,
            "wrong": wrong,
            "total": total,
            "scorePct": scorePct,
          });
        }
        return MapEntry(k.toString(), {
          "correct": 0,
          "wrong": 0,
          "total": 0,
          "scorePct": 0,
        });
      });
    }

    return CBTAttemptModel(
      id: m["id"],
      courseCode: m["courseCode"],
      sessionType: m["sessionType"]?.toString() ?? "ASSESSMENT",
      gradingType: m["gradingType"]?.toString() ?? "UNGRADED",
      mode: m["mode"],
      totalQuestions: m["totalQuestions"],
      correct: m["correct"],
      startedAt: DateTime.parse(m["startedAt"]),
      endedAt: DateTime.parse(m["endedAt"]),
      topic: m["topic"],
      durationMinutes: m["durationMinutes"],
      topicStats: parsed,
      deliveryMode: ExamDeliveryModeX.fromRaw(m["deliveryMode"]?.toString()),
      whiteboardEnabled: m["whiteboardEnabled"] == true,
      whiteboardRequired: m["whiteboardRequired"] == true,
      whiteboardStrokeCount: _asInt(m["whiteboardStrokeCount"]),
      whiteboardPrompt: m["whiteboardPrompt"]?.toString(),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? "") ?? 0;
  }
}

class CbtAttemptStorage {
  static final _box = GetStorage();
  static const _k = "cbt_attempts";
  static const _max = 50;

  /// Minimal summary store for weak-areas feature
  static void add(Map<String, dynamic> attempt) {
    final list = loadAll();
    list.insert(0, attempt);
    _box.write(_k, jsonEncode(list.take(_max).toList()));
  }

  static List<Map<String, dynamic>> loadAll() {
    final raw = _box.read(_k);
    if (raw == null) return [];
    final arr = jsonDecode(raw as String) as List;
    return arr.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }
}
