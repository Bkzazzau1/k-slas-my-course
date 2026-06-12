import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_assessment_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/course_assessment_service.dart';

class AssessmentsTab extends StatelessWidget {
  const AssessmentsTab({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseAssessmentModel>>(
      future: CourseAssessmentService.fetchAssessments(course),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <CourseAssessmentModel>[];
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _AssessmentTile(course: course, assessment: item);
          },
        );
      },
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.course, required this.assessment});

  final CourseModel course;
  final CourseAssessmentModel assessment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGraded = assessment.gradingType == GradingType.graded;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isGraded ? cs.primary : cs.secondary).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isGraded ? Icons.verified_user_outlined : Icons.quiz_outlined,
              color: isGraded ? cs.primary : cs.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${isGraded ? 'Graded' : 'Ungraded'} · ${assessment.kind} · ${assessment.durationMinutes} min',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Get.toNamed(
                    Routes.cbtSetup,
                    arguments: {
                      'courseCode': course.code,
                      'gradingType': assessment.gradingType,
                    },
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Take assessment'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
