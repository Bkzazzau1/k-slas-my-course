import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/revision_models.dart';

class RevisionPlanStorage {
  static final _box = GetStorage();
  static const _k = "daily_revision_plan";

  static void save(DailyRevisionPlan p) {
    _box.write(
      _k,
      jsonEncode({
        "courseCode": p.courseCode,
        "focusTopic": p.focusTopic,
        "reason": p.reason,
        "tasks": p.tasks
            .map(
              (t) => {
                "title": t.title,
                "minutes": t.minutes,
                "type": t.type,
                "meta": t.meta,
              },
            )
            .toList(),
      }),
    );
  }

  static DailyRevisionPlan? load() {
    final raw = _box.read(_k);
    if (raw == null) return null;

    final m = jsonDecode(raw as String) as Map<String, dynamic>;
    return DailyRevisionPlan(
      courseCode: m["courseCode"] as String,
      focusTopic: m["focusTopic"] as String,
      reason: m["reason"] as String,
      tasks: (m["tasks"] as List).map((x) {
        final t = x as Map<String, dynamic>;
        return RevisionTask(
          title: t["title"] as String,
          minutes: t["minutes"] as int,
          type: t["type"] as String,
          meta: (t["meta"] as Map?)?.cast<String, dynamic>() ?? {},
        );
      }).toList(),
    );
  }
}
