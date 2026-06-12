import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/theory_models.dart';
import '../../../data/services/theory_marker_service.dart';

class TheoryController extends GetxController {
  final question = Rxn<TheoryQuestionModel>();
  final answerCtrl = TextEditingController();

  final isMarking = false.obs;
  final result = Rxn<TheoryMarkResult>();

  void loadQuestion(TheoryQuestionModel q) {
    question.value = q;
    result.value = null;
    answerCtrl.text = "";
  }

  Future<void> markNow() async {
    final q = question.value;
    if (q == null) return;

    final ans = answerCtrl.text.trim();
    if (ans.length < 20) {
      Get.snackbar(
        "Too short",
        "Write at least 2–3 lines before marking.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isMarking.value = true;
    try {
      final r = await TheoryMarkerService.mark(q: q, studentAnswer: ans);
      result.value = r;
    } finally {
      isMarking.value = false;
    }
  }

  @override
  void onClose() {
    answerCtrl.dispose();
    super.onClose();
  }
}
