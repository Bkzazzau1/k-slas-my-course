// lib/features/dashboard/widgets/dashboard_hero_focus_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../modules/revision/controller/revision_controller.dart';
import '../../../modules/settings/controller/settings_controller.dart';
import '../../../modules/timetable/controller/timetable_controller.dart';
import '../../../modules/weak_areas/controller/weak_areas_controller.dart';
import '../controller/dashboard_controller.dart';
import 'premium_glass.dart';

class DashboardHeroFocusCard extends GetView<DashboardController> {
  const DashboardHeroFocusCard({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final rev = Get.find<RevisionPlanController>();
    final settings = Get.find<SettingsController>();
    final tt = Get.find<TimetableController>();

    final weak = Get.find<WeakAreasController>();

    return Obx(() {
      final plan = rev.plan.value;
      final summary = weak.summary.value;
      final top = summary?.weakestFirst.isNotEmpty == true
          ? summary!.weakestFirst.first
          : null;

      final focusTopic = plan?.focusTopic ?? top?.topic ?? "Revision";
      final subtitle =
          plan?.reason ??
          (top == null
              ? "Take a short CBT to discover your weak areas."
              : "Your weakest area needs attention today.");

      // ExamMode badge (from Settings)
      final mode = settings.examMode.value.toString();
      final modeLabel = _prettyExamMode(mode);

      // Today schedule: next exam or next timetable item
      final exam = controller.nextExam.value;
      final scheduleLine = _todayScheduleLine(
        examCourse: exam?.courseCode,
        examWhen: exam?.dateLabel,
        tt: tt,
      );

      final actionLabel = "Take Exam";
      final actionRoute = Routes.examSetup;

      final courseCode =
          plan?.courseCode ?? controller.courses.firstOrNull?.code ?? "CSC 305";

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withValues(alpha: 0.94),
              cs.secondary.withValues(alpha: 0.82),
            ],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              offset: const Offset(0, 12),
              color: cs.primary.withValues(alpha: 0.20),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top line: badge + subtle status
            Row(
              children: [
                _Badge(
                  text: modeLabel,
                  bg: Colors.white.withValues(alpha: 0.18),
                  fg: Colors.white,
                  icon: Icons.shield_moon_outlined,
                ),
                const SizedBox(width: 8),
                if (scheduleLine != null)
                  Expanded(
                    child: Text(
                      scheduleLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              "Today’s Focus",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              focusTopic,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            // Mini stat pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  text: top == null
                      ? "No weak areas yet"
                      : "Weak score: ${top.score0to100}/100",
                  bg: Colors.white.withValues(alpha: 0.16),
                  fg: Colors.white,
                  icon: Icons.trending_down_rounded,
                ),
                _Badge(
                  text: plan == null
                      ? "No plan yet"
                      : "Plan: ${plan.totalMinutes} mins",
                  bg: Colors.white.withValues(alpha: 0.16),
                  fg: Colors.white,
                  icon: Icons.timer_outlined,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Premium CTA row (uses your Premium buttons)
            Row(
              children: [
                Expanded(
                  child: PremiumFilledButton(
                    label: actionLabel,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      Get.toNamed(
                        actionRoute,
                        arguments: {
                          "courseCode": courseCode,
                          "mode": "Timed",
                          "topic": focusTopic,
                          "questions": 15,
                          "minutes": 15,
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PremiumOutlineButton(
                    label: "Weak areas",
                    icon: Icons.analytics_outlined,
                    onPressed: () => Get.toNamed(Routes.weakAreas),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Premium “trust” note (glass inline)
            PremiumGlass(
              padding: const EdgeInsets.all(12),
              radius: 16,
              child: Row(
                children: [
                  Icon(Icons.verified_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Answers and corrections will cite your lecturer notes only.",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  static String _prettyExamMode(String raw) {
    // Handles: ExamMode.objective / ExamMode.essay / etc.
    final s = raw.split('.').last.toLowerCase();
    if (s.contains('obj')) return "Objective Mode";
    if (s.contains('essay')) return "Essay Mode";
    if (s.contains('blank')) return "Fill-in Mode";
    return "Study Mode";
  }

  static String? _todayScheduleLine({
    required String? examCourse,
    required String? examWhen,
    required TimetableController tt,
  }) {
    // If next exam exists, display it. Otherwise show “No exam scheduled”
    if (examCourse != null && examWhen != null) {
      return "Next: $examCourse • $examWhen";
    }
    // If your TimetableController later exposes a next lecture, plug it here.
    // For now: keep it classy and minimal.
    return "Stay consistent • your streak matters";
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  final String text;
  final Color bg;
  final Color fg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: fg, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
