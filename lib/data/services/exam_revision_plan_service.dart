import '../models/exam_models.dart';
import '../models/revision_models.dart';
import 'exam_insights_service.dart';

class ExamRevisionPlanService {
  static DailyRevisionPlan fromExam(ExamResult res) {
    final insights = ExamInsightsService.analyze(res);

    // If theory missing keywords exist, focus on that
    final focusTopic = insights.missingKeywords.isNotEmpty
        ? "Theory keywords"
        : "Mixed practice";

    final tasks = <RevisionTask>[
      RevisionTask(
        title: insights.missingKeywords.isNotEmpty
            ? "Revise missing keywords (lecturer notes)"
            : "Revise weak areas summary",
        minutes: 20,
        type: "REVISION",
        meta: {"missingKeywords": insights.missingKeywords},
      ),
      RevisionTask(
        title: "Practice: mixed set (10 questions)",
        minutes: 20,
        type: "PRACTICE",
        meta: {"topic": "Mixed", "questions": 10},
      ),
      RevisionTask(
        title: "Rewrite 1 theory answer using keywords",
        minutes: 15,
        type: "THEORY_REWRITE",
        meta: {"keywords": insights.missingKeywords.take(10).toList()},
      ),
    ];

    return DailyRevisionPlan(
      courseCode: res.courseCode,
      focusTopic: focusTopic,
      reason: "Generated from your last exam report (${res.pct}%).",
      tasks: tasks,
    );
  }
}
