import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_assessment_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/course_assessment_service.dart';
import '../controller/dashboard_controller.dart';

class DashboardAssessmentsLux extends GetView<DashboardController> {
  const DashboardAssessmentsLux({super.key, required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final courses = controller.courses.toList();
      if (courses.isEmpty) {
        return Text(
          'Register courses to see assessment progress.',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.70),
            fontWeight: FontWeight.w700,
          ),
        );
      }

      return Column(
        children: courses
            .map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AssessmentCourseRow(course: course, cs: cs),
              ),
            )
            .toList(),
      );
    });
  }
}

class _AssessmentCourseRow extends StatelessWidget {
  const _AssessmentCourseRow({required this.course, required this.cs});

  final CourseModel course;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CourseAssessmentSummary>(
      future: CourseAssessmentService.summaryFor(course),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        return InkWell(
          onTap: () => Get.toNamed(
            Routes.courseDetail,
            arguments: {'course': course, 'initialTab': 3},
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.52),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${course.code} · ${course.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: cs.primary),
                  ],
                ),
                const SizedBox(height: 10),
                if (summary == null)
                  const LinearProgressIndicator(minHeight: 4)
                else ...[
                  _ProgressLine(
                    label: 'Graded',
                    completed: summary.gradedCompleted,
                    pending: summary.gradedPending,
                    total: summary.gradedTotal,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 8),
                  _ProgressLine(
                    label: 'Ungraded',
                    completed: summary.ungradedCompleted,
                    pending: summary.ungradedPending,
                    total: summary.ungradedTotal,
                    color: cs.secondary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.completed,
    required this.pending,
    required this.total,
    required this.color,
  });

  final String label;
  final int completed;
  final int pending;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : completed / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label: $completed completed · $pending pending',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '$completed/$total',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
