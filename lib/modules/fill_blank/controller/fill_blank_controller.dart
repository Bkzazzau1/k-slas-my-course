import 'package:get/get.dart';

import '../../../data/models/fill_blank_models.dart';
import '../../../data/services/fill_blank_marker_service.dart';

class FillBlankController extends GetxController {
  final questions = <FillBlankQuestionModel>[].obs;
  final answers = <String, String>{}.obs;

  void load(List<FillBlankQuestionModel> qs) {
    questions.assignAll(qs);
    answers.clear();
  }

  void setAnswer(String qid, String value) {
    answers[qid] = value;
  }

  FillBlankResult submit() {
    return FillBlankMarkerService.mark(questions: questions, answers: answers);
  }
}
