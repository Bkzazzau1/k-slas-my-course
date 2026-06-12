import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/main_nav/main_nav_view.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/student_notification_service.dart';
import '../controller/dashboard_controller.dart';

class DashboardTopBar extends GetView<DashboardController> {
  const DashboardTopBar({super.key, required this.cs, required this.isTablet});

  final ColorScheme cs;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withAlpha((0.65 * 255).toInt());
    final unread = StudentNotificationService.unreadCount();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Obx(() {
            final title = controller.headerTitle;
            final sub = controller.studentProgramLine.value;
            final pill = controller.nextExamPillText;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _PrimaryCourseChip(cs: cs),
                const SizedBox(height: 10),
                if (!isTablet && pill != null)
                  _NextExamPill(cs: cs, text: pill, icon: Icons.timer_outlined),
              ],
            );
          }),
        ),
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: "Notifications",
                  onPressed: () => Get.toNamed(Routes.notifications),
                  icon: Icon(
                    Icons.notifications_none_outlined,
                    color: cs.onSurface,
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: TextStyle(
                          color: cs.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              tooltip: "Settings",
              onPressed: () {
                final nav = Get.find<MainNavController>();
                nav.setIndex(2);
              },
              icon: Icon(Icons.settings_outlined, color: cs.onSurface),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryCourseChip extends GetView<DashboardController> {
  const _PrimaryCourseChip({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withAlpha((0.70 * 255).toInt());

    return Obx(() {
      if (controller.courses.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.onSurface.withAlpha((0.04 * 255).toInt()),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.onSurface.withAlpha((0.06 * 255).toInt()),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                "No course yet",
                style: TextStyle(color: muted, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      }

      final c = controller.courses.first;
      final progress = (c.progress.clamp(0, 100)) / 100.0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.onSurface.withAlpha((0.04 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.onSurface.withAlpha((0.06 * 255).toInt()),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4.5,
                    backgroundColor: cs.onSurface.withAlpha(
                      (0.08 * 255).toInt(),
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                  Text(
                    "${c.progress}%",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${c.code} • ${c.title}",
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subLine(c),
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha((0.10 * 255).toInt()),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: cs.primary.withAlpha((0.16 * 255).toInt()),
                ),
              ),
              child: Text(
                "Primary",
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _subLine(dynamic c) {
    final notes = (c.notes == true) ? "Notes" : "No notes";
    final pq = (c.pastQuestions == true) ? "Past Qs" : "No past Qs";
    return "$notes • $pq";
  }
}

class _NextExamPill extends StatelessWidget {
  const _NextExamPill({
    required this.cs,
    required this.text,
    required this.icon,
  });

  final ColorScheme cs;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withAlpha((0.14 * 255).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
