import 'multi_format_exam_models.dart';

class ExamSectionType {
  static const String objective = "OBJECTIVE";
  static const String fillBlank = "FILL_BLANK";
  static const String theory = "THEORY";
}

class SessionType {
  static const String assessment = "ASSESSMENT";
  static const String examination = "EXAMINATION";
}

class GradingType {
  static const String graded = "GRADED";
  static const String ungraded = "UNGRADED";
}

class QuestionSourceType {
  static const String lecturerAdmin = "LECTURER_ADMIN";
  static const String studentLocal = "STUDENT_LOCAL";
}

class ExamMode {
  static const String practice = "PRACTICE";
  static const String simulation = "SIMULATION";
}

enum ExamDeliveryMode { centerBased, remoteProctored }

extension ExamDeliveryModeX on ExamDeliveryMode {
  String get raw {
    switch (this) {
      case ExamDeliveryMode.centerBased:
        return 'center';
      case ExamDeliveryMode.remoteProctored:
        return 'remote';
    }
  }

  String get label {
    switch (this) {
      case ExamDeliveryMode.centerBased:
        return 'Normal / No Proctoring';
      case ExamDeliveryMode.remoteProctored:
        return 'Remote (Proctored)';
    }
  }

  static ExamDeliveryMode fromRaw(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'remote':
      case 'remoteproctored':
      case 'remote_proctored':
        return ExamDeliveryMode.remoteProctored;
      case 'center':
      case 'centerbased':
      case 'center_based':
      case 'normal':
      case 'ungraded':
      default:
        return ExamDeliveryMode.centerBased;
    }
  }
}

class ExamConfig {
  ExamConfig({
    required this.courseCode,
    required this.sessionType,
    required this.gradingType,
    required this.mode,
    required this.topic,
    required this.sections,
    required this.objectiveQuestions,
    required this.fillBlankQuestions,
    required this.theoryQuestions,
    required this.durationMinutes,
    required this.deliveryMode,
    this.questionSource = QuestionSourceType.studentLocal,
    this.whiteboardEnabled = false,
    this.whiteboardRequired = false,
    this.whiteboardPrompt,
    this.enabledFormats = const [],
    this.securityPolicy = const ExamSecurityPolicy(),
  });

  final String courseCode;
  final String sessionType; // ASSESSMENT / EXAMINATION
  final String gradingType; // GRADED / UNGRADED
  final String mode; // PRACTICE / SIMULATION
  final String topic; // Mixed / Trees / WeakOnly etc.
  final List<String> sections; // section types
  final int objectiveQuestions;
  final int fillBlankQuestions;
  final int theoryQuestions;
  final int durationMinutes;
  final ExamDeliveryMode deliveryMode;
  final String questionSource; // LECTURER_ADMIN / STUDENT_LOCAL
  final bool whiteboardEnabled;
  final bool whiteboardRequired;
  final String? whiteboardPrompt;
  final List<MultiFormatQuestionType> enabledFormats;
  final ExamSecurityPolicy securityPolicy;

  bool get isGraded => gradingType == GradingType.graded;
  bool get isRemoteProctored =>
      isGraded && deliveryMode == ExamDeliveryMode.remoteProctored;
  bool get isCenterBased => deliveryMode == ExamDeliveryMode.centerBased;
  bool get requiresWhiteboard =>
      isGraded && whiteboardEnabled && whiteboardRequired;
}

class ExamSectionScore {
  ExamSectionScore({
    required this.sectionType,
    required this.totalMarks,
    required this.scoredMarks,
    this.extra = const {},
  });

  final String sectionType;
  final int totalMarks;
  final int scoredMarks;

  /// extra: keyword counts, missing keywords, attempt ids, etc.
  final Map<String, dynamic> extra;
}

class ExamResult {
  ExamResult({
    required this.courseCode,
    required this.sessionType,
    required this.gradingType,
    required this.startedAt,
    required this.endedAt,
    required this.sectionScores,
    required this.deliveryMode,
    this.whiteboardEnabled = false,
    this.whiteboardRequired = false,
    this.whiteboardSubmitted = false,
    this.whiteboardStrokeCount = 0,
    this.whiteboardPrompt,
  });

  final String courseCode;
  final String sessionType;
  final String gradingType;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<ExamSectionScore> sectionScores;
  final ExamDeliveryMode deliveryMode;
  final bool whiteboardEnabled;
  final bool whiteboardRequired;
  final bool whiteboardSubmitted;
  final int whiteboardStrokeCount;
  final String? whiteboardPrompt;

  int get totalMarks => sectionScores.fold(0, (a, b) => a + b.totalMarks);
  int get scoredMarks => sectionScores.fold(0, (a, b) => a + b.scoredMarks);

  int get pct =>
      totalMarks == 0 ? 0 : ((scoredMarks / totalMarks) * 100).round();
}
