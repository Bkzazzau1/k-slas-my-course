import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/theory_rewrite_models.dart';
import '../controller/theory_rewrite_controller.dart';

class TheoryRewriteView extends StatefulWidget {
  const TheoryRewriteView({super.key});

  @override
  State<TheoryRewriteView> createState() => _TheoryRewriteViewState();
}

class _TheoryRewriteViewState extends State<TheoryRewriteView> {
  late final TheoryRewriteController controller;
  late final TheoryRewritePrompt p;

  @override
  void initState() {
    super.initState();
    controller = Get.find<TheoryRewriteController>();

    p = Get.arguments as TheoryRewritePrompt;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadPrompt(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rewrite (Theory)')),
      body: LuxuryScaffold(
        safeArea: true,
        child: Obx(() {
        final br = controller.beforeResult.value;
        final ar = controller.afterResult.value;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
            _glassCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.courseCode} - ${p.topic}',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Source: ${p.sourceRef}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Required keywords (lecturer terms)',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.requiredKeywords
                          .take(24)
                          .map((k) => Chip(label: Text(k)))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Why keywords matter: lecturers scan for these terms before awarding full marks. '
                      'Correct ideas without the lecturer terms still lose marks.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _AnswerCard(
              title: 'Before (your previous answer)',
              controller: controller.beforeCtrl,
              hint: 'Paste your old answer here (or leave empty).',
            ),
            const SizedBox(height: 12),

            _AnswerCard(
              title: 'Rewrite (improved answer)',
              controller: controller.afterCtrl,
              hint: 'Rewrite using lecturer keywords + clear structure.',
              highlight: true,
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: Obx(
                () => FilledButton(
                  onPressed:
                      controller.isMarking.value ? null : controller.markRewrite,
                  child: controller.isMarking.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mark rewrite'),
                ),
              ),
            ),

            if (br != null || ar != null) ...[
              const SizedBox(height: 12),
              _CompareCard(before: br, after: ar),
            ],

            if (ar != null) ...[
              const SizedBox(height: 12),
              _glassCard(
                context,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rewrite keyword check',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      ...ar.keywordChecks.map(
                        (k) => Row(
                          children: [
                            Icon(
                              k.found ? Icons.check_circle : Icons.cancel,
                              color: k.found ? Colors.green : cs.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                k.keyword,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
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
            ],
          ],
          );
        }),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.title,
    required this.controller,
    required this.hint,
    this.highlight = false,
  });

  final String title;
  final TextEditingController controller;
  final String hint;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _glassCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              minLines: 5,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: highlight ? cs.primary : cs.outline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.before, required this.after});

  final dynamic before; // TheoryMarkResult?
  final dynamic after;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (before == null && after == null) return const SizedBox.shrink();

    final bScore = before?.scoredMarks ?? 0;
    final bTotal = before?.totalMarks ?? (after?.totalMarks ?? 10);

    final aScore = after?.scoredMarks ?? 0;
    final aTotal = after?.totalMarks ?? bTotal;

    final diff = aScore - bScore;

    return _glassCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Improvement',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _scoreBox('Before', '$bScore/$bTotal')),
                const SizedBox(width: 10),
                Expanded(child: _scoreBox('After', '$aScore/$aTotal')),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (diff >= 0 ? cs.primary : cs.error).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (diff >= 0 ? cs.primary : cs.error).withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                diff >= 0 ? '+$diff marks improvement' : '$diff marks drop',
                style: TextStyle(
                  color: diff >= 0 ? cs.primary : cs.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.04),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

Widget _glassCard(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
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
