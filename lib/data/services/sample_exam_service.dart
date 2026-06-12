import '../models/fill_blank_models.dart';
import '../models/multi_format_exam_models.dart';
import '../models/theory_models.dart';
import 'multi_format_sample_exam_service.dart';

class SampleExamService {
  SampleExamService._();

  static List<FillBlankQuestionModel> fillBlankQuestions({
    required String courseCode,
    required String topic,
    required int count,
  }) {
    final resolvedTopic = _topic(topic);
    final samples = [
      FillBlankQuestionModel(
        id: 'fb_bst_property',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt:
            'In a binary search tree, values smaller than a node are stored in the ______ subtree.',
        marks: 1,
        sourceRef: '',
        expectedKeywords: const ['left'],
      ),
      FillBlankQuestionModel(
        id: 'fb_queue_policy',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt:
            'A queue removes items according to the ______ order of arrival.',
        marks: 1,
        sourceRef: '',
        expectedKeywords: const ['first in first out', 'fifo'],
      ),
      FillBlankQuestionModel(
        id: 'fb_bfs_structure',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt:
            'Breadth-first search uses a ______ to keep track of vertices waiting to be visited.',
        marks: 1,
        sourceRef: '',
        expectedKeywords: const ['queue'],
      ),
      FillBlankQuestionModel(
        id: 'fb_complexity_pairwise',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt:
            'An algorithm that compares every pair of items normally has ______ time complexity.',
        marks: 1,
        sourceRef: '',
        expectedKeywords: const ['o(n^2)', 'o(n²)', 'quadratic'],
      ),
      FillBlankQuestionModel(
        id: 'fb_heap_priority',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt:
            'A priority queue is commonly implemented using a binary ______.',
        marks: 1,
        sourceRef: '',
        expectedKeywords: const ['heap'],
      ),
    ];

    return List.generate(count, (i) {
      final sample = samples[i % samples.length];
      return FillBlankQuestionModel(
        id: '${sample.id}_$i',
        courseCode: sample.courseCode,
        topic: sample.topic,
        prompt: sample.prompt,
        marks: sample.marks,
        sourceRef: sample.sourceRef,
        expectedKeywords: sample.expectedKeywords,
      );
    });
  }

  static TheoryQuestionModel theoryQuestion({
    required String courseCode,
    required String topic,
  }) {
    return TheoryQuestionModel(
      id: 'essay_data_structures_1',
      courseCode: courseCode,
      topic: _topic(topic),
      question:
          'A university result-processing system must store student records, search by matric number, process requests in order of arrival, and generate ranked merit lists. Recommend suitable data structures for these requirements and justify your choices.',
      marks: 10,
      sourceRef: '',
      expectedKeywords: const [
        'hash table',
        'binary search tree',
        'queue',
        'priority queue',
        'time complexity',
        'search',
        'insertion',
        'ordering',
      ],
    );
  }

  static List<MultiFormatQuestion> multiFormatQuestions({
    required String courseCode,
    required String topic,
    List<MultiFormatQuestionType> formats = MultiFormatSampleExamService.importedFormats,
  }) {
    return MultiFormatSampleExamService.questions(
      courseCode: courseCode,
      topic: topic,
      formats: formats,
    );
  }

  static String _topic(String topic) {
    final value = topic.trim();
    if (value.isEmpty || value == 'WeakOnly') return 'Mixed';
    return value;
  }
}
