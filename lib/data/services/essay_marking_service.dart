// lib/data/services/essay_marking_service.dart

import 'dart:math';

import 'package:my_courses/data/models/theory_models.dart';

/// Uses your existing models:
/// - TheoryQuestionModel
/// - KeywordCheck
/// - TheoryMarkResult
///
/// This service is deterministic (keyword-based) and testable now.
/// Later, we can add AI-based rubric feedback without changing return types.
class EssayMarkingService {
  /// Mark an essay/theory answer.
  ///
  /// Keyword logic:
  /// - Each expected keyword contributes equally to score.
  /// - If no keywords exist, we fall back to length/structure heuristic (very conservative).
  ///
  /// lecturerNotes is optional for now; we mainly rely on expectedKeywords in the question model.
  Future<TheoryMarkResult> markTheoryAnswer({
    required TheoryQuestionModel question,
    required String studentAnswer,
    String? lecturerNotes,
  }) async {
    final total = max(0, question.marks);
    final answer = studentAnswer.trim();

    // If empty answer
    if (answer.isEmpty) {
      return TheoryMarkResult(
        totalMarks: total,
        scoredMarks: 0,
        keywordChecks: question.expectedKeywords
            .map(
              (k) =>
                  KeywordCheck(keyword: k, found: false, note: _keywordNote(k)),
            )
            .toList(),
        feedback:
            "No answer submitted. You scored 0/$total. Write a direct definition first, then explain with 1–2 examples.",
        citations: _citationsFrom(question),
      );
    }

    final expected = question.expectedKeywords;

    // If no keywords provided, do conservative heuristic grading.
    if (expected.isEmpty) {
      final heuristicScore = _heuristicScore(answer, total);
      return TheoryMarkResult(
        totalMarks: total,
        scoredMarks: heuristicScore,
        keywordChecks: const [],
        feedback: _heuristicFeedback(answer, total, heuristicScore),
        citations: _citationsFrom(question),
      );
    }

    final normAnswer = _norm(answer);

    // Keyword checks
    final checks = <KeywordCheck>[];
    int foundCount = 0;

    for (final kw in expected) {
      final found = _containsKeyword(normAnswer, kw);
      if (found) foundCount++;

      checks.add(
        KeywordCheck(keyword: kw, found: found, note: _keywordNote(kw)),
      );
    }

    // Score: proportional to keywords found
    // Example: marks=10, keywords=8, found=6 => 10*(6/8)=7.5 => round
    final ratio = expected.isEmpty ? 0.0 : (foundCount / expected.length);
    final raw = total * ratio;

    // We round to nearest int but keep bounds safe.
    int scored = raw.round();
    scored = scored.clamp(0, total);

    final missing = checks
        .where((c) => !c.found)
        .map((c) => c.keyword)
        .toList();
    final matched = checks.where((c) => c.found).map((c) => c.keyword).toList();

    final feedback = _buildFeedback(
      question: question,
      scored: scored,
      total: total,
      matched: matched,
      missing: missing,
      studentAnswer: answer,
      lecturerNotes: lecturerNotes,
    );

    return TheoryMarkResult(
      totalMarks: total,
      scoredMarks: scored,
      keywordChecks: checks,
      feedback: feedback,
      citations: _citationsFrom(question),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Feedback builders
  // ─────────────────────────────────────────────────────────────

  String _buildFeedback({
    required TheoryQuestionModel question,
    required int scored,
    required int total,
    required List<String> matched,
    required List<String> missing,
    required String studentAnswer,
    String? lecturerNotes,
  }) {
    final buf = StringBuffer();

    buf.writeln("Score: $scored/$total");
    buf.writeln("");

    if (matched.isNotEmpty) {
      buf.writeln("✅ You included important keywords:");
      buf.writeln(
        "- ${matched.take(8).join(", ")}${matched.length > 8 ? "..." : ""}",
      );
      buf.writeln("");
    }

    if (missing.isNotEmpty) {
      buf.writeln("❌ Missing keywords (these usually carry marks):");
      buf.writeln(
        "- ${missing.take(10).join(", ")}${missing.length > 10 ? "..." : ""}",
      );
      buf.writeln("");
    }

    // Explain why keywords matter (your required feature)
    buf.writeln("Why keywords matter:");
    buf.writeln(
      "Lecturers often award marks when specific concepts appear in your answer. "
      "Keywords act like proof that you covered the marking guide points. "
      "Long writing without the expected terms may still lose marks.",
    );
    buf.writeln("");

    // Actionable correction steps
    buf.writeln("How to improve this answer:");
    buf.writeln("1) Start with a clear definition (1–2 lines).");
    buf.writeln("2) Explain the main idea in 2–4 bullet points.");
    buf.writeln("3) Add one relevant example.");
    if (missing.isNotEmpty) {
      buf.writeln("4) Include and explain: ${missing.take(6).join(", ")}.");
    }

    // Optional: use lecturer notes later for deeper corrections
    if (lecturerNotes != null && lecturerNotes.trim().isNotEmpty) {
      buf.writeln("");
      buf.writeln("Lecturer notes hint:");
      buf.writeln(
        "Use the lecturer notes to structure your answer. If the notes have headings, follow the same headings in your response.",
      );
    }

    // Citation
    buf.writeln("");
    buf.writeln("Source: ${question.sourceRef}");

    return buf.toString().trim();
  }

  // ─────────────────────────────────────────────────────────────
  // Keyword matching
  // ─────────────────────────────────────────────────────────────

  String _norm(String s) {
    final lower = s.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return " ${cleaned.replaceAll(RegExp(r'\s+'), ' ').trim()} ";
  }

  bool _containsKeyword(String normAnswer, String keyword) {
    final kw = _norm(keyword).trim();
    if (kw.isEmpty) return false;

    // Use regular expressions for robust word boundary matching.
    // This handles punctuation and line breaks much better than hardcoded strings.
    final regex = RegExp(
      r'\b' + RegExp.escape(kw) + r'\b',
      caseSensitive: false,
    );
    return regex.hasMatch(normAnswer);
  }

  String? _keywordNote(String keyword) {
    // MVP: generic note. Later we can store per-keyword notes from lecturer notes.
    return "Include this concept because it is part of the lecturer marking guide.";
  }

  List<String> _citationsFrom(TheoryQuestionModel q) {
    final ref = q.sourceRef.trim();
    if (ref.isEmpty) return const [];
    return [ref];
  }

  // ─────────────────────────────────────────────────────────────
  // Heuristic fallback when keywords are missing
  // ─────────────────────────────────────────────────────────────

  int _heuristicScore(String answer, int total) {
    // Conservative: we can't confidently grade without keywords/notes.
    // We give small marks for effort + structure only.
    final len = answer.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    double part = 0.0;
    if (len >= 20) part += 0.2;
    if (len >= 50) part += 0.2;
    if (_hasDefinitionStyle(answer)) part += 0.2;
    if (_hasExamples(answer)) part += 0.2;

    // cap at 60% when no keywords exist
    part = min(part, 0.6);

    return (total * part).round().clamp(0, total);
  }

  bool _hasDefinitionStyle(String a) {
    final t = a.toLowerCase();
    return t.contains("is defined as") ||
        t.contains("means") ||
        t.contains("refers to");
  }

  bool _hasExamples(String a) {
    final t = a.toLowerCase();
    return t.contains("example") ||
        t.contains("e.g") ||
        t.contains("for instance");
  }

  String _heuristicFeedback(String answer, int total, int scored) {
    return [
      "Score: $scored/$total",
      "",
      "This question has no expected keywords configured, so marking was conservative.",
      "To improve scoring accuracy, attach lecturer keywords/notes to this question.",
      "",
      "How to improve:",
      "1) Start with a definition (\"X refers to...\")",
      "2) Add 3 key points",
      "3) Add 1 example",
    ].join("\n");
  }
}
