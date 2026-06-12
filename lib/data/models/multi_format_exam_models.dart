enum MultiFormatQuestionType {
  objectiveSingle,
  objectiveMultiple,
  trueFalse,
  fillBlank,
  shortAnswer,
  essay,
  dragDrop,
  whiteboard,
}

extension MultiFormatQuestionTypeX on MultiFormatQuestionType {
  String get raw => name;

  String get label {
    switch (this) {
      case MultiFormatQuestionType.objectiveSingle:
        return 'Objective single';
      case MultiFormatQuestionType.objectiveMultiple:
        return 'Multiple response';
      case MultiFormatQuestionType.trueFalse:
        return 'True / False';
      case MultiFormatQuestionType.fillBlank:
        return 'Fill blank';
      case MultiFormatQuestionType.shortAnswer:
        return 'Short answer';
      case MultiFormatQuestionType.essay:
        return 'Essay';
      case MultiFormatQuestionType.dragDrop:
        return 'Drag & drop';
      case MultiFormatQuestionType.whiteboard:
        return 'Whiteboard';
    }
  }

  static MultiFormatQuestionType fromRaw(String raw) {
    return MultiFormatQuestionType.values.firstWhere(
      (type) => type.raw == raw,
      orElse: () => MultiFormatQuestionType.objectiveSingle,
    );
  }
}

class MultiFormatQuestion {
  const MultiFormatQuestion({
    required this.id,
    required this.type,
    required this.questionText,
    this.options = const [],
    this.correctIndexes = const [],
    this.correctTextAnswers = const [],
    this.dragItems = const [],
    this.dropTargets = const [],
    this.whiteboardPrompt,
    this.sourceRef,
    this.points = 1,
  });

  final String id;
  final MultiFormatQuestionType type;
  final String questionText;
  final List<String> options;
  final List<int> correctIndexes;
  final List<String> correctTextAnswers;
  final List<String> dragItems;
  final List<String> dropTargets;
  final String? whiteboardPrompt;
  final String? sourceRef;
  final int points;
}

class ExamSecurityPolicy {
  const ExamSecurityPolicy({
    this.demoMode = true,
    this.shuffleQuestions = true,
    this.lockCopyPaste = true,
    this.calculatorEnabled = false,
    this.requireProctoring = true,
    this.allowVerificationOverride = true,
  });

  final bool demoMode;
  final bool shuffleQuestions;
  final bool lockCopyPaste;
  final bool calculatorEnabled;
  final bool requireProctoring;
  final bool allowVerificationOverride;
}
