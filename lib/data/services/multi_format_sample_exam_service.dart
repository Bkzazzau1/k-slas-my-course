import '../models/multi_format_exam_models.dart';

class MultiFormatSampleExamService {
  MultiFormatSampleExamService._();

  static const importedFormats = [
    MultiFormatQuestionType.objectiveSingle,
    MultiFormatQuestionType.objectiveMultiple,
    MultiFormatQuestionType.fillBlank,
    MultiFormatQuestionType.dragDrop,
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
        .take(6)
        .toList(growable: false);
  }

  static List<String> labelsFor(List<MultiFormatQuestionType> formats) {
    return formats.map((format) => format.label).toList(growable: false);
  }

  static List<MultiFormatQuestion> _allQuestions({
    required String courseCode,
    required String topic,
  }) {
    return [
      MultiFormatQuestion(
        id: 'mf_single_tree_search',
        type: MultiFormatQuestionType.objectiveSingle,
        questionText:
            'Which structure gives efficient ordered search when values are inserted according to a left-less-than-root and right-greater-than-root rule?',
        options: const ['Binary search tree', 'Plain queue', 'Stack', 'Unordered list only'],
        correctIndexes: const [0],
        points: 1,
        sourceRef: '',
      ),
      MultiFormatQuestion(
        id: 'mf_multi_bfs_properties',
        type: MultiFormatQuestionType.objectiveMultiple,
        questionText:
            'Select the statements that correctly describe breadth-first search in an unweighted graph.',
        options: const [
          'It visits vertices level by level',
          'It commonly uses a queue',
          'It can find a shortest path by number of edges',
          'It must use recursion for every implementation',
        ],
        correctIndexes: const [0, 1, 2],
        points: 3,
        sourceRef: '',
      ),
      MultiFormatQuestion(
        id: 'mf_fill_complexity',
        type: MultiFormatQuestionType.fillBlank,
        questionText:
            'An algorithm with two nested loops over the same input size usually has ______ time complexity.',
        correctTextAnswers: const ['o(n^2)', 'o(n²)', 'quadratic'],
        points: 2,
        sourceRef: '',
      ),
      MultiFormatQuestion(
        id: 'mf_match_structures',
        type: MultiFormatQuestionType.dragDrop,
        questionText:
            'Match each use case with the most suitable data structure.',
        dragItems: const [
          'Process requests in arrival order',
          'Undo the latest action',
          'Rank entries by score',
          'Search records with a key',
        ],
        dropTargets: const ['Queue', 'Stack', 'Priority queue', 'Hash table'],
        points: 4,
        sourceRef: '',
      ),
      MultiFormatQuestion(
        id: 'mf_essay_selection',
        type: MultiFormatQuestionType.essay,
        questionText:
            'A course-registration system must search student records, process requests in arrival order, and rank students by score. Recommend suitable data structures and justify each recommendation.',
        correctTextAnswers: const ['hash table', 'queue', 'priority queue', 'time complexity'],
        points: 10,
        sourceRef: '',
      ),
      MultiFormatQuestion(
        id: 'mf_whiteboard_bst',
        type: MultiFormatQuestionType.whiteboard,
        questionText:
            'Draw a binary search tree formed by inserting 50, 30, 70, 20, 40, 60, and 80 in that order.',
        whiteboardPrompt:
            'Show the final tree clearly and label the left and right child relationships.',
        points: 8,
        sourceRef: '',
      ),
    ];
  }

  static String _topic(String topic) {
    final value = topic.trim();
    if (value.isEmpty || value == 'WeakOnly') return 'Mixed';
    return value;
  }
}
