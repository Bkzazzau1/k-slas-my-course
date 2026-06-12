// lib/data/services/essay_marking_service.dart

import 'dart:math';

import 'package:my_courses/data/models/theory_models.dart';

/// Deterministic rubric marker for essay/theory answers.
/// Later, this can be replaced with an AI rubric engine without changing the UI.
class EssayMarkingService {
  Future<TheoryMarkResult> markTheoryAnswer({
    required TheoryQuestionModel question,
    required String studentAnswer,
    String? lecturerNotes,
  }) async {
    final total = max(0, question.marks);
    final answer = studentAnswer.trim();

    if (answer.isEmpty) {
      return TheoryMarkResult(
        totalMarks: total,
        scoredMarks: 0,
        keywordChecks: question.expectedKeywords
            .map(
              (k) => KeywordCheck(keyword: k, found: false, note: _keywordNote(k)),
            )
            .toList(),
        feedback:
            'No answer submitted. You scored 0/$total. Start with a direct answer, then support it with clear points and examples.',
        citations: const [],
      );
    }

    final expected = question.expectedKeywords;

    if (expected.isEmpty) {
      final heuristicScore = _heuristicScore(answer, total);
      return TheoryMarkResult(
        totalMarks: total,
        scoredMarks: heuristicScore,
        keywordChecks: const [],
        feedback: _heuristicFeedback(answer, total, heuristicScore),
        citations: const [],
      );
    }

    final normAnswer = _norm(answer);
    final checks = <KeywordCheck>[];
    int foundCount = 0;

    for (final kw in expected) {
      final found = _containsKeyword(normAnswer, kw);
      if (found) foundCount++;
      checks.add(KeywordCheck(keyword: kw, found: found, note: _keywordNote(kw)));
    }

    final ratio = foundCount / expected.length;
    final scored = (total * ratio).round().clamp(0, total) as int;

    final missing = checks.where((c) => !c.found).map((c) => c.keyword).toList();
    final matched = checks.where((c) => c.found).map((c) => c.keyword).toList();

    return TheoryMarkResult(
      totalMarks: total,
      scoredMarks: scored,
      keywordChecks: checks,
      feedback: _buildFeedback(
        scored: scored,
        total: total,
        matched: matched,
        missing: missing,
      ),
      citations: const [],
    );
  }

  String _buildFeedback({
    required int scored,
    required int total,
    required List<String> matched,
    required List<String> missing,
  }) {
    final buf = StringBuffer();

    buf.writeln('Score: $scored/$total');
    buf.writeln('');

    if (matched.isNotEmpty) {
      buf.writeln('Strong points included:');
      buf.writeln('- ${matched.take(8).join(', ')}${matched.length > 8 ? '...' : ''}');
      buf.writeln('');
    }

    if (missing.isNotEmpty) {
      buf.writeln('Expected points not clearly covered:');
      buf.writeln('- ${missing.take(10).join(', ')}${missing.length > 10 ? '...' : ''}');
      buf.writeln('');
    }

    buf.writeln('How to improve this answer:');
    buf.writeln('1) Start with a clear recommendation or definition.');
    buf.writeln('2) Explain each point briefly and directly.');
    buf.writeln('3) Add one relevant example or use case.');
    if (missing.isNotEmpty) {
      buf.writeln('4) Revise the answer to cover: ${missing.take(6).join(', ')}.');
    }

    return buf.toString().trim();
  }

  String _norm(String s) {
    final lower = s.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return ' ${cleaned.replaceAll(RegExp(r'\s+'), ' ').trim()} ';
  }

  bool _containsKeyword(String normAnswer, String keyword) {
    final kw = _norm(keyword).trim();
    if (kw.isEmpty) return false;
    final regex = RegExp(
      r'\b' + RegExp.escape(kw) + r'\b',
      caseSensitive: false,
    );
    return regex.hasMatch(normAnswer);
  }

  String? _keywordNote(String keyword) {
    return 'This point is part of the expected marking rubric.';
  }

  int _heuristicScore(String answer, int total) {
    final len = answer.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (len >= 180) return (total * 0.60).round();
    if (len >= 100) return (total * 0.45).round();
    if (len >= 50) return (total * 0.30).round();
    return (total * 0.15).round();
  }

  String _heuristicFeedback(String answer, int total, int scored) {
    return [
      'Score: $scored/$total',
      '',
      'The answer was marked using a structure-based fallback because no rubric keywords were configured.',
      'Improve by giving a direct answer, explaining the major points, and adding a relevant example.',
    ].join('\n');
  }
}
