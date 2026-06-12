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
        _ownsProctoringSession = true;

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
                title: "${cfg.courseCode} - ${_sessionLabel(cfg.sessionType)}",
                subtitle: _useProctoring
                    ? "Remote proctored session: finish sections in order. Device checks are active."
                    : "Distance self-practice session: device proctoring is off.",
                onBack: () => Get.back(),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (_useProctoring)
                    Obx(
                      () => _IntegrityStrip(
                        score: proctoring.integrityScore.value,
                        moved: proctoring.isPhoneMoved.value,
                        recording: proctoring.isScreenRecorded.value,
                      ),
                    )
                  else
                    _NonProctoredStrip(label: _sessionLabel(cfg.sessionType)),
                  const SizedBox(height: 12),
                  _InfoStrip(
                    text:
                        'Formats: ${_formatSummary()}. Security: ${_securitySummary()}.',
                    icon: Icons.tune_outlined,
                  ),
                  if (cfg.whiteboardEnabled) ...[
                    const SizedBox(height: 12),
                    Obx(
                      () => _WhiteboardStrip(
                        required: cfg.whiteboardRequired,
                        prompt: cfg.whiteboardPrompt,
                        strokeCount: ctrl.whiteboardStrokes.length,
                        onOpen: _openWhiteboard,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Obx(() {
                    final done = ctrl.sectionScores
                        .map((e) => e.sectionType)
                        .toSet();

                    return Column(
                      children: [
                        _SectionTile(
                          title: "Objective (CBT)",
                          enabled: cfg.sections.contains(
                            ExamSectionType.objective,
                          ),
                          done: done.contains(ExamSectionType.objective),
                        ),
                        const SizedBox(height: 10),
                        _SectionTile(
                          title: "Fill in the blank",
                          enabled: cfg.sections.contains(
                            ExamSectionType.fillBlank,
                          ),
                          done: done.contains(ExamSectionType.fillBlank),
                        ),
                        const SizedBox(height: 10),
                        _SectionTile(
                          title: "Theory (Essay)",
                          enabled: cfg.sections.contains(
                            ExamSectionType.theory,
                          ),
                          done: done.contains(ExamSectionType.theory),
                        ),
                        const SizedBox(height: 12),

                        _InfoStrip(
                          text:
                              "Tip: Even correct ideas can lose marks without lecturer keywords. Use the exact terms taught.",
                          icon: Icons.verified_outlined,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.03),
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.06),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async => _startNextSection(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Continue",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNextSection() async {
    final exam = ctrl;
    final done = exam.sectionScores.map((e) => e.sectionType).toSet();

    final order = [
      ExamSectionType.objective,
      ExamSectionType.fillBlank,
      ExamSectionType.theory,
    ];

    String? next;
    for (final s in order) {
      if (cfg.sections.contains(s) && !done.contains(s)) {
        next = s;
        break;
      }
    }

    if (next == null) {
      if (cfg.requiresWhiteboard && !exam.hasWhiteboardSketch) {
        Get.snackbar(
          'Whiteboard required',
          'This ${_sessionLabel(cfg.sessionType).toLowerCase()} requires a diagram on whiteboard.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final res = exam.finalize();
      Get.offNamed('/exam/result', arguments: res);
      return;
    }

    if (next == ExamSectionType.objective) {
      final res = await Get.toNamed(
        '/cbt/take',
        arguments: {
          "courseCode": cfg.courseCode,
          "mode": cfg.mode == ExamMode.practice ? "Untimed" : "Timed",
          "topic": cfg.topic == "WeakOnly" ? "Mixed" : cfg.topic,
          "questions": cfg.objectiveQuestions,
          "minutes": cfg.mode == ExamMode.practice
              ? 20
              : (cfg.durationMinutes ~/ 2).clamp(10, 90),
          "examMode": true,
          "sessionType": cfg.sessionType,
          "gradingType": cfg.gradingType,
          "deliveryMode": cfg.deliveryMode.raw,
          "questionSource": cfg.questionSource,
          "whiteboardEnabled": cfg.whiteboardEnabled,
          "whiteboardRequired": cfg.whiteboardRequired,
          "whiteboardPrompt": cfg.whiteboardPrompt,
          "enabledFormats": cfg.enabledFormats
              .map((format) => format.raw)
              .toList(),
          "demoMode": cfg.securityPolicy.demoMode,
          "shuffleQuestions": cfg.securityPolicy.shuffleQuestions,
          "lockCopyPaste": cfg.securityPolicy.lockCopyPaste,
          "calculatorEnabled": cfg.securityPolicy.calculatorEnabled,
        },
      );
      if (res is CBTAttemptModel) {
        exam.addSectionScore(
          ExamSectionScore(
            sectionType: ExamSectionType.objective,
            totalMarks: res.totalQuestions,
            scoredMarks: res.correct,
            extra: {"cbtAttemptId": res.id},
          ),
        );
        await _startNextSection();
      }
      return;
    }

    if (next == ExamSectionType.fillBlank) {
      final out = await Get.toNamed('/fillblank/start', arguments: cfg);
      if (out is Map && out["section"] == "FILL_BLANK") {
        exam.addSectionScore(
          ExamSectionScore(
            sectionType: ExamSectionType.fillBlank,
            totalMarks: (out["totalMarks"] ?? 0) as int,
            scoredMarks: (out["scoredMarks"] ?? 0) as int,
            extra: (out["extra"] ?? {}) as Map<String, dynamic>,
          ),
        );
        await _startNextSection();
      }
      return;
    }

    if (next == ExamSectionType.theory) {
      final tq = SampleExamService.theoryQuestion(
        courseCode: cfg.courseCode,
        topic: cfg.topic,
      );
      final out = await Get.toNamed(
        '/theory/practice',
        arguments: {
          "question": tq,
          "examMode": true,
          "sessionType": cfg.sessionType,
          "gradingType": cfg.gradingType,
          "deliveryMode": cfg.deliveryMode.raw,
          "whiteboardEnabled": cfg.whiteboardEnabled,
          "whiteboardRequired": cfg.whiteboardRequired,
          "whiteboardPrompt": cfg.whiteboardPrompt,
          "enabledFormats": cfg.enabledFormats
              .map((format) => format.raw)
              .toList(),
          "demoMode": cfg.securityPolicy.demoMode,
          "shuffleQuestions": cfg.securityPolicy.shuffleQuestions,
          "lockCopyPaste": cfg.securityPolicy.lockCopyPaste,
          "calculatorEnabled": cfg.securityPolicy.calculatorEnabled,
        },
      );
      if (out is Map && out["section"] == "THEORY") {
        exam.addSectionScore(
          ExamSectionScore(
            sectionType: ExamSectionType.theory,
            totalMarks: (out["totalMarks"] ?? 0) as int,
            scoredMarks: (out["scoredMarks"] ?? 0) as int,
            extra: (out["extra"] ?? {}) as Map<String, dynamic>,
          ),
        );
        await _startNextSection();
      }
      return;
    }
  }

  String _formatSummary() {
    if (cfg.enabledFormats.isEmpty) {
      return cfg.sections.join(', ');
    }
    return cfg.enabledFormats.map((format) => format.label).join(', ');
  }

  String _securitySummary() {
    final policy = cfg.securityPolicy;
    return [
      policy.demoMode ? 'demo override' : 'strict verification',
      policy.shuffleQuestions ? 'shuffle' : 'fixed order',
      policy.lockCopyPaste ? 'paste locked' : 'paste allowed',
      if (policy.calculatorEnabled) 'calculator',
    ].join(', ');
  }

  void _handleSessionTermination() {
    if (!mounted) return;
    final result = ctrl.finalize();
    Get.offNamed('/exam/result', arguments: result);
  }

  String _sessionLabel(String type) {
    return type == SessionType.assessment ? "Assessment" : "Examination";
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(20),
          ),
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
        ),
      ),
    );
  }
}

class _NonProctoredStrip extends StatelessWidget {
  const _NonProctoredStrip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: cs.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Non-proctored distance $label session.",
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
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

class _RunHero extends StatelessWidget {
  const _RunHero({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
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
  const _SectionTile({
    required this.title,
    required this.enabled,
    required this.done,
  });

  final String title;
  final bool enabled;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = enabled
        ? cs.onSurface.withValues(alpha: 0.03)
        : cs.onSurface.withValues(alpha: 0.015);

    final border = enabled
        ? cs.onSurface.withValues(alpha: 0.06)
        : cs.onSurface.withValues(alpha: 0.04);

    final icon = done
        ? Icons.verified_outlined
        : (enabled ? Icons.circle_outlined : Icons.remove_circle_outline);

    final iconColor = done
        ? cs.primary
        : (enabled
              ? cs.onSurface.withValues(alpha: 0.55)
              : cs.onSurface.withValues(alpha: 0.35));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          if (!enabled)
            Text(
              "OFF",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "Done",
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(20),
          ),
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
                    label: Text(
                      hasSketch ? 'Edit whiteboard' : 'Open whiteboard',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
