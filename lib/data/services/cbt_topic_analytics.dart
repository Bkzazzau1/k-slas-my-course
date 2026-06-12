import '../models/cbt_models.dart';

/// Builds per-topic correctness stats from a CBT session.
class CbtTopicAnalytics {
  static Map<String, Map<String, int>> build({
    required List<CBTQuestionModel> questions,
    required Map<String, int> selectedIndexByQuestionId, // qid -> chosen option index
  }) {
    final Map<String, Map<String, int>> out = {};

    void ensureTopic(String topic) {
      out.putIfAbsent(topic, () => {
            "total": 0,
            "correct": 0,
            "wrong": 0,
            // optional score convenience
            "scorePct": 0,
          });
    }

    for (final q in questions) {
      final topic = (q.topic.trim().isEmpty) ? "Unknown Topic" : q.topic.trim();
      ensureTopic(topic);

      final chosen = selectedIndexByQuestionId[q.id];
      final isCorrect = chosen != null && chosen == q.correctIndex;

      out[topic]!["total"] = (out[topic]!["total"] ?? 0) + 1;
      if (isCorrect) {
        out[topic]!["correct"] = (out[topic]!["correct"] ?? 0) + 1;
      } else {
        out[topic]!["wrong"] = (out[topic]!["wrong"] ?? 0) + 1;
      }
    }

    // compute scorePct per topic
    out.forEach((topic, m) {
      final total = m["total"] ?? 0;
      final correct = m["correct"] ?? 0;
      final pct = total == 0 ? 0 : ((correct / total) * 100).round();
      m["scorePct"] = pct;
    });

    return out;
  }
}
