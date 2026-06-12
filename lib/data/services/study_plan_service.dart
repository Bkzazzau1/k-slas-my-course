import '../models/course_model.dart';

class StudyRecommendation {
  StudyRecommendation({
    required this.title,
    required this.reason,
    required this.tags,
  });

  final String title;
  final String reason;
  final List<String> tags;
}

class StudyPlanService {
  // MVP: weak topics + progress determines recommendation
  static StudyRecommendation recommend({
    required CourseModel course,
    required List<String> weakTopics,
    required int daysToExam,
    required String examMode, // Strict | Balanced | Chill
  }) {
    final topWeak = weakTopics.isNotEmpty ? weakTopics.first : "Revision";
    final urgency = daysToExam <= 3
        ? "High urgency"
        : (daysToExam <= 7 ? "Medium urgency" : "Normal pace");

    final time = examMode == "Strict"
        ? "45 mins"
        : examMode == "Balanced"
        ? "30 mins"
        : "20 mins";

    return StudyRecommendation(
      title: "${course.code}: $topWeak",
      reason: "Based on weak areas + exam in $daysToExam day(s) • $urgency",
      tags: ["Weak area", "Time: $time", "Progress: ${course.progress}%"],
    );
  }
}
