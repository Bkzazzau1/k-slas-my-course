import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/models/theory_models.dart';
import '../../proctoring/controller/proctoring_controller.dart';
import '../controller/theory_controller.dart';

class TheoryPracticeView extends StatefulWidget {
  const TheoryPracticeView({super.key});

  @override
  State<TheoryPracticeView> createState() => _TheoryPracticeViewState();
}

class _TheoryPracticeViewState extends State<TheoryPracticeView> {
  static const int _minIntegrityToMark = 40;

  late final TheoryController controller;
  late final TheoryQuestionModel q;
  late final ProctoringController proctoring;
  late final bool _examMode;
  late final String _gradingType;
  late final ExamDeliveryMode _deliveryMode;
  late final bool _useProctoring;
  late final bool _lockCopyPaste;
  late final FocusNode _answerFocusNode;
  bool _ownsProctoringSession = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<TheoryController>();
    _answerFocusNode = FocusNode();

    final rawArgs = Get.arguments;
    if (rawArgs is Map && rawArgs['question'] is TheoryQuestionModel) {
      q = rawArgs['question'] as TheoryQuestionModel;
      _examMode = rawArgs['examMode'] == true;
      _gradingType =
          (rawArgs['gradingType'] as String?) ?? GradingType.ungraded;
      _deliveryMode = ExamDeliveryModeX.fromRaw(
        rawArgs['deliveryMode']?.toString(),
      );
      _lockCopyPaste = rawArgs['lockCopyPaste'] != false;
    } else {
      q = rawArgs as TheoryQuestionModel;
      _examMode = false;
      _gradingType = GradingType.ungraded;
      _deliveryMode = ExamDeliveryMode.remoteProctored;
      _lockCopyPaste = false;
    }
    _useProctoring = _deliveryMode == ExamDeliveryMode.remoteProctored;

    proctoring = Get.isRegistered<ProctoringController>()
        ? Get.find<ProctoringController>()
        : Get.put(ProctoringController(), permanent: true);

    if (_useProctoring && _examMode) {
      final highStakesAlreadyActive =
          proctoring.shieldActive.value &&
          proctoring.currentLevel.value ==
              AssessmentIntegrityLevel.highStakesExam;

      if (!highStakesAlreadyActive) {
        _ownsProctoringSession = true;
        unawaited(
          proctoring.startSession(
            level: AssessmentIntegrityLevel.highStakesExam,
            onSessionTerminated: _handleSessionTermination,
          ),
        );
      }
    } else if (_useProctoring) {
      _ownsProctoringSession = true;
      unawaited(
        proctoring.startSession(
          level: AssessmentIntegrityLevel.gradedAssessment,
          onSessionTerminated: _handleSessionTermination,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadQuestion(q);
      if (_shouldLockPaste) {
        unawaited(proctoring.clearClipboard());
      }
    });

    _answerFocusNode.addListener(() {
      if (_answerFocusNode.hasFocus && _shouldLockPaste) {
        unawaited(proctoring.clearClipboard());
      }
    });
  }

  @override
  void dispose() {
    _answerFocusNode.dispose();
    if (_ownsProctoringSession) {
      unawaited(proctoring.stopSession(silent: true));
    }
    super.dispose();
  }

  bool get _isGradedSession => _gradingType == GradingType.graded;
  bool get _shouldLockPaste => _isGradedSession || _lockCopyPaste;

  void _handleSessionTermination() {
    if (!mounted) return;
    _leaveTheorySection();
  }

  Future<void> _leaveTheorySection() async {
    if (!_examMode) {
      Get.back();
      return;
    }

    final result = controller.result.value;
    if (result != null) {
      _returnTheoryResult(result);
      return;
    }

    final leave = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leave theory section?'),
        content: const Text(
          'Your essay answer has not been marked yet. Leaving will return to the exam section list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (leave == true) {
      Get.back(result: null);
    }
  }

  void _returnTheoryResult(TheoryMarkResult r) {
    Get.back(
      result: {
        'section': 'THEORY',
        'totalMarks': r.totalMarks,
        'scoredMarks': r.scoredMarks,
        'extra': {
          'keywords': r.keywordChecks
              .map((k) => {'k': k.keyword, 'found': k.found})
              .toList(),
          'citations': r.citations,
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_leaveTheorySection());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaveTheorySection,
          ),
          title: Text('${q.courseCode} - Theory'),
        ),
        body: LuxuryScaffold(
          safeArea: true,
          child: Obx(() {
            final res = controller.result.value;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _QuestionCard(q: q),
                const SizedBox(height: 12),
                if (_useProctoring) ...[
                  Obx(
                    () => _IntegrityStrip(
                      score: proctoring.integrityScore.value,
                      moved: proctoring.isPhoneMoved.value,
                      recording: proctoring.isScreenRecorded.value,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _glassCard(
                  context,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Write your answer',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Obx(() {
                          final pasteLocked = _shouldLockPaste;

                          return Shortcuts(
                            shortcuts: pasteLocked
                                ? const <ShortcutActivator, Intent>{
                                    SingleActivator(
                                      LogicalKeyboardKey.keyV,
                                      control: true,
                                    ): DoNothingAndStopPropagationIntent(),
                                    SingleActivator(
                                      LogicalKeyboardKey.keyV,
                                      meta: true,
                                    ): DoNothingAndStopPropagationIntent(),
                                    SingleActivator(
                                      LogicalKeyboardKey.insert,
                                      shift: true,
                                    ): DoNothingAndStopPropagationIntent(),
                                  }
                                : const <ShortcutActivator, Intent>{},
                            child: Actions(
                              actions: pasteLocked
                                  ? <Type, Action<Intent>>{
                                      DoNothingAndStopPropagationIntent:
                                          CallbackAction<
                                            DoNothingAndStopPropagationIntent
                                          >(
                                            onInvoke: (intent) {
                                              unawaited(
                                                proctoring.clearClipboard(),
                                              );
                                              proctoring.registerViolation(
                                                "Clipboard paste shortcut blocked in essay field.",
                                                penalty: 4,
                                                alert: true,
                                              );
                                              return null;
                                            },
                                          ),
                                    }
                                  : const <Type, Action<Intent>>{},
                              child: TextField(
                                controller: controller.answerCtrl,
                                focusNode: _answerFocusNode,
                                minLines: 6,
                                maxLines: 14,
                                enableInteractiveSelection: !pasteLocked,
                                onTap: () {
                                  if (!pasteLocked) return;
                                  unawaited(proctoring.clearClipboard());
                                },
                                contextMenuBuilder: (context, editableTextState) {
                                  if (pasteLocked) {
                                    proctoring.registerViolation(
                                      "Text selection menu blocked in essay field.",
                                      penalty: 2,
                                      alert: false,
                                    );
                                    return const SizedBox.shrink();
                                  }
                                  return AdaptiveTextSelectionToolbar.editableText(
                                    editableTextState: editableTextState,
                                  );
                                },
                                style: TextStyle(color: cs.onSurface),
                                cursorColor: cs.secondary,
                                decoration: InputDecoration(
                                  hintText: 'Type your answer here manually...',
                                  filled: true,
                                  fillColor: cs.onSurface.withValues(
                                    alpha: 0.05,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: cs.secondary.withValues(
                                        alpha: 0.75,
                                      ),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        Text(
                          'Why keywords matter: lecturers scan for key terms taught in class. Missing them = lost marks.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    controller.answerCtrl.text = '',
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Obx(
                                () => FilledButton(
                                  onPressed: controller.isMarking.value
                                      ? null
                                      : () {
                                          if (_isGradedSession &&
                                              _useProctoring &&
                                              proctoring.integrityScore.value <
                                                  _minIntegrityToMark) {
                                            proctoring.registerViolation(
                                              "Essay marking blocked due to low integrity score.",
                                              penalty: 0,
                                              alert: false,
                                            );
                                            Get.snackbar(
                                              "Integrity check failed",
                                              "Your integrity score is too low for graded essay marking.",
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                            );
                                            return;
                                          }
                                          controller.markNow();
                                        },
                                  child: controller.isMarking.value
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Mark answer'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (res != null) ...[
                  const SizedBox(height: 12),
                  _ResultCard(result: res),
                  const SizedBox(height: 12),
                  _KeywordBreakdown(result: res),
                  const SizedBox(height: 12),
                  _Citations(result: res),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        _returnTheoryResult(controller.result.value!);
                      },
                      child: const Text('Continue Exam'),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _IntegrityStrip extends StatelessWidget {
  const _IntegrityStrip({
    required this.score,
    required this.moved,
    required this.recording,
  });

  final int score;
  final bool moved;
  final bool recording;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final issues = <String>[if (moved) 'Movement', if (recording) 'Recording'];

    return _glassCard(
      context,
      child: Row(
        children: [
          Icon(Icons.security, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issues.isEmpty
                  ? 'Integrity score: $score'
                  : 'Integrity score: $score • ${issues.join(", ")}',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.q});
  final TheoryQuestionModel q;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _glassCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    q.topic,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.secondary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '${q.marks} marks',
                    style: TextStyle(
                      color: cs.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Source: ${q.sourceRef}',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final TheoryMarkResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = result.totalMarks == 0
        ? 0
        : ((result.scoredMarks / result.totalMarks) * 100).round();

    return _glassCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Result', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${result.scoredMarks}/${result.totalMarks}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result.feedback,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeywordBreakdown extends StatelessWidget {
  const _KeywordBreakdown({required this.result});
  final TheoryMarkResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ok = result.keywordChecks.where((k) => k.found).length;
    final total = result.keywordChecks.length;

    return _glassCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keyword analysis ($ok/$total)',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...result.keywordChecks.map(
              (k) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      k.found ? Icons.check_circle : Icons.cancel,
                      color: k.found ? Colors.green : cs.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            k.keyword,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (k.note != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                k.note!,
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Citations extends StatelessWidget {
  const _Citations({required this.result});
  final TheoryMarkResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _glassCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Citations (from lecturer materials)',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...result.citations.map(
              (c) => Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _glassCard(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: cs.onSurface.withValues(alpha: 0.04),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}
