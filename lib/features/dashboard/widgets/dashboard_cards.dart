import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/timetable_models.dart';

import '../../../modules/revision/controller/revision_controller.dart';
import '../../../modules/settings/controller/settings_controller.dart';
import '../../../modules/timetable/controller/timetable_controller.dart';
import '../../../modules/timetable/timetable_form_view.dart';
import '../controller/dashboard_controller.dart';

import 'premium_glass.dart';
import 'premium_skeleton.dart';
import 'dashboard_small_parts.dart';

CourseModel? dashboardPrimaryCourse(DashboardController controller) {
  return controller.courses.isNotEmpty ? controller.courses.first : null;
}

void dashboardShowMissingCourse() {
  Get.snackbar(
    'No course selected',
    'Add a course first to continue.',
    snackPosition: SnackPosition.BOTTOM,
  );
}

class DashboardNextExamCard extends GetView<DashboardController> {
  const DashboardNextExamCard({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final exam = controller.nextExam.value;
    final course = dashboardPrimaryCourse(controller);
    final daysLeft = exam?.daysLeft ?? 5;
    final muted = cs.onSurface.withValues(alpha: 0.65);

    final urgencyColor = daysLeft <= 3
        ? const Color(0xFFEF4444)
        : (daysLeft <= 7 ? const Color(0xFFF59E0B) : cs.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exam != null ? "${exam.courseCode}: ${exam.title}" : "Next exam",
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                exam != null ? "${exam.dateLabel} - ${exam.location}" : "Date tbd",
                style: TextStyle(color: muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: DashboardProgressBar(cs: cs, label: "Readiness", value: 0.62)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "$daysLeft days left",
                style: TextStyle(color: urgencyColor, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            PremiumFilledButton(
              label: "View plan",
              icon: Icons.calendar_today_outlined,
              onPressed: () {
                if (course != null) {
                  final tt = Get.find<TimetableController>();
                  tt.tabIndex.value = 1;
                  Get.toNamed(Routes.timetable);
                } else {
                  dashboardShowMissingCourse();
                }
              },
            ),
            const SizedBox(width: 10),
            PremiumOutlineButton(
              label: "Add timetable",
              icon: Icons.add_circle_outline,
              onPressed: () {
                if (course != null) {
                  Get.to(() => TimetableFormView(type: TimetableType.exams));
                } else {
                  dashboardShowMissingCourse();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardContinueStudyingCard extends GetView<DashboardController> {
  const DashboardContinueStudyingCard({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);
    final course = dashboardPrimaryCourse(controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CSC 305 - Data Structures",
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DashboardPill(text: "Syllabus 72%", bg: cs.primary.withValues(alpha: 0.12), fg: cs.primary),
            DashboardPill(text: "Past Qs 24", bg: cs.onSurface.withValues(alpha: 0.06), fg: cs.onSurface),
            DashboardPill(text: "Weak: Trees, Graphs", bg: cs.onSurface.withValues(alpha: 0.06), fg: cs.onSurface),
          ],
        ),
        const SizedBox(height: 12),
        Text("Continue from where you stopped last time.", style: TextStyle(color: muted)),
        const SizedBox(height: 12),
        PremiumFilledButton(
          label: "Continue",
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            if (course != null) {
              Get.toNamed(Routes.practiceSetup, arguments: {'course': course});
            } else {
              dashboardShowMissingCourse();
            }
          },
        ),
      ],
    );
  }
}

class DashboardDailyGoalCard extends StatelessWidget {
  const DashboardDailyGoalCard({super.key, required this.cs, required this.settings});
  final ColorScheme cs;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final rev = Get.find<RevisionPlanController>();
    return Obx(() {
      final targetGrade = settings.targetGrade.value;
      final preferred = settings.preferredTime.value;
      final dailyTime = settings.dailyStudyLabel;
      final muted = cs.onSurface.withValues(alpha: 0.75);
      final plan = rev.plan.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Daily study goal", style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          Text('Target grade: $targetGrade', style: TextStyle(color: muted)),
          Text('Daily time: $dailyTime - Preferred: $preferred', style: TextStyle(color: muted)),
          if (plan != null) ...[
            const SizedBox(height: 8),
            Text('Today\'s tasks:', style: TextStyle(color: cs.onSurface)),
            const SizedBox(height: 6),
            ...plan.tasks.take(3).map(
                  (t) => Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text("${t.title} (${t.minutes} mins)", style: TextStyle(color: muted))),
                    ],
                  ),
                ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              PremiumFilledButton(
                label: "Start session",
                icon: Icons.play_circle_outline,
                onPressed: () {
                  final dash = Get.find<DashboardController>();
                  final course = dashboardPrimaryCourse(dash);
                  final p = rev.plan.value;

                  if (p != null) {
                    Get.toNamed(
                      Routes.cbtTake,
                      arguments: {"courseCode": p.courseCode, "mode": "Timed", "topic": p.focusTopic, "questions": 12, "minutes": 12},
                    );
                    return;
                  }
                  if (course != null) {
                    Get.toNamed(Routes.practiceSetup, arguments: {'course': course});
                  } else {
                    dashboardShowMissingCourse();
                  }
                },
              ),
              const SizedBox(width: 8),
              PremiumOutlineButton(
                label: "Edit goal",
                icon: Icons.tune_rounded,
                onPressed: () {
                  try {
                    Get.toNamed(Routes.settings);
                  } catch (_) {}
                },
              ),
            ],
          ),
        ],
      );
    });
  }
}

class DashboardLowDataOffline extends StatelessWidget {
  const DashboardLowDataOffline({super.key, required this.cs, required this.settings});
  final ColorScheme cs;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.75);

    return Obx(() {
      final dataSaver = settings.dataSaver.value;
      final offline = settings.offlineDownloads.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Low-data & offline", style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          Text("Data Saver: ${dataSaver ? "ON" : "OFF"} • Offline: ${offline ? "ON" : "OFF"}", style: TextStyle(color: muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: offline ? () {} : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.save_alt),
                label: const Text("Save for offline"),
              ),
              TextButton(
                onPressed: () => settings.setDataSaver(!dataSaver),
                style: TextButton.styleFrom(foregroundColor: cs.primary),
                child: Text(dataSaver ? 'Disable data saver' : 'Enable data saver'),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class DashboardQuickActionsRow extends StatelessWidget {
  const DashboardQuickActionsRow({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final course = controller.courses.isNotEmpty ? controller.courses.first : null;

    final actions = <(String, IconData, VoidCallback?)>[
      ('Ask Course AI', Icons.chat_bubble_outline, course == null ? null : () => Get.toNamed(Routes.chat, arguments: {'course': course})),
      ('CBT practice', Icons.task_alt_outlined, course == null ? null : () => Get.toNamed(Routes.cbtSetup, arguments: {"courseCode": course.code})),
      ('Timetable', Icons.event_note_outlined, () => Get.toNamed(Routes.timetable)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((a) {
        return SizedBox(
          width: 150,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: cs.primary,
            ),
            onPressed: a.$3,
            icon: Icon(a.$2, color: cs.primary),
            label: Text(a.$1),
          ),
        );
      }).toList(),
    );
  }
}

class DashboardPerformance extends GetView<DashboardController> {
  const DashboardPerformance({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final tileColor = cs.onSurface.withValues(alpha: 0.05);
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return Obx(() {
      final loading = controller.isLoading.value;
      if (loading) {
        return const PremiumSkeletonBlock();
      }
      final p = controller.performance.value;
      final accuracy = p?.accuracyPct ?? 0;
      final studyTime = p?.studyTimeLabel ?? "0m";
      final consistency = p?.consistencyLabel ?? "${controller.streakDays.value}-day streak";

      final items = [
        ('Accuracy', '$accuracy%', 'Based on last attempts'),
        ('Study time', studyTime, 'Recent practice time'),
        ('Consistency', consistency, 'Keep momentum'),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance snapshot', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
                return Container(
                width: 180,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$1, style: TextStyle(color: muted)),
                    const SizedBox(height: 6),
                    Text(item.$2, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(item.$3, style: TextStyle(color: muted)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}

class DashboardFocusAndTips extends GetView<DashboardController> {
  const DashboardFocusAndTips({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final tileColor = cs.onSurface.withValues(alpha: 0.05);
    final muted = cs.onSurface.withValues(alpha: 0.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.secondary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Study streak', style: TextStyle(fontWeight: FontWeight.w700)),
              Obx(() => Text('${controller.streakDays.value} days', style: const TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.lightbulb_outline, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart academic tip', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text('70% of last past questions repeated Trees & Graphs. Revise both before Friday.', style: TextStyle(color: muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardNoticeboard extends StatelessWidget {
  const DashboardNoticeboard({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ("CSC 305", "Assignment on Graphs due Friday.", "Class Rep"),
      ("MTH 202", "Exam covers Chapters 1-5 only.", "Dr. Bala"),
      ("GST 201", "Past questions uploaded.", "Portal"),
    ];
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map((it) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardDot(color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.$1, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(it.$2, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(it.$3, style: TextStyle(color: muted)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Get.toNamed(Routes.noticeboard),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text("View all"),
          ),
        ),
      ],
    );
  }
}

class DashboardGrades extends StatelessWidget {
  const DashboardGrades({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final grades = const [
      ("Mid-term paper", "Summer term", "98"),
      ("Algorithms", "Spring term", "82"),
      ("Maths & Stats", "Spring term", "74"),
    ];
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return Column(
      children: grades.map((g) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.$1, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(g.$2, style: TextStyle(color: muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: cs.secondary.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                child: Text(g.$3, style: TextStyle(color: cs.onSecondary, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
