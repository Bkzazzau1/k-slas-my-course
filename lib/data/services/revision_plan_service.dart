import '../models/revision_models.dart';
import 'weak_topics_service.dart';

class RevisionPlanService {
  static DailyRevisionPlan buildPlan(String courseCode) {
    final weak = WeakTopicsService.computeWeakTopics(courseCode);

    // If no data, give a neutral plan
    if (weak.isEmpty) {
      return DailyRevisionPlan(
        courseCode: courseCode,
        focusTopic: "Mixed",
        reason:
            "No CBT history yet — start with a mixed set to detect weak areas.",
        tasks: [
          RevisionTask(
            title: "Quick review: last lecture summary",
            minutes: 15,
            type: "REVISION",
          ),
          RevisionTask(
            title: "Practice: Mixed (10 questions)",
            minutes: 15,
            type: "PRACTICE",
            meta: {"topic": "Mixed", "questions": 10},
          ),
          RevisionTask(
            title: "Flashcards: key definitions",
            minutes: 10,
            type: "FLASHCARDS",
          ),
        ],
      );
    }

    final focus = weak.first;
    final topic = focus.topic;

    // Simple plan: revise + practice + flashcards
    return DailyRevisionPlan(
      courseCode: courseCode,
      focusTopic: topic,
      reason: "Weak area detected: $topic (${focus.accuracyPct}% accuracy).",
      tasks: [
        RevisionTask(
          title: "Revise: $topic (course pack)",
          minutes: 20,
          type: "REVISION",
          meta: {"topic": topic},
        ),
        RevisionTask(
          title: "Practice: $topic (15 questions)",
          minutes: 20,
          type: "PRACTICE",
          meta: {"topic": topic, "questions": 15},
        ),
        RevisionTask(
          title: "Flashcards: $topic key points",
          minutes: 10,
          type: "FLASHCARDS",
          meta: {"topic": topic},
        ),
      ],
    );
  }
}
