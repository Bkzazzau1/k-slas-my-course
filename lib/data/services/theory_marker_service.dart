import '../models/theory_models.dart';
import 'essay_marking_service.dart';

class TheoryMarkerService {
  static final EssayMarkingService _essayService = EssayMarkingService();

  /// Unified marker path for theory/essay answers in K-SLAS.
  /// Delegates to EssayMarkingService so graded workflows share one rubric engine.
  static Future<TheoryMarkResult> mark({
    required TheoryQuestionModel q,
    required String studentAnswer,
  }) async {
    return _essayService.markTheoryAnswer(
      question: q,
      studentAnswer: studentAnswer,
    );
  }
}
