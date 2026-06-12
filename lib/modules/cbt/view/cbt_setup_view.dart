import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/models/multi_format_exam_models.dart';
import '../../../data/services/cbt_question_service.dart';
import '../../../data/services/drawing_requirement_service.dart';
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
  String mode = 'Timed';
  String gradingType = GradingType.graded;
  ExamDeliveryMode deliveryMode = ExamDeliveryMode.remoteProctored;
  String topic = 'Mixed';
  bool objective = true;
  bool fillBlank = true;
  bool theory = true;
  int questions = 10;
  int fillQuestions = 4;
  int theoryQuestions = 1;
  bool includeObjectiveSingle = true;
  bool includeObjectiveMultiple = true;
  bool includeTrueFalse = true;
  bool includeFillBlank = true;
  bool includeShortAnswer = true;
  bool includeEssay = true;
  bool includeDragDrop = true;
  bool includeWhiteboard = true;
  bool shuffleQuestions = true;
  bool lockCopyPaste = true;
  bool calculatorEnabled = false;
  late bool demoMode;
  int minutes = 30;
  GradedSessionTemplate? _gradedTemplate;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map?;
    final requestedGradingType = args?['gradingType']?.toString();
    if (requestedGradingType == GradingType.ungraded) {
      gradingType = GradingType.ungraded;
    }
    demoMode = StorageService.getDemoMode();
    _syncGradedTemplate();
  }

  void _syncGradedTemplate() {
    if (gradingType != GradingType.graded) {
      _gradedTemplate = null;
      deliveryMode = ExamDeliveryMode.remoteProctored;
      return;
    }

    mode = 'Timed';
    topic = 'Mixed';

    _gradedTemplate = GradedSessionTemplateService.templateFor(
      courseCode: widget.courseCode,
      sessionType: SessionType.assessment,
    );

    final t = _gradedTemplate;
    if (t == null) return;

    objective = t.hasObjective;
    fillBlank = t.hasFillBlank;
    theory = t.hasTheory;
    includeObjectiveSingle = t.hasObjective;
    includeObjectiveMultiple = t.hasObjective;
    includeTrueFalse = t.hasObjective;
    includeDragDrop = t.hasObjective;
    includeFillBlank = t.hasFillBlank;
    includeShortAnswer = t.hasTheory;
    includeEssay = t.hasTheory;
    includeWhiteboard = t.hasTheory;
    questions = t.objectiveQuestions;
    fillQuestions = t.fillBlankQuestions;
    theoryQuestions = t.theoryQuestions;
    minutes = t.durationMinutes;
    deliveryMode = ExamDeliveryMode.remoteProctored;
  }

  List<MultiFormatQuestionType> get _enabledFormats {
    return [
      if (includeObjectiveSingle) MultiFormatQuestionType.objectiveSingle,
      if (includeObjectiveMultiple) MultiFormatQuestionType.objectiveMultiple,
      if (includeTrueFalse) MultiFormatQuestionType.trueFalse,
      if (includeFillBlank) MultiFormatQuestionType.fillBlank,
      if (includeShortAnswer) MultiFormatQuestionType.shortAnswer,
      if (includeEssay) MultiFormatQuestionType.essay,
      if (includeDragDrop) MultiFormatQuestionType.dragDrop,
      if (includeWhiteboard) MultiFormatQuestionType.whiteboard,
    ];
  }

  void _setFormat(MultiFormatQuestionType type, bool value) {
    setState(() {
      switch (type) {
        case MultiFormatQuestionType.objectiveSingle:
          includeObjectiveSingle = value;
          break;
        case MultiFormatQuestionType.objectiveMultiple:
          includeObjectiveMultiple = value;
          break;
        case MultiFormatQuestionType.trueFalse:
          includeTrueFalse = value;
          break;
        case MultiFormatQuestionType.fillBlank:
          includeFillBlank = value;
          break;
        case MultiFormatQuestionType.shortAnswer:
          includeShortAnswer = value;
          break;
        case MultiFormatQuestionType.essay:
          includeEssay = value;
          break;
        case MultiFormatQuestionType.dragDrop:
          includeDragDrop = value;
          break;
        case MultiFormatQuestionType.whiteboard:
          includeWhiteboard = value;
          break;
      }
      objective =
          includeObjectiveSingle ||
          includeObjectiveMultiple ||
          includeTrueFalse ||
          includeDragDrop;
      fillBlank = includeFillBlank;
      theory = includeShortAnswer || includeEssay || includeWhiteboard;
    });
  }

  ExamSecurityPolicy _securityPolicy() {
    return ExamSecurityPolicy(
      demoMode: demoMode,
      shuffleQuestions: shuffleQuestions,
      lockCopyPaste: lockCopyPaste,
      calculatorEnabled: calculatorEnabled,
      requireProctoring: gradingType == GradingType.graded,
      allowVerificationOverride: demoMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topics = CBTQuestionService.topicsForCourse(widget.courseCode);
    final isGradedLocked = gradingType == GradingType.graded;
    final isDeliveryLocked = isGradedLocked;
    final isDurationLocked = isGradedLocked && _gradedTemplate != null;
    final drawingPolicy = DrawingRequirementService.policyForCourse(
      widget.courseCode,
    );
    final whiteboardEnabledForGraded =
        gradingType == GradingType.graded &&
        drawingPolicy.whiteboardEnabledForGraded;
    final sampleFormatQuestions = MultiFormatSampleExamService.questions(
      courseCode: widget.courseCode,
      topic: topic,
      formats: _enabledFormats.isEmpty
          ? MultiFormatSampleExamService.importedFormats
          : _enabledFormats,
    );

    return Scaffold(
      appBar: AppBar(title: Text('${widget.courseCode} - Assessment Setup')),
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assessment type',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Graded (Proctored)'),
                        selected: gradingType == GradingType.graded,
                        onSelected: (_) => setState(() {
                          gradingType = GradingType.graded;
                          _syncGradedTemplate();
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('Ungraded (No Proctoring)'),
                        selected: gradingType == GradingType.ungraded,
                        onSelected: (_) => setState(() {
                          gradingType = GradingType.ungraded;
                          _syncGradedTemplate();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gradingType == GradingType.graded
                        ? "Graded sessions use lecturer/admin-defined question sets."
                        : "Ungraded sessions are self-practice and not proctored.",
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
                ],
              ),
            ),
            const SizedBox(height: 12),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Imported sample pack',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  ...sampleFormatQuestions.map(
                    (question) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              question.type.label,
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              question.questionText,
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  const Text(
                    'Delivery mode',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Remote (Proctored)'),
                        selected:
                            deliveryMode == ExamDeliveryMode.remoteProctored,
                        onSelected: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deliveryMode == ExamDeliveryMode.remoteProctored
                        ? 'Graded assessment. Environment, device, and audio checks are required.'
                        : 'Distance self-practice. Exam proctoring is off.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isDeliveryLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Graded assessments always use proctoring. Ungraded practice does not.',
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
                        'Remote proctored mode is available only for graded backend sessions.',
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

            if (drawingPolicy.whiteboardEnabledForGraded) ...[
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagram whiteboard',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      whiteboardEnabledForGraded
                          ? (drawingPolicy.whiteboardRequired
                                ? 'Enabled and required for graded assessments.'
                                : 'Enabled for graded assessments.')
                          : 'Available, but activated only in graded mode.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (drawingPolicy.prompt != null &&
                        drawingPolicy.prompt!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        drawingPolicy.prompt!.trim(),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.68),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['Timed', 'Untimed', 'CBT style']
                        .map(
                          (m) => ChoiceChip(
                            label: Text(m),
                            selected: mode == m,
                            onSelected: isGradedLocked
                                ? null
                                : (_) => setState(() => mode = m),
                          ),
                        )
                        .toList(),
                  ),
                  if (isGradedLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Mode is locked by lecturer backend settings.',
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

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Topic',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: topic,
                    items: topics
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: isGradedLocked
                        ? null
                        : (v) => setState(() => topic = v ?? 'Mixed'),
                  ),
                  if (isGradedLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Topic is locked by lecturer backend settings.',
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

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exam formats',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Imported from the K-SLAS CBT format pack.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MultiFormatSampleExamService.importedFormats
                        .map(
                          (format) => FilterChip(
                            label: Text(format.label),
                            selected: _enabledFormats.contains(format),
                            onSelected: isGradedLocked
                                ? null
                                : (value) => _setFormat(format, value),
                          ),
                        )
                        .toList(),
                  ),
                  if (isGradedLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Formats are locked by lecturer backend settings for graded sessions.',
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

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security & demo',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Demo verification override'),
                    subtitle: const Text(
                      'Failed verification can continue in demo mode.',
                    ),
                    value: demoMode,
                    onChanged: (value) async {
                      setState(() => demoMode = value);
                      await StorageService.setDemoMode(value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Shuffle questions'),
                    value: shuffleQuestions,
                    onChanged: (value) =>
                        setState(() => shuffleQuestions = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lock copy and paste'),
                    value: lockCopyPaste,
                    onChanged: (value) => setState(() => lockCopyPaste = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Scientific calculator'),
                    value: calculatorEnabled,
                    onChanged: (value) =>
                        setState(() => calculatorEnabled = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Counts',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (isGradedLocked) ...[
                    if (objective)
                      _lockedCountRow(context, 'Objective', questions),
                    if (fillBlank)
                      _lockedCountRow(
                        context,
                        'Fill in the blank',
                        fillQuestions,
                      ),
                    if (theory)
                      _lockedCountRow(context, 'Essay', theoryQuestions),
                  ] else ...[
                    if (objective) ...[
                      Slider(
                        value: questions.toDouble(),
                        min: 5,
                        max: 50,
                        divisions: 9,
                        label: '$questions',
                        onChanged: (v) => setState(() => questions = v.round()),
                      ),
                      Text(
                        '$questions objective questions',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    if (fillBlank) ...[
                      Slider(
                        value: fillQuestions.toDouble(),
                        min: 3,
                        max: 30,
                        divisions: 9,
                        label: '$fillQuestions',
                        onChanged: (v) =>
                            setState(() => fillQuestions = v.round()),
                      ),
                      Text(
                        '$fillQuestions fill-blank questions',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    if (theory) ...[
                      Slider(
                        value: theoryQuestions.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$theoryQuestions',
                        onChanged: (v) =>
                            setState(() => theoryQuestions = v.round()),
                      ),
                      Text(
                        '$theoryQuestions essay questions',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (mode != 'Untimed')
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timer',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (isDurationLocked)
                      _lockedValueRow(context, 'Duration', '$minutes minutes')
                    else ...[
                      Slider(
                        value: minutes.toDouble(),
                        min: 5,
                        max: 60,
                        divisions: 11,
                        label: '$minutes min',
                        onChanged: (v) => setState(() => minutes = v.round()),
                      ),
                      Text(
                        '$minutes minutes',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final gradedTemplate = gradingType == GradingType.graded
                      ? (_gradedTemplate ??
                            GradedSessionTemplateService.templateFor(
                              courseCode: widget.courseCode,
                              sessionType: SessionType.assessment,
                            ))
                      : null;

                  if (gradingType == GradingType.graded &&
                      gradedTemplate == null) {
                    Get.snackbar(
                      'Graded template missing',
                      'Lecturer has not published graded assessment settings yet.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  final effectiveObjective =
                      gradedTemplate?.hasObjective ??
                      (includeObjectiveSingle ||
                          includeObjectiveMultiple ||
                          includeTrueFalse ||
                          includeDragDrop);
                  final effectiveFillBlank =
                      gradedTemplate?.hasFillBlank ?? includeFillBlank;
                  final effectiveTheory =
                      gradedTemplate?.hasTheory ??
                      (includeShortAnswer || includeEssay || includeWhiteboard);
                  final enabledFormats = gradedTemplate != null
                      ? [
                          if (gradedTemplate.hasObjective)
                            MultiFormatQuestionType.objectiveSingle,
                          if (gradedTemplate.hasObjective)
                            MultiFormatQuestionType.objectiveMultiple,
                          if (gradedTemplate.hasObjective)
                            MultiFormatQuestionType.trueFalse,
                          if (gradedTemplate.hasFillBlank)
                            MultiFormatQuestionType.fillBlank,
                          if (gradedTemplate.hasTheory)
                            MultiFormatQuestionType.shortAnswer,
                          if (gradedTemplate.hasTheory)
                            MultiFormatQuestionType.essay,
                          if (gradedTemplate.hasObjective)
                            MultiFormatQuestionType.dragDrop,
                          if (gradedTemplate.hasTheory)
                            MultiFormatQuestionType.whiteboard,
                        ]
                      : _enabledFormats;
                  final effectiveObjectiveCount =
                      gradedTemplate?.objectiveQuestions ??
                      (effectiveObjective ? questions : 0);
                  final effectiveFillCount =
                      gradedTemplate?.fillBlankQuestions ??
                      (effectiveFillBlank ? fillQuestions : 0);
                  final effectiveTheoryCount =
                      gradedTemplate?.theoryQuestions ??
                      (effectiveTheory ? theoryQuestions : 0);
                  final effectiveMinutes =
                      gradedTemplate?.durationMinutes ?? minutes;
                  final effectiveMode = gradedTemplate != null ? 'Timed' : mode;
                  final effectiveTopic = gradedTemplate != null
                      ? 'Mixed'
                      : topic;

                  if (!effectiveObjective &&
                      !effectiveFillBlank &&
                      !effectiveTheory) {
                    Get.snackbar(
                      'Select a type',
                      'Choose at least one question type.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  final effectiveDeliveryMode =
                      ExamDeliveryMode.remoteProctored;
                  final effectiveWhiteboardEnabled =
                      gradingType == GradingType.graded
                      ? whiteboardEnabledForGraded
                      : includeWhiteboard;
                  final effectiveWhiteboardRequired =
                      effectiveWhiteboardEnabled &&
                      (gradingType == GradingType.graded
                          ? drawingPolicy.whiteboardRequired
                          : false);
                  final effectiveWhiteboardPrompt = effectiveWhiteboardEnabled
                      ? (drawingPolicy.prompt ??
                            'Use the whiteboard for diagrams or workings.')
                      : null;
                  final securityPolicy = _securityPolicy();
                  if (gradingType == GradingType.graded) {
                    if (gradedTemplate == null) {
                      Get.snackbar(
                        'Proctored setup locked',
                        'Remote proctored sessions must use backend lecturer settings.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                  }
                  final questionSource = gradingType == GradingType.graded
                      ? QuestionSourceType.lecturerAdmin
                      : QuestionSourceType.studentLocal;

                  Future<void> openProctoredAssessment(
                    VoidCallback launch,
                  ) async {
                    final proctoring = Get.isRegistered<ProctoringController>()
                        ? Get.find<ProctoringController>()
                        : Get.put(ProctoringController(), permanent: true);
                    final assessmentId =
                        '${widget.courseCode}-assessment-${DateTime.now().millisecondsSinceEpoch}';
                    await proctoring.startAssessmentSequence(
                      assessmentId,
                      onVerified: launch,
                    );
                  }

                  if (effectiveObjective &&
                      !effectiveFillBlank &&
                      !effectiveTheory) {
                    final arguments = {
                      'courseCode': widget.courseCode,
                      'mode': effectiveMode,
                      'topic': effectiveTopic,
                      'questions': effectiveObjectiveCount,
                      'minutes': effectiveMinutes,
                      'sessionType': SessionType.assessment,
                      'gradingType': gradingType,
                      'questionSource': questionSource,
                      'deliveryMode': effectiveDeliveryMode.raw,
                      'whiteboardEnabled': effectiveWhiteboardEnabled,
                      'whiteboardRequired': effectiveWhiteboardRequired,
                      'whiteboardPrompt': effectiveWhiteboardPrompt,
                      'enabledFormats': enabledFormats
                          .map((format) => format.raw)
                          .toList(),
                      'demoMode': securityPolicy.demoMode,
                      'shuffleQuestions': securityPolicy.shuffleQuestions,
                      'lockCopyPaste': securityPolicy.lockCopyPaste,
                      'calculatorEnabled': securityPolicy.calculatorEnabled,
                    };
                    if (gradingType == GradingType.graded) {
                      await openProctoredAssessment(
                        () => Get.toNamed('/cbt/take', arguments: arguments),
                      );
                    } else {
                      Get.toNamed('/cbt/take', arguments: arguments);
                    }
                    return;
                  }

                  final sections = <String>[];
                  if (effectiveObjective) {
                    sections.add(ExamSectionType.objective);
                  }
                  if (effectiveFillBlank) {
                    sections.add(ExamSectionType.fillBlank);
                  }
                  if (effectiveTheory) {
                    sections.add(ExamSectionType.theory);
                  }

                  final cfg = ExamConfig(
                    courseCode: widget.courseCode,
                    sessionType: SessionType.assessment,
                    gradingType: gradingType,
                    mode: effectiveMode == 'Untimed'
                        ? ExamMode.practice
                        : ExamMode.simulation,
                    topic: effectiveTopic,
                    sections: sections,
                    objectiveQuestions: effectiveObjectiveCount,
                    fillBlankQuestions: effectiveFillCount,
                    theoryQuestions: effectiveTheoryCount,
                    durationMinutes: effectiveMinutes,
                    questionSource: questionSource,
                    deliveryMode: effectiveDeliveryMode,
                    whiteboardEnabled: effectiveWhiteboardEnabled,
                    whiteboardRequired: effectiveWhiteboardRequired,
                    whiteboardPrompt: effectiveWhiteboardPrompt,
                    enabledFormats: enabledFormats,
                    securityPolicy: securityPolicy,
                  );

                  final exam = Get.isRegistered<ExamController>()
                      ? Get.find<ExamController>()
                      : Get.put(ExamController());
                  exam.startExam(cfg);
                  if (gradingType == GradingType.graded) {
                    await openProctoredAssessment(
                      () => Get.toNamed('/exam/run', arguments: cfg),
                    );
                  } else {
                    Get.toNamed('/exam/run', arguments: cfg);
                  }
                },
                child: Text(
                  gradingType == GradingType.graded
                      ? 'Start ${AppStrings.gradedAssessment}'
                      : 'Start Ungraded Assessment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => _glassCard(
    context,
    child: Padding(padding: const EdgeInsets.all(14), child: child),
  );
}

Widget _glassCard(BuildContext context, {required Widget child}) {
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
        child: child,
      ),
    ),
  );
}

Widget _lockedCountRow(BuildContext context, String label, int value) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    margin: const EdgeInsets.only(top: 8),
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
            '$label questions',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800),
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

Widget _lockedValueRow(BuildContext context, String label, String value) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    margin: const EdgeInsets.only(top: 8),
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
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800),
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
