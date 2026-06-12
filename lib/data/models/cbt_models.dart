import 'exam_models.dart';

class CBTQuestionModel {
  CBTQuestionModel({
    required this.id,
    required this.courseCode,
    required this.topic,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.sourceLabel, // e.g. "ABU CSC305 2019 Q4"
  });

  final String id;
  final String courseCode;
  final String topic;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String? sourceLabel;
}

class CBTAttemptModel {
  CBTAttemptModel({
    required this.id,
    required this.courseCode,
    this.sessionType = "ASSESSMENT", // ASSESSMENT / EXAMINATION
    this.gradingType = "UNGRADED", // GRADED / UNGRADED
    required this.mode, // Timed, Untimed, CBT style
    required this.totalQuestions,
    required this.correct,
    required this.startedAt,
    required this.endedAt,
    required this.topic,
    required this.durationMinutes,
    this.topicStats, // topic -> {"correct": int, "wrong": int, "total": int, "scorePct": int}
    this.whiteboardEnabled = false,
    this.whiteboardRequired = false,
    this.whiteboardStrokeCount = 0,
    this.whiteboardPrompt,
    this.deliveryMode = ExamDeliveryMode.remoteProctored,
  });

  final String id;
  final String courseCode;
  final String sessionType;
  final String gradingType;
  final String mode;
  final int totalQuestions;
  final int correct;
  final DateTime startedAt;
  final DateTime endedAt;
  final String topic;
  final int durationMinutes;
  final Map<String, Map<String, int>>? topicStats;
  final bool whiteboardEnabled;
  final bool whiteboardRequired;
  final int whiteboardStrokeCount;
  final String? whiteboardPrompt;
  final ExamDeliveryMode deliveryMode;

  int get scorePct =>
      totalQuestions == 0 ? 0 : ((correct / totalQuestions) * 100).round();

  bool get whiteboardSubmitted => whiteboardStrokeCount > 0;
  bool get isRemoteProctored =>
      deliveryMode == ExamDeliveryMode.remoteProctored;
}
