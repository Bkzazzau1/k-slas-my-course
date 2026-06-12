import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../controller/practice_controller.dart';

class PracticeSessionView extends GetView<PracticeController> {
  const PracticeSessionView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice • ${controller.course.code}'),
        actions: [
          Obx(() {
            if (controller.selectedMode.value != 'Timed') {
              return const SizedBox.shrink();
            }
            final s = controller.timeLeftSec.value;
            final mm = (s ~/ 60).toString().padLeft(2, '0');
            final ss = (s % 60).toString().padLeft(2, '0');
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Text(
                    '$mm:$ss',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: LuxuryScaffold(
        safeArea: false,
        child: Obx(() {
          if (controller.questions.isEmpty) {
            return const Center(child: Text('No questions loaded.'));
          }

          final q = controller.currentQ;
          final idx = controller.currentIndex.value + 1;
          final total = controller.questions.length;
          final progress = total == 0 ? 0.0 : (idx / total).clamp(0.0, 1.0);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _glassCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Question $idx / $total',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            controller.finish();
                            Get.offNamed(Routes.practiceResult);
                          },
                          child: const Text('Finish'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(value: progress),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      q.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              ...List.generate(q.options.length, (i) {
                final opt = q.options[i];
                return Obx(() {
                  final picked = controller.selectedOptionIndex.value == i;
                  return _optionCard(
                    context,
                    text: opt,
                    selected: picked,
                    onTap: () => controller.chooseOption(i),
                  );
                });
              }),
            ],
          );
        }),
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.currentIndex.value == 0
                            ? null
                            : controller.prev,
                        icon: const Icon(Icons.chevron_left_rounded),
                        label: const Text('Prev'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            controller.currentIndex.value >=
                                controller.questions.length - 1
                            ? null
                            : controller.next,
                        icon: const Icon(Icons.chevron_right_rounded),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionCard(
    BuildContext context, {
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.14)
                : cs.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.35)
                  : cs.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 10),
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
        ),
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
