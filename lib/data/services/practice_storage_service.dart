import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/practice_models.dart';

class PracticeStorageService {
  PracticeStorageService._();
  static final box = GetStorage();

  static String _attemptKey(String courseCode) =>
      "practice.attempts.$courseCode";
  static const String kStreak = "practice.streak";
  static const String kLastStudyDay = "practice.lastStudyDay";

  static List<PracticeAttemptModel> loadAttempts(String courseCode) {
    final raw = box.read(_attemptKey(courseCode));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAttempt(
    PracticeAttemptModel a, {
    int maxKeep = 20,
  }) async {
    final items = loadAttempts(a.courseCode);
    items.insert(0, a); // newest first
    final trimmed = items.take(maxKeep).toList();

    final raw = jsonEncode(trimmed.map(_toJson).toList());
    await box.write(_attemptKey(a.courseCode), raw);
  }

  static int loadStreak() => box.read(kStreak) ?? 0;
  static Future<void> setStreak(int v) => box.write(kStreak, v);

  static String? loadLastStudyDay() => box.read(kLastStudyDay);
  static Future<void> setLastStudyDay(String day) =>
      box.write(kLastStudyDay, day);

  // ---- json helpers ----
  static Map<String, dynamic> _toJson(PracticeAttemptModel a) => {
    "courseCode": a.courseCode,
    "mode": a.mode,
    "total": a.total,
    "correct": a.correct,
    "durationSec": a.durationSec,
    "createdAt": a.createdAt.toIso8601String(),
    "topicLabel": a.topicLabel,
  };

  static PracticeAttemptModel _fromJson(Map<String, dynamic> m) =>
      PracticeAttemptModel(
        courseCode: m["courseCode"] ?? "",
        mode: m["mode"] ?? "Timed",
        total: m["total"] ?? 0,
        correct: m["correct"] ?? 0,
        durationSec: m["durationSec"] ?? 0,
        createdAt: DateTime.tryParse(m["createdAt"] ?? "") ?? DateTime.now(),
        topicLabel: m["topicLabel"] ?? "Mixed",
      );
}
