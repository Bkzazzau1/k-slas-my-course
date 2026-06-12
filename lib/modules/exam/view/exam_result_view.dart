import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/models/theory_rewrite_models.dart';
import '../../../data/services/exam_insights_service.dart';
import '../../revision/controller/revision_controller.dart';

class ExamResultView extends StatelessWidget {
  const ExamResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final res = Get.arguments as ExamResult;
    final isAssessment = res.sessionType == SessionType.assessment;
    final sessionLabel = isAssessment ? "assessment" : "examination";
    final gradingLabel = res.gradingType == GradingType.graded
        ? "graded"
        : "ungraded";
    final insights = ExamInsightsService.analyze(res);

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _ResultHero(res: res),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _GlassCard(
                    title: "What this means",
                    icon: Icons.insights_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...insights.suggestions.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "-  ",
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Expanded(child: Text(s)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (insights.missingKeywords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _GlassCard(
                      title: "Missing theory keywords",
                      icon: Icons.key_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: insights.missingKeywords.take(24).map((
                              k,
                            ) {
                              return ActionChip(
                                label: Text(k),
                                onPressed: () {
                                  Get.toNamed(
                                    Routes.theoryRewrite,
                                    arguments: TheoryRewritePrompt(
                                      courseCode: res.courseCode,
                                      topic: "Theory keywords",
                                      question:
                                          "Rewrite your answer using the lecturer keywords below. Keep definition + properties + example.",
                                      sourceRef:
                                          "Lecturer Notes (from exam citations)",
                                      requiredKeywords:
                                          insights.missingKeywords,
                                      originalAnswer: null,
                                      originalScore: null,
                                      originalTotal: 10,
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.secondary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              "Why keywords matter: lecturers award marks when they see the exact terms taught in class. "
                              "Even correct ideas can lose marks without those terms.",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (insights.fillBlankMistakes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _GlassCard(
                      title: "Fill-blank mistakes",
                      icon: Icons.rule_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...insights.fillBlankMistakes.take(6).map((m) {
                            final prompt = m["prompt"]?.toString() ?? "";
                            final student = m["student"]?.toString() ?? "";
                            final expected =
                                (m["expected"] as List?)?.join(", ") ?? "";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.onSurface.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: cs.onSurface.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prompt,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text("Your answer: $student"),
                                  const SizedBox(height: 2),
                                  Text("Accepted (from notes): $expected"),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  if (res.whiteboardEnabled) ...[
                    const SizedBox(height: 12),
                    _GlassCard(
                      title: "Whiteboard diagram",
                      icon: Icons.draw_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.whiteboardRequired
                                ? "Diagram was required for this session."
                                : "Diagram was optional for this session.",
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            res.whiteboardSubmitted
                                ? "Submitted (${res.whiteboardStrokeCount} stroke(s))."
                                : "No whiteboard diagram submitted.",
                            style: TextStyle(
                              color: res.whiteboardSubmitted
                                  ? cs.primary
                                  : cs.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (res.whiteboardPrompt != null &&
                              res.whiteboardPrompt!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              res.whiteboardPrompt!.trim(),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  _GlassCard(
                    title: "Section scores",
                    icon: Icons.list_alt_outlined,
                    child: Column(
                      children: res.sectionScores
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.onSurface.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: cs.onSurface.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: cs.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: cs.primary.withValues(
                                            alpha: 0.18,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.checklist_outlined,
                                        color: cs.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _label(s.sectionType),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${s.scoredMarks}/${s.totalMarks}",
                                            style: TextStyle(
                                              color: cs.onSurface.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _PrimaryCta(
                    label: "Generate Tomorrow Plan",
                    onTap: () {
                      Get.find<RevisionPlanController>().applyExamResult(res);
                      Get.offAllNamed('/dashboard');
                    },
                    subText:
                        "We'll focus tomorrow on your weakest topics and missed keywords.",
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (isAssessment) {
                          Get.offAllNamed(
                            Routes.cbtSetup,
                            arguments: {"courseCode": res.courseCode},
                          );
                          return;
                        }
                        Get.offAllNamed(Routes.examSetup);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Take another $sessionLabel",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This was a $gradingLabel $sessionLabel.",
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
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

  String _label(String s) {
    if (s == ExamSectionType.objective) return "Objective (CBT)";
    if (s == ExamSectionType.fillBlank) return "Fill in the blank";
    return "Theory (Essay)";
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.res});
  final ExamResult res;

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
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: const Icon(Icons.assessment_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.courseCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  res.sessionType == SessionType.assessment
                      ? "Assessment report"
                      : "Examination report",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${res.pct}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                  ),
                ),
                Text(
                  "${res.scoredMarks}/${res.totalMarks} marks",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.90)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: const Text(
              "Report",
              style: TextStyle(
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
