class WeakTopic {
  WeakTopic({
    required this.courseCode,
    required this.topic,
    required this.score0to100,
    required this.evidenceCount,
    required this.reasons,
    required this.lastUpdatedIso,
  });

  final String courseCode;
  final String topic;

  /// 0 (very weak) -> 100 (strong)
  final int score0to100;

  /// number of evidence items (wrong answers, missing keywords, mistakes)
  final int evidenceCount;

  /// list of human readable reasons
  final List<String> reasons;

  final String lastUpdatedIso;
}

class WeakAreasSummary {
  WeakAreasSummary({required this.courseCode, required this.topics});

  final String courseCode;
  final List<WeakTopic> topics;

  List<WeakTopic> get weakestFirst {
    final list = [...topics];
    list.sort((a, b) => a.score0to100.compareTo(b.score0to100));
    return list;
  }
}
