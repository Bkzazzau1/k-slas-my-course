import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/timetable_models.dart';
import '../../../modules/timetable/controller/timetable_controller.dart';
import '../../../modules/timetable/timetable_form_view.dart';
import '../controller/dashboard_controller.dart';

class DashboardNextExamLux extends GetView<DashboardController> {
  const DashboardNextExamLux({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.68);

    return Obx(() {
      final exam = controller.nextExam.value;
      final course = _primaryCourse(controller);

      final daysLeft = (exam?.daysLeft ?? 14).clamp(0, 365);

      final urgencyColor = daysLeft <= 3
          ? const Color(0xFFEF4444)
          : (daysLeft <= 7 ? const Color(0xFFF59E0B) : cs.primary);

      final title = exam != null ? "${exam.courseCode}: ${exam.title}" : "Next exam";
      final meta = exam != null ? "${exam.dateLabel} - ${exam.location}" : "Date tbd - Location tbd";
      final deliveryMode = exam?.deliveryLabel ?? "Delivery mode pending";
      final deliveryIcon = exam?.isRemoteProctored == true
          ? Icons.security_outlined
          : Icons.apartment_outlined;

      // Readiness can later come from real analytics; MVP uses performance accuracy
      final acc = controller.performance.value?.accuracyPct ?? 0;
      final readiness = (acc / 100).clamp(0.0, 1.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: ring + title + urgency badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CountdownRing(
                cs: cs,
                daysLeft: daysLeft,
                color: urgencyColor,
                progress: _daysProgress(daysLeft),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.15,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 16, color: muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            meta,
                            style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(deliveryIcon, size: 16, color: muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            deliveryMode,
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _UrgencyPill(
                cs: cs,
                color: urgencyColor,
                text: daysLeft == 0 ? "Today" : "$daysLeft days",
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Readiness
          _ReadinessBar(cs: cs, value: readiness, label: "Readiness", hint: "Based on recent attempts"),

          const SizedBox(height: 12),

          // Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (course != null) {
                      final tt = Get.find<TimetableController>();
                      tt.tabIndex.value = 1;
                      Get.toNamed(Routes.timetable);
                    } else {
                      _showMissingCourse();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("View plan"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (course != null) {
                      Get.to(() => TimetableFormView(type: TimetableType.exams));
                    } else {
                      _showMissingCourse();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: cs.primary.withValues(alpha: 0.22)),
                  ),
                  child: const Text("Add timetable"),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  // Ring progress: assume max window = 14 days
  static double _daysProgress(int daysLeft) {
    const max = 14;
    final left = daysLeft.clamp(0, max);
    return 1 - (left / max);
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.cs,
    required this.daysLeft,
    required this.color,
    required this.progress,
  });

  final ColorScheme cs;
  final int daysLeft;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _RingPainter(
          track: cs.onSurface.withValues(alpha: 0.08),
          color: color,
          progress: progress.clamp(0, 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$daysLeft",
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                "days",
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.track,
    required this.color,
    required this.progress,
  });

  final Color track;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 7.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = (size.shortestSide / 2) - stroke;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final progPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, r, trackPaint);

    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      start,
      sweep,
      false,
      progPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.progress != progress || old.color != color || old.track != track;
  }
}

class _UrgencyPill extends StatelessWidget {
  const _UrgencyPill({required this.cs, required this.color, required this.text});
  final ColorScheme cs;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReadinessBar extends StatelessWidget {
  const _ReadinessBar({
    required this.cs,
    required this.value,
    required this.label,
    required this.hint,
  });

  final ColorScheme cs;
  final double value;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(hint, style: TextStyle(color: muted, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text("${(value * 100).round()}%", style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 10,
            backgroundColor: cs.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

CourseModel? _primaryCourse(DashboardController controller) {
  return controller.courses.isNotEmpty ? controller.courses.first : null;
}

void _showMissingCourse() {
  Get.snackbar(
    'No course selected',
    'Add a course first to continue.',
    snackPosition: SnackPosition.BOTTOM,
  );
}
