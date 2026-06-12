import '../models/exam_models.dart';

class ExamInsights {
  ExamInsights({
    required this.suggestions,
    required this.missingKeywords,
    required this.fillBlankMistakes,
  });

  final List<String> suggestions;
  final List<String> missingKeywords; // flattened missing keywords
  final List<Map<String, dynamic>> fillBlankMistakes; // details rows
}

class ExamInsightsService {
  static ExamInsights analyze(ExamResult res) {
    final missingKeywords = <String>[];
    final fillMistakes = <Map<String, dynamic>>[];
    final suggestions = <String>[];

    for (final s in res.sectionScores) {
      if (s.sectionType == "THEORY") {
        final kw = (s.extra["keywords"] as List?) ?? [];
        for (final item in kw) {
          if (item is Map && item["found"] == false) {
            final k = item["k"]?.toString();
            if (k != null && k.isNotEmpty) missingKeywords.add(k);
          }
        }
      }

      if (s.sectionType == "FILL_BLANK") {
        final details = (s.extra["details"] as List?) ?? [];
        for (final d in details) {
          if (d is Map && d["correct"] == false) {
            fillMistakes.add(Map<String, dynamic>.from(d));
          }
        }
      }
    }

    if (missingKeywords.isNotEmpty) {
      suggestions.add(
        "Theory marks are keyword-based. Review missing keywords and rewrite your answer using lecturer terms.",
      );
    }
    if (fillMistakes.isNotEmpty) {
      suggestions.add(
        "Fill-blank is strict. Memorize exact lecturer phrasing/keywords (no outside synonyms unless in notes).",
      );
    }
    if (res.pct < 50) {
      suggestions.add(
        "Do Weak Topics mode tomorrow and take a mixed exam after.",
      );
    } else if (res.pct < 75) {
      suggestions.add(
        "You’re close. Focus weak areas + take a mixed exam again.",
      );
    } else {
      suggestions.add(
        "Great. Keep consistency and practice past questions under time.",
      );
    }

    // de-dup keywords
    final uniqKeywords = missingKeywords.toSet().toList()..sort();

    return ExamInsights(
      suggestions: suggestions,
      missingKeywords: uniqKeywords,
      fillBlankMistakes: fillMistakes,
    );
  }
}
