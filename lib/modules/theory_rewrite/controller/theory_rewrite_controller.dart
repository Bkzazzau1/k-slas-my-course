import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/theory_models.dart';
import '../../../data/models/theory_rewrite_models.dart';
import '../../../data/services/theory_marker_service.dart';
import '../../../data/services/theory_rewrite_storage.dart';

class TheoryRewriteController extends GetxController {
  final prompt = Rxn<TheoryRewritePrompt>();

  final beforeCtrl = TextEditingController();
  final afterCtrl = TextEditingController();

  final isMarking = false.obs;

  final beforeResult = Rxn<TheoryMarkResult>();
  final afterResult = Rxn<TheoryMarkResult>();

  void loadPrompt(TheoryRewritePrompt p) {
    prompt.value = p;

    // If exam gave original answer, preload it as BEFORE.
    beforeCtrl.text = (p.originalAnswer ?? "").trim();
    afterCtrl.text = "";

    beforeResult.value = null;
    afterResult.value = null;

    // If we have original score, show it without marking
    if (p.originalScore != null && p.originalTotal != null) {
      beforeResult.value = TheoryMarkResult(
        totalMarks: p.originalTotal!,
        scoredMarks: p.originalScore!,
        keywordChecks: p.requiredKeywords
            .map((k) => KeywordCheck(keyword: k, found: false))
            .toList(),
        feedback:
            "This is your exam result baseline. Now rewrite using lecturer keywords.",
        citations: [p.sourceRef],
      );
    }
  }

  Future<void> markRewrite() async {
    final p = prompt.value;
    if (p == null) return;

    final before = beforeCtrl.text.trim();
    final after = afterCtrl.text.trim();

    if (after.length < 20) {
      Get.snackbar(
        "Too short",
        "Rewrite at least 2–3 lines with lecturer keywords.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isMarking.value = true;
    try {
      // Build a marker question from prompt keywords
      final q = TheoryQuestionModel(
        id: "rewrite",
        courseCode: p.courseCode,
        topic: p.topic,
        question: p.question,
        marks: 10,
        sourceRef: p.sourceRef,
        expectedKeywords: p.requiredKeywords,
      );

      // If before not already marked, mark it now (unless baseline from exam exists)
      if (beforeResult.value == null) {
        final br = await TheoryMarkerService.mark(q: q, studentAnswer: before);
        beforeResult.value = br;
      }

      final ar = await TheoryMarkerService.mark(q: q, studentAnswer: after);
      afterResult.value = ar;

      // Save attempt
      final b = beforeResult.value!;
      final a = afterResult.value!;

      TheoryRewriteStorage.add(
        TheoryRewriteAttempt(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          courseCode: p.courseCode,
          topic: p.topic,
          question: p.question,
          sourceRef: p.sourceRef,
          requiredKeywords: p.requiredKeywords,
          beforeAnswer: before,
          afterAnswer: after,
          beforeScore: b.scoredMarks,
          afterScore: a.scoredMarks,
          totalMarks: a.totalMarks,
          createdAtIso: DateTime.now().toIso8601String(),
        ),
      );
    } finally {
      isMarking.value = false;
    }
  }

  @override
  void onClose() {
    beforeCtrl.dispose();
    afterCtrl.dispose();
    super.onClose();
  }
}
