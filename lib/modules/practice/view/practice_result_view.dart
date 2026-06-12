import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../controller/practice_controller.dart';

class PracticeResultView extends GetView<PracticeController> {
  const PracticeResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Practice - ${controller.course.code}')),
      body: LuxuryScaffold(
        safeArea: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _hero(
              context,
              title: 'Practice Mode',
              subtitle:
                  'Train fast, track weak areas, and improve your exam score.',
            ),
            const SizedBox(height: 12),

            _glassCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),

                  Obx(
                    () => Wrap(
                      spacing: 8,
                      runSpacing: 8,
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

                  const SizedBox(height: 14),

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
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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

            const SizedBox(height: 12),

            _glassCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                  const SizedBox(height: 10),
                  Text(
                    'Timed = countdown like exam. CBT style = exam feel (still MVP).',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
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
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                ),
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
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    controller.startSession();
                    Get.toNamed(Routes.practiceSession);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start practice'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
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
    );
  }

  Widget _glassCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: child,
        ),
      ),
    );
  }
}
