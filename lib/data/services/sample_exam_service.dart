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
        id: 'fb_bst_order',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt:
            'In a binary search tree, left subtree values are ______ than the root.',
        marks: 1,
        sourceRef: 'Sample Lecture Notes: Trees',
        expectedKeywords: const ['less', 'less than', 'smaller'],
      ),
      FillBlankQuestionModel(
        id: 'fb_queue_order',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt: 'A queue follows the ______ principle.',
        marks: 1,
        sourceRef: 'Sample Lecture Notes: Linear Structures',
        expectedKeywords: const [
          'fifo',
          'first in first out',
          'first-in first-out',
        ],
      ),
      FillBlankQuestionModel(
        id: 'fb_bfs_structure',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt: 'Breadth-first search commonly uses a ______ to track nodes.',
        marks: 1,
        sourceRef: 'Sample Lecture Notes: Graphs',
        expectedKeywords: const ['queue'],
      ),
      FillBlankQuestionModel(
        id: 'fb_encapsulation',
        courseCode: courseCode,
        topic: resolvedTopic,
        prompt:
            'Encapsulation hides implementation details behind a public ______.',
        marks: 1,
        sourceRef: 'Sample Lecture Notes: OOP',
        expectedKeywords: const ['interface', 'api'],
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
      id: 'essay_sample_1',
      courseCode: courseCode,
      topic: _topic(topic),
      question:
          'Explain how a distance learning student platform should support assessment integrity, offline access, and feedback after submission.',
      marks: 10,
      sourceRef: 'Sample Exam Pack: Distance Learning Assessment',
      expectedKeywords: const [
        'assessment integrity',
        'offline access',
        'feedback',
        'submission',
        'synchronization',
      ],
    );
  }

  static List<MultiFormatQuestion> multiFormatQuestions({
    required String courseCode,
    required String topic,
    List<MultiFormatQuestionType> formats = MultiFormatQuestionType.values,
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
