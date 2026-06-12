import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/whiteboard/whiteboard_editor_sheet.dart';
import '../../../core/whiteboard/whiteboard_models.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/assignment_model.dart';
import '../controller/assignments_controller.dart';

class AssignmentsView extends GetView<AssignmentsController> {
  const AssignmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Obx(
                () => _Header(
                  cs: cs,
                  isLecturerMode: controller.isLecturerMode.value,
                  providerLabel: controller.providerLabel.value,
                  onCreateAssignment: _openCreateAssignmentSheet,
                  onRoleChanged: (lecturer) {
                    controller.switchDemoRole(lecturer: lecturer);
                  },
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final items = controller.visibleAssignments;
                final courses =
                    controller.assignments
                        .map((a) => a.courseCode)
                        .toSet()
                        .toList()
                      ..sort();

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No assignments available.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  children: [
                    _CourseFilter(
                      cs: cs,
                      courses: courses,
                      value: controller.filterCourseCode.value,
                      onChanged: (value) {
                        controller.filterCourseCode.value = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (assignment) => _AssignmentCard(
                        cs: cs,
                        assignment: assignment,
                        state: controller.submissionState(assignment),
                        submission: controller.submissionFor(assignment.id),
                        peerReviewSubmission: controller.peerReviewFor(
                          assignment.id,
                        ),
                        isLecturerMode: controller.isLecturerMode.value,
                        lecturerSubmissions: controller
                            .submissionsForAssignment(assignment),
                        gradeForSubmission: (submission) => controller.gradeFor(
                          assignmentId: assignment.id,
                          submissionId:
                              AssignmentsController.submissionIdForGrade(
                                submission,
                              ),
                        ),
                        studentGrade: controller.gradeForStudentAssignment(
                          assignment,
                        ),
                        onOpenGroupChat: controller.canOpenGroupChat(assignment)
                            ? () => _openGroupChatSheet(assignment: assignment)
                            : null,
                        onOpenPeerReview: assignment.hasPeerReview
                            ? () => _openPeerReviewSheet(
                                assignment: assignment,
                                existingReview: controller.peerReviewFor(
                                  assignment.id,
                                ),
                              )
                            : null,
                        onSubmit: () => _openSubmissionSheet(
                          assignment: assignment,
                          existingSubmission: controller.submissionFor(
                            assignment.id,
                          ),
                        ),
                        onOpenGrading: (submission) => _openGradingSheet(
                          assignment: assignment,
                          submission: submission,
                          existingGrade: controller.gradeFor(
                            assignmentId: assignment.id,
                            submissionId:
                                AssignmentsController.submissionIdForGrade(
                                  submission,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubmissionSheet({
    required AssignmentModel assignment,
    AssignmentSubmissionModel? existingSubmission,
  }) {
    Get.bottomSheet<void>(
      _AssignmentSubmissionSheet(
        assignment: assignment,
        existingSubmission: existingSubmission,
        controller: controller,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _openCreateAssignmentSheet() {
    Get.bottomSheet<void>(
      _CreateAssignmentSheet(controller: controller),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _openGradingSheet({
    required AssignmentModel assignment,
    required AssignmentSubmissionModel submission,
    AssignmentGradeModel? existingGrade,
  }) {
    Get.bottomSheet<void>(
      _AssignmentGradingSheet(
        assignment: assignment,
        submission: submission,
        existingGrade: existingGrade,
        controller: controller,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _openGroupChatSheet({required AssignmentModel assignment}) {
    if (!controller.canOpenGroupChat(assignment)) return;

    Get.bottomSheet<void>(
      _AssignmentGroupChatSheet(assignment: assignment, controller: controller),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _openPeerReviewSheet({
    required AssignmentModel assignment,
    AssignmentPeerReviewSubmission? existingReview,
  }) {
    if (!assignment.hasPeerReview) return;

    Get.bottomSheet<void>(
      _AssignmentPeerReviewSheet(
        assignment: assignment,
        existingReview: existingReview,
        controller: controller,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cs,
    required this.isLecturerMode,
    required this.providerLabel,
    required this.onCreateAssignment,
    required this.onRoleChanged,
  });
  final ColorScheme cs;
  final bool isLecturerMode;
  final String providerLabel;
  final VoidCallback onCreateAssignment;
  final ValueChanged<bool> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.82),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Get.back<void>(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assignments',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isLecturerMode
                          ? 'Publish, review, and grade coursework.'
                          : 'Submit work and view lecturer feedback.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      providerLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLecturerMode) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: cs.primary,
                  ),
                  onPressed: onCreateAssignment,
                  icon: const Icon(Icons.add_task_outlined),
                  label: const Text('New'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? cs.primary
                      : Colors.white,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.12),
                ),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.school_outlined, size: 18),
                  label: Text('Student demo'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.co_present_outlined, size: 18),
                  label: Text('Lecturer demo'),
                ),
              ],
              selected: {isLecturerMode},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) {
                  onRoleChanged(values.first);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseFilter extends StatelessWidget {
  const _CourseFilter({
    required this.cs,
    required this.courses,
    required this.value,
    required this.onChanged,
  });

  final ColorScheme cs;
  final List<String> courses;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, color: cs.primary),
          const SizedBox(width: 10),
          const Text('Course', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: value,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...courses.map(
                    (course) =>
                        DropdownMenuItem(value: course, child: Text(course)),
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.cs,
    required this.assignment,
    required this.state,
    required this.submission,
    required this.peerReviewSubmission,
    required this.isLecturerMode,
    required this.lecturerSubmissions,
    required this.gradeForSubmission,
    required this.studentGrade,
    required this.onOpenGroupChat,
    required this.onOpenPeerReview,
    required this.onSubmit,
    required this.onOpenGrading,
  });

  final ColorScheme cs;
  final AssignmentModel assignment;
  final AssignmentSubmissionState state;
  final AssignmentSubmissionModel? submission;
  final AssignmentPeerReviewSubmission? peerReviewSubmission;
  final bool isLecturerMode;
  final List<AssignmentSubmissionModel> lecturerSubmissions;
  final AssignmentGradeModel? Function(AssignmentSubmissionModel submission)
  gradeForSubmission;
  final AssignmentGradeModel? studentGrade;
  final VoidCallback? onOpenGroupChat;
  final VoidCallback? onOpenPeerReview;
  final VoidCallback onSubmit;
  final ValueChanged<AssignmentSubmissionModel> onOpenGrading;

  @override
  Widget build(BuildContext context) {
    final status = _statusMeta(state, cs);
    final canSubmit = state != AssignmentSubmissionState.overdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${assignment.courseCode} • ${assignment.title}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            assignment.description,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(cs, 'Lecturer: ${assignment.lecturerName}', cs.secondary),
              _pill(
                cs,
                'Assigned: ${_fmtDateTime(assignment.assignedAt)}',
                cs.primary,
              ),
              _pill(
                cs,
                'Deadline: ${_fmtDateTime(assignment.deadline)}',
                status.color,
              ),
            ],
          ),
          if (assignment.isGroupAssignment) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.secondary.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group assignment',
                    style: TextStyle(
                      color: cs.secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (assignment.groupName != null &&
                      assignment.groupName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      assignment.groupName!,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (assignment.groupSource != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      assignment.groupSource!.backendLabel,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (assignment.groupMembers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Members (${assignment.groupMembers.length})',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: assignment.groupMembers
                          .map(
                            (member) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: cs.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                member.name,
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (assignment.hasGroupChat) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Group-only chat enabled. Lecturer can read and write.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.74),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (assignment.hasPeerReview && !isLecturerMode) ...[
            const SizedBox(height: 10),
            _PeerReviewPanel(
              cs: cs,
              assignment: assignment,
              review: peerReviewSubmission,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Accepted files: ${assignment.allowedExtensions.join(", ")}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (assignment.whiteboardEnabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.whiteboardRequired
                        ? 'Diagram whiteboard: required'
                        : 'Diagram whiteboard: optional',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (assignment.whiteboardPrompt != null &&
                      assignment.whiteboardPrompt!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      assignment.whiteboardPrompt!.trim(),
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.74),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (submission != null && !isLecturerMode) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
              ),
              child: Text(
                'Last submitted: ${_fmtDateTime(submission!.submittedAt)}'
                '${submission!.files.isNotEmpty ? " • ${submission!.files.length} file(s)" : ""}'
                '${submission!.whiteboardStrokes.isNotEmpty ? " • diagram attached" : ""}',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (studentGrade != null && !isLecturerMode) ...[
            const SizedBox(height: 10),
            _StudentGradePanel(cs: cs, grade: studentGrade!),
          ],
          if (assignment.hasGroupChat) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenGroupChat,
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Open group chat'),
              ),
            ),
          ],
          if (assignment.hasPeerReview && !isLecturerMode) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenPeerReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(
                  peerReviewSubmission == null
                      ? 'Review assigned peer'
                      : 'Update peer review',
                ),
              ),
            ),
          ],
          if (isLecturerMode) ...[
            const SizedBox(height: 12),
            _LecturerSubmissionPanel(
              cs: cs,
              submissions: lecturerSubmissions,
              gradeForSubmission: gradeForSubmission,
              onOpenGrading: onOpenGrading,
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSubmit ? onSubmit : null,
                icon: Icon(
                  submission == null
                      ? Icons.upload_file_outlined
                      : Icons.edit_outlined,
                ),
                label: Text(
                  submission == null
                      ? 'Submit assignment'
                      : 'Update submission',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(ColorScheme cs, String text, Color tone) {
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
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StudentGradePanel extends StatelessWidget {
  const _StudentGradePanel({required this.cs, required this.grade});

  final ColorScheme cs;
  final AssignmentGradeModel grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.tertiary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: cs.tertiary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Graded: ${grade.score}/${grade.maxScore} (${grade.displayGrade})',
                  style: TextStyle(
                    color: cs.tertiary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            grade.feedback,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.76),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Marked by ${grade.gradedByName} • ${_fmtDateTime(grade.gradedAt)}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LecturerSubmissionPanel extends StatelessWidget {
  const _LecturerSubmissionPanel({
    required this.cs,
    required this.submissions,
    required this.gradeForSubmission,
    required this.onOpenGrading,
  });

  final ColorScheme cs;
  final List<AssignmentSubmissionModel> submissions;
  final AssignmentGradeModel? Function(AssignmentSubmissionModel submission)
  gradeForSubmission;
  final ValueChanged<AssignmentSubmissionModel> onOpenGrading;

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Text(
          'No student submissions yet.',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submissions (${submissions.length})',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...submissions.map((submission) {
          final grade = gradeForSubmission(submission);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        submission.submittedByName ?? 'Student',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (grade != null)
                      Text(
                        '${grade.score}/${grade.maxScore} (${grade.displayGrade})',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted ${_fmtDateTime(submission.submittedAt)}'
                  '${submission.files.isNotEmpty ? " • ${submission.files.length} file(s)" : ""}'
                  '${submission.whiteboardStrokes.isNotEmpty ? " • diagram" : ""}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => onOpenGrading(submission),
                    icon: Icon(
                      grade == null
                          ? Icons.fact_check_outlined
                          : Icons.edit_note_outlined,
                    ),
                    label: Text(
                      grade == null ? 'Mark submission' : 'Edit mark',
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PeerReviewPanel extends StatelessWidget {
  const _PeerReviewPanel({
    required this.cs,
    required this.assignment,
    required this.review,
  });

  final ColorScheme cs;
  final AssignmentModel assignment;
  final AssignmentPeerReviewSubmission? review;

  @override
  Widget build(BuildContext context) {
    final peer = assignment.peerReview!;
    final target = peer.target;
    final deadline = peer.deadline;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peer-to-peer review',
            style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            peer.source.backendLabel,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniPill(cs, 'Peer: ${target.name}', cs.tertiary),
              if ((target.registrationNumber ?? '').trim().isNotEmpty)
                _miniPill(cs, target.registrationNumber!.trim(), cs.primary),
              if ((target.groupName ?? '').trim().isNotEmpty)
                _miniPill(cs, target.groupName!.trim(), cs.secondary),
              if (deadline != null)
                _miniPill(cs, 'Review by: ${_fmtDateTime(deadline)}', cs.error),
            ],
          ),
          if (peer.rubric.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Rubric from lecturer',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            ...peer.rubric.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 15,
                      color: cs.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.74),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (review != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Review submitted: ${_fmtDateTime(review!.submittedAt)}'
                ' • Score ${review!.score}/${peer.maxScore}',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniPill(ColorScheme cs, String text, Color tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AssignmentGroupChatSheet extends StatefulWidget {
  const _AssignmentGroupChatSheet({
    required this.assignment,
    required this.controller,
  });

  final AssignmentModel assignment;
  final AssignmentsController controller;

  @override
  State<_AssignmentGroupChatSheet> createState() =>
      _AssignmentGroupChatSheetState();
}

class _AssignmentGroupChatSheetState extends State<_AssignmentGroupChatSheet> {
  late final TextEditingController _messageController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _sending = true);
    await widget.controller.sendGroupMessage(
      assignment: widget.assignment,
      message: message,
      senderRole: widget.controller.activeChatSenderRole,
      senderName: widget.controller.currentActorName.value,
    );
    if (!mounted) return;

    _messageController.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final headerTone = widget.assignment.groupSource == null
        ? cs.secondary
        : (widget.assignment.groupSource == AssignmentGroupSource.randomBackend
              ? cs.secondary
              : cs.primary);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Group Chat • ${widget.assignment.courseCode}',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.assignment.groupName?.trim().isNotEmpty == true
                  ? widget.assignment.groupName!.trim()
                  : widget.assignment.title,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.assignment.groupSource != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: headerTone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.assignment.groupSource!.backendLabel,
                  style: TextStyle(
                    color: headerTone,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Members only. Lecturer can read and write in this chat.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (widget.assignment.groupMembers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.assignment.groupMembers
                    .map(
                      (member) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          member.name,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final messages = widget.controller.messagesForAssignmentGroup(
                  widget.assignment,
                );
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start your group discussion.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.66),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = messages[index];
                    final isLecturer = item.isLecturer;
                    final bubble = isLecturer ? cs.primary : cs.secondary;

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bubble.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: bubble.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.senderName,
                                style: TextStyle(
                                  color: bubble,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: bubble.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isLecturer ? 'Lecturer' : 'Member',
                                  style: TextStyle(
                                    color: bubble,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _fmtDateTime(item.sentAt),
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.58),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.message,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.84),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Send a message to your group...',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAssignmentSheet extends StatefulWidget {
  const _CreateAssignmentSheet({required this.controller});

  final AssignmentsController controller;

  @override
  State<_CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<_CreateAssignmentSheet> {
  final _courseController = TextEditingController(text: 'CSC 305');
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _extensionsController = TextEditingController(
    text: 'pdf, doc, docx, png',
  );
  final _whiteboardPromptController = TextEditingController();
  final _membersController = TextEditingController(
    text: '1, Amina Yusuf\n2, David John',
  );
  final _rubricController = TextEditingController(
    text: 'Answer follows the brief\nEvidence is clear\nPresentation is neat',
  );

  int _deadlineDays = 7;
  bool _isGroupAssignment = false;
  bool _peerReviewEnabled = false;
  bool _allowText = true;
  bool _allowFile = true;
  bool _whiteboardEnabled = false;
  bool _whiteboardRequired = false;
  bool _publishing = false;

  @override
  void dispose() {
    _courseController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _extensionsController.dispose();
    _whiteboardPromptController.dispose();
    _membersController.dispose();
    _rubricController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    final ok = await widget.controller.createAssignment(
      courseCode: _courseController.text,
      title: _titleController.text,
      description: _descriptionController.text,
      deadline: DateTime.now().add(Duration(days: _deadlineDays)),
      isGroupAssignment: _isGroupAssignment,
      peerReviewEnabled: _peerReviewEnabled,
      allowTextSubmission: _allowText,
      allowFileSubmission: _allowFile,
      whiteboardEnabled: _whiteboardEnabled,
      whiteboardRequired: _whiteboardRequired,
      whiteboardPrompt: _whiteboardPromptController.text,
      allowedExtensions: _extensionsController.text,
      groupMembers: _parseMembers(_membersController.text),
      peerRubric: _rubricController.text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
    if (mounted) {
      setState(() => _publishing = false);
    }
    if (ok) {
      Get.back<void>();
    }
  }

  List<AssignmentGroupMember> _parseMembers(String raw) {
    return raw
        .split('\n')
        .map((line) {
          final parts = line.split(',');
          final id = parts.isNotEmpty ? parts.first.trim() : '';
          final name = parts.length > 1
              ? parts.sublist(1).join(',').trim()
              : '';
          if (id.isEmpty || name.isEmpty) return null;
          return AssignmentGroupMember(id: id, name: name);
        })
        .whereType<AssignmentGroupMember>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'New assignment',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(
                  labelText: 'Course code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Assignment title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Deadline: $_deadlineDays day(s)',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Slider(
                min: 1,
                max: 30,
                divisions: 29,
                value: _deadlineDays.toDouble(),
                label: '$_deadlineDays',
                onChanged: (value) {
                  setState(() => _deadlineDays = value.round());
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowText,
                onChanged: (value) => setState(() => _allowText = value),
                title: const Text('Text submission'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowFile,
                onChanged: (value) => setState(() => _allowFile = value),
                title: const Text('File upload'),
              ),
              if (_allowFile) ...[
                const SizedBox(height: 6),
                TextFormField(
                  controller: _extensionsController,
                  decoration: const InputDecoration(
                    labelText: 'Allowed extensions',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _whiteboardEnabled,
                onChanged: (value) {
                  setState(() {
                    _whiteboardEnabled = value;
                    if (!value) _whiteboardRequired = false;
                  });
                },
                title: const Text('Whiteboard/diagram submission'),
              ),
              if (_whiteboardEnabled) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _whiteboardRequired,
                  onChanged: (value) {
                    setState(() => _whiteboardRequired = value);
                  },
                  title: const Text('Require whiteboard'),
                ),
                TextFormField(
                  controller: _whiteboardPromptController,
                  decoration: const InputDecoration(
                    labelText: 'Whiteboard prompt',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isGroupAssignment,
                onChanged: (value) =>
                    setState(() => _isGroupAssignment = value),
                title: const Text('Group assignment'),
              ),
              if (_isGroupAssignment || _peerReviewEnabled) ...[
                TextFormField(
                  controller: _membersController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Backend-assigned members',
                    hintText: 'student-id, Student Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _peerReviewEnabled,
                onChanged: (value) {
                  setState(() => _peerReviewEnabled = value);
                },
                title: const Text('Peer-to-peer review'),
              ),
              if (_peerReviewEnabled) ...[
                TextFormField(
                  controller: _rubricController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Peer-review rubric',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: _publishing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.add_task_outlined),
                  label: Text(_publishing ? 'Publishing...' : 'Publish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentGradingSheet extends StatefulWidget {
  const _AssignmentGradingSheet({
    required this.assignment,
    required this.submission,
    required this.existingGrade,
    required this.controller,
  });

  final AssignmentModel assignment;
  final AssignmentSubmissionModel submission;
  final AssignmentGradeModel? existingGrade;
  final AssignmentsController controller;

  @override
  State<_AssignmentGradingSheet> createState() =>
      _AssignmentGradingSheetState();
}

class _AssignmentGradingSheetState extends State<_AssignmentGradingSheet> {
  late final TextEditingController _feedbackController;
  late int _score;
  late int _maxScore;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _score = widget.existingGrade?.score ?? 0;
    _maxScore = widget.existingGrade?.maxScore ?? 100;
    _feedbackController = TextEditingController(
      text: widget.existingGrade?.feedback ?? '',
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.controller.gradeSubmission(
      assignment: widget.assignment,
      submission: widget.submission,
      score: _score,
      maxScore: _maxScore,
      feedback: _feedbackController.text,
    );
    if (mounted) {
      setState(() => _saving = false);
    }
    if (ok) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final submission = widget.submission;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Grade • ${widget.assignment.courseCode}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                submission.submittedByName ?? 'Student',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if ((submission.textAnswer ?? '').trim().isNotEmpty) ...[
                Text(
                  'Text answer',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(submission.textAnswer!.trim()),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sheetPill(
                    cs,
                    '${submission.files.length} file(s)',
                    cs.primary,
                  ),
                  _sheetPill(
                    cs,
                    '${submission.whiteboardStrokes.length} diagram stroke(s)',
                    cs.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Score: $_score/$_maxScore',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Slider(
                min: 0,
                max: _maxScore.toDouble(),
                divisions: _maxScore.clamp(1, 1000),
                value: _score.clamp(0, _maxScore).toDouble(),
                label: '$_score',
                onChanged: (value) => setState(() => _score = value.round()),
              ),
              TextFormField(
                initialValue: _maxScore.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum mark',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final next = int.tryParse(value) ?? _maxScore;
                  setState(() {
                    _maxScore = next.clamp(1, 1000);
                    if (_score > _maxScore) _score = _maxScore;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _feedbackController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(_saving ? 'Saving grade...' : 'Save grade'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetPill(ColorScheme cs, String text, Color tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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

class _AssignmentSubmissionSheet extends StatefulWidget {
  const _AssignmentSubmissionSheet({
    required this.assignment,
    required this.existingSubmission,
    required this.controller,
  });

  final AssignmentModel assignment;
  final AssignmentSubmissionModel? existingSubmission;
  final AssignmentsController controller;

  @override
  State<_AssignmentSubmissionSheet> createState() =>
      _AssignmentSubmissionSheetState();
}

class _AssignmentSubmissionSheetState
    extends State<_AssignmentSubmissionSheet> {
  late final TextEditingController _textController;
  final _files = <AssignmentUploadFile>[];
  List<WhiteboardStroke> _whiteboardStrokes = <WhiteboardStroke>[];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.existingSubmission?.textAnswer ?? '',
    );
    if (widget.existingSubmission != null) {
      _files.addAll(widget.existingSubmission!.files);
      _whiteboardStrokes = List<WhiteboardStroke>.from(
        widget.existingSubmission!.whiteboardStrokes,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final picked = await widget.controller.pickAllowedFiles(widget.assignment);
    if (picked.isEmpty) return;

    final known = _files.map((f) => f.path).toSet();
    for (final file in picked) {
      if (!known.contains(file.path)) {
        _files.add(file);
      }
    }
    setState(() {});
  }

  Future<void> _openWhiteboard() async {
    if (!widget.assignment.whiteboardEnabled) return;

    final result = await Get.bottomSheet<List<WhiteboardStroke>>(
      WhiteboardEditorSheet(
        title: 'Assignment Whiteboard',
        prompt: widget.assignment.whiteboardPrompt,
        initialStrokes: _whiteboardStrokes,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );

    if (result == null) return;
    setState(() {
      _whiteboardStrokes = result;
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await widget.controller.submitAssignment(
      assignment: widget.assignment,
      textAnswer: _textController.text,
      files: _files,
      whiteboardStrokes: _whiteboardStrokes,
    );
    if (mounted) {
      setState(() => _submitting = false);
    }
    if (ok) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Submit • ${widget.assignment.courseCode}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.assignment.title,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _textController,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Text answer (optional)',
                  hintText: 'Type your response here...',
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.assignment.whiteboardEnabled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.assignment.whiteboardRequired
                            ? 'Diagram whiteboard is required for this assignment.'
                            : 'Diagram whiteboard is available for this assignment.',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.assignment.whiteboardPrompt != null &&
                          widget.assignment.whiteboardPrompt!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.assignment.whiteboardPrompt!.trim(),
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.74),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _whiteboardStrokes.isEmpty
                                  ? 'No diagram added'
                                  : '${_whiteboardStrokes.length} stroke(s) added',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openWhiteboard,
                            icon: const Icon(Icons.draw_outlined),
                            label: Text(
                              _whiteboardStrokes.isEmpty
                                  ? 'Open whiteboard'
                                  : 'Edit whiteboard',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _files
                    .asMap()
                    .entries
                    .map(
                      (entry) => Chip(
                        label: Text(entry.value.name),
                        onDeleted: () {
                          _files.removeAt(entry.key);
                          setState(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file_outlined),
                label: Text(
                  'Add files (${widget.assignment.allowedExtensions.join(", ")})',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_submitting ? 'Submitting...' : 'Submit now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentPeerReviewSheet extends StatefulWidget {
  const _AssignmentPeerReviewSheet({
    required this.assignment,
    required this.existingReview,
    required this.controller,
  });

  final AssignmentModel assignment;
  final AssignmentPeerReviewSubmission? existingReview;
  final AssignmentsController controller;

  @override
  State<_AssignmentPeerReviewSheet> createState() =>
      _AssignmentPeerReviewSheetState();
}

class _AssignmentPeerReviewSheetState
    extends State<_AssignmentPeerReviewSheet> {
  late final TextEditingController _feedbackController;
  late int _score;
  late final Map<String, bool> _rubricChecks;
  bool _submitting = false;

  AssignmentPeerReviewConfig get _peerReview => widget.assignment.peerReview!;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    _feedbackController = TextEditingController(text: existing?.feedback ?? '');
    _score = existing?.score ?? _peerReview.minScore;
    _rubricChecks = {
      for (final item in _peerReview.rubric)
        item: existing?.rubricChecks[item] ?? false,
    };
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await widget.controller.submitPeerReview(
      assignment: widget.assignment,
      score: _score,
      feedback: _feedbackController.text,
      rubricChecks: _rubricChecks,
    );
    if (mounted) {
      setState(() => _submitting = false);
    }
    if (ok) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final target = _peerReview.target;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Peer Review • ${widget.assignment.courseCode}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Assigned peer: ${target.name}',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sheetPill(cs, _peerReview.source.backendLabel, cs.tertiary),
                  if ((target.registrationNumber ?? '').trim().isNotEmpty)
                    _sheetPill(
                      cs,
                      target.registrationNumber!.trim(),
                      cs.primary,
                    ),
                  if ((target.groupName ?? '').trim().isNotEmpty)
                    _sheetPill(cs, target.groupName!.trim(), cs.secondary),
                  if (_peerReview.deadline != null)
                    _sheetPill(
                      cs,
                      'Due ${_fmtDateTime(_peerReview.deadline!)}',
                      cs.error,
                    ),
                ],
              ),
              if (_rubricChecks.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Rubric checks',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                ..._rubricChecks.keys.map(
                  (item) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _rubricChecks[item] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _rubricChecks[item] = value == true;
                      });
                    },
                    title: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Score: $_score/${_peerReview.maxScore}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Slider(
                min: _peerReview.minScore.toDouble(),
                max: _peerReview.maxScore.toDouble(),
                divisions: (_peerReview.maxScore - _peerReview.minScore)
                    .clamp(1, 100)
                    .toInt(),
                value: _score
                    .clamp(_peerReview.minScore, _peerReview.maxScore)
                    .toDouble(),
                label: _score.toString(),
                onChanged: (value) {
                  setState(() {
                    _score = value.round();
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _feedbackController,
                minLines: 5,
                maxLines: 9,
                decoration: const InputDecoration(
                  labelText: 'Feedback for your peer',
                  hintText:
                      'Explain what is strong, what needs correction, and one concrete next step.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.rate_review_outlined),
                  label: Text(
                    _submitting ? 'Saving review...' : 'Submit peer review',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetPill(ColorScheme cs, String text, Color tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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

class _StatusMeta {
  const _StatusMeta({required this.label, required this.color});
  final String label;
  final Color color;
}

_StatusMeta _statusMeta(AssignmentSubmissionState state, ColorScheme cs) {
  switch (state) {
    case AssignmentSubmissionState.pending:
      return const _StatusMeta(label: 'Pending', color: Color(0xFFF57C00));
    case AssignmentSubmissionState.submitted:
      return _StatusMeta(label: 'Submitted', color: cs.primary);
    case AssignmentSubmissionState.overdue:
      return const _StatusMeta(
        label: 'Deadline passed',
        color: Color(0xFFD32F2F),
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
