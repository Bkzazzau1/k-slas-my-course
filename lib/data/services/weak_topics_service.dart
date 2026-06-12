import 'cbt_attempt_storage.dart';

class WeakTopic {
  WeakTopic({
    required this.topic,
    required this.accuracyPct,
    required this.totalQuestions,
    required this.evidenceCount,
  });

  final String topic;
  final int accuracyPct; // 0-100
  final int totalQuestions; // total questions contributing to this topic
  final int evidenceCount; // number of attempts where topic appeared
}

class WeakTopicsService {
  /// Returns topics sorted weakest -> strongest
  /// - Uses per-topic scorePct if present, else computes from correct/total
  /// - Weighted by number of questions per topic
  /// - Considers last [lastNAttempts] attempts
  static List<WeakTopic> computeWeakTopics(
    String courseCode, {
    int lastNAttempts = 5,
    int minEvidenceCount = 2,
    bool includeUnknownTopic = false,
  }) {
    final attempts = CBTAttemptStorage.loadAttempts(courseCode);

    if (attempts.isEmpty) return [];

    // ensure newest first (storage already inserts at 0, but keep safe)
    final list = [...attempts]..sort((a, b) => b.endedAt.compareTo(a.endedAt));
    final recent = list.take(lastNAttempts).toList();

    final Map<String, int> total = {};
    final Map<String, int> correct = {};
    final Map<String, int> evidence = {};

    for (final a in recent) {
      final ts = a.topicStats;

      // If older attempt without topicStats, ignore "Mixed" bucket
      if (ts == null || ts.isEmpty) {
        final bucket = a.topic.trim();
        if (bucket.isEmpty || bucket == "Mixed") continue;
        if (!includeUnknownTopic && bucket == "Unknown Topic") continue;

        total[bucket] = (total[bucket] ?? 0) + a.totalQuestions;
        correct[bucket] = (correct[bucket] ?? 0) + a.correct;
        evidence[bucket] = (evidence[bucket] ?? 0) + 1;
        continue;
      }

      // Count evidence per attempt per topic (avoid double counting within same attempt)
      final seenInAttempt = <String>{};

      ts.forEach((topicRaw, m) {
        final topic = topicRaw.trim().isEmpty ? "Unknown Topic" : topicRaw.trim();
        if (!includeUnknownTopic && topic == "Unknown Topic") return;

        final t = m["total"] ?? 0;
        final c = m["correct"] ?? 0;

        if (t <= 0) return;

        total[topic] = (total[topic] ?? 0) + t;
        correct[topic] = (correct[topic] ?? 0) + c;

        if (!seenInAttempt.contains(topic)) {
          evidence[topic] = (evidence[topic] ?? 0) + 1;
          seenInAttempt.add(topic);
        }
      });
    }

    final out = <WeakTopic>[];
    for (final topic in total.keys) {
      final t = total[topic] ?? 0;
      if (t <= 0) continue;

      final ev = evidence[topic] ?? 0;
      if (ev < minEvidenceCount) continue;

      final c = correct[topic] ?? 0;
      final acc = ((c / t) * 100).round();

      out.add(
        WeakTopic(
          topic: topic,
          accuracyPct: acc,
          totalQuestions: t,
          evidenceCount: ev,
        ),
      );
    }

    out.sort((a, b) => a.accuracyPct.compareTo(b.accuracyPct)); // weak first
    return out;
  }
}
