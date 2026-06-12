import '../models/multi_format_exam_models.dart';

class MultiFormatSampleExamService {
  MultiFormatSampleExamService._();

  static const importedFormats = [
    MultiFormatQuestionType.objectiveSingle,
    MultiFormatQuestionType.objectiveMultiple,
    MultiFormatQuestionType.fillBlank,
    MultiFormatQuestionType.essay,
    MultiFormatQuestionType.whiteboard,
  ];

  static List<MultiFormatQuestion> questions({
    required String courseCode,
    required String topic,
    List<MultiFormatQuestionType> formats = importedFormats,
  }) {
    final selected = formats.toSet();
    return _allQuestions(courseCode: courseCode, topic: _topic(topic))
        .where((question) => selected.contains(question.type))
        .take(5)
        .toList(growable: false);
  }

  static List<String> labelsFor(List<MultiFormatQuestionType> formats) {
    return formats.map((format) => format.label).toList(growable: false);
  }

  static List<MultiFormatQuestion> _allQuestions({
    required String courseCode,
    required String topic,
  }) {
    final source = 'K-SLAS assessment sample pack: $courseCode';
    return [
      MultiFormatQuestion(
        id: 'mf_single_integrity',
        type: MultiFormatQuestionType.objectiveSingle,
        questionText:
            'Which platform feature is most important for protecting a graded distance-learning assessment?',
        options: const [
          'Identity verification and live integrity monitoring',
          'Allowing unlimited device switching',
          'Disabling answer autosave',
          'Hiding lecturer feedback permanently',
        ],
        correctIndexes: const [0],
        points: 1,
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_multi_controls',
        type: MultiFormatQuestionType.objectiveMultiple,
        questionText:
            'Select the controls that should be active during a proctored graded assessment.',
        options: const [
          'Camera/environment verification',
          'Copy-and-paste restriction',
          'Question shuffling',
          'Anonymous account sharing',
        ],
        correctIndexes: const [0, 1, 2],
        points: 3,
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_fill_autosave',
        type: MultiFormatQuestionType.fillBlank,
        questionText:
            'Before final submission, the platform should continuously ______ student answers to prevent data loss.',
        correctTextAnswers: const ['autosave', 'auto-save', 'save'],
        points: 2,
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_essay_resilience',
        type: MultiFormatQuestionType.essay,
        questionText:
            'Explain how K-SLAS should combine assessment integrity, offline resilience, and post-submission feedback for distance learners.',
        correctTextAnswers: const [
          'integrity',
          'offline',
          'autosave',
          'feedback',
        ],
        points: 10,
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_whiteboard_flow',
        type: MultiFormatQuestionType.whiteboard,
        questionText:
            'Use the whiteboard to sketch the flow of a remote graded assessment from login to submission.',
        whiteboardPrompt:
            'Include verification, question delivery, autosave, answer submission, and lecturer feedback.',
        points: 8,
        sourceRef: source,
      ),
    ];
  }

  static String _topic(String topic) {
    final value = topic.trim();
    if (value.isEmpty || value == 'WeakOnly') return 'Mixed';
    return value;
  }
}
