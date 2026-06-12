import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/whiteboard/whiteboard_editor_sheet.dart';
import '../../../core/whiteboard/whiteboard_models.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/graded_session_template_service.dart';
import '../../exam/controller/exam_controller.dart';
import '../../proctoring/controller/proctoring_controller.dart';
import '../controller/cbt_controller.dart';

class CBTTakeView extends StatefulWidget {
  const CBTTakeView({super.key});

  @override
  State<CBTTakeView> createState() => _CBTTakeViewState();
}

class _CBTTakeViewState extends State<CBTTakeView> {
  late final CBTController controller;
  late final Map args;
  late final ProctoringController proctoring;
  late final bool _examMode;
  late final ExamDeliveryMode _deliveryMode;
  late final bool _useProctoring;
  late final String _gradingType;
  late final String _questionSource;
  late final bool _whiteboardEnabled;
  late final bool _whiteboardRequired;
  late final String? _whiteboardPrompt;
  ExamController? _examController;
  List<WhiteboardStroke> _localWhiteboardStrokes = <WhiteboardStroke>[];
  bool _ownsProctoringSession = false;
  bool _autoSubmitted = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CBTController>();
    args = (Get.arguments ?? {}) as Map;
    _examMode = args['examMode'] == true;
    _gradingType = (args['gradingType'] as String?) ?? GradingType.ungraded;
    _questionSource =
        (args['questionSource'] as String?) ?? QuestionSourceType.studentLocal;
    final requestedDeliveryMode = ExamDeliveryModeX.fromRaw(
      args['deliveryMode']?.toString(),
    );
    final courseCode = _argString('courseCode', 'CSC 305');
    final sessionType =
        (args['sessionType'] as String?) ?? SessionType.assessment;
    final isGradedAssessment =
        sessionType == SessionType.assessment &&
        _gradingType == GradingType.graded;
    final backendTemplate =
        courseCode.trim().isEmpty ||
            (_questionSource != QuestionSourceType.lecturerAdmin &&
                _gradingType != GradingType.graded)
        ? null
        : GradedSessionTemplateService.templateFor(
            courseCode: courseCode,
            sessionType: sessionType,
          );
    _deliveryMode = isGradedAssessment
        ? ExamDeliveryMode.remoteProctored
        : (backendTemplate?.deliveryMode ?? requestedDeliveryMode);
    _useProctoring =
        isGradedAssessment ||
        (_examMode && _deliveryMode == ExamDeliveryMode.remoteProctored);
    _whiteboardEnabled = args['whiteboardEnabled'] == true;
    _whiteboardRequired =
        _whiteboardEnabled && args['whiteboardRequired'] == true;
    _whiteboardPrompt = args['whiteboardPrompt']?.toString();

    if (_examMode && Get.isRegistered<ExamController>()) {
      _examController = Get.find<ExamController>();
      _localWhiteboardStrokes = _examController!.whiteboardStrokes.toList();
    }

    proctoring = Get.isRegistered<ProctoringController>()
        ? Get.find<ProctoringController>()
        : Get.put(ProctoringController(), permanent: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_bootstrapSession());
    });
  }

  Future<void> _bootstrapSession() async {
    final courseCode = _argString('courseCode', 'CSC 305');
    final sessionType =
        (args['sessionType'] as String?) ?? SessionType.assessment;
    final isGradedAssessment =
        sessionType == SessionType.assessment &&
        _gradingType == GradingType.graded;

    if (_useProctoring) {
      proctoring.registerExamTimerHooks(
        onPauseTimer: controller.pauseTimer,
        onResumeTimer: controller.resumeTimer,
      );
    }

    if (isGradedAssessment &&
        (!proctoring.shieldActive.value ||
            proctoring.currentLevel.value !=
                AssessmentIntegrityLevel.gradedAssessment)) {
      _ownsProctoringSession = true;
      final verified = await proctoring.startAssessmentSequence(
        '$courseCode-assessment-${DateTime.now().millisecondsSinceEpoch}',
        onSessionTerminated: _handleSessionTermination,
        onAutoSubmit: () async {
          if (_autoSubmitted || !mounted) return;
          _autoSubmitted = true;
          await controller.submit(returnAttempt: _examMode);
        },
      );
      if (!verified) {
        if (mounted) Get.back();
        return;
      }
    }

    controller.start(
      course: _argString('courseCode', 'CSC 305'),
      sessionMode: _argString('mode', 'Timed'),
      sessionTopic: _argString('topic', 'Mixed'),
      sessionQuestions: _argInt('questions', 10),
      sessionMinutes: _argInt('minutes', 12),
      sessionKind: sessionType,
      sessionGradingType: _gradingType,
      sessionQuestionSource: _questionSource,
      sessionDeliveryMode: _deliveryMode,
      sessionWhiteboardEnabled: _whiteboardEnabled,
      sessionWhiteboardRequired: _whiteboardRequired,
      sessionWhiteboardPrompt: _whiteboardPrompt,
      sessionWhiteboardStrokeCount: _whiteboardStrokeCount,
      sessionShuffleQuestions: args['shuffleQuestions'] != false,
      sessionLockCopyPaste: args['lockCopyPaste'] != false,
      sessionCalculatorEnabled: args['calculatorEnabled'] == true,
    );

    if (_examMode) {
      if (_useProctoring &&
          (!proctoring.shieldActive.value ||
              proctoring.currentLevel.value !=
                  AssessmentIntegrityLevel.highStakesExam)) {
        _ownsProctoringSession = true;
        await proctoring.startSession(
          level: AssessmentIntegrityLevel.highStakesExam,
          onSessionTerminated: _handleSessionTermination,
        );
      }
      return;
    }

    if (!_useProctoring) {
      return;
    }

    _ownsProctoringSession = true;
    await proctoring.startSession(
      level: AssessmentIntegrityLevel.objectiveQuiz,
      onSessionTerminated: _handleSessionTermination,
      onAutoSubmit: () async {
        if (_autoSubmitted || !mounted) return;
        _autoSubmitted = true;
        await controller.submit(returnAttempt: _examMode);
      },
    );
  }

  String _argString(String key, String fallback) {
    final value = args[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  int _argInt(String key, int fallback) {
    final raw = args[key];
    if (raw is int && raw > 0) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  @override
  void dispose() {
    if (_useProctoring) {
      proctoring.clearExamTimerHooks();
    }
    if (_ownsProctoringSession) {
      unawaited(proctoring.stopSession(silent: true));
    }
    super.dispose();
  }

  void _handleSessionTermination() {
    if (!mounted) return;
    if (_examMode) {
      _leaveAttempt();
      return;
    }
    if (_autoSubmitted) return;
    _autoSubmitted = true;
    unawaited(controller.submit(returnAttempt: _examMode));
  }

  Future<void> _leaveAttempt() async {
    if (!_examMode) {
      Get.back();
      return;
    }

    final leave = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leave objective section?'),
        content: const Text(
          'This section has not been submitted. Leaving returns to the exam section list.',
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

  List<WhiteboardStroke> get _whiteboardStrokes {
    if (_examController != null) {
      return _examController!.whiteboardStrokes.toList();
    }
    return _localWhiteboardStrokes;
  }

  int get _whiteboardStrokeCount {
    return _whiteboardStrokes.where((s) => s.isUsable).length;
  }

  bool get _isWhiteboardMissingRequired {
    return _whiteboardRequired && _whiteboardStrokeCount == 0;
  }

  Future<void> _openWhiteboard() async {
    if (!_whiteboardEnabled) return;

    final strokes = await Get.bottomSheet<List<WhiteboardStroke>>(
      WhiteboardEditorSheet(
        title: 'Assessment Whiteboard',
        prompt: _whiteboardPrompt,
        initialStrokes: _whiteboardStrokes,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );

    if (strokes == null) return;

    if (_examController != null) {
      _examController!.saveWhiteboardStrokes(strokes);
    } else {
      _localWhiteboardStrokes = List<WhiteboardStroke>.from(strokes);
    }
    controller.setWhiteboardStrokeCount(_whiteboardStrokeCount);
    setState(() {});
  }

  Future<void> _submitWithWhiteboardGuard() async {
    if (_whiteboardEnabled && _isWhiteboardMissingRequired) {
      Get.snackbar(
        'Whiteboard required',
        'This assessment requires a whiteboard diagram before submission.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await controller.submit(returnAttempt: _examMode);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_leaveAttempt());
      },
      child: Scaffold(
        body: LuxuryScaffold(
          safeArea: true,
          child: Obx(() {
            final questions = controller.questions;
            final hasQuestions = questions.isNotEmpty;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                _HeroHeader(
                  courseCode: _argString('courseCode', 'CSC 305'),
                  index: controller.index.value,
                  total: questions.length,
                  mode: controller.mode,
                  secondsLeft: controller.secondsLeft.value,
                  paused: controller.isPaused.value,
                  onBack: _leaveAttempt,
                ),
                const SizedBox(height: 12),
                _DeliveryModeStrip(useProctoring: _useProctoring),
                const SizedBox(height: 12),
                if (_useProctoring) ...[
                  Obx(
                    () => _IntegrityStrip(
                      score: proctoring.integrityScore.value,
                      moved: proctoring.isPhoneMoved.value,
                      recording: proctoring.isScreenRecorded.value,
                      paused: proctoring.isExamPaused.value,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_whiteboardEnabled) ...[
                  _WhiteboardStrip(
                    required: _whiteboardRequired,
                    prompt: _whiteboardPrompt,
                    strokeCount: _whiteboardStrokeCount,
                    onOpen: _openWhiteboard,
                  ),
                  const SizedBox(height: 12),
                ],

                if (!hasQuestions)
                  _glassCard(
                    context,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz_outlined, size: 40, color: cs.primary),
                        const SizedBox(height: 10),
                        const Text(
                          'No questions available',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try a different topic or course.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Go back'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _QuestionCard(q: controller.current),
                  const SizedBox(height: 12),

                  ...List.generate(controller.current.options.length, (i) {
                    final selected = controller.selectedIndex.value == i;
                    return _OptionTile(
                      label: String.fromCharCode(65 + i),
                      text: controller.current.options[i],
                      selected: selected,
                      onTap: () => controller.pick(i),
                    );
                  }),

                  const SizedBox(height: 12),
                  if (controller.current.sourceLabel != null)
                    Text(
                      'Source: ${controller.current.sourceLabel}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.index.value == 0
                              ? null
                              : controller.prev,
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              controller.index.value == questions.length - 1
                              ? _submitWithWhiteboardGuard
                              : controller.next,
                          child: Text(
                            controller.index.value == questions.length - 1
                                ? 'Submit'
                                : 'Next',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _submitWithWhiteboardGuard,
                    child: Text(
                      'End attempt',
                      style: TextStyle(color: cs.error),
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
    required this.paused,
  });

  final int score;
  final bool moved;
  final bool recording;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final issues = <String>[
      if (moved) 'Movement',
      if (recording) 'Recording',
      if (paused) 'Timer paused',
    ];

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

class _DeliveryModeStrip extends StatelessWidget {
  const _DeliveryModeStrip({required this.useProctoring});

  final bool useProctoring;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = useProctoring ? cs.primary : cs.onSurface;
    final icon = useProctoring
        ? Icons.security_outlined
        : Icons.apartment_outlined;
    final text = useProctoring
        ? 'Remote proctored exam. Device checks required.'
        : 'Distance self-practice. Device proctoring is off.';

    return _glassCard(
      context,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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

class _WhiteboardStrip extends StatelessWidget {
  const _WhiteboardStrip({
    required this.required,
    required this.prompt,
    required this.strokeCount,
    required this.onOpen,
  });

  final bool required;
  final String? prompt;
  final int strokeCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSketch = strokeCount > 0;

    return _glassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  required
                      ? 'Whiteboard diagram is required.'
                      : 'Whiteboard diagram is available.',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (hasSketch ? cs.primary : cs.secondary).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hasSketch ? 'Added' : 'Pending',
                  style: TextStyle(
                    color: hasSketch ? cs.primary : cs.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (prompt != null && prompt!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              prompt!.trim(),
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                hasSketch
                    ? '$strokeCount stroke(s) captured'
                    : 'No drawing captured yet',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.edit_outlined),
                label: Text(hasSketch ? 'Edit whiteboard' : 'Open whiteboard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.courseCode,
    required this.index,
    required this.total,
    required this.mode,
    required this.secondsLeft,
    required this.paused,
    required this.onBack,
  });

  final String courseCode;
  final int index;
  final int total;
  final String mode;
  final int secondsLeft;
  final bool paused;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.80),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CBT Practice',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$courseCode - Q ${index + 1}/$total',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (mode != 'Untimed')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: paused
                    ? const Color(0xFFD32F2F).withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: Text(
                paused ? 'PAUSED' : '$mm:$ss',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
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
  final dynamic q;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _glassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.topic,
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            q.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected
        ? cs.primary.withValues(alpha: 0.12)
        : cs.onSurface.withValues(alpha: 0.03);
    final border = selected
        ? cs.primary.withValues(alpha: 0.22)
        : cs.onSurface.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
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
