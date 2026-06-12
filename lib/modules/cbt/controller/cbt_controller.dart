import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/cbt_models.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/cbt_attempt_storage.dart';
import '../../../data/services/cbt_question_service.dart';
import '../../../data/services/graded_session_template_service.dart';
import '../../../data/services/storage_service.dart';
import '../../revision/controller/revision_controller.dart';

class CBTController extends GetxController {
  final _uuid = const Uuid();

  late String courseCode;
  String mode = 'Timed';
  String topic = 'Mixed';
  String sessionType = 'ASSESSMENT';
  String gradingType = 'UNGRADED';
  String questionSource = QuestionSourceType.studentLocal;
  ExamDeliveryMode deliveryMode = ExamDeliveryMode.centerBased;
  bool whiteboardEnabled = false;
  bool whiteboardRequired = false;
  String? whiteboardPrompt;
  int whiteboardStrokeCount = 0;
  bool shuffleQuestions = true;
  bool lockCopyPaste = false;
  bool calculatorEnabled = false;
  int totalQuestions = 20;
  int durationMinutes = 12;

  final questions = <CBTQuestionModel>[].obs;
  final index = 0.obs;
  final selectedIndex = RxnInt();
  final answers = <String, int>{}.obs;
  final markedForReview = <String>{}.obs;
  final correctCount = 0.obs;
  final secondsLeft = 0.obs;
  final isPaused = false.obs;
  final lastAutoSavedAt = Rxn<DateTime>();

  Timer? _timer;
  Timer? _autosaveTimer;
  bool _isSubmitting = false;
  DateTime? _startedAt;

  String get _draftKey =>
      'assessmentDraft.$courseCode.$sessionType.$gradingType.$topic.objective';

  void start({
    required String course,
    required String sessionMode,
    required String sessionTopic,
    required int sessionQuestions,
    required int sessionMinutes,
    String sessionKind = 'ASSESSMENT',
    String sessionGradingType = 'UNGRADED',
    String sessionQuestionSource = QuestionSourceType.studentLocal,
    ExamDeliveryMode sessionDeliveryMode = ExamDeliveryMode.centerBased,
    bool sessionWhiteboardEnabled = false,
    bool sessionWhiteboardRequired = false,
    String? sessionWhiteboardPrompt,
    int sessionWhiteboardStrokeCount = 0,
    bool sessionShuffleQuestions = true,
    bool sessionLockCopyPaste = false,
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

    mode = shouldLockToBackend ? 'Timed' : sessionMode;
    topic = shouldLockToBackend ? 'Mixed' : sessionTopic;
    deliveryMode = backendTemplate?.deliveryMode ?? sessionDeliveryMode;
    totalQuestions = backendTemplate != null && backendTemplate.hasObjective
        ? backendTemplate.objectiveQuestions
        : sessionQuestions;
    durationMinutes = backendTemplate?.durationMinutes ?? sessionMinutes;

    _startedAt = DateTime.now();
    _isSubmitting = false;
    answers.clear();
    markedForReview.clear();
    correctCount.value = 0;
    index.value = 0;
    selectedIndex.value = null;
    isPaused.value = false;
    lastAutoSavedAt.value = null;

    final pool = CBTQuestionService.loadQuestions(
      courseCode: courseCode,
      topic: topic,
    );
    final list = <CBTQuestionModel>[];
    while (list.length < totalQuestions) {
      list.addAll(pool);
      if (pool.isEmpty) break;
    }
    final selected = list.take(totalQuestions).toList();
    if (shuffleQuestions) selected.shuffle(Random());
    questions.assignAll(selected);

    if (questions.isEmpty) {
      _timer?.cancel();
      _autosaveTimer?.cancel();
      secondsLeft.value = 0;
      return;
    }

    _restoreDraftIfAvailable();

    _timer?.cancel();
    secondsLeft.value = secondsLeft.value > 0 ? secondsLeft.value : durationMinutes * 60;
    if (mode != 'Untimed') {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isSubmitting || isPaused.value) return;
        secondsLeft.value--;
        if (secondsLeft.value <= 0) {
          submit();
        }
      });
    }

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_isSubmitting) saveDraft();
    });
  }

  void pauseTimer() {
    if (mode == 'Untimed') return;
    isPaused.value = true;
    saveDraft();
  }

  void resumeTimer() {
    if (mode == 'Untimed') return;
    isPaused.value = false;
    saveDraft();
  }

  CBTQuestionModel get current => questions[index.value];

  void pick(int optionIndex) {
    selectedIndex.value = optionIndex;
    answers[current.id] = optionIndex;
    saveDraft();
  }

  void toggleCurrentReview() {
    if (markedForReview.contains(current.id)) {
      markedForReview.remove(current.id);
    } else {
      markedForReview.add(current.id);
    }
    saveDraft();
  }

  void jumpTo(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= questions.length) return;
    index.value = targetIndex;
    selectedIndex.value = answers[current.id];
    saveDraft();
  }

  bool isAnswered(String questionId) => answers.containsKey(questionId);
  bool isMarked(String questionId) => markedForReview.contains(questionId);

  void setWhiteboardStrokeCount(int count) {
    whiteboardStrokeCount = count < 0 ? 0 : count;
    saveDraft();
  }

  void next() {
    if (index.value < questions.length - 1) {
      index.value++;
      selectedIndex.value = answers[current.id];
      saveDraft();
    }
  }

  void prev() {
    if (index.value > 0) {
      index.value--;
      selectedIndex.value = answers[current.id];
      saveDraft();
    }
  }

  void saveDraft() {
    if (questions.isEmpty) return;
    final now = DateTime.now();
    StorageService.box.write(_draftKey, {
      'answers': answers.map((key, value) => MapEntry(key, value)),
      'marked': markedForReview.toList(),
      'index': index.value,
      'secondsLeft': secondsLeft.value,
      'whiteboardStrokeCount': whiteboardStrokeCount,
      'savedAt': now.toIso8601String(),
    });
    lastAutoSavedAt.value = now;
  }

  void _restoreDraftIfAvailable() {
    final raw = StorageService.box.read(_draftKey);
    if (raw is! Map) return;
    final validQuestionIds = questions.map((q) => q.id).toSet();

    final rawAnswers = raw['answers'];
    if (rawAnswers is Map) {
      rawAnswers.forEach((key, value) {
        final questionId = key.toString();
        final selected = value is int ? value : int.tryParse(value.toString());
        if (selected != null && validQuestionIds.contains(questionId)) {
          answers[questionId] = selected;
        }
      });
    }

    final rawMarked = raw['marked'];
    if (rawMarked is List) {
      markedForReview.addAll(
        rawMarked.map((e) => e.toString()).where(validQuestionIds.contains),
      );
    }

    final savedIndex = raw['index'];
    final restoredIndex = savedIndex is int
        ? savedIndex
        : int.tryParse(savedIndex?.toString() ?? '') ?? 0;
    index.value = restoredIndex.clamp(0, questions.length - 1);
    selectedIndex.value = answers[current.id];

    final savedSeconds = raw['secondsLeft'];
    final restoredSeconds = savedSeconds is int
        ? savedSeconds
        : int.tryParse(savedSeconds?.toString() ?? '') ?? 0;
    if (restoredSeconds > 0 && restoredSeconds <= durationMinutes * 60) {
      secondsLeft.value = restoredSeconds;
    }

    final savedWhiteboardCount = raw['whiteboardStrokeCount'];
    whiteboardStrokeCount = savedWhiteboardCount is int
        ? savedWhiteboardCount
        : int.tryParse(savedWhiteboardCount?.toString() ?? '') ?? whiteboardStrokeCount;

    final savedAt = DateTime.tryParse(raw['savedAt']?.toString() ?? '');
    if (savedAt != null) lastAutoSavedAt.value = savedAt;
  }

  Future<CBTAttemptModel?> submit({bool returnAttempt = false}) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    try {
      _timer?.cancel();
      _autosaveTimer?.cancel();
      isPaused.value = false;

      int correct = 0;
      final Map<String, Map<String, int>> stats = {};

      void ensure(String topic) {
        final t = topic.trim().isEmpty ? 'Unknown Topic' : topic.trim();
        stats.putIfAbsent(
          t,
          () => {'total': 0, 'correct': 0, 'wrong': 0, 'scorePct': 0},
        );
      }

      for (final q in questions) {
        final t = q.topic.trim().isEmpty ? 'Unknown Topic' : q.topic.trim();
        ensure(t);
        stats[t]!['total'] = (stats[t]!['total'] ?? 0) + 1;
        final a = answers[q.id];
        final isCorrect = a != null && a == q.correctIndex;
        if (isCorrect) {
          correct++;
          stats[t]!['correct'] = (stats[t]!['correct'] ?? 0) + 1;
        } else {
          stats[t]!['wrong'] = (stats[t]!['wrong'] ?? 0) + 1;
        }
      }

      stats.forEach((t, m) {
        final total = m['total'] ?? 0;
        final c = m['correct'] ?? 0;
        m['scorePct'] = total == 0 ? 0 : ((c / total) * 100).round();
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
      await StorageService.box.remove(_draftKey);

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
    _autosaveTimer?.cancel();
    super.onClose();
  }
}
