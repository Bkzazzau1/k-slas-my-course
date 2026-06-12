class TheoryQuestionModel {
  TheoryQuestionModel({
    required this.id,
    required this.courseCode,
    required this.topic,
    required this.question,
    required this.marks,
    required this.sourceRef, // "Lecture 3 p7"
    required this.expectedKeywords, // derived from lecturer notes
  });

  final String id;
  final String courseCode;
  final String topic;
  final String question;
  final int marks;
  final String sourceRef;
  final List<String> expectedKeywords;
}

class KeywordCheck {
  KeywordCheck({required this.keyword, required this.found, this.note});

  final String keyword;
  final bool found;
  final String? note; // why important / context note
}

class TheoryMarkResult {
  TheoryMarkResult({
    required this.totalMarks,
    required this.scoredMarks,
    required this.keywordChecks,
    required this.feedback,
    required this.citations,
  });

  final int totalMarks;
  final int scoredMarks;
  final List<KeywordCheck> keywordChecks;
  final String feedback; // explain deductions based on notes
  final List<String> citations; // lecture references
}
