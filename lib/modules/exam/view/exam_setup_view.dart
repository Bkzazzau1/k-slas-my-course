import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/cbt_question_service.dart';
import '../../../data/services/drawing_requirement_service.dart';
import '../../../data/services/graded_session_template_service.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../proctoring/controller/proctoring_controller.dart';
import '../controller/exam_controller.dart';

class ExamSetupView extends StatefulWidget {
  const ExamSetupView({super.key});

  @override
  State<ExamSetupView> createState() => _ExamSetupViewState();
}

class _ExamSetupViewState extends State<ExamSetupView> {
  String? courseCode;
  late final List<String> courses;
  GradedSessionTemplate? _gradedTemplate;

  String mode = ExamMode.simulation;
  String gradingType = GradingType.graded;
  ExamDeliveryMode deliveryMode = ExamDeliveryMode.remoteProctored;
  String topic = 'Mixed';

  bool objective = true;
  bool fillBlank = true;
  bool theory = true;

  int objectiveCount = 10;
  int fillCount = 4;
  int theoryCount = 1;
  int minutes = 40;

  bool get isGraded => gradingType == GradingType.graded;
  bool get hasTemplate => _gradedTemplate != null;
  bool get settingsLocked => isGraded && hasTemplate;
  bool get readyToStart => courseCode != null && (!isGraded || hasTemplate);

  @override
  void initState() {
    super.initState();
    final profile = StudentProfileStorage.load();
    courses = profile?.selectedCourses ?? const <String>[];
    courseCode = courses.isNotEmpty ? courses.first : 'CSC 305';
    _syncGradedTemplate();
  }

  void _syncGradedTemplate() {
    if (!isGraded || courseCode == null) {
      _gradedTemplate = null;
      deliveryMode = ExamDeliveryMode.remoteProctored;
      return;
    }

    mode = ExamMode.simulation;
    topic = 'Mixed';
    _gradedTemplate = GradedSessionTemplateService.templateFor(
      courseCode: courseCode!,
      sessionType: SessionType.examination,
    );

    final template = _gradedTemplate;
    if (template == null) return;

    objective = template.hasObjective;
    fillBlank = template.hasFillBlank;
    theory = template.hasTheory;
    objectiveCount = template.objectiveQuestions;
    fillCount = template.fillBlankQuestions;
    theoryCount = template.theoryQuestions;
    minutes = template.durationMinutes;
    deliveryMode = template.deliveryMode;
  }

  @override
  Widget build(BuildContext context) {
    final topics = CBTQuestionService.topicsForCourse(courseCode ?? 'CSC 305');
    final drawingPolicy = DrawingRequirementService.policyForCourse(
      courseCode ?? 'CSC 305',
    );
    final whiteboardEnabled =
        isGraded && drawingPolicy.whiteboardEnabledForGraded;
    final totalQuestions =
        (objective ? objectiveCount : 0) +
        (fillBlank ? fillCount : 0) +
        (theory ? theoryCount : 0);

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            _ExamHero(
              courseCode: courseCode ?? 'Course',
              minutes: minutes,
              totalQuestions: totalQuestions,
              isGraded: isGraded,
              onBack: () => Get.back<void>(),
            ),
            const SizedBox(height: 12),
            _ReadinessChecklist(
              courseSelected: courseCode != null,
              templateReady: !isGraded || hasTemplate,
              proctoringActive: isGraded,
              deliveryMode: deliveryMode,
              whiteboardEnabled: whiteboardEnabled,
              readyToStart: readyToStart,
            ),
            const SizedBox(height: 12),
            _VerificationSteps(isGraded: isGraded),
            const SizedBox(height: 12),
            _ExamRulesCard(isGraded: isGraded, minutes: minutes),
            const SizedBox(height: 12),
            _GlassCard(
              title: 'Course',
              icon: Icons.book_outlined,
              child: _PremiumDropdown<String>(
                value: courseCode ?? 'CSC 305',
                items: courses.isEmpty ? [courseCode ?? 'CSC 305'] : courses,
                labelBuilder: (value) => value,
                onChanged: (value) => setState(() {
                  courseCode = value;
                  _syncGradedTemplate();
                }),
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              title: 'Examination type',
              icon: Icons.verified_user_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChoicePill(
                        label: 'Graded exam',
                        selected: isGraded,
                        onTap: () => setState(() {
                          gradingType = GradingType.graded;
                          _syncGradedTemplate();
                        }),
                      ),
                      _ChoicePill(
                        label: 'Ungraded simulation',
                        selected: !isGraded,
                        onTap: () => setState(() {
                          gradingType = GradingType.ungraded;
                          _syncGradedTemplate();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoBar(
                    icon: isGraded
                        ? Icons.security_rounded
                        : Icons.school_outlined,
                    text: isGraded
                        ? hasTemplate
                              ? 'This exam is locked to lecturer-published settings.'
                              : 'Lecturer has not published graded examination settings yet.'
                        : 'Ungraded simulation is for self-practice only and does not submit as official exam.',
                    danger: isGraded && !hasTemplate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (drawingPolicy.whiteboardEnabledForGraded) ...[
              _GlassCard(
                title: 'Diagram whiteboard',
                icon: Icons.draw_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      whiteboardEnabled
                          ? drawingPolicy.whiteboardRequired
                                ? 'Enabled and required for this graded exam.'
                                : 'Enabled for this graded exam.'
                          : 'Available only when a graded exam requires it.',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (drawingPolicy.prompt != null &&
                        drawingPolicy.prompt!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        drawingPolicy.prompt!.trim(),
                        style: _mutedStyle(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _GlassCard(
              title: 'Delivery mode',
              icon: Icons.public_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChoicePill(
                        label: 'Remote proctored',
                        selected:
                            deliveryMode == ExamDeliveryMode.remoteProctored,
                        onTap: settingsLocked
                            ? () {}
                            : () => setState(
                                () => deliveryMode =
                                    ExamDeliveryMode.remoteProctored,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isGraded
                        ? 'Camera, audio, environment scan, and integrity monitoring are required before start.'
                        : 'Simulation mode keeps proctoring off unless the lecturer publishes a graded exam.',
                    style: _mutedStyle(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              title: 'Mode',
              icon: Icons.tune_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChoicePill(
                        label: 'Exam simulation',
                        selected: mode == ExamMode.simulation,
                        onTap: settingsLocked
                            ? () {}
                            : () => setState(() => mode = ExamMode.simulation),
                      ),
                      _ChoicePill(
                        label: 'Practice',
                        selected: mode == ExamMode.practice,
                        onTap: settingsLocked
                            ? () {}
                            : () => setState(() => mode = ExamMode.practice),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    settingsLocked
                        ? 'Mode is locked by lecturer backend settings.'
                        : 'Simulation behaves like a real exam; practice gives more learning flexibility.',
                    style: _mutedStyle(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              title: 'Question types',
              icon: Icons.layers_outlined,
              child: Column(
                children: [
                  _SwitchRow(
                    title: 'Objective / CBT',
                    subtitle: 'Fast scoring and broad coverage',
                    value: objective,
                    enabled: !settingsLocked,
                    onChanged: (value) => setState(() => objective = value),
                  ),
                  _SwitchRow(
                    title: 'Fill in the blank',
                    subtitle: 'Short-answer keyword checking',
                    value: fillBlank,
                    enabled: !settingsLocked,
                    onChanged: (value) => setState(() => fillBlank = value),
                  ),
                  _SwitchRow(
                    title: 'Theory / Essay',
                    subtitle: 'Long-form answers with review feedback',
                    value: theory,
                    enabled: !settingsLocked,
                    onChanged: (value) => setState(() => theory = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              title: 'Topic',
              icon: Icons.category_outlined,
              child: _PremiumDropdown<String>(
                value: topic,
                items: [
                  'Mixed',
                  'WeakOnly',
                  ...topics.where((item) => item != 'Mixed'),
                ],
                labelBuilder: (value) =>
                    value == 'WeakOnly' ? 'Weak topics only' : value,
                onChanged: (value) {
                  if (settingsLocked) return;
                  setState(() => topic = value ?? 'Mixed');
                },
              ),
            ),
            if (settingsLocked) ...[
              const SizedBox(height: 8),
              Text(
                'Topic, question counts, and timer are locked by lecturer backend settings.',
                style: _mutedStyle(context),
              ),
            ],
            const SizedBox(height: 12),
            _GlassCard(
              title: 'Question counts',
              icon: Icons.format_list_numbered_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settingsLocked) ...[
                    if (objective)
                      _LockedCountRow(
                        label: 'Objective questions',
                        value: objectiveCount,
                      ),
                    if (fillBlank)
                      _LockedCountRow(
                        label: 'Fill-blank questions',
                        value: fillCount,
                      ),
                    if (theory)
                      _LockedCountRow(
                        label: 'Theory questions',
                        value: theoryCount,
                      ),
                  ] else ...[
                    if (objective)
                      _SliderBlock(
                        label: 'Objective questions',
                        value: objectiveCount,
                        min: 5,
                        max: 60,
                        onChanged: (value) =>
                            setState(() => objectiveCount = value),
                      ),
                    if (fillBlank)
                      _SliderBlock(
                        label: 'Fill-blank questions',
                        value: fillCount,
                        min: 1,
                        max: 40,
                        onChanged: (value) => setState(() => fillCount = value),
                      ),
                    if (theory)
                      _SliderBlock(
                        label: 'Theory questions',
                        value: theoryCount,
                        min: 1,
                        max: 10,
                        onChanged: (value) =>
                            setState(() => theoryCount = value),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              title: 'Duration',
              icon: Icons.timer_outlined,
              child: settingsLocked
                  ? _LockedCountRow(label: 'Duration', value: minutes)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: minutes.toDouble(),
                          min: 10,
                          max: 180,
                          divisions: 17,
                          label: '$minutes mins',
                          onChanged: (value) =>
                              setState(() => minutes = value.round()),
                        ),
                        Text('$minutes minutes', style: _mutedStyle(context)),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _PrimaryCta(
              label: isGraded
                  ? 'Start Graded Examination'
                  : 'Start Ungraded Simulation',
              enabled: readyToStart,
              onTap: _startExam,
              subText: readyToStart
                  ? 'Your report will show weak areas, missing keywords, and recommended revision.'
                  : 'Waiting for lecturer to publish graded examination settings.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startExam() async {
    final gradedTemplate = isGraded
        ? (_gradedTemplate ??
              GradedSessionTemplateService.templateFor(
                courseCode: courseCode!,
                sessionType: SessionType.examination,
              ))
        : null;

    if (isGraded && gradedTemplate == null) {
      Get.snackbar(
        'Graded template missing',
        'Lecturer has not published graded examination settings yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final effectiveObjective = gradedTemplate?.hasObjective ?? objective;
    final effectiveFillBlank = gradedTemplate?.hasFillBlank ?? fillBlank;
    final effectiveTheory = gradedTemplate?.hasTheory ?? theory;
    final effectiveObjectiveCount =
        gradedTemplate?.objectiveQuestions ??
        (effectiveObjective ? objectiveCount : 0);
    final effectiveFillCount =
        gradedTemplate?.fillBlankQuestions ??
        (effectiveFillBlank ? fillCount : 0);
    final effectiveTheoryCount =
        gradedTemplate?.theoryQuestions ?? (effectiveTheory ? theoryCount : 0);
    final effectiveMinutes = gradedTemplate?.durationMinutes ?? minutes;
    final effectiveMode = gradedTemplate != null ? ExamMode.simulation : mode;
    final effectiveTopic = gradedTemplate != null ? 'Mixed' : topic;
    final effectiveDeliveryMode = gradedTemplate?.deliveryMode ?? deliveryMode;

    if (!effectiveObjective && !effectiveFillBlank && !effectiveTheory) {
      Get.snackbar(
        'Select a type',
        'Choose at least one question type.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final sections = <String>[
      if (effectiveObjective) ExamSectionType.objective,
      if (effectiveFillBlank) ExamSectionType.fillBlank,
      if (effectiveTheory) ExamSectionType.theory,
    ];

    final drawingPolicy = DrawingRequirementService.policyForCourse(
      courseCode!,
    );
    final whiteboardEnabled =
        isGraded && drawingPolicy.whiteboardEnabledForGraded;

    final cfg = ExamConfig(
      courseCode: courseCode!,
      sessionType: SessionType.examination,
      gradingType: gradingType,
      mode: effectiveMode,
      topic: effectiveTopic,
      sections: sections,
      objectiveQuestions: effectiveObjectiveCount,
      fillBlankQuestions: effectiveFillCount,
      theoryQuestions: effectiveTheoryCount,
      durationMinutes: effectiveMinutes,
      deliveryMode: effectiveDeliveryMode,
      questionSource: isGraded
          ? QuestionSourceType.lecturerAdmin
          : QuestionSourceType.studentLocal,
      whiteboardEnabled: whiteboardEnabled,
      whiteboardRequired: whiteboardEnabled && drawingPolicy.whiteboardRequired,
      whiteboardPrompt: whiteboardEnabled ? drawingPolicy.prompt : null,
    );

    Get.find<ExamController>().startExam(cfg);

    if (cfg.isCenterBased || !isGraded) {
      Get.toNamed(Routes.examRun, arguments: cfg);
      return;
    }

    final proctoring = Get.isRegistered<ProctoringController>()
        ? Get.find<ProctoringController>()
        : Get.put(ProctoringController(), permanent: true);
    final examId = '${cfg.courseCode}-${DateTime.now().millisecondsSinceEpoch}';
    await proctoring.startExamSequence(
      examId,
      onVerified: () => Get.toNamed(Routes.examRun, arguments: cfg),
    );
  }
}

class _ExamHero extends StatelessWidget {
  const _ExamHero({
    required this.courseCode,
    required this.minutes,
    required this.totalQuestions,
    required this.isGraded,
    required this.onBack,
  });

  final String courseCode;
  final int minutes;
  final int totalQuestions;
  final bool isGraded;
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
                  '$courseCode Examination',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              const Icon(Icons.verified_user_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isGraded
                ? 'High-stakes exam gateway with verification, readiness checks, and proctoring rules.'
                : 'Ungraded exam simulation for student practice only.',
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
              _HeroPill(text: '$minutes min'),
              _HeroPill(text: '$totalQuestions questions'),
              _HeroPill(text: isGraded ? 'Proctored' : 'Simulation'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessChecklist extends StatelessWidget {
  const _ReadinessChecklist({
    required this.courseSelected,
    required this.templateReady,
    required this.proctoringActive,
    required this.deliveryMode,
    required this.whiteboardEnabled,
    required this.readyToStart,
  });

  final bool courseSelected;
  final bool templateReady;
  final bool proctoringActive;
  final ExamDeliveryMode deliveryMode;
  final bool whiteboardEnabled;
  final bool readyToStart;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      title: 'Readiness checklist',
      icon: Icons.fact_check_outlined,
      child: Column(
        children: [
          _CheckRow(label: 'Course selected', done: courseSelected),
          _CheckRow(label: 'Lecturer exam settings ready', done: templateReady),
          _CheckRow(label: 'Remote proctoring gateway', done: proctoringActive),
          _CheckRow(
            label: 'Camera/audio/environment scan required',
            done:
                proctoringActive &&
                deliveryMode == ExamDeliveryMode.remoteProctored,
          ),
          _CheckRow(
            label: 'Whiteboard enabled when required',
            done: whiteboardEnabled || !proctoringActive,
          ),
          const SizedBox(height: 8),
          _InfoBar(
            icon: readyToStart
                ? Icons.verified_rounded
                : Icons.warning_amber_rounded,
            text: readyToStart
                ? 'Ready to continue. Review the rules before starting.'
                : 'Not ready yet. Wait for the lecturer/exam officer to publish exam settings.',
            danger: !readyToStart,
          ),
        ],
      ),
    );
  }
}

class _VerificationSteps extends StatelessWidget {
  const _VerificationSteps({required this.isGraded});
  final bool isGraded;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      title: 'Verification steps',
      icon: Icons.security_rounded,
      child: Column(
        children: [
          _StepRow(
            number: 1,
            title: 'Identity and candidate session',
            subtitle: 'Confirm course, exam mode, and student record.',
          ),
          _StepRow(
            number: 2,
            title: 'Device and network check',
            subtitle: 'Prepare a stable device and avoid switching apps.',
          ),
          _StepRow(
            number: 3,
            title: isGraded
                ? 'Camera/audio/environment scan'
                : 'Practice readiness',
            subtitle: isGraded
                ? 'Room scan and integrity checks run before entry.'
                : 'No proctoring is requested in simulation.',
          ),
          _StepRow(
            number: 4,
            title: 'Start exam',
            subtitle: 'Timer starts only after the final gateway is completed.',
          ),
        ],
      ),
    );
  }
}

class _ExamRulesCard extends StatelessWidget {
  const _ExamRulesCard({required this.isGraded, required this.minutes});
  final bool isGraded;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      title: 'Exam rules',
      icon: Icons.rule_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RuleBullet(
            text: 'Keep this app open until submission is completed.',
          ),
          _RuleBullet(text: 'Submit before the $minutes-minute timer expires.'),
          _RuleBullet(
            text:
                'Saved answers are tracked locally for recovery during poor network.',
          ),
          if (isGraded) ...[
            _RuleBullet(
              text: 'Do not leave the camera/audio verification environment.',
            ),
            _RuleBullet(
              text:
                  'Multiple faces, phone visibility, or app switching may affect integrity score.',
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: cs.shadow.withValues(alpha: 0.04),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.done});
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = done ? Colors.green.shade700 : Colors.orange.shade800;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
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

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
  });
  final int number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
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
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: _mutedStyle(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleBullet extends StatelessWidget {
  const _RuleBullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                height: 1.32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.icon, required this.text, this.danger = false});
  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = danger ? cs.error : cs.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
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

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: cs.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: selected ? cs.primary : cs.onSurface,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _PremiumDropdown<T> extends StatelessWidget {
  const _PremiumDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });
  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value',
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}

class _LockedCountRow extends StatelessWidget {
  const _LockedCountRow({required this.label, required this.value});
  final String label;
  final int value;

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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onTap,
    required this.subText,
    required this.enabled,
  });
  final String label;
  final VoidCallback onTap;
  final String subText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: enabled ? onTap : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(label),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.70),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.text});
  final String text;

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
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
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
