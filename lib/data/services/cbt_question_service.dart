import 'package:uuid/uuid.dart';

import '../models/cbt_models.dart';

class CBTQuestionService {
  static final _uuid = const Uuid();

  static List<CBTQuestionModel> loadQuestions({
    required String courseCode,
    String? topic,
  }) {
    final code = courseCode.trim().isEmpty ? 'CSC 305' : courseCode.trim();
    final all = <CBTQuestionModel>[
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: code,
        topic: 'Data Structures',
        question:
            'A search operation repeatedly divides a sorted dataset into two halves. Which condition is required for this method to work correctly?',
        options: const [
          'The records must be ordered by the search key',
          'The records must contain duplicate keys',
          'The records must be stored only as a linked list',
          'The records must be shuffled before searching',
        ],
        correctIndex: 0,
        explanation:
            'Binary search depends on ordered records and comparison with the middle item.',
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: code,
        topic: 'Trees',
        question:
            'In a binary search tree with unique values, where should a value smaller than the current node be placed?',
        options: const [
          'Right subtree',
          'Left subtree',
          'Root position',
          'Any empty node',
        ],
        correctIndex: 1,
        explanation:
            'A binary search tree keeps smaller values on the left and larger values on the right.',
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: code,
        topic: 'Queues and Stacks',
        question:
            'A service desk must attend to requests in the same order they arrive. Which structure is most suitable?',
        options: const [
          'Stack',
          'Queue',
          'Unordered tree',
          'Recursive call stack',
        ],
        correctIndex: 1,
        explanation:
            'A queue follows first-in, first-out processing.',
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: code,
        topic: 'Algorithms',
        question:
            'Which time complexity best describes quicksort in the average case when partitions are reasonably balanced?',
        options: const [
          'O(n)',
          'O(n log n)',
          'O(n²) for every input',
          'O(log n) for the full sort',
        ],
        correctIndex: 1,
        explanation:
            'Balanced partitioning gives logarithmic levels with linear work across each level.',
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: code,
        topic: 'Graphs',
        question:
            'Which traversal is normally used to find the shortest path in an unweighted graph?',
        options: const [
          'Depth-first search',
          'Breadth-first search',
          'Postorder traversal',
          'Selection sort',
        ],
        correctIndex: 1,
        explanation:
            'Breadth-first search explores vertices level by level.',
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: code,
        topic: 'Complexity Analysis',
        question:
            'An algorithm compares every pair of items in a list of size n. What is the dominant time complexity?',
        options: const [
          'O(log n)',
          'O(n)',
          'O(n log n)',
          'O(n²)',
        ],
        correctIndex: 3,
        explanation:
            'Comparing every pair usually creates a nested iteration pattern with quadratic growth.',
      ),
    ];

    if (topic == null || topic == 'Mixed') return all;
    return all.where((q) => q.topic == topic).toList();
  }

  static List<String> topicsForCourse(String courseCode) {
    return const [
      'Mixed',
      'Data Structures',
      'Trees',
      'Queues and Stacks',
      'Algorithms',
      'Graphs',
      'Complexity Analysis',
    ];
  }
}
