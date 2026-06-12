import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../controller/dashboard_controller.dart';

class DashboardFocusLux extends GetView<DashboardController> {
  const DashboardFocusLux({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Obx(() {
      final weak = controller.weakTopics.isEmpty
          ? "Revision"
          : controller.weakTopics.first;
      final streak = controller.streakDays.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.secondary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_outlined, color: cs.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Study streak: $streak days",
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.2, // ✅ Prevents clipping
                    ),
                  ),
                ),
                _MiniPill(cs: cs, text: "Keep it up", tone: _Tone.secondary),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Smart tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(accent: cs.primary, icon: Icons.lightbulb_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Smart academic tip",
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Your weakest focus is $weak. If you revise it now, your CBT accuracy can jump quickly.",
                        style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Get.toNamed(Routes.weakAreas),
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Open weak areas"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.toNamed(
                                Routes.cbtTake,
                                arguments: {
                                  "courseCode":
                                      controller.courses.firstOrNull?.code ??
                                      "CSC 305",
                                  "mode": "Timed",
                                  "topic": weak,
                                  "questions": 12,
                                  "minutes": 12,
                                },
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(
                                  color: cs.primary.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Text("Practice now"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

enum _Tone { secondary }

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.cs, required this.text, required this.tone});
  final ColorScheme cs;
  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = cs.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          height: 1.2,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.accent, required this.icon});
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: accent),
    );
  }
}
