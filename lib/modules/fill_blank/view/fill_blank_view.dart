import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/assessment_calculator.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/sample_exam_service.dart';
import '../controller/fill_blank_controller.dart';

class FillBlankView extends StatefulWidget {
  const FillBlankView({super.key});

  @override
  State<FillBlankView> createState() => _FillBlankViewState();
}

class _FillBlankViewState extends State<FillBlankView> {
  bool _loaded = false;

  Future<void> _leaveSection() async {
    final leave = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leave fill-blank section?'),
        content: const Text(
          'Your answers have not been submitted. You can stay, or return to the section list.',
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

  Future<void> _submitSection(FillBlankController controller) async {
    final unanswered = controller.questions.length - controller.answers.length;
    final submit = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          unanswered > 0
              ? 'Submit with unanswered items?'
              : 'Submit fill-blank section?',
        ),
        content: Text(
          unanswered > 0
              ? 'You still have $unanswered unanswered item${unanswered == 1 ? '' : 's'}. Submit now?'
              : 'All items have been answered. Submit this section now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    final r = controller.submit();
    Get.back(
      result: {
        'section': 'FILL_BLANK',
        'totalMarks': r.totalMarks,
        'scoredMarks': r.scoredMarks,
        'extra': {'details': r.details},
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cfg = Get.arguments as ExamConfig;
    final controller = Get.find<FillBlankController>();
    final pasteLocked = cfg.securityPolicy.lockCopyPaste;

    if (!_loaded) {
      controller.load(
        SampleExamService.fillBlankQuestions(
          courseCode: cfg.courseCode,
          topic: cfg.topic,
          count: cfg.fillBlankQuestions,
        ),
      );
      _loaded = true;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leaveSection();
      },
      child: Scaffold(
        body: LuxuryScaffold(
          safeArea: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: _HeroHeader(
                  title: '${cfg.courseCode} - Fill in the blank',
                  subtitle:
                      'Type the exact concept or term that completes each statement.',
                  onBack: _leaveSection,
                  rightPill: '${cfg.fillBlankQuestions} Qs',
                ),
              ),
              Expanded(
                child: Obx(() {
                  final qs = controller.questions;
                  final answered = controller.answers.values
                      .where((v) => v.trim().isNotEmpty)
                      .length;
                  final remaining = (qs.length - answered).clamp(0, qs.length);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    children: [
                      _GlassCard(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _StatusPill(
                              icon: Icons.check_circle_outline,
                              text: 'Answered $answered/${qs.length}',
                            ),
                            _StatusPill(
                              icon: Icons.pending_actions_rounded,
                              text: 'Remaining $remaining',
                            ),
                            const AssessmentCalculatorButton(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...qs.asMap().entries.map((entry) {
                        final q = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GlassCard(
                            title: 'Question ${entry.key + 1}',
                            icon: Icons.edit_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.prompt,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  onChanged: (v) =>
                                      controller.setAnswer(q.id, v),
                                  enableInteractiveSelection: !pasteLocked,
                                  contextMenuBuilder: pasteLocked
                                      ? (context, editableTextState) =>
                                            const SizedBox.shrink()
                                      : null,
                                  decoration: InputDecoration(
                                    hintText: 'Type your answer',
                                    filled: true,
                                    fillColor: cs.onSurface.withValues(
                                      alpha: 0.04,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _StatusPill(
                                    icon: Icons.grade_outlined,
                                    text:
                                        '${q.marks} mark${q.marks == 1 ? '' : 's'}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: _GlassCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _leaveSection,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Section list'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _submitSection(controller),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Submit section'),
                        ),
                      ),
                    ],
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.rightPill,
  });
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final String rightPill;

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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({this.title, this.icon, required this.child});
  final String? title;
  final IconData? icon;
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
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (icon != null) Icon(icon, color: cs.primary),
                    if (icon != null) const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
