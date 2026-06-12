import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/course_model.dart';
import '../../../data/models/practice_models.dart';
import '../../../data/services/practice_storage_service.dart';
import '../../../features/dashboard/controller/dashboard_controller.dart';

class PracticeController extends GetxController {
  late CourseModel course;

  // Setup state
  final selectedMode = 'Timed'.obs; // Timed | Untimed | CBT style
  final selectedSet = 'Mixed'.obs; // Mixed | By topic
  final selectedTopic = 'Trees'.obs;

  // Session state
  final questions = <PracticeQuestionModel>[].obs;
  final currentIndex = 0.obs;
  final selectedOptionIndex = (-1).obs;
  final answers = <String, int>{}.obs; // qId -> option index

  // Timer
  final timeLeftSec = 0.obs;
  Timer? _timer;

  // Results
  final lastAttempt = Rxn<PracticeAttemptModel>();

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments ?? {}) as Map;
    course = args['course'] as CourseModel;

    // Seed dummy last attempt (later from storage)
    lastAttempt.value = PracticeAttemptModel(
      courseCode: course.code,
      mode: "Timed",
      total: 20,
      correct: 14,
      durationSec: 12 * 60,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      topicLabel: "Trees",
    );
  }

  // ---- Setup -> start session ----
  void startSession() {
    // Build question list (placeholder, later from your materials/past papers DB)
    questions.assignAll(_mockQuestions(topic: selectedTopic.value));

    currentIndex.value = 0;
    selectedOptionIndex.value = -1;
    answers.clear();

    // Timer behavior
    if (selectedMode.value == 'Timed') {
      timeLeftSec.value = 12 * 60; // 12 minutes default
      _startTimer();
    } else {
      timeLeftSec.value = 0;
      _stopTimer();
    }
  }

  // ---- Session actions ----
  PracticeQuestionModel get currentQ => questions[currentIndex.value];

  void chooseOption(int idx) {
    selectedOptionIndex.value = idx;
    answers[currentQ.id] = idx;
  }

  void next() {
    if (currentIndex.value < questions.length - 1) {
      currentIndex.value++;
      selectedOptionIndex.value = answers[currentQ.id] ?? -1;
    }
  }

  void prev() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      selectedOptionIndex.value = answers[currentQ.id] ?? -1;
    }
  }

  Future<void> finish() async {
    _stopTimer();

    final total = questions.length;
    int correct = 0;

    for (final q in questions) {
      final picked = answers[q.id];
      if (picked != null && picked == q.correctIndex) correct++;
    }

    final durationUsed = selectedMode.value == 'Timed'
        ? (12 * 60 - timeLeftSec.value).clamp(0, 12 * 60)
        : 0;

    final attempt = PracticeAttemptModel(
      courseCode: course.code,
      mode: selectedMode.value,
      total: total,
      correct: correct,
      durationSec: durationUsed,
      createdAt: DateTime.now(),
      topicLabel: selectedSet.value == "By topic"
          ? selectedTopic.value
          : "Mixed",
    );

    lastAttempt.value = attempt;

    await PracticeStorageService.saveAttempt(attempt);

    final dash = Get.find<DashboardController>();
    await dash.bumpStreak();
    dash.refreshFromAttempts();
  }

  // ---- Timer helpers ----
  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (timeLeftSec.value <= 1) {
        timeLeftSec.value = 0;
        _stopTimer();
        // time up -> finish automatically
        finish();
        return;
      }
      timeLeftSec.value--;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }

  // ---- Mock questions ----
  List<PracticeQuestionModel> _mockQuestions({required String topic}) {
    return [
      PracticeQuestionModel(
        id: "q1",
        topic: topic,
        question:
            "In a binary search tree, inorder traversal returns values in:",
        options: [
          "Random order",
          "Descending order",
          "Ascending order",
          "Level order",
        ],
        correctIndex: 2,
        explanation: "Inorder traversal visits Left → Root → Right.",
      ),
      PracticeQuestionModel(
        id: "q2",
        topic: topic,
        question: "Which structure is best for implementing recursion?",
        options: ["Queue", "Stack", "Heap", "Graph"],
        correctIndex: 1,
        explanation: "Recursion uses the call stack.",
      ),
      PracticeQuestionModel(
        id: "q3",
        topic: topic,
        question: "AVL tree is a type of:",
        options: ["Unbalanced BST", "Balanced BST", "Hash table", "Graph"],
        correctIndex: 1,
        explanation: "AVL maintains balance with rotations.",
      ),
    ];
  }
}
