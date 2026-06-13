import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/services/assignment_quality_service.dart';
import '../../../data/services/assignment_submission_storage.dart';
import '../controller/dashboard_controller.dart';

class DashboardAssignmentsLux extends StatelessWidget {
  const DashboardAssignmentsLux({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final items = controller.upcomingAssignments;
      if (items.isEmpty) {
        return Text(
          'No assignments yet.',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        );
      }

      final quality = [
        for (final item in items)
          AssignmentQualityService.statusFor(
            assignment: item,
            submission: AssignmentSubmissionStorage.loadSubmission(item.id),
          ),
      ];
      final dueSoon = quality.where((item) => item.isDueSoon && !item.isSubmitted).length;
      final overdue = quality.where((item) => item.isOverdue && !item.isSubmitted).length;
      final submitted = quality.where((item) => item.isSubmitted).length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                text: '${controller.pendingAssignmentsCount} pending',
                tone: controller.pendingAssignmentsCount == 0
                    ? cs.primary
                    : const Color(0xFFF57C00),
              ),
              _pill(text: '$dueSoon due soon', tone: const Color(0xFFF57C00)),
              _pill(text: '$overdue overdue', tone: const Color(0xFFD32F2F)),
              _pill(text: '$submitted submitted', tone: cs.primary),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((a) => _assignmentRow(controller, a)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Get.toNamed(Routes.assignments),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Open assignments'),
            ),
          ),
        ],
      );
    });
  }

  Widget _assignmentRow(DashboardController controller, AssignmentModel item) {
    final submission = AssignmentSubmissionStorage.loadSubmission(item.id);
    final statusInfo = AssignmentQualityService.statusFor(
      assignment: item,
      submission: submission,
    );
    final color = statusInfo.isSubmitted
        ? cs.primary
        : (statusInfo.isOverdue
              ? const Color(0xFFD32F2F)
              : statusInfo.isDueSoon
              ? const Color(0xFFF57C00)
              : cs.secondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.courseCode} • ${item.title}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  statusInfo.detail,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: statusInfo.completionScore / 100,
                    minHeight: 5,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _pill(text: statusInfo.label, tone: color),
        ],
      ),
    );
  }

  Widget _pill({required String text, required Color tone}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
