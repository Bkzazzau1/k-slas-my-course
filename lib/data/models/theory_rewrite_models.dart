class TheoryRewritePrompt {
  TheoryRewritePrompt({
    required this.courseCode,
    required this.topic,
    required this.question,
    required this.sourceRef,
    required this.requiredKeywords,
    this.originalAnswer,
    this.originalScore,
    this.originalTotal,
  });

  final String courseCode;
  final String topic;
  final String question;
  final String sourceRef;
  final List<String> requiredKeywords;

  // from exam (optional)
  final String? originalAnswer;
  final int? originalScore;
  final int? originalTotal;
}

class TheoryRewriteAttempt {
  TheoryRewriteAttempt({
    required this.id,
    required this.courseCode,
    required this.topic,
    required this.question,
    required this.sourceRef,
    required this.requiredKeywords,
    required this.beforeAnswer,
    required this.afterAnswer,
    required this.beforeScore,
    required this.afterScore,
    required this.totalMarks,
    required this.createdAtIso,
  });

  final String id;
  final String courseCode;
  final String topic;
  final String question;
  final String sourceRef;
  final List<String> requiredKeywords;

  final String beforeAnswer;
  final String afterAnswer;

  final int beforeScore;
  final int afterScore;
  final int totalMarks;

  final String createdAtIso;
}
