import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/assessment_calculator.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/graded_session_template_service.dart';
import '../../proctoring/controller/proctoring_controller.dart';
import '../controller/cbt_controller.dart';

class CBTTakeView extends StatefulWidget {
  const CBTTakeView({super.key});

  @override
  State<CBTTakeView> createState() => _CBTTakeViewState();
}

class _CBTTakeViewState extends State<CBTTakeView> {
  late final CBTController c;
  late final Map args;
  late final ProctoringController p;
  late final bool examMode;
  late final bool useProctoring;
  bool ownsSession = false;
  bool autoSubmitted = false;

  @override
  void initState() {
    super.initState();
    c = Get.find<CBTController>();
    args = (Get.arguments ?? {}) as Map;
    examMode = args['examMode'] == true;
    final gradingType = (args['gradingType'] as String?) ?? GradingType.ungraded;
    final sessionType = (args['sessionType'] as String?) ?? SessionType.assessment;
    final questionSource = (args['questionSource'] as String?) ?? QuestionSourceType.studentLocal;
    final courseCode = _s('courseCode', 'CSC 305');
    final backendTemplate = questionSource == QuestionSourceType.lecturerAdmin || gradingType == GradingType.graded
        ? GradedSessionTemplateService.templateFor(courseCode: courseCode, sessionType: sessionType)
        : null;
    final delivery = gradingType == GradingType.graded
        ? ExamDeliveryMode.remoteProctored
        : (backendTemplate?.deliveryMode ?? ExamDeliveryModeX.fromRaw(args['deliveryMode']?.toString()));
    useProctoring = gradingType == GradingType.graded || (examMode && delivery == ExamDeliveryMode.remoteProctored);
    p = Get.isRegistered<ProctoringController>() ? Get.find<ProctoringController>() : Get.put(ProctoringController(), permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start(delivery, gradingType, questionSource, sessionType)));
  }

  Future<void> _start(ExamDeliveryMode delivery, String gradingType, String questionSource, String sessionType) async {
    if (useProctoring) p.registerExamTimerHooks(onPauseTimer: c.pauseTimer, onResumeTimer: c.resumeTimer);
    if (gradingType == GradingType.graded && (!p.shieldActive.value || p.currentLevel.value != AssessmentIntegrityLevel.gradedAssessment)) {
      ownsSession = true;
      final ok = await p.startAssessmentSequence('${_s('courseCode', 'CSC 305')}-${DateTime.now().millisecondsSinceEpoch}', onSessionTerminated: _terminated, onAutoSubmit: () async => _autoSubmit());
      if (!ok) {
        if (mounted) Get.back<void>();
        return;
      }
    }
    c.start(
      course: _s('courseCode', 'CSC 305'),
      sessionMode: _s('mode', 'Timed'),
      sessionTopic: _s('topic', 'Mixed'),
      sessionQuestions: _i('questions', 10),
      sessionMinutes: _i('minutes', 12),
      sessionKind: sessionType,
      sessionGradingType: gradingType,
      sessionQuestionSource: questionSource,
      sessionDeliveryMode: delivery,
      sessionShuffleQuestions: args['shuffleQuestions'] != false,
      sessionLockCopyPaste: args['lockCopyPaste'] == true,
      sessionCalculatorEnabled: true,
    );
    if (examMode && useProctoring && (!p.shieldActive.value || p.currentLevel.value != AssessmentIntegrityLevel.highStakesExam)) {
      ownsSession = true;
      await p.startSession(level: AssessmentIntegrityLevel.highStakesExam, onSessionTerminated: _terminated);
    }
  }

  String _s(String key, String fallback) {
    final v = args[key]?.toString().trim();
    return v == null || v.isEmpty ? fallback : v;
  }

  int _i(String key, int fallback) {
    final raw = args[key];
    if (raw is int && raw > 0) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  Future<void> _autoSubmit() async {
    if (autoSubmitted || !mounted) return;
    autoSubmitted = true;
    await c.submit(returnAttempt: examMode);
  }

  void _terminated() {
    if (!mounted) return;
    if (examMode) {
      Get.back(result: null);
    } else {
      unawaited(_autoSubmit());
    }
  }

  @override
  void dispose() {
    if (useProctoring) p.clearExamTimerHooks();
    if (ownsSession) unawaited(p.stopSession(silent: true));
    super.dispose();
  }

  Future<void> _leave() async {
    if (!examMode) {
      Get.back<void>();
      return;
    }
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Leave section?'),
      content: const Text('Your answers are auto-saved. The section is recorded only after submission.'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Stay')),
        FilledButton(onPressed: () => Get.back(result: true), child: const Text('Leave')),
      ],
    ));
    if (ok == true) Get.back(result: null);
  }

  Future<void> _submitReview() async {
    c.saveDraft();
    final total = c.questions.length;
    final answered = c.answers.length;
    final marked = c.markedForReview.length;
    final unanswered = (total - answered).clamp(0, total).toInt();
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Final submit review'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _summary('Total questions', '$total'),
        _summary('Answered', '$answered'),
        _summary('Unanswered', '$unanswered'),
        _summary('Marked for review', '$marked'),
        if (useProctoring) _summary('Integrity score', '${p.integrityScore.value}'),
        const SizedBox(height: 8),
        Text(unanswered > 0 || marked > 0 ? 'You still have items to review. Submit only when you are sure.' : 'All questions are answered.'),
      ]),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Review')),
        FilledButton(onPressed: () => Get.back(result: true), child: const Text('Submit now')),
      ],
    ));
    if (ok == true) await c.submit(returnAttempt: examMode);
  }

  Widget _summary(String a, String b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: Text(a, style: const TextStyle(fontWeight: FontWeight.w700))), Text(b, style: const TextStyle(fontWeight: FontWeight.w900))]));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        body: LuxuryScaffold(
          safeArea: true,
          child: Obx(() {
            final total = c.questions.length;
            final answered = c.answers.length;
            final remaining = (total - answered).clamp(0, total).toInt();
            return ListView(padding: const EdgeInsets.all(16), children: [
              _Header(courseCode: _s('courseCode', 'CSC 305'), index: c.index.value, total: total, seconds: c.secondsLeft.value, paused: c.isPaused.value, onBack: _leave),
              const SizedBox(height: 12),
              _card(context, child: Wrap(spacing: 10, runSpacing: 10, children: [
                _pill(context, Icons.check_circle_outline, 'Answered $answered/$total'),
                _pill(context, Icons.pending_actions_rounded, 'Remaining $remaining'),
                _pill(context, Icons.outlined_flag_rounded, 'Review ${c.markedForReview.length}'),
                _pill(context, Icons.save_alt_rounded, c.lastAutoSavedAt.value == null ? 'Autosave ready' : 'Autosaved'),
                const AssessmentCalculatorButton(),
              ])),
              const SizedBox(height: 12),
              if (total == 0)
                _card(context, child: const Text('No questions available', style: TextStyle(fontWeight: FontWeight.w900)))
              else
                LayoutBuilder(builder: (context, box) {
                  final main = _QuestionArea(onSubmit: _submitReview);
                  final side = _SidePanel(useProctoring: useProctoring, p: p, onSubmit: _submitReview);
                  if (box.maxWidth < 980) return Column(children: [side, const SizedBox(height: 12), main]);
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: main), const SizedBox(width: 14), SizedBox(width: 320, child: side)]);
                }),
            ]);
          }),
        ),
      ),
    );
  }
}

class _QuestionArea extends StatelessWidget {
  const _QuestionArea({required this.onSubmit});
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    final c = Get.find<CBTController>();
    return Obx(() {
      final q = c.current;
      final marked = c.markedForReview.contains(q.id);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(q.topic, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(q.question, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, height: 1.3))])),
        const SizedBox(height: 12),
        ...List.generate(q.options.length, (i) => _OptionTile(label: String.fromCharCode(65 + i), text: q.options[i], selected: c.selectedIndex.value == i, onTap: () => c.pick(i))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: c.index.value == 0 ? null : c.prev, child: const Text('Previous'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: c.index.value == c.questions.length - 1 ? onSubmit : c.next, child: Text(c.index.value == c.questions.length - 1 ? 'Submit section' : 'Next'))),
        ]),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.spaceBetween, spacing: 8, children: [
          OutlinedButton.icon(onPressed: c.toggleCurrentReview, icon: Icon(marked ? Icons.flag_rounded : Icons.outlined_flag_rounded), label: Text(marked ? 'Unmark review' : 'Mark for review')),
          TextButton.icon(onPressed: onSubmit, icon: const Icon(Icons.stop_circle_outlined), label: const Text('End attempt')),
        ]),
      ]);
    });
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.useProctoring, required this.p, required this.onSubmit});
  final bool useProctoring;
  final ProctoringController p;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    final c = Get.find<CBTController>();
    return Column(children: [
      _QuestionNavigator(c: c),
      const SizedBox(height: 12),
      _card(context, child: useProctoring ? Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Protected status', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), _check('Camera', p.examStartupScanCompleted.value), _check('Timer', !p.isExamPaused.value), _check('Integrity score ${p.integrityScore.value}', p.integrityScore.value >= 70), _check('Incidents ${p.violationCount.value}', p.violationCount.value == 0)])) : const Text('Normal mode\nNo camera or audio checks are active.', style: TextStyle(fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      _card(context, child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.assignment_turned_in_rounded), label: const Text('Final submit review')))),
    ]);
  }

  Widget _check(String text, bool ok) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [Icon(ok ? Icons.check_circle : Icons.error, color: ok ? Colors.green : Colors.orange, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)))]));
}

class _QuestionNavigator extends StatelessWidget {
  const _QuestionNavigator({required this.c});
  final CBTController c;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _card(context, child: Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Question navigator', style: TextStyle(fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: List.generate(c.questions.length, (i) {
        final q = c.questions[i];
        final current = c.index.value == i;
        final answered = c.answers.containsKey(q.id);
        final marked = c.markedForReview.contains(q.id);
        final bg = current ? cs.primary : marked ? Colors.orange.withValues(alpha: 0.18) : answered ? Colors.green.withValues(alpha: 0.18) : cs.surfaceContainerHighest.withValues(alpha: 0.55);
        final fg = current ? cs.onPrimary : cs.onSurface;
        return InkWell(onTap: () => c.jumpTo(i), borderRadius: BorderRadius.circular(12), child: Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Stack(clipBehavior: Clip.none, children: [Center(child: Text('${i + 1}', style: TextStyle(color: fg, fontWeight: FontWeight.w900))), if (marked) const Positioned(right: -8, top: -8, child: Icon(Icons.flag_rounded, color: Colors.orange, size: 14))])));
      })),
      const SizedBox(height: 8),
      const Text('Green answered • Flag review • Blue current', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ])));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.courseCode, required this.index, required this.total, required this.seconds, required this.paused, required this.onBack});
  final String courseCode; final int index; final int total; final int seconds; final bool paused; final VoidCallback onBack;
  @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; final mm = (seconds ~/ 60).toString().padLeft(2, '0'); final ss = (seconds % 60).toString().padLeft(2, '0'); return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [cs.primary, cs.secondary])), child: Row(children: [IconButton.filledTonal(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Objective section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)), Text('$courseCode • Question ${total == 0 ? 0 : index + 1}/$total', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w600))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: paused ? Colors.red : Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)), child: Text(paused ? 'PAUSED' : '$mm:$ss', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))])); }
}

class _OptionTile extends StatelessWidget { const _OptionTile({required this.label, required this.text, required this.selected, required this.onTap}); final String label; final String text; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: selected ? cs.primary.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.06))), child: Row(children: [CircleAvatar(backgroundColor: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.10), child: Text(label, style: TextStyle(color: selected ? Colors.white : cs.onSurface, fontWeight: FontWeight.w900))), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.25)))])))); } }

Widget _pill(BuildContext context, IconData icon, String text) { final cs = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: cs.primary), const SizedBox(width: 6), Text(text, style: const TextStyle(fontWeight: FontWeight.w800))])); }
Widget _card(BuildContext context, {required Widget child}) { final cs = Theme.of(context).colorScheme; return ClipRRect(borderRadius: BorderRadius.circular(20), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))), child: child))); }
