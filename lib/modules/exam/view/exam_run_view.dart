import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/whiteboard/whiteboard_editor_sheet.dart';
import '../../../core/whiteboard/whiteboard_models.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/cbt_models.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/models/multi_format_exam_models.dart';
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
        if (proctoring.hasActiveSessionFor(
          AssessmentIntegrityLevel.highStakesExam,
        )) {
          proctoring.attachSessionCallbacks(
            onSessionTerminated: _handleSessionTermination,
          );
          if (proctoring.examStartupScanCompleted.value) {
            proctoring.armExamMonitoring();
          }
          return;
        }
        _ownsProctoringSession = true;
        unawaited(
          proctoring
              .startSession(
                level: AssessmentIntegrityLevel.highStakesExam,
                onSessionTerminated: _handleSessionTermination,
              )
              .then((_) {
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

  Set<String> get _doneSections =>
      ctrl.sectionScores.map((e) => e.sectionType).toSet();

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
          'enabledFormats': cfg.enabledFormats
              .map((format) => format.raw)
              .toList(),
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
          'enabledFormats': cfg.enabledFormats
              .map((format) => format.raw)
              .toList(),
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

    final pending = cfg.sections
        .where((s) => !_doneSections.contains(s))
        .toList();
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          pending.isEmpty
              ? 'Final review'
              : 'Submit incomplete ${_sessionLabel(cfg.sessionType).toLowerCase()}?',
        ),
        content: _FinalReviewDialogContent(
          pending: pending.map(_sectionTitle).toList(),
          completed: _doneSections.map(_sectionTitle).toList(),
          sessionLabel: _sessionLabel(cfg.sessionType),
          whiteboardRequired: cfg.requiresWhiteboard,
          hasWhiteboard: ctrl.hasWhiteboardSketch,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Continue working'),
          ),
          FilledButton.icon(
            onPressed: _hasAnySubmittedSection
                ? () => Get.back(result: true)
                : null,
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Submit final'),
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

  String _sectionHint(String section) {
    switch (section) {
      case ExamSectionType.objective:
        return '${cfg.objectiveQuestions} questions • timed CBT section';
      case ExamSectionType.fillBlank:
        return '${cfg.fillBlankQuestions} short answers • keyword scoring';
      case ExamSectionType.theory:
        return '${cfg.theoryQuestions} theory task${cfg.theoryQuestions == 1 ? '' : 's'} • essay/whiteboard support';
      default:
        return 'Exam section';
    }
  }

  String _sessionLabel(String type) {
    return type == SessionType.assessment ? 'Assessment' : 'Examination';
  }

  String _formatSummary() {
    if (cfg.enabledFormats.isEmpty) {
      return cfg.sections.map(_sectionTitle).join(', ');
    }
    return cfg.enabledFormats.map((format) => format.label).join(', ');
  }

  String _securitySummary() {
    final policy = cfg.securityPolicy;
    return [
      cfg.isRemoteProctored ? 'remote proctored' : 'normal mode',
      policy.shuffleQuestions ? 'shuffled questions' : 'fixed order',
      policy.lockCopyPaste ? 'copy/paste locked' : 'copy/paste allowed',
      if (policy.calculatorEnabled) 'calculator enabled',
      'autosave/recovery active',
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Obx(() {
                final doneCount = _doneSections.length;
                return _RunHero(
                  title: '${cfg.courseCode} ${_sessionLabel(cfg.sessionType)}',
                  subtitle: _useProctoring
                      ? 'Protected live exam workspace. Complete all sections and submit after final review.'
                      : 'Live assessment workspace. Complete sections and submit after final review.',
                  minutes: cfg.durationMinutes,
                  doneCount: doneCount,
                  totalCount: cfg.sections.length,
                  onBack: () => Get.back<void>(),
                );
              }),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Obx(() {
                    final done = _doneSections;
                    final progress = cfg.sections.isEmpty
                        ? 0.0
                        : done.length / cfg.sections.length;
                    return _ProgressOverviewCard(
                      progress: progress,
                      doneCount: done.length,
                      totalCount: cfg.sections.length,
                      nextLabel: _nextSection == null
                          ? 'Ready for final submission'
                          : 'Next: ${_sectionTitle(_nextSection!)}',
                      autosaveLabel: 'Autosave and offline recovery active',
                    );
                  }),
                  const SizedBox(height: 12),
                  if (_useProctoring)
                    Obx(
                      () => _IntegrityCard(
                        score: proctoring.integrityScore.value,
                        paused: proctoring.isExamPaused.value,
                        scanReady: proctoring.examStartupScanCompleted.value,
                      ),
                    )
                  else
                    const _StatusCard(
                      icon: Icons.school_outlined,
                      title: 'Normal mode',
                      subtitle:
                          'No camera/audio proctoring is active for this session.',
                    ),
                  const SizedBox(height: 12),
                  _StatusCard(
                    icon: Icons.tune_rounded,
                    title: 'Session plan',
                    subtitle:
                        'Formats: ${_formatSummary()}\nSecurity: ${_securitySummary()}',
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
                  _SectionHeader(
                    title: 'Exam sections',
                    subtitle:
                        'Open each section, submit it, then return here to continue.',
                  ),
                  const SizedBox(height: 10),
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
                                subtitle: _sectionHint(section),
                                done: done.contains(section),
                                active: _nextSection == section,
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
                    final pending = cfg.sections.length - doneCount;
                    return _FinalActionCard(
                      doneCount: doneCount,
                      totalCount: cfg.sections.length,
                      pendingCount: pending,
                      nextLabel: next == null
                          ? 'Submit ${_sessionLabel(cfg.sessionType)}'
                          : 'Start ${_sectionTitle(next)}',
                      canSubmit: _hasAnySubmittedSection,
                      onNext: _startNextSection,
                      onSubmitNow: _finishExam,
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
  const _RunHero({
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.doneCount,
    required this.totalCount,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final int minutes;
  final int doneCount;
  final int totalCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
                  ),
                ),
              ),
              const Icon(Icons.shield_outlined, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: '$minutes min'),
              _HeroPill(label: '$doneCount/$totalCount sections'),
              const _HeroPill(label: 'Autosave active'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ProgressOverviewCard extends StatelessWidget {
  const _ProgressOverviewCard({
    required this.progress,
    required this.doneCount,
    required this.totalCount,
    required this.nextLabel,
    required this.autosaveLabel,
  });

  final double progress;
  final int doneCount;
  final int totalCount;
  final String nextLabel;
  final String autosaveLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primary.withValues(alpha: 0.10),
                child: Icon(Icons.track_changes_outlined, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Live progress',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                text: '$doneCount of $totalCount submitted',
                active: doneCount == totalCount,
              ),
              _MiniBadge(text: nextLabel),
              _MiniBadge(text: autosaveLabel, active: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntegrityCard extends StatelessWidget {
  const _IntegrityCard({
    required this.score,
    required this.paused,
    required this.scanReady,
  });
  final int score;
  final bool paused;
  final bool scanReady;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? Colors.green.shade700
        : score >= 45
        ? Colors.orange.shade800
        : Theme.of(context).colorScheme.error;
    return _GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            paused
                ? Icons.pause_circle_outline_rounded
                : Icons.security_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Integrity score: $score',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  paused
                      ? 'Exam paused for verification.'
                      : scanReady
                      ? 'Camera, audio, environment, screen, and device checks are active.'
                      : 'Startup scan is not fully completed yet.',
                  style: _mutedStyle(context),
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
  const _StatusCard({
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: _mutedStyle(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: _mutedStyle(context)),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
    required this.onStart,
  });
  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = done
        ? Colors.green.shade700
        : active
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.50);
    return _GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : active
                ? Icons.play_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: _mutedStyle(context)),
              ],
            ),
          ),
          if (!done)
            TextButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(active ? 'Start' : 'Open'),
            )
          else
            const Text(
              'Submitted',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
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
    final done = strokeCount > 0;
    return _GlassCard(
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_outline_rounded : Icons.draw_outlined,
            color: done
                ? Colors.green.shade700
                : Theme.of(context).colorScheme.primary,
          ),
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

class _FinalActionCard extends StatelessWidget {
  const _FinalActionCard({
    required this.doneCount,
    required this.totalCount,
    required this.pendingCount,
    required this.nextLabel,
    required this.canSubmit,
    required this.onNext,
    required this.onSubmitNow,
  });

  final int doneCount;
  final int totalCount;
  final int pendingCount;
  final String nextLabel;
  final bool canSubmit;
  final VoidCallback onNext;
  final VoidCallback onSubmitNow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Final review & submission',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pendingCount == 0
                ? 'All sections are complete. Review and submit your final work.'
                : '$pendingCount section${pendingCount == 1 ? '' : 's'} still pending. You can continue or submit completed work only.',
            style: _mutedStyle(context),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onNext,
            icon: Icon(
              pendingCount == 0
                  ? Icons.verified_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(nextLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: canSubmit ? onSubmitNow : null,
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(
              doneCount == totalCount
                  ? 'Open final review'
                  : 'End and submit now',
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalReviewDialogContent extends StatelessWidget {
  const _FinalReviewDialogContent({
    required this.pending,
    required this.completed,
    required this.sessionLabel,
    required this.whiteboardRequired,
    required this.hasWhiteboard,
  });

  final List<String> pending;
  final List<String> completed;
  final String sessionLabel;
  final bool whiteboardRequired;
  final bool hasWhiteboard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pending.isEmpty
                ? 'All enabled sections have been completed. Submit your ${sessionLabel.toLowerCase()} now?'
                : 'You still have ${pending.length} pending section${pending.length == 1 ? '' : 's'}. Submit only the completed work now?',
          ),
          const SizedBox(height: 12),
          _DialogLine(
            icon: Icons.check_circle_outline_rounded,
            label: 'Completed',
            value: completed.isEmpty ? 'None yet' : completed.join(', '),
          ),
          _DialogLine(
            icon: Icons.pending_outlined,
            label: 'Pending',
            value: pending.isEmpty ? 'None' : pending.join(', '),
          ),
          if (whiteboardRequired)
            _DialogLine(
              icon: Icons.draw_outlined,
              label: 'Whiteboard',
              value: hasWhiteboard ? 'Submitted' : 'Required',
            ),
        ],
      ),
    );
  }
}

class _DialogLine extends StatelessWidget {
  const _DialogLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                offset: const Offset(0, 8),
                color: cs.shadow.withValues(alpha: 0.035),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, this.active = false});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? cs.primary.withValues(alpha: 0.11)
            : cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? cs.primary : cs.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

TextStyle _mutedStyle(BuildContext context) {
  return TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
    fontWeight: FontWeight.w600,
    height: 1.30,
  );
}
