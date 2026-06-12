import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/main_nav/main_nav_view.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_model.dart';
import '../../../modules/revision/controller/revision_controller.dart';
import '../../../modules/settings/controller/settings_controller.dart';
import '../controller/dashboard_controller.dart';

class DashboardDailyGoalLux extends StatelessWidget {
  const DashboardDailyGoalLux({
    super.key,
    required this.cs,
    required this.settings,
  });

  final ColorScheme cs;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final rev = Get.find<RevisionPlanController>();

    return Obx(() {
      final muted = cs.onSurface.withValues(alpha: 0.72);

      final targetGrade = settings.targetGrade.value;
      final preferred = settings.preferredTime.value;
      final dailyTime = settings.dailyStudyLabel;

      final plan = rev.plan.value;
      final tasks = plan?.tasks ?? const [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your daily goal",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Target grade - schedule - today plan",
                      style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _MiniPill(
                cs: cs,
                text: "Streak",
                icon: Icons.local_fire_department_outlined,
                tone: _Tone.secondary,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Goal tiles
          _GoalRow(
            cs: cs,
            left: _GoalTile(
              cs: cs,
              title: "Target grade",
              value: targetGrade,
              icon: Icons.grade_outlined,
              tone: _Tone.primary,
            ),
            right: _GoalTile(
              cs: cs,
              title: "Daily time",
              value: dailyTime,
              icon: Icons.schedule_outlined,
              tone: _Tone.secondary,
            ),
          ),

          const SizedBox(height: 10),

          // Preferred time
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Preferred study time: $preferred",
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Today's tasks
          Text(
            "Today's tasks",
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),

          if (tasks.isEmpty)
            _EmptyTasks(cs: cs)
          else
            Column(
              children: tasks.take(3).map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskRow(
                    cs: cs,
                    title: t.title,
                    minutes: t.minutes,
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // CTAs
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final p = rev.plan.value;
                    final dash = Get.find<DashboardController>();
                    final course = _primaryCourse(dash);

                    if (p != null) {
                      Get.toNamed(
                        Routes.cbtTake,
                        arguments: {
                          "courseCode": p.courseCode,
                          "mode": "Timed",
                          "topic": p.focusTopic,
                          "questions": 12,
                          "minutes": 12,
                        },
                      );
                      return;
                    }

                    if (course != null) {
                      Get.toNamed(
                        Routes.practiceSetup,
                        arguments: {'course': course},
                      );
                      return;
                    }

                    Get.snackbar(
                      "No course selected",
                      "Add a course first to start a session.",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Start session"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    try {
                      final nav = Get.find<MainNavController>();
                      nav.setIndex(2);
                    } catch (_) {
                      Get.toNamed(Routes.settings);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: cs.primary.withValues(alpha: 0.22)),
                  ),
                  child: const Text("Edit goal"),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.cs, required this.left, required this.right});
  final ColorScheme cs;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

enum _Tone { primary, secondary }

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.cs,
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final ColorScheme cs;
  final String title;
  final String value;
  final IconData icon;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == _Tone.primary ? cs.primary : cs.secondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.cs, required this.title, required this.minutes});
  final ColorScheme cs;
  final String title;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.68);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: cs.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$minutes mins",
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "No plan yet. Take a short CBT to generate today's plan.",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.cs,
    required this.text,
    required this.icon,
    required this.tone,
  });

  final ColorScheme cs;
  final String text;
  final IconData icon;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == _Tone.primary ? cs.primary : cs.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

CourseModel? _primaryCourse(DashboardController controller) {
  return controller.courses.isNotEmpty ? controller.courses.first : null;
}
