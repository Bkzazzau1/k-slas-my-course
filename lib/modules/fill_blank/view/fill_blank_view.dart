import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    final submit = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Submit fill-blank section?'),
        content: const Text(
          'This will end this section and return to the examination section list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Review answers'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Submit section'),
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
                      'Short-answer section. Type the exact concept or term that completes each statement.',
                  onBack: _leaveSection,
                  rightPill: '${cfg.fillBlankQuestions} Qs',
                ),
              ),
              Expanded(
                child: Obx(() {
                  final qs = controller.questions;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    children: [
                      _GlassCard(
                        title: 'Instructions',
                        icon: Icons.rule_outlined,
                        child: Text(
                          'Answer each item using a concise technical term or phrase. Review your responses before submitting this section.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.80),
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
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
                                  onChanged: (v) => controller.setAnswer(q.id, v),
                                  enableInteractiveSelection: !pasteLocked,
                                  contextMenuBuilder: pasteLocked
                                      ? (context, editableTextState) =>
                                            const SizedBox.shrink()
                                      : null,
                                  decoration: InputDecoration(
                                    hintText: 'Type your answer',
                                    filled: true,
                                    fillColor: cs.onSurface.withValues(alpha: 0.04),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: cs.onSurface.withValues(alpha: 0.10),
                                      ),
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
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${q.marks} mark${q.marks == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
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
                child: ClipRRect(
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
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
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
                      style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
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
