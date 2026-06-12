import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/cbt_models.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/cbt_attempt_storage.dart';
import '../../../data/services/cbt_question_service.dart';
import '../../../data/services/graded_session_template_service.dart';
import '../../revision/controller/revision_controller.dart';

class CBTController extends GetxController {
  final _uuid = const Uuid();

  // session config
  late String courseCode;
  String mode = "Timed"; // Timed, Untimed, CBT style
  String topic = "Mixed";
  String sessionType = "ASSESSMENT";
  String gradingType = "UNGRADED";
  String questionSource = QuestionSourceType.studentLocal;
  ExamDeliveryMode deliveryMode = ExamDeliveryMode.remoteProctored;
  bool whiteboardEnabled = false;
  bool whiteboardRequired = false;
  String? whiteboardPrompt;
  int whiteboardStrokeCount = 0;
  bool shuffleQuestions = true;
  bool lockCopyPaste = true;
  bool calculatorEnabled = false;
  int totalQuestions = 20;
  int durationMinutes = 12;

  // session state
  final questions = <CBTQuestionModel>[].obs;
  final index = 0.obs;

  final selectedIndex = RxnInt();
  final answers = <String, int>{}.obs; // questionId -> selectedOptionIndex
  final correctCount = 0.obs;

  final secondsLeft = 0.obs;
  final isPaused = false.obs;
  Timer? _timer;
  bool _isSubmitting = false;

  DateTime? _startedAt;

  void start({
    required String course,
    required String sessionMode,
    required String sessionTopic,
    required int sessionQuestions,
    required int sessionMinutes,
    String sessionKind = "ASSESSMENT",
    String sessionGradingType = "UNGRADED",
    String sessionQuestionSource = QuestionSourceType.studentLocal,
    ExamDeliveryMode sessionDeliveryMode = ExamDeliveryMode.remoteProctored,
    bool sessionWhiteboardEnabled = false,
    bool sessionWhiteboardRequired = false,
    String? sessionWhiteboardPrompt,
    int sessionWhiteboardStrokeCount = 0,
    bool sessionShuffleQuestions = true,
    bool sessionLockCopyPaste = true,
    bool sessionCalculatorEnabled = false,
  }) {
    courseCode = course;
    sessionType = sessionKind;
    gradingType = sessionGradingType;
    questionSource = sessionQuestionSource;
    whiteboardEnabled = sessionWhiteboardEnabled;
    whiteboardRequired = sessionWhiteboardRequired;
    whiteboardPrompt = sessionWhiteboardPrompt;
    whiteboardStrokeCount = sessionWhiteboardStrokeCount;
    shuffleQuestions = sessionShuffleQuestions;
    lockCopyPaste = sessionLockCopyPaste;
    calculatorEnabled = sessionCalculatorEnabled;

    final shouldLockToBackend =
        questionSource == QuestionSourceType.lecturerAdmin ||
        gradingType == GradingType.graded;

    final backendTemplate = shouldLockToBackend
        ? GradedSessionTemplateService.templateFor(
            courseCode: courseCode,
            sessionType: sessionType,
          )
        : null;

    mode = shouldLockToBackend ? "Timed" : sessionMode;
    topic = shouldLockToBackend ? "Mixed" : sessionTopic;
    deliveryMode = backendTemplate?.deliveryMode ?? sessionDeliveryMode;
    totalQuestions = backendTemplate != null && backendTemplate.hasObjective
        ? backendTemplate.objectiveQuestions
        : sessionQuestions;
    durationMinutes = backendTemplate?.durationMinutes ?? sessionMinutes;

    _startedAt = DateTime.now();
    _isSubmitting = false;
    answers.clear();
    correctCount.value = 0;
    index.value = 0;
    selectedIndex.value = null;
    isPaused.value = false;

    // load questions
    final pool = CBTQuestionService.loadQuestions(
      courseCode: courseCode,
      topic: topic,
    );
    // MVP: repeat if less than needed
    final list = <CBTQuestionModel>[];
    while (list.length < totalQuestions) {
      list.addAll(pool);
      if (pool.isEmpty) break;
    }
    final selected = list.take(totalQuestions).toList();
    if (shuffleQuestions) {
      selected.shuffle(Random());
    }
    questions.assignAll(selected);

    // If no questions, stop and leave timer off to avoid crashes
    if (questions.isEmpty) {
      _timer?.cancel();
      secondsLeft.value = 0;
      return;
    }

    // timer for timed/cbt
    _timer?.cancel();
    secondsLeft.value = durationMinutes * 60;
    if (mode != "Untimed") {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isSubmitting || isPaused.value) return;
        secondsLeft.value--;
        if (secondsLeft.value <= 0) {
          submit();
        }
      });
    }
  }

  void pauseTimer() {
    if (mode == "Untimed") return;
    isPaused.value = true;
  }

  void resumeTimer() {
    if (mode == "Untimed") return;
    isPaused.value = false;
  }

  CBTQuestionModel get current => questions[index.value];

  void pick(int optionIndex) {
    selectedIndex.value = optionIndex;
    answers[current.id] = optionIndex;
  }

  void setWhiteboardStrokeCount(int count) {
    whiteboardStrokeCount = count < 0 ? 0 : count;
  }

  void next() {
    if (index.value < questions.length - 1) {
      index.value++;
      selectedIndex.value = answers[current.id];
    }
  }

  void prev() {
    if (index.value > 0) {
      index.value--;
      selectedIndex.value = answers[current.id];
    }
  }

  Future<CBTAttemptModel?> submit({bool returnAttempt = false}) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    try {
      _timer?.cancel();
      isPaused.value = false;

      int correct = 0;

      // topic -> {"total": x, "correct": y, "wrong": z, "scorePct": p}
      final Map<String, Map<String, int>> stats = {};

      void ensure(String topic) {
        final t = topic.trim().isEmpty ? "Unknown Topic" : topic.trim();
        stats.putIfAbsent(
          t,
          () => {"total": 0, "correct": 0, "wrong": 0, "scorePct": 0},
        );
      }

      for (final q in questions) {
        final t = q.topic.trim().isEmpty ? "Unknown Topic" : q.topic.trim();
        ensure(t);

        stats[t]!["total"] = (stats[t]!["total"] ?? 0) + 1;

        final a = answers[q.id];
        final isCorrect = a != null && a == q.correctIndex;

        if (isCorrect) {
          correct++;
          stats[t]!["correct"] = (stats[t]!["correct"] ?? 0) + 1;
        } else {
          stats[t]!["wrong"] = (stats[t]!["wrong"] ?? 0) + 1;
        }
      }

      // compute scorePct per topic
      stats.forEach((t, m) {
        final total = m["total"] ?? 0;
        final c = m["correct"] ?? 0;
        final pct = total == 0 ? 0 : ((c / total) * 100).round();
        m["scorePct"] = pct;
      });

      correctCount.value = correct;

      final endedAt = DateTime.now();
      final startedAt = _startedAt ?? endedAt;

      final attempt = CBTAttemptModel(
        id: _uuid.v4(),
        courseCode: courseCode,
        sessionType: sessionType,
        gradingType: gradingType,
        mode: mode,
        totalQuestions: questions.length,
        correct: correct,
        startedAt: startedAt,
        endedAt: endedAt,
        topic: topic,
        durationMinutes: durationMinutes,
        topicStats: stats,
        deliveryMode: deliveryMode,
        whiteboardEnabled: whiteboardEnabled,
        whiteboardRequired: whiteboardRequired,
        whiteboardStrokeCount: whiteboardStrokeCount,
        whiteboardPrompt: whiteboardPrompt,
      );

      await CBTAttemptStorage.saveAttempt(courseCode, attempt);

      try {
        final rev = Get.find<RevisionPlanController>();
        rev.loadForCourse(courseCode);
      } catch (_) {}

      if (returnAttempt) {
        Get.back(result: attempt);
      } else {
        Get.offNamed('/cbt/result', arguments: attempt);
      }
      return attempt;
    } finally {
      _isSubmitting = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
