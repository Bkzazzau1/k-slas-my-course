import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../controller/practice_controller.dart';

class PracticeSetupView extends GetView<PracticeController> {
  const PracticeSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Practice - ${controller.course.code}')),
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Choose practice',
              style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
            ),
            const SizedBox(height: 12),

            _glassCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        children: ['Mixed', 'By topic']
                            .map(
                              (s) => ChoiceChip(
                                label: Text(s),
                                selected: controller.selectedSet.value == s,
                                onSelected: (_) =>
                                    controller.selectedSet.value = s,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.selectedSet.value != 'By topic') {
                        return const SizedBox.shrink();
                      }
                      final topics = ['Trees', 'Sorting', 'Graphs', 'Stacks'];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Topic',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: topics
                                .map(
                                  (t) => ChoiceChip(
                                    label: Text(t),
                                    selected: controller.selectedTopic.value == t,
                                    onSelected: (_) =>
                                        controller.selectedTopic.value = t,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            _glassCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mode',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        children: ['Timed', 'Untimed', 'CBT style']
                            .map(
                              (m) => ChoiceChip(
                                label: Text(m),
                                selected: controller.selectedMode.value == m,
                                onSelected: (_) =>
                                    controller.selectedMode.value = m,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Timed = countdown like exam. CBT style = exam feel (still MVP).',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Obx(() {
              final a = controller.lastAttempt.value;
              if (a == null) return const SizedBox.shrink();
              return _glassCard(
                context,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                          ),
                          child: Icon(Icons.assessment_outlined, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last attempt - ${a.topicLabel}',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Score: ${a.scorePct}% - ${a.mode}',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: cs.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: () {
                controller.startSession();
                Get.toNamed(Routes.practiceSession);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start practice'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
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
