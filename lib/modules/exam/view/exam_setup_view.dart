import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/cbt_question_service.dart';
import '../../../data/services/drawing_requirement_service.dart';
import '../../../data/services/graded_session_template_service.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../app/routes/app_routes.dart';
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
  String topic = "Mixed";

  bool objective = true;
  bool fillBlank = true;
  bool theory = true;

  int objectiveCount = 10;
  int fillCount = 4;
  int theoryCount = 1;

  int minutes = 40;

  @override
  void initState() {
    super.initState();
    final profile = StudentProfileStorage.load();
    courses = profile?.selectedCourses ?? const <String>[];
    courseCode = courses.isNotEmpty ? courses.first : "CSC 305";
    _syncGradedTemplate();
  }

  void _syncGradedTemplate() {
    if (gradingType != GradingType.graded || courseCode == null) {
      _gradedTemplate = null;
      deliveryMode = ExamDeliveryMode.remoteProctored;
      return;
    }

    mode = ExamMode.simulation;
    topic = "Mixed";

    _gradedTemplate = GradedSessionTemplateService.templateFor(
      courseCode: courseCode!,
      sessionType: SessionType.examination,
    );

    final t = _gradedTemplate;
    if (t == null) return;

    objective = t.hasObjective;
    fillBlank = t.hasFillBlank;
    theory = t.hasTheory;
    objectiveCount = t.objectiveQuestions;
    fillCount = t.fillBlankQuestions;
    theoryCount = t.theoryQuestions;
    minutes = t.durationMinutes;
    deliveryMode = t.deliveryMode;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGradedLocked = gradingType == GradingType.graded;
    final isDeliveryLocked = isGradedLocked && _gradedTemplate != null;
    final isDurationLocked = isGradedLocked && _gradedTemplate != null;
    final topics = CBTQuestionService.topicsForCourse(courseCode!);
    final drawingPolicy = DrawingRequirementService.policyForCourse(
      courseCode!,
    );
    final whiteboardEnabledForGraded =
        gradingType == GradingType.graded &&
        drawingPolicy.whiteboardEnabledForGraded;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            // HERO
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _HeroHeader(
                title: "Examination Setup",
                subtitle:
                    "Build a real exam mix: Objective + Fill-blank + Theory.\nTake both CBT + Theory for best results.",
                rightPill: "$minutes mins",
                onBack: () => Get.back(),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _GlassCard(
                    title: "Course",
                    icon: Icons.book_outlined,
                    child: _PremiumDropdown<String>(
                      value: courseCode!,
                      items: (courses.isEmpty ? [courseCode!] : courses),
                      labelBuilder: (v) => v,
                      onChanged: (v) => setState(() {
                        courseCode = v;
                        _syncGradedTemplate();
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (drawingPolicy.whiteboardEnabledForGraded) ...[
                    _GlassCard(
                      title: "Diagram whiteboard",
                      icon: Icons.draw_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            whiteboardEnabledForGraded
                                ? (drawingPolicy.whiteboardRequired
                                      ? "Enabled and required for graded sessions."
                                      : "Enabled for graded sessions.")
                                : "Available, but activated only in graded mode.",
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (drawingPolicy.prompt != null &&
                              drawingPolicy.prompt!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              drawingPolicy.prompt!.trim(),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _GlassCard(
                    title: "Delivery mode",
                    icon: Icons.public_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChoicePill(
                              label: "Remote (Proctored)",
                              selected:
                                  deliveryMode ==
                                  ExamDeliveryMode.remoteProctored,
                              onTap: () {
                                setState(
                                  () => deliveryMode =
                                      ExamDeliveryMode.remoteProctored,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          deliveryMode == ExamDeliveryMode.remoteProctored
                              ? "Remote proctored examination. Device checks are required."
                              : "Distance self-practice. Exam proctoring is off.",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isDeliveryLocked)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "Delivery mode is locked by lecturer backend settings.",
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (!isGradedLocked)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "Remote proctored mode is available only for graded backend sessions.",
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.68),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassCard(
                    title: "Examination type",
                    icon: Icons.verified_user_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChoicePill(
                          label: "Graded (Proctored)",
                          selected: gradingType == GradingType.graded,
                          onTap: () => setState(() {
                            gradingType = GradingType.graded;
                            _syncGradedTemplate();
                          }),
                        ),
                        _ChoicePill(
                          label: "Ungraded (No Proctoring)",
                          selected: gradingType == GradingType.ungraded,
                          onTap: () => setState(() {
                            gradingType = GradingType.ungraded;
                            _syncGradedTemplate();
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gradingType == GradingType.graded
                        ? "Graded examinations use lecturer/admin-defined question sets."
                        : "Ungraded examinations are self-practice and not proctored.",
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isGradedLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Question types, counts, and timer are locked by lecturer backend settings.",
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  _GlassCard(
                    title: "Mode",
                    icon: Icons.tune_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChoicePill(
                              label: "Exam Simulation",
                              selected: mode == ExamMode.simulation,
                              onTap: isGradedLocked
                                  ? () {}
                                  : () => setState(
                                      () => mode = ExamMode.simulation,
                                    ),
                            ),
                            _ChoicePill(
                              label: "Practice",
                              selected: mode == ExamMode.practice,
                              onTap: isGradedLocked
                                  ? () {}
                                  : () => setState(
                                      () => mode = ExamMode.practice,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          mode == ExamMode.simulation
                              ? "Runs like real exam: you finish then see report."
                              : "Runs section-by-section with feedback after each section.",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        if (isGradedLocked)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "Mode is locked by lecturer backend settings.",
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassCard(
                    title: "Question types",
                    icon: Icons.layers_outlined,
                    child: Column(
                      children: [
                        _SwitchRow(
                          title: "Objective (CBT)",
                          subtitle: "Fast scoring + wide coverage",
                          value: objective,
                          enabled: !isGradedLocked,
                          onChanged: (v) => setState(() => objective = v),
                        ),
                        _SwitchRow(
                          title: "Fill in the blank",
                          subtitle: "Short answers marked by lecturer keywords",
                          value: fillBlank,
                          enabled: !isGradedLocked,
                          onChanged: (v) => setState(() => fillBlank = v),
                        ),
                        _SwitchRow(
                          title: "Theory (Essay)",
                          subtitle: "Marked with keyword feedback + citations",
                          value: theory,
                          enabled: !isGradedLocked,
                          onChanged: (v) => setState(() => theory = v),
                        ),
                        const SizedBox(height: 10),
                        _TipBar(
                          text:
                              "Tip: Nigerian exams often have both CBT + Theory. Take both for best results.",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassCard(
                    title: "Topic",
                    icon: Icons.category_outlined,
                    child: _PremiumDropdown<String>(
                      value: topic,
                      items: [
                        "Mixed",
                        "WeakOnly",
                        ...topics.where((t) => t != "Mixed"),
                      ],
                      labelBuilder: (t) =>
                          t == "WeakOnly" ? "Weak topics only" : t,
                      onChanged: (v) {
                        if (isGradedLocked) return;
                        setState(() => topic = v ?? "Mixed");
                      },
                    ),
                  ),
                  if (isGradedLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Topic is locked by lecturer backend settings.",
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  _GlassCard(
                    title: "Counts",
                    icon: Icons.format_list_numbered_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isGradedLocked) ...[
                          if (objective)
                            _LockedCountRow(
                              label: "Objective questions",
                              value: objectiveCount,
                            ),
                          if (fillBlank)
                            _LockedCountRow(
                              label: "Fill-blank questions",
                              value: fillCount,
                            ),
                          if (theory)
                            _LockedCountRow(
                              label: "Theory questions",
                              value: theoryCount,
                            ),
                        ] else ...[
                          if (objective)
                            _SliderBlock(
                              label: "Objective questions",
                              value: objectiveCount,
                              min: 5,
                              max: 60,
                              onChanged: (v) =>
                                  setState(() => objectiveCount = v),
                            ),
                          if (fillBlank)
                            _SliderBlock(
                              label: "Fill-blank questions",
                              value: fillCount,
                              min: 5,
                              max: 40,
                              onChanged: (v) => setState(() => fillCount = v),
                            ),
                          if (theory)
                            _SliderBlock(
                              label: "Theory questions",
                              value: theoryCount,
                              min: 1,
                              max: 10,
                              onChanged: (v) => setState(() => theoryCount = v),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassCard(
                    title: "Duration",
                    icon: Icons.timer_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDurationLocked)
                          _LockedCountRow(
                            label: "Duration (minutes)",
                            value: minutes,
                          )
                        else ...[
                          Slider(
                            value: minutes.toDouble(),
                            min: 10,
                            max: 180,
                            divisions: 17,
                            label: "$minutes mins",
                            onChanged: (v) =>
                                setState(() => minutes = v.round()),
                          ),
                          Text(
                            "$minutes minutes",
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _PrimaryCta(
                    label: gradingType == GradingType.graded
                        ? "Start ${AppStrings.gradedExamination}"
                        : "Start Ungraded Examination",
                    onTap: () async {
                      final gradedTemplate = gradingType == GradingType.graded
                          ? (_gradedTemplate ??
                                GradedSessionTemplateService.templateFor(
                                  courseCode: courseCode!,
                                  sessionType: SessionType.examination,
                                ))
                          : null;

                      if (gradingType == GradingType.graded &&
                          gradedTemplate == null) {
                        Get.snackbar(
                          "Graded template missing",
                          "Lecturer has not published graded examination settings yet.",
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final effectiveObjective =
                          gradedTemplate?.hasObjective ?? objective;
                      final effectiveFillBlank =
                          gradedTemplate?.hasFillBlank ?? fillBlank;
                      final effectiveTheory =
                          gradedTemplate?.hasTheory ?? theory;
                      final effectiveObjectiveCount =
                          gradedTemplate?.objectiveQuestions ??
                          (effectiveObjective ? objectiveCount : 0);
                      final effectiveFillCount =
                          gradedTemplate?.fillBlankQuestions ??
                          (effectiveFillBlank ? fillCount : 0);
                      final effectiveTheoryCount =
                          gradedTemplate?.theoryQuestions ??
                          (effectiveTheory ? theoryCount : 0);
                      final effectiveMinutes =
                          gradedTemplate?.durationMinutes ?? minutes;
                      final effectiveMode = gradedTemplate != null
                          ? ExamMode.simulation
                          : mode;
                      final effectiveTopic = gradedTemplate != null
                          ? "Mixed"
                          : topic;
                      final effectiveDeliveryMode =
                          gradedTemplate?.deliveryMode ?? deliveryMode;

                      if (!effectiveObjective &&
                          !effectiveFillBlank &&
                          !effectiveTheory) {
                        Get.snackbar(
                          "Select a type",
                          "Choose at least one question type.",
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      if (gradingType == GradingType.graded) {
                        if (gradedTemplate == null) {
                          Get.snackbar(
                            "Proctored setup locked",
                            "Remote proctored sessions must use backend lecturer settings.",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                      }

                      final sections = <String>[];
                      if (effectiveObjective) {
                        sections.add(ExamSectionType.objective);
                      }
                      if (effectiveFillBlank) {
                        sections.add(ExamSectionType.fillBlank);
                      }
                      if (effectiveTheory) sections.add(ExamSectionType.theory);

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
                        questionSource: gradingType == GradingType.graded
                            ? QuestionSourceType.lecturerAdmin
                            : QuestionSourceType.studentLocal,
                        whiteboardEnabled: whiteboardEnabledForGraded,
                        whiteboardRequired:
                            whiteboardEnabledForGraded &&
                            drawingPolicy.whiteboardRequired,
                        whiteboardPrompt: whiteboardEnabledForGraded
                            ? drawingPolicy.prompt
                            : null,
                      );

                      Get.find<ExamController>().startExam(cfg);

                      if (cfg.isCenterBased) {
                        Get.toNamed(Routes.examRun, arguments: cfg);
                        return;
                      }

                      final proctoring =
                          Get.isRegistered<ProctoringController>()
                          ? Get.find<ProctoringController>()
                          : Get.put(ProctoringController(), permanent: true);

                      final examId =
                          "${cfg.courseCode}-${DateTime.now().millisecondsSinceEpoch}";

                      if (gradingType == GradingType.graded) {
                        await proctoring.startExamSequence(
                          examId,
                          onVerified: () =>
                              Get.toNamed(Routes.examRun, arguments: cfg),
                        );
                      } else {
                        Get.toNamed(Routes.examRun, arguments: cfg);
                      }
                    },
                    subText:
                        "Your report will show weak areas + missing keywords + tomorrow plan.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------- UI kit -------------------------------- */

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.rightPill,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final String rightPill;
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: Text(
              rightPill,
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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
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
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (v) =>
                    DropdownMenuItem<T>(value: v, child: Text(labelBuilder(v))),
              )
              .toList(),
          onChanged: onChanged,
        ),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.14)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.22)
                : cs.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? cs.primary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: enabled ? 0.70 : 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

class _TipBar extends StatelessWidget {
  const _TipBar({required this.text});
  final String text;

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
          Icon(Icons.lightbulb_outline, color: cs.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: $value",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min),
          onChanged: (v) => onChanged(v.round()),
        ),
        const SizedBox(height: 6),
        Divider(color: cs.onSurface.withValues(alpha: 0.08)),
        const SizedBox(height: 6),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$value (locked)',
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
  });

  final String label;
  final VoidCallback onTap;
  final String subText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subText,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72)),
            ),
          ],
        ),
      ),
    );
  }
}
