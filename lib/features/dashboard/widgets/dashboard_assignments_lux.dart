import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/assignment_model.dart';
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
              _pill(text: '${items.length} visible', tone: cs.secondary),
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
    final submitted = controller.isAssignmentSubmitted(item.id);
    final overdue = controller.isAssignmentOverdue(item);
    final color = submitted
        ? cs.primary
        : (overdue ? const Color(0xFFD32F2F) : const Color(0xFFF57C00));
    final status = submitted ? 'Submitted' : (overdue ? 'Overdue' : 'Pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
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
                  'Deadline: ${_fmtDateTime(item.deadline)}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _pill(text: status, tone: color),
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

String _fmtDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
