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
          'This section has not been submitted. Leaving returns to the exam section list.',
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

    if (leave == true) {
      Get.back(result: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cfg = Get.arguments as ExamConfig;
    final controller = Get.find<FillBlankController>();
    final pasteLocked = cfg.securityPolicy.lockCopyPaste;

    // Load once (not every rebuild)
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
                  title: "${cfg.courseCode} - Fill in the blank",
                  subtitle:
                      "Marked strictly from lecturer keywords.\nIf it's not in your materials, it won't count.",
                  onBack: () {
                    _leaveSection();
                  },
                  rightPill: "${cfg.fillBlankQuestions} Qs",
                ),
              ),

              Expanded(
                child: Obx(() {
                  final qs = controller.questions;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    children: [
                      _GlassCard(
                        title: "Rules",
                        icon: Icons.rule_outlined,
                        child: Text(
                          "Use exact lecturer keywords. Short forms not taught in class may be rejected. "
                          "If the keyword is missing in your notes, your mark won't count.",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.80),
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...qs.map((q) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GlassCard(
                            title: "Question",
                            icon: Icons.edit_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.prompt,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
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
                                    hintText:
                                        "Your answer (keyword from notes)",
                                    filled: true,
                                    fillColor: cs.onSurface.withValues(
                                      alpha: 0.04,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.10,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.10,
                                        ),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.sticky_note_2_outlined,
                                      size: 16,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Source: ${q.sourceRef}",
                                        style: TextStyle(
                                          color: cs.onSurface.withValues(
                                            alpha: 0.70,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        "${q.marks} mark",
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
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

              // Sticky submit
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
                        border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.06),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            final r = controller.submit();
                            Get.back(
                              result: {
                                "section": "FILL_BLANK",
                                "totalMarks": r.totalMarks,
                                "scoredMarks": r.scoredMarks,
                                "extra": {"details": r.details},
                              },
                            );
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Submit Section",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
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

/* -------------------------- Shared premium widgets -------------------------- */

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
