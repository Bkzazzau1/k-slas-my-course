class FillBlankQuestionModel {
  FillBlankQuestionModel({
    required this.id,
    required this.courseCode,
    required this.topic,
    required this.prompt,
    required this.marks,
    required this.sourceRef,
    required this.expectedKeywords, // accepted answers (from lecturer notes)
  });

  final String id;
  final String courseCode;
  final String topic;
  final String prompt;
  final int marks;
  final String sourceRef;
  final List<String> expectedKeywords;
}

class FillBlankResult {
  FillBlankResult({
    required this.totalMarks,
    required this.scoredMarks,
    required this.details,
  });

  final int totalMarks;
  final int scoredMarks;

  /// list of per-question: prompt, expected, student, correct?
  final List<Map<String, dynamic>> details;
}
