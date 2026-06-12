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
  late final String _sessionType;
  late final String _gradingType;
  late final ExamDeliveryMode _deliveryMode;
  late final bool _useProctoring;
  late final bool _lockCopyPaste;
  late final FocusNode _answerFocusNode;

  bool _ownsProctoringSession = false;

  bool get _isGradedSession => _gradingType == GradingType.graded;
  bool get _shouldLockPaste => _isGradedSession || _lockCopyPaste;

  @override
  void initState() {
    super.initState();
    controller = Get.find<TheoryController>();
    _answerFocusNode = FocusNode();

    final rawArgs = Get.arguments;
    if (rawArgs is Map && rawArgs['question'] is TheoryQuestionModel) {
      q = rawArgs['question'] as TheoryQuestionModel;
      _examMode = rawArgs['examMode'] == true;
      _sessionType =
          (rawArgs['sessionType'] as String?) ?? SessionType.assessment;
      _gradingType =
          (rawArgs['gradingType'] as String?) ?? GradingType.ungraded;
      _deliveryMode = ExamDeliveryModeX.fromRaw(
        rawArgs['deliveryMode']?.toString(),
      );
      _lockCopyPaste = rawArgs['lockCopyPaste'] == true;
    } else {
      q = rawArgs as TheoryQuestionModel;
      _examMode = false;
      _sessionType = SessionType.assessment;
      _gradingType = GradingType.ungraded;
      _deliveryMode = ExamDeliveryMode.centerBased;
      _lockCopyPaste = false;
    }

    _useProctoring =
        _isGradedSession && _deliveryMode == ExamDeliveryMode.remoteProctored;

    proctoring = Get.isRegistered<ProctoringController>()
        ? Get.find<ProctoringController>()
        : Get.put(ProctoringController(), permanent: true);

    if (_useProctoring) {
      final level = _sessionType == SessionType.examination
          ? AssessmentIntegrityLevel.highStakesExam
          : AssessmentIntegrityLevel.gradedAssessment;
      final alreadyActive = proctoring.hasActiveSessionFor(level);
      if (alreadyActive) {
        proctoring.attachSessionCallbacks(
          onSessionTerminated: _handleSessionTermination,
        );
      } else {
        _ownsProctoringSession = true;
        unawaited(
          proctoring.startSession(
            level: level,
            onSessionTerminated: _handleSessionTermination,
          ),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadQuestion(q);
      if (_shouldLockPaste) unawaited(proctoring.clearClipboard());
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
          'Your answer has not been marked yet. Leaving returns to the section list.',
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

    if (leave == true) Get.back(result: null);
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

  void _markAnswer() {
    if (_isGradedSession &&
        _useProctoring &&
        proctoring.integrityScore.value < _minIntegrityToMark) {
      proctoring.registerViolation(
        'Theory marking blocked because integrity score is below threshold.',
        penalty: 0,
        alert: false,
      );
      Get.snackbar(
        'Integrity check failed',
        'Your integrity score is too low for graded theory marking.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    controller.markNow();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_leaveTheorySection());
      },
      child: Scaffold(
        body: LuxuryScaffold(
          safeArea: true,
          child: Obx(() {
            final res = controller.result.value;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                _TheoryHero(
                  courseCode: q.courseCode,
                  graded: _isGradedSession,
                  proctored: _useProctoring,
                  onBack: _leaveTheorySection,
                ),
                const SizedBox(height: 12),
                _QuestionCard(q: q),
                const SizedBox(height: 12),
                if (_useProctoring)
                  Obx(
                    () => _IntegrityStrip(
                      score: proctoring.integrityScore.value,
                      moved: proctoring.isPhoneMoved.value,
                      recording: proctoring.isScreenRecorded.value,
                    ),
                  )
                else
                  const _NormalStrip(),
                const SizedBox(height: 12),
                _AnswerCard(
                  controller: controller,
                  focusNode: _answerFocusNode,
                  pasteLocked: _shouldLockPaste,
                  onPasteBlocked: () {
                    unawaited(proctoring.clearClipboard());
                    if (_shouldLockPaste) {
                      proctoring.registerViolation(
                        'Paste shortcut blocked in theory answer field.',
                        penalty: 4,
                        alert: true,
                      );
                    }
                  },
                  onClear: () => controller.answerCtrl.clear(),
                  onMark: _markAnswer,
                ),
                if (res != null) ...[
                  const SizedBox(height: 12),
                  _ResultCard(result: res),
                  const SizedBox(height: 12),
                  _KeywordBreakdown(result: res),
                  const SizedBox(height: 12),
                  _Citations(result: res),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _returnTheoryResult(res),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_examMode ? 'Continue' : 'Finish'),
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

class _TheoryHero extends StatelessWidget {
  const _TheoryHero({
    required this.courseCode,
    required this.graded,
    required this.proctored,
    required this.onBack,
  });

  final String courseCode;
  final bool graded;
  final bool proctored;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.96),
            cs.secondary.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$courseCode Theory',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  graded
                      ? 'Graded theory answer with lecturer-style feedback.'
                      : 'Ungraded normal practice answer.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(label: proctored ? 'Proctored' : 'Normal'),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: q.topic, color: cs.primary),
              _Chip(label: '${q.marks} marks', color: cs.secondary),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Source: ${q.sourceRef}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
    final issues = <String>[if (moved) 'Movement', if (recording) 'Recording'];
    return _InfoStrip(
      icon: Icons.security_rounded,
      title: 'Integrity score: $score',
      subtitle: issues.isEmpty ? 'No active warning.' : issues.join(', '),
    );
  }
}

class _NormalStrip extends StatelessWidget {
  const _NormalStrip();

  @override
  Widget build(BuildContext context) {
    return const _InfoStrip(
      icon: Icons.school_outlined,
      title: 'Normal ungraded assessment',
      subtitle: 'Camera, audio, and device checks are not active.',
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _glassCard(
      context,
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.controller,
    required this.focusNode,
    required this.pasteLocked,
    required this.onPasteBlocked,
    required this.onClear,
    required this.onMark,
  });

  final TheoryController controller;
  final FocusNode focusNode;
  final bool pasteLocked;
  final VoidCallback onPasteBlocked;
  final VoidCallback onClear;
  final VoidCallback onMark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final answerHeight = (MediaQuery.sizeOf(context).height * 0.34).clamp(
      220.0,
      380.0,
    );
    return _glassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Write your answer',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              if (pasteLocked)
                _Chip(label: 'Paste locked', color: cs.primary),
            ],
          ),
          const SizedBox(height: 10),
          Shortcuts(
            shortcuts: pasteLocked
                ? const <ShortcutActivator, Intent>{
                    SingleActivator(LogicalKeyboardKey.keyV, control: true):
                        DoNothingAndStopPropagationIntent(),
                    SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                        DoNothingAndStopPropagationIntent(),
                    SingleActivator(LogicalKeyboardKey.insert, shift: true):
                        DoNothingAndStopPropagationIntent(),
                  }
                : const <ShortcutActivator, Intent>{},
            child: Actions(
              actions: pasteLocked
                  ? <Type, Action<Intent>>{
                      DoNothingAndStopPropagationIntent:
                          CallbackAction<DoNothingAndStopPropagationIntent>(
                        onInvoke: (intent) {
                          onPasteBlocked();
                          return null;
                        },
                      ),
                    }
                  : const <Type, Action<Intent>>{},
              child: SizedBox(
                height: answerHeight,
                child: TextField(
                  controller: controller.answerCtrl,
                  focusNode: focusNode,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  enableInteractiveSelection: !pasteLocked,
                  onTap: () {
                    if (pasteLocked) onPasteBlocked();
                  },
                  contextMenuBuilder: (context, editableTextState) {
                    if (pasteLocked) return const SizedBox.shrink();
                    return AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                  style: TextStyle(
                    color: cs.onSurface,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: cs.primary,
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: cs.primary, width: 1.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Use clear paragraphs and include the exact lecturer keywords where possible.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => FilledButton.icon(
                    onPressed: controller.isMarking.value ? null : onMark,
                    icon: controller.isMarking.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      controller.isMarking.value ? 'Marking...' : 'Submit answer',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Result', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${result.scoredMarks}/${result.totalMarks}',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 12),
              _Chip(label: '$pct%', color: cs.primary),
            ],
          ),
          const SizedBox(height: 10),
          Text(result.feedback),
        ],
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
                color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    k.found ? Icons.check_circle : Icons.cancel,
                    color: k.found ? Colors.green : cs.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      k.keyword,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Citations extends StatelessWidget {
  const _Citations({required this.result});
  final TheoryMarkResult result;

  @override
  Widget build(BuildContext context) {
    return _glassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lecturer material reference',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...result.citations.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _glassCard(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
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
