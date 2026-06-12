class PracticeQuestionModel {
  PracticeQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.topic = "General",
    this.explanation = "",
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String topic;
  final String explanation;
}

class PracticeAttemptModel {
  PracticeAttemptModel({
    required this.courseCode,
    required this.mode,
    required this.total,
    required this.correct,
    required this.durationSec,
    required this.createdAt,
    required this.topicLabel,
  });

  final String courseCode;
  final String mode; // Timed | Untimed | CBT style
  final int total;
  final int correct;
  final int durationSec;
  final DateTime createdAt;
  final String topicLabel;

  int get scorePct => total == 0 ? 0 : ((correct / total) * 100).round();
}
