import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/models/multi_format_exam_models.dart';
import '../../../data/services/graded_session_template_service.dart';
import '../../../data/services/multi_format_sample_exam_service.dart';
import '../../../data/services/storage_service.dart';
import '../../exam/controller/exam_controller.dart';
import '../../proctoring/controller/proctoring_controller.dart';

class CBTSetupView extends StatefulWidget {
  const CBTSetupView({super.key, required this.courseCode});

  final String courseCode;

  @override
  State<CBTSetupView> createState() => _CBTSetupViewState();
}

class _CBTSetupViewState extends State<CBTSetupView> {
  String gradingType = GradingType.ungraded;
  String topic = 'Mixed';
  bool shuffleQuestions = true;
  bool calculatorEnabled = false;
  bool demoMode = true;
  bool lockCopyPaste = false;

  Set<MultiFormatQuestionType> selectedFormats = {
    MultiFormatQuestionType.objectiveSingle,
    MultiFormatQuestionType.objectiveMultiple,
    MultiFormatQuestionType.fillBlank,
    MultiFormatQuestionType.essay,
    MultiFormatQuestionType.whiteboard,
  };

  bool get isGraded => gradingType == GradingType.graded;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map?;
    final requested = args?['gradingType']?.toString();
    if (requested == GradingType.graded) {
      gradingType = GradingType.graded;
      lockCopyPaste = true;
    }
    demoMode = StorageService.getDemoMode();
  }

  GradedSessionTemplate? get _template => isGraded
      ? GradedSessionTemplateService.templateFor(
          courseCode: widget.courseCode,
          sessionType: SessionType.assessment,
        )
      : null;

  int get objectiveCount => _template?.objectiveQuestions ?? 3;
  int get fillCount => _template?.fillBlankQuestions ?? 1;
  int get theoryCount => _template?.theoryQuestions ?? 1;
  int get minutes => _template?.durationMinutes ?? 20;

  List<MultiFormatQuestionType> get effectiveFormats {
    if (isGraded) return MultiFormatSampleExamService.importedFormats;
    if (selectedFormats.isEmpty) return MultiFormatSampleExamService.importedFormats;
    return selectedFormats.toList(growable: false);
  }

  List<MultiFormatQuestion> get sampleQuestions {
    return MultiFormatSampleExamService.questions(
      courseCode: widget.courseCode,
      topic: topic,
      formats: effectiveFormats,
    ).take(5).toList(growable: false);
  }

  void _setGradingType(String value) {
    setState(() {
      gradingType = value;
      lockCopyPaste = value == GradingType.graded;
    });
  }

  void _toggleFormat(MultiFormatQuestionType format, bool value) {
    if (isGraded) return;
    setState(() {
      if (value) {
        selectedFormats.add(format);
      } else {
        selectedFormats.remove(format);
      }
    });
  }

  List<String> _sections() {
    final formats = effectiveFormats.toSet();
    final hasObjective = formats.contains(MultiFormatQuestionType.objectiveSingle) ||
        formats.contains(MultiFormatQuestionType.objectiveMultiple);
    final hasFill = formats.contains(MultiFormatQuestionType.fillBlank);
    final hasTheory = formats.contains(MultiFormatQuestionType.essay) ||
        formats.contains(MultiFormatQuestionType.whiteboard);

    return [
      if (hasObjective) ExamSectionType.objective,
      if (hasFill) ExamSectionType.fillBlank,
      if (hasTheory) ExamSectionType.theory,
    ];
  }

  ExamSecurityPolicy _securityPolicy() {
    return ExamSecurityPolicy(
      demoMode: demoMode,
      shuffleQuestions: shuffleQuestions,
      lockCopyPaste: isGraded && lockCopyPaste,
      calculatorEnabled: calculatorEnabled,
      requireProctoring: isGraded,
      allowVerificationOverride: demoMode,
    );
  }

  Future<void> _startAssessment() async {
    final sections = _sections();
    if (sections.isEmpty) {
      Get.snackbar(
        'Select question format',
        'Choose at least one assessment question format.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final deliveryMode = isGraded
        ? ExamDeliveryMode.remoteProctored
        : ExamDeliveryMode.centerBased;
    final questionSource = isGraded
        ? QuestionSourceType.lecturerAdmin
        : QuestionSourceType.studentLocal;
    final securityPolicy = _securityPolicy();
    final hasOnlyObjective = sections.length == 1 &&
        sections.first == ExamSectionType.objective;

    Future<void> openProctored(VoidCallback launch) async {
      final proctoring = Get.isRegistered<ProctoringController>()
          ? Get.find<ProctoringController>()
          : Get.put(ProctoringController(), permanent: true);
      final id =
          '${widget.courseCode}-assessment-${DateTime.now().millisecondsSinceEpoch}';
      await proctoring.startAssessmentSequence(id, onVerified: launch);
    }

    if (hasOnlyObjective) {
      final args = {
        'courseCode': widget.courseCode,
        'mode': isGraded ? 'Timed' : 'Untimed',
        'topic': topic,
        'questions': objectiveCount,
        'minutes': minutes,
        'sessionType': SessionType.assessment,
        'gradingType': gradingType,
        'questionSource': questionSource,
        'deliveryMode': deliveryMode.raw,
        'enabledFormats': effectiveFormats.map((format) => format.raw).toList(),
        'demoMode': securityPolicy.demoMode,
        'shuffleQuestions': securityPolicy.shuffleQuestions,
        'lockCopyPaste': securityPolicy.lockCopyPaste,
        'calculatorEnabled': securityPolicy.calculatorEnabled,
      };
      if (isGraded) {
        await openProctored(() => Get.toNamed('/cbt/take', arguments: args));
      } else {
        Get.toNamed('/cbt/take', arguments: args);
      }
      return;
    }

    final cfg = ExamConfig(
      courseCode: widget.courseCode,
      sessionType: SessionType.assessment,
      gradingType: gradingType,
      mode: isGraded ? ExamMode.simulation : ExamMode.practice,
      topic: topic,
      sections: sections,
      objectiveQuestions: sections.contains(ExamSectionType.objective) ? objectiveCount : 0,
      fillBlankQuestions: sections.contains(ExamSectionType.fillBlank) ? fillCount : 0,
      theoryQuestions: sections.contains(ExamSectionType.theory) ? theoryCount : 0,
      durationMinutes: minutes,
      deliveryMode: deliveryMode,
      questionSource: questionSource,
      whiteboardEnabled: effectiveFormats.contains(MultiFormatQuestionType.whiteboard),
      whiteboardRequired: isGraded && effectiveFormats.contains(MultiFormatQuestionType.whiteboard),
      whiteboardPrompt: effectiveFormats.contains(MultiFormatQuestionType.whiteboard)
          ? 'Use the whiteboard for diagrams, calculations, or sketches.'
          : null,
      enabledFormats: effectiveFormats,
      securityPolicy: securityPolicy,
    );

    final exam = Get.isRegistered<ExamController>()
        ? Get.find<ExamController>()
        : Get.put(ExamController());
    exam.startExam(cfg);

    if (isGraded) {
      await openProctored(() => Get.toNamed('/exam/run', arguments: cfg));
    } else {
      Get.toNamed('/exam/run', arguments: cfg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleCourse = widget.courseCode.isEmpty ? 'Course' : widget.courseCode;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            _HeroCard(
              courseCode: titleCourse,
              isGraded: isGraded,
              minutes: minutes,
              onBack: () => Get.back<void>(),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.rule_rounded,
                    title: 'Assessment type',
                    subtitle:
                        'Ungraded is normal practice. Graded uses the same protected gateway as examinations.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        selected: !isGraded,
                        avatar: const Icon(Icons.school_outlined, size: 18),
                        label: const Text('Ungraded / Normal'),
                        onSelected: (_) => _setGradingType(GradingType.ungraded),
                      ),
                      ChoiceChip(
                        selected: isGraded,
                        avatar: const Icon(Icons.security_rounded, size: 18),
                        label: const Text('Graded / Proctored'),
                        onSelected: (_) => _setGradingType(GradingType.graded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ModeBanner(isGraded: isGraded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.preview_rounded,
                    title: 'Five-question sample pack',
                    subtitle:
                        'One clean sample from each format so the demo does not look overloaded.',
                  ),
                  const SizedBox(height: 12),
                  ...sampleQuestions.asMap().entries.map(
                        (entry) => _SampleTile(
                          number: entry.key + 1,
                          question: entry.value,
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.layers_rounded,
                    title: 'Question formats',
                    subtitle: isGraded
                        ? 'Locked by lecturer settings for graded assessment.'
                        : 'Available in normal ungraded practice.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MultiFormatSampleExamService.importedFormats
                        .map(
                          (format) => FilterChip(
                            selected: effectiveFormats.contains(format),
                            label: Text(format.label),
                            onSelected: isGraded
                                ? null
                                : (value) => _toggleFormat(format, value),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.assignment_rounded,
                    title: 'Assessment plan',
                    subtitle: 'Demo plan is limited to five questions only.',
                  ),
                  const SizedBox(height: 12),
                  _PlanRow(label: 'Objective / CBT', value: '$objectiveCount'),
                  _PlanRow(label: 'Fill blank', value: '$fillCount'),
                  _PlanRow(label: 'Essay / Whiteboard', value: '$theoryCount'),
                  _PlanRow(label: 'Duration', value: '$minutes minutes'),
                  _PlanRow(
                    label: 'Security',
                    value: isGraded ? 'Proctored' : 'Normal / no proctoring',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Shuffle questions'),
                    value: shuffleQuestions,
                    onChanged: (value) => setState(() => shuffleQuestions = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lock copy and paste'),
                    subtitle: Text(
                      isGraded
                          ? 'Enabled for graded assessment.'
                          : 'Disabled in normal ungraded practice.',
                    ),
                    value: isGraded && lockCopyPaste,
                    onChanged: isGraded
                        ? (value) => setState(() => lockCopyPaste = value)
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Scientific calculator'),
                    value: calculatorEnabled,
                    onChanged: (value) => setState(() => calculatorEnabled = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Demo verification override'),
                    value: demoMode,
                    onChanged: isGraded
                        ? (value) async {
                            setState(() => demoMode = value);
                            await StorageService.setDemoMode(value);
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startAssessment,
              icon: Icon(isGraded ? Icons.security_rounded : Icons.play_arrow_rounded),
              label: Text(isGraded ? 'Start Graded Assessment' : 'Start Ungraded Assessment'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isGraded
                  ? 'This will open camera, audio, and integrity verification before the assessment starts.'
                  : 'This starts immediately as normal practice. No camera, audio, or integrity score is shown.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
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
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.courseCode,
    required this.isGraded,
    required this.minutes,
    required this.onBack,
  });

  final String courseCode;
  final bool isGraded;
  final int minutes;
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
                  '$courseCode Assessment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isGraded
                      ? 'Graded, protected, lecturer-controlled assessment.'
                      : 'Ungraded normal practice assessment.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _HeroPill(text: '$minutes min'),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.text});
  final String text;

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
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({required this.isGraded});
  final bool isGraded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isGraded ? cs.error : Colors.green;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(isGraded ? Icons.security_rounded : Icons.school_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isGraded
                  ? 'Graded mode: proctoring, camera/audio gateway, copy/paste lock, and integrity score are active.'
                  : 'Ungraded mode: normal practice only. No proctoring, no camera/audio request, no integrity score.',
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
    return Row(
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
                  color: cs.onSurface.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SampleTile extends StatelessWidget {
  const _SampleTile({required this.number, required this.question});

  final int number;
  final MultiFormatQuestion question;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primary.withValues(alpha: 0.14),
            child: Text(
              '$number',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniPill(label: question.type.label),
                    _MiniPill(label: '${question.points} mark${question.points == 1 ? '' : 's'}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.questionText,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (question.options.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Options: ${question.options.take(3).join(' • ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(value, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
