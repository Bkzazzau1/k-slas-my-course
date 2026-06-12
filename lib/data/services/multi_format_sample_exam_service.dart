import '../models/multi_format_exam_models.dart';

class MultiFormatSampleExamService {
  MultiFormatSampleExamService._();

  static const importedFormats = MultiFormatQuestionType.values;

  static List<MultiFormatQuestion> questions({
    required String courseCode,
    required String topic,
    List<MultiFormatQuestionType> formats = MultiFormatQuestionType.values,
  }) {
    final selected = formats.toSet();
    return _allQuestions(courseCode: courseCode, topic: _topic(topic))
        .where((question) => selected.contains(question.type))
        .toList(growable: false);
  }

  static List<String> labelsFor(List<MultiFormatQuestionType> formats) {
    return formats.map((format) => format.label).toList(growable: false);
  }

  static List<MultiFormatQuestion> _allQuestions({
    required String courseCode,
    required String topic,
  }) {
    final source = 'Imported K-SLAS CBT sample pack: $courseCode';
    return [
      MultiFormatQuestion(
        id: 'mf_obj_single',
        type: MultiFormatQuestionType.objectiveSingle,
        questionText:
            'Which feature best supports distance-learning exam continuity?',
        options: const [
          'Offline autosave',
          'Removing feedback',
          'Manual-only scoring',
          'No identity checks',
        ],
        correctIndexes: const [0],
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_obj_multiple',
        type: MultiFormatQuestionType.objectiveMultiple,
        questionText: 'Select all safeguards useful in a remote CBT session.',
        options: const [
          'Question shuffling',
          'Copy and paste control',
          'Integrity scoring',
          'Unlimited account sharing',
        ],
        correctIndexes: const [0, 1, 2],
        points: 3,
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_true_false',
        type: MultiFormatQuestionType.trueFalse,
        questionText:
            'A demo proctoring session may allow the student to proceed after failed verification.',
        options: const ['True', 'False'],
        correctIndexes: const [0],
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_fill_blank',
        type: MultiFormatQuestionType.fillBlank,
        questionText:
            'A distance-learning exam should autosave answers before final ______.',
        correctTextAnswers: const ['submission', 'submit'],
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_short_answer',
        type: MultiFormatQuestionType.shortAnswer,
        questionText:
            'State two reasons why remote CBT needs both timer and autosave controls.',
        correctTextAnswers: const ['time', 'autosave', 'continuity'],
        points: 4,
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_essay',
        type: MultiFormatQuestionType.essay,
        questionText:
            'Explain how a distance-learning CBT platform should balance demo access, proctoring, offline resilience, and learner feedback.',
        correctTextAnswers: const ['demo', 'proctoring', 'offline', 'feedback'],
        points: 10,
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_drag_drop',
        type: MultiFormatQuestionType.dragDrop,
        questionText:
            'Match each CBT security signal with the correct response.',
        dragItems: const [
          'Failed verification',
          'Screen recording detected',
          'Network drop',
        ],
        dropTargets: const [
          'Demo override or retry',
          'Integrity warning',
          'Autosave and resume',
        ],
        points: 3,
        sourceRef: source,
      ),
      MultiFormatQuestion(
        id: 'mf_whiteboard',
        type: MultiFormatQuestionType.whiteboard,
        questionText:
            'Use the whiteboard to sketch the flow of a remote CBT attempt from login to submission.',
        whiteboardPrompt:
            'Include verification, question delivery, autosave, submission, and feedback.',
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
