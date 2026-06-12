import 'dart:math';

import '../models/cbt_models.dart';
import '../models/weak_area_models.dart';
import 'cbt_attempt_storage.dart';
import 'theory_rewrite_storage.dart';

class WeakAreasService {
  /// Build weak topics for a course from local evidence
  static WeakAreasSummary compute({required String courseCode}) {
    final nowIso = DateTime.now().toIso8601String();

    final cbtAttempts = CBTAttemptStorage.loadAttempts(courseCode);
    final cbtSummary = WeakAreasFromCbt.build(
      courseCode: courseCode,
      attempts: cbtAttempts,
      lastNAttempts: 5,
    );

    final topics = <WeakTopic>[...cbtSummary.topics];
    topics.addAll(_theoryTopics(courseCode: courseCode, nowIso: nowIso));

    // If no evidence, give default
    if (topics.isEmpty) {
      topics.add(
        WeakTopic(
          courseCode: courseCode,
          topic: "Mixed",
          score0to100: 70,
          evidenceCount: 0,
          reasons: const [
            "No attempts yet. Take a CBT or Exam to generate weak areas.",
          ],
          lastUpdatedIso: nowIso,
        ),
      );
    }

    return WeakAreasSummary(courseCode: courseCode, topics: topics);
  }
}

class WeakAreasFromCbt {
  static WeakAreasSummary build({
    required String courseCode,
    required List<CBTAttemptModel> attempts,
    int lastNAttempts = 5,
  }) {
    // Only attempts that have topicStats
    final usable = attempts
        .where((a) => a.courseCode == courseCode && a.topicStats != null)
        .toList();

    // take last N by endedAt
    usable.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    final recent = usable.take(lastNAttempts).toList();

    // topic -> list of pct
    final Map<String, List<int>> scores = {};
    final Map<String, int> evidence = {};
    final Map<String, int> wrongTotals = {};
    final Map<String, int> totalTotals = {};

    for (final a in recent) {
      final stats = a.topicStats!;
      stats.forEach((topic, m) {
        final pct = m["scorePct"] ?? _pct(m["correct"] ?? 0, m["total"] ?? 0);

        scores.putIfAbsent(topic, () => []).add(pct);
        evidence[topic] = (evidence[topic] ?? 0) + 1;

        wrongTotals[topic] = (wrongTotals[topic] ?? 0) + (m["wrong"] ?? 0);
        totalTotals[topic] = (totalTotals[topic] ?? 0) + (m["total"] ?? 0);
      });
    }

    final topics = <WeakTopic>[];

    scores.forEach((topic, pctList) {
      final avg =
          (pctList.reduce((a, b) => a + b) / pctList.length).round();
      final ev = evidence[topic] ?? 0;
      final wrong = wrongTotals[topic] ?? 0;
      final total = totalTotals[topic] ?? 0;

      final reasons = <String>[
        "Avg topic score: $avg% across $ev attempt(s)",
        if (total > 0) "Wrong answers: $wrong / $total in recent CBTs",
      ];

      topics.add(
        WeakTopic(
          courseCode: courseCode,
          topic: topic,
          score0to100: avg,
          evidenceCount: ev,
          reasons: reasons,
          lastUpdatedIso: DateTime.now().toIso8601String(),
        ),
      );
    });

    return WeakAreasSummary(courseCode: courseCode, topics: topics);
  }

  static int _pct(int correct, int total) =>
      total == 0 ? 0 : ((correct / total) * 100).round();
}

List<WeakTopic> _theoryTopics({
  required String courseCode,
  required String nowIso,
}) {
  // --- Theory rewrite attempts (missing keywords & low scores) ---
  final rewrites = TheoryRewriteStorage.loadAll()
      .where((x) => x.courseCode == courseCode)
      .toList();

  if (rewrites.isEmpty) return const [];

  final List<WeakTopic> topics = [];
  for (final r in rewrites.take(30)) {
    final diff = r.afterScore - r.beforeScore;
    final reasons = <String>[];
    int evidence = 0;

    if (r.beforeScore < (r.totalMarks * 0.6).round()) {
      reasons.add(
        "Low theory score before rewrite (${r.beforeScore}/${r.totalMarks})",
      );
      evidence++;
    }
    if (diff > 0) {
      reasons.add("Rewrite improved by +$diff marks (needs repetition)");
      evidence++;
    }
    final kwCount = min(6, r.requiredKeywords.length);
    reasons.add("Missing/required keywords practice ($kwCount keywords)");
    evidence++;

    topics.add(
      WeakTopic(
        courseCode: r.courseCode,
        topic: r.topic,
        score0to100: max(10, 100 - (evidence * 10)),
        evidenceCount: evidence,
        reasons: reasons,
        lastUpdatedIso: nowIso,
      ),
    );
  }

  return topics;
}
