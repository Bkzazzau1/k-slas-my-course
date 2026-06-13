import '../models/assignment_model.dart';
import 'assignment_quality_service.dart';

class AssignmentLecturerDashboardSnapshot {
  const AssignmentLecturerDashboardSnapshot({
    required this.totalAssignments,
    required this.openAssignments,
    required this.overdueAssignments,
    required this.totalSubmissions,
    required this.pendingGrading,
    required this.gradedSubmissions,
    required this.averageScore,
  });

  final int totalAssignments;
  final int openAssignments;
  final int overdueAssignments;
  final int totalSubmissions;
  final int pendingGrading;
  final int gradedSubmissions;
  final int averageScore;
}

class AssignmentLecturerAnalyticsService {
  const AssignmentLecturerAnalyticsService._();

  static AssignmentLecturerDashboardSnapshot buildSnapshot({
    required List<AssignmentModel> assignments,
    required Map<String, AssignmentSubmissionModel> submissions,
    required List<AssignmentGradeModel> grades,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final openAssignments = assignments
        .where((item) => currentTime.isBefore(item.deadline))
        .length;
    final overdueAssignments = assignments.length - openAssignments;
    final submissionItems = submissions.values.toList();
    final summary = AssignmentQualityService.lecturerSummary(
      submissions: submissionItems,
      grades: grades,
    );
    return AssignmentLecturerDashboardSnapshot(
      totalAssignments: assignments.length,
      openAssignments: openAssignments,
      overdueAssignments: overdueAssignments,
      totalSubmissions: summary.totalSubmissions,
      pendingGrading: summary.pendingGrading,
      gradedSubmissions: summary.gradedSubmissions,
      averageScore: summary.averageScore,
    );
  }
}
