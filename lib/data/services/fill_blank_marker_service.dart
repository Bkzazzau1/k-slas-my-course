import '../models/fill_blank_models.dart';

class FillBlankMarkerService {
  static bool _match(String student, List<String> accepted) {
    final s = student.trim().toLowerCase();
    if (s.isEmpty) return false;

    // strict: only lecturer keywords accepted
    for (final a in accepted) {
      if (s == a.trim().toLowerCase()) return true;
    }
    return false;
  }

  static FillBlankResult mark({
    required List<FillBlankQuestionModel> questions,
    required Map<String, String> answers,
  }) {
    int total = 0;
    int scored = 0;

    final details = <Map<String, dynamic>>[];

    for (final q in questions) {
      total += q.marks;
      final ans = answers[q.id] ?? "";
      final ok = _match(ans, q.expectedKeywords);

      if (ok) scored += q.marks;

      details.add({
        "id": q.id,
        "prompt": q.prompt,
        "student": ans,
        "expected": q.expectedKeywords,
        "correct": ok,
        "sourceRef": q.sourceRef,
      });
    }

    return FillBlankResult(
      totalMarks: total,
      scoredMarks: scored,
      details: details,
    );
  }
}
