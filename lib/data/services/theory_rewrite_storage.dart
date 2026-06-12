import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/theory_rewrite_models.dart';

class TheoryRewriteStorage {
  static final _box = GetStorage();
  static const _k = "theory_rewrite_attempts";
  static const _max = 30;

  static List<TheoryRewriteAttempt> loadAll() {
    final raw = _box.read(_k);
    if (raw == null) return [];
    final list = jsonDecode(raw as String) as List;
    return list.map((x) {
      final m = x as Map<String, dynamic>;
      return TheoryRewriteAttempt(
        id: m["id"],
        courseCode: m["courseCode"],
        topic: m["topic"],
        question: m["question"],
        sourceRef: m["sourceRef"],
        requiredKeywords: (m["requiredKeywords"] as List)
            .map((e) => e.toString())
            .toList(),
        beforeAnswer: m["beforeAnswer"],
        afterAnswer: m["afterAnswer"],
        beforeScore: m["beforeScore"],
        afterScore: m["afterScore"],
        totalMarks: m["totalMarks"],
        createdAtIso: m["createdAtIso"],
      );
    }).toList();
  }

  static void add(TheoryRewriteAttempt a) {
    final items = loadAll();
    items.insert(0, a);
    final trimmed = items.take(_max).toList();

    _box.write(
      _k,
      jsonEncode(
        trimmed
            .map(
              (t) => {
                "id": t.id,
                "courseCode": t.courseCode,
                "topic": t.topic,
                "question": t.question,
                "sourceRef": t.sourceRef,
                "requiredKeywords": t.requiredKeywords,
                "beforeAnswer": t.beforeAnswer,
                "afterAnswer": t.afterAnswer,
                "beforeScore": t.beforeScore,
                "afterScore": t.afterScore,
                "totalMarks": t.totalMarks,
                "createdAtIso": t.createdAtIso,
              },
            )
            .toList(),
      ),
    );
  }

  static void clear() => _box.remove(_k);
}
