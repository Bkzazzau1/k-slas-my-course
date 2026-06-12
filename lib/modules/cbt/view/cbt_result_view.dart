import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/cbt_models.dart';
import '../../../data/models/exam_models.dart';

class CBTResultView extends StatelessWidget {
  const CBTResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final attempt = Get.arguments as CBTAttemptModel;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _glassCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${attempt.courseCode} - ${attempt.mode}',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${attempt.scorePct}%',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      attempt.gradingType == GradingType.graded
                          ? 'Graded Assessment'
                          : 'Ungraded Assessment',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attempt.deliveryMode.label,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${attempt.correct}/${attempt.totalQuestions} correct - ${attempt.topic}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (attempt.whiteboardEnabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        attempt.whiteboardSubmitted
                            ? 'Whiteboard diagram submitted (${attempt.whiteboardStrokeCount} stroke(s)).'
                            : (attempt.whiteboardRequired
                                  ? 'Whiteboard diagram was required but not submitted.'
                                  : 'No whiteboard diagram submitted.'),
                        style: TextStyle(
                          color: attempt.whiteboardSubmitted
                              ? cs.primary
                              : (attempt.whiteboardRequired
                                    ? cs.error
                                    : cs.onSurface.withValues(alpha: 0.72)),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (attempt.whiteboardPrompt != null &&
                          attempt.whiteboardPrompt!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          attempt.whiteboardPrompt!.trim(),
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    _hint(attempt.scorePct),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Get.back(result: attempt),
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hint(int score) {
    if (score >= 80) {
      return const Text(
        'Excellent. Do another mixed set to confirm consistency.',
      );
    }
    if (score >= 60) {
      return const Text('Good. Revise your weak topics then retry.');
    }
    return const Text(
      'Needs work. Start Revision Mode and practice topic-by-topic.',
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
