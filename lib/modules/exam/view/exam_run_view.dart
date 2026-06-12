import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/whiteboard/whiteboard_editor_sheet.dart';
import '../../../core/whiteboard/whiteboard_models.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/cbt_models.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/sample_exam_service.dart';
import '../../proctoring/controller/proctoring_controller.dart';
import '../controller/exam_controller.dart';

class ExamRunView extends StatefulWidget {
  const ExamRunView({super.key});

  @override
  State<ExamRunView> createState() => _ExamRunViewState();
}

class _ExamRunViewState extends State<ExamRunView> {
  late final ExamConfig cfg;
  late final ExamController ctrl;
  late final ProctoringController proctoring;
  bool _ownsProctoringSession = false;

  bool get _useProctoring => cfg.isGraded && cfg.isRemoteProctored;

  @override
  void initState() {
    super.initState();
    cfg = Get.arguments as ExamConfig;
    ctrl = Get.find<ExamController>();
    proctoring = Get.isRegistered<ProctoringController>()
        ? Get.find<ProctoringController>()
        : Get.put(ProctoringController(), permanent: true);

    if (_useProctoring) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (proctoring.hasActiveSessionFor(AssessmentIntegrityLevel.highStakesExam)) {
          proctoring.attachSessionCallbacks(onSessionTerminated: _handleSessionTermination);
          if (proctoring.examStartupScanCompleted.value) {
            proctoring.armExamMonitoring();
          }
          return;
        }
        _ownsProctoringSession = true;
        unawaited(
          proctoring.startSession(
            level: AssessmentIntegrityLevel.highStakesExam,
            onSessionTerminated: _handleSessionTermination,
          ).then((_) {
            if (proctoring.examStartupScanCompleted.value) {
              proctoring.armExamMonitoring();
            }
          }),
        );
      });
    }
  }

  @override
  void dispose() {
    if (_ownsProctoringSession) {
      unawaited(proctoring.stopSession(silent: true));
    }
    super.dispose();
  }

  List<String> get _sectionOrder => const [
        ExamSectionType.objective,
        ExamSectionType.fillBlank,
        ExamSectionType.theory,
      ];

  Set<String> get _doneSections => ctrl.sectionScores.map((e) => e.sectionType).toSet();

  String? get _nextSection {
    for (final section in _sectionOrder) {
      if (cfg.sections.contains(section) && !_doneSections.contains(section)) {
        return section;
      }
    }
    return null;
  }

  bool get _hasAnySubmittedSection => ctrl.sectionScores.isNotEmpty;

  Future<void> _startNextSection() async {
    final section = _nextSection;
    if (section == null) {
      await _finishExam();
      return;
    }
    await _startSection(section);
  }

  Future<void> _startSection(String section) async {
    if (!cfg.sections.contains(section)) return;
    if (_doneSections.contains(section)) return;

    if (section == ExamSectionType.objective) {
      final res = await Get.toNamed(
        '/cbt/take',
        arguments: {
          'courseCode': cfg.courseCode,
          'mode': cfg.mode == ExamMode.practice ? 'Untimed' : 'Timed',
          'topic': cfg.topic == 'WeakOnly' ? 'Mixed' : cfg.topic,
          'questions': cfg.objectiveQuestions,
          'minutes': cfg.mode == ExamMode.practice
              ? 20
              : (cfg.durationMinutes ~/ 2).clamp(10, 90),
          'examMode': true,
          'sessionType': cfg.sessionType,
          'gradingType': cfg.gradingType,
          'deliveryMode': cfg.deliveryMode.raw,
          'questionSource': cfg.questionSource,
          'whiteboardEnabled': cfg.whiteboardEnabled,
          'whiteboardRequired': cfg.whiteboardRequired,
          'whiteboardPrompt': cfg.whiteboardPrompt,
          'enabledFormats': cfg.enabledFormats.map((format) => format.raw).toList(),
          'demoMode': cfg.securityPolicy.demoMode,
          'shuffleQuestions': cfg.securityPolicy.shuffleQuestions,
          'lockCopyPaste': cfg.securityPolicy.lockCopyPaste,
          'calculatorEnabled': cfg.securityPolicy.calculatorEnabled,
        },
      );
      if (res is CBTAttemptModel) {
        ctrl.addSectionScore(
          ExamSectionScore(
            sectionType: ExamSectionType.objective,
            totalMarks: res.totalQuestions,
            scoredMarks: res.correct,
            extra: {'cbtAttemptId': res.id},
          ),
        );
      }
      return;
    }

    if (section == ExamSectionType.fillBlank) {
      final out = await Get.toNamed('/fillblank/start', arguments: cfg);
      if (out is Map && out['section'] == 'FILL_BLANK') {
        ctrl.addSectionScore(
          ExamSectionScore(
            sectionType: ExamSectionType.fillBlank,
            totalMarks: (out['totalMarks'] ?? 0) as int,
            scoredMarks: (out['scoredMarks'] ?? 0) as int,
            extra: (out['extra'] ?? {}) as Map<String, dynamic>,
          ),
        );
      }
      return;
    }

    if (section == ExamSectionType.theory) {
      final tq = SampleExamService.theoryQuestion(
        courseCode: cfg.courseCode,
        topic: cfg.topic,
      );
      final out = await Get.toNamed(
        '/theory/practice',
        arguments: {
          'question': tq,
          'examMode': true,
          'sessionType': cfg.sessionType,
          'gradingType': cfg.gradingType,
          'deliveryMode': cfg.deliveryMode.raw,
          'whiteboardEnabled': cfg.whiteboardEnabled,
          'whiteboardRequired': cfg.whiteboardRequired,
          'whiteboardPrompt': cfg.whiteboardPrompt,
          'enabledFormats': cfg.enabledFormats.map((format) => format.raw).toList(),
          'demoMode': cfg.securityPolicy.demoMode,
          'shuffleQuestions': cfg.securityPolicy.shuffleQuestions,
          'lockCopyPaste': cfg.securityPolicy.lockCopyPaste,
          'calculatorEnabled': cfg.securityPolicy.calculatorEnabled,
        },
      );
      if (out is Map && out['section'] == 'THEORY') {
        ctrl.addSectionScore(
          ExamSectionScore(
            sectionType: ExamSectionType.theory,
            totalMarks: (out['totalMarks'] ?? 0) as int,
            scoredMarks: (out['scoredMarks'] ?? 0) as int,
            extra: (out['extra'] ?? {}) as Map<String, dynamic>,
          ),
        );
      }
    }
  }

  Future<void> _finishExam() async {
    if (cfg.requiresWhiteboard && !ctrl.hasWhiteboardSketch) {
      Get.snackbar(
        'Whiteboard required',
        'This ${_sessionLabel(cfg.sessionType).toLowerCase()} requires a submitted diagram before final submission.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final pending = cfg.sections.where((s) => !_doneSections.contains(s)).toList();
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text(pending.isEmpty ? 'Submit ${_sessionLabel(cfg.sessionType)}?' : 'End and submit now?'),
        content: Text(
          pending.isEmpty
              ? 'All enabled sections have been completed. Submit your ${_sessionLabel(cfg.sessionType).toLowerCase()} now?'
              : 'You still have ${pending.length} section${pending.length == 1 ? '' : 's'} not completed. Submit only the completed work now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Continue working'),
          ),
          FilledButton(
            onPressed: _hasAnySubmittedSection ? () => Get.back(result: true) : null,
            child: const Text('Submit now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final result = ctrl.finalize();
    Get.offNamed('/exam/result', arguments: result);
  }

  void _handleSessionTermination() {
    if (!mounted) return;
    final result = ctrl.finalize();
    Get.offNamed('/exam/result', arguments: result);
  }

  Future<void> _openWhiteboard() async {
    final strokes = await Get.bottomSheet<List<WhiteboardStroke>>(
      WhiteboardEditorSheet(
        title: '${_sessionLabel(cfg.sessionType)} Whiteboard',
        prompt: cfg.whiteboardPrompt,
        initialStrokes: ctrl.whiteboardStrokes.toList(),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
    if (strokes == null) return;
    ctrl.saveWhiteboardStrokes(strokes);
  }

  String _sectionTitle(String section) {
    switch (section) {
      case ExamSectionType.objective:
        return 'Objective / CBT';
      case ExamSectionType.fillBlank:
        return 'Fill in the blank';
      case ExamSectionType.theory:
        return 'Theory / Essay';
      default:
        return section;
    }
  }

  String _sessionLabel(String type) {
    return type == SessionType.assessment ? 'Assessment' : 'Examination';
  }

  String _formatSummary() {
    if (cfg.enabledFormats.isEmpty) return cfg.sections.map(_sectionTitle).join(', ');
    return cfg.enabledFormats.map((format) => format.label).join(', ');
  }

  String _securitySummary() {
    final policy = cfg.securityPolicy;
    return [
      cfg.isRemoteProctored ? 'remote proctored' : 'normal mode',
      policy.shuffleQuestions ? 'shuffled questions' : 'fixed order',
      policy.lockCopyPaste ? 'copy/paste locked' : 'copy/paste allowed',
      if (policy.calculatorEnabled) 'calculator enabled',
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _RunHero(
                title: '${cfg.courseCode} - ${_sessionLabel(cfg.sessionType)}',
                subtitle: _useProctoring
                    ? 'Protected examination workspace. Start any pending section, then submit when ready.'
                    : 'Normal assessment workspace. Start sections and submit when ready.',
                onBack: () => Get.back<void>(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (_useProctoring)
                    Obx(
                      () => _StatusCard(
                        icon: Icons.security_rounded,
                        title: 'Integrity score: ${proctoring.integrityScore.value}',
                        subtitle: proctoring.isExamPaused.value
                            ? 'Exam paused for verification.'
                            : 'Camera, audio, screen, and device checks are active.',
                      ),
                    )
                  else
                    _StatusCard(
                      icon: Icons.school_outlined,
                      title: 'Normal mode',
                      subtitle: 'No camera or audio proctoring is active.',
                    ),
                  const SizedBox(height: 12),
                  _StatusCard(
                    icon: Icons.tune_rounded,
                    title: 'Session plan',
                    subtitle: 'Formats: ${_formatSummary()}\nSecurity: ${_securitySummary()}',
                  ),
                  if (cfg.whiteboardEnabled) ...[
                    const SizedBox(height: 12),
                    Obx(
                      () => _WhiteboardCard(
                        required: cfg.whiteboardRequired,
                        prompt: cfg.whiteboardPrompt,
                        strokeCount: ctrl.whiteboardStrokes.length,
                        onOpen: _openWhiteboard,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Obx(() {
                    final done = _doneSections;
                    return Column(
                      children: _sectionOrder
                          .where(cfg.sections.contains)
                          .map(
                            (section) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SectionTile(
                                title: _sectionTitle(section),
                                done: done.contains(section),
                                onStart: done.contains(section)
                                    ? null
                                    : () => _startSection(section),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }),
                  const SizedBox(height: 14),
                  Obx(() {
                    final next = _nextSection;
                    final doneCount = _doneSections.length;
                    return _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '$doneCount of ${cfg.sections.length} section${cfg.sections.length == 1 ? '' : 's'} submitted',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _startNextSection,
                            icon: Icon(next == null ? Icons.check_circle_outline : Icons.play_arrow_rounded),
                            label: Text(next == null ? 'Submit ${_sessionLabel(cfg.sessionType)}' : 'Start ${_sectionTitle(next)}'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _hasAnySubmittedSection ? _finishExam : null,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('End and submit now'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunHero extends StatelessWidget {
  const _RunHero({required this.title, required this.subtitle, required this.onBack});
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.title, required this.done, required this.onStart});
  final String title;
  final bool done;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: done ? Colors.green : cs.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          if (!done)
            TextButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start'),
            )
          else
            const Text('Submitted', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _WhiteboardCard extends StatelessWidget {
  const _WhiteboardCard({
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
    return _GlassCard(
      child: Row(
        children: [
          const Icon(Icons.draw_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${required ? 'Required' : 'Optional'} whiteboard • $strokeCount strokes${prompt == null ? '' : '\n$prompt'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: child,
        ),
      ),
    );
  }
}
