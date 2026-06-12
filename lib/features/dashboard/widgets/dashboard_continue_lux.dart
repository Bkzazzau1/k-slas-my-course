import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_model.dart';
import '../controller/dashboard_controller.dart';

class DashboardContinueLux extends GetView<DashboardController> {
  const DashboardContinueLux({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Obx(() {
      final course = _primaryCourse(controller);
      if (course == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "No course selected yet.",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => Get.toNamed(Routes.courses),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text("Add a course"),
            ),
          ],
        );
      }

      final progress = (course.progress).clamp(0, 100);
      final ring = (progress / 100).clamp(0.0, 1.0);

      final weakTags = controller.weakTopics.isEmpty
          ? <String>["Revision"]
          : controller.weakTopics.take(3).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: course + ring
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CourseHeader(cs: cs, course: course),
              ),
              const SizedBox(width: 10),
              _ProgressRing(cs: cs, progress: ring, label: "$progress%"),
            ],
          ),

          const SizedBox(height: 12),

          // Weak tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weakTags
                .map((t) => _Chip(cs: cs, label: t, tone: _ChipTone.neutral))
                .toList(),
          ),

          const SizedBox(height: 10),

          Text(
            "Continue from where you stopped. We'll prioritize your weak topics first.",
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 12),

          // CTAs
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Get.toNamed(
                      Routes.practiceSetup,
                      arguments: {'course': course},
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Continue"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.toNamed(
                      Routes.cbtTake,
                      arguments: {
                        "courseCode": course.code,
                        "mode": "Timed",
                        "topic": weakTags.isNotEmpty
                            ? weakTags.first
                            : "Revision",
                        "questions": 10,
                        "minutes": 10,
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: cs.primary.withValues(alpha: 0.22)),
                  ),
                  child: const Text("Quick practice"),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.cs, required this.course});
  final ColorScheme cs;
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Chip(cs: cs, label: course.code, tone: _ChipTone.primary),
        const SizedBox(height: 8),
        Text(
          course.title,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 16, color: muted),
            const SizedBox(width: 6),
            Text(
              _assetsLabel(course),
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  static String _assetsLabel(CourseModel c) {
    final notes = (c.notes == true) ? "Notes" : "No notes";
    final pq = (c.pastQuestions == true) ? "Past Qs" : "No past Qs";
    return "$notes • $pq";
  }
}

enum _ChipTone { primary, neutral }

class _Chip extends StatelessWidget {
  const _Chip({required this.cs, required this.label, required this.tone});
  final ColorScheme cs;
  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final isPrimary = tone == _ChipTone.primary;
    final bg = isPrimary
        ? cs.primary.withValues(alpha: 0.12)
        : cs.onSurface.withValues(alpha: 0.05);
    final br = isPrimary
        ? cs.primary.withValues(alpha: 0.16)
        : cs.onSurface.withValues(alpha: 0.07);
    final fg = isPrimary ? cs.primary : cs.onSurface.withValues(alpha: 0.82);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: br),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.cs,
    required this.progress,
    required this.label,
  });

  final ColorScheme cs;
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _RingPainter(
          track: cs.onSurface.withValues(alpha: 0.08),
          color: cs.secondary,
          progress: progress.clamp(0, 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
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

CourseModel? _primaryCourse(DashboardController controller) {
  return controller.courses.isNotEmpty ? controller.courses.first : null;
}
