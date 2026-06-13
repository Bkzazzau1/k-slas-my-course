import '../models/assignment_model.dart';

class AssignmentQualityStatus {
  const AssignmentQualityStatus({
    required this.label,
    required this.detail,
    required this.isSubmitted,
    required this.isOverdue,
    required this.isDueSoon,
    required this.minutesRemaining,
    required this.completionScore,
  });

  final String label;
  final String detail;
  final bool isSubmitted;
  final bool isOverdue;
  final bool isDueSoon;
  final int minutesRemaining;
  final int completionScore;

  bool get canSubmit => !isOverdue;
}

class AssignmentSubmissionChecklist {
  const AssignmentSubmissionChecklist({
    required this.items,
    required this.blockers,
    required this.warnings,
    required this.ready,
  });

  final List<String> items;
  final List<String> blockers;
  final List<String> warnings;
  final bool ready;
}

class AssignmentLecturerReviewSummary {
  const AssignmentLecturerReviewSummary({
    required this.totalSubmissions,
    required this.gradedSubmissions,
    required this.pendingGrading,
    required this.averageScore,
    required this.maxScore,
  });

  final int totalSubmissions;
  final int gradedSubmissions;
  final int pendingGrading;
  final int averageScore;
  final int maxScore;
}

class AssignmentQualityService {
  const AssignmentQualityService._();

  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  static AssignmentQualityStatus statusFor({
    required AssignmentModel assignment,
    AssignmentSubmissionModel? submission,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final remaining = assignment.deadline.difference(currentTime).inMinutes;
    final overdue = remaining < 0;
    final dueSoon = !overdue && remaining <= 24 * 60;
    final submitted = submission != null;

    if (submitted) {
      return AssignmentQualityStatus(
        label: overdue ? 'Submitted late window closed' : 'Submitted',
        detail: 'Last submitted ${_relativeTime(submission.submittedAt, currentTime)}',
        isSubmitted: true,
        isOverdue: overdue,
        isDueSoon: dueSoon,
        minutesRemaining: remaining,
        completionScore: 100,
      );
    }

    if (overdue) {
      return AssignmentQualityStatus(
        label: 'Overdue',
        detail: 'Deadline passed ${_relativeTime(assignment.deadline, currentTime)}',
        isSubmitted: false,
        isOverdue: true,
        isDueSoon: false,
        minutesRemaining: remaining,
        completionScore: 0,
      );
    }

    return AssignmentQualityStatus(
      label: dueSoon ? 'Due soon' : 'Open',
      detail: 'Due in ${_durationLabel(remaining)}',
      isSubmitted: false,
      isOverdue: false,
      isDueSoon: dueSoon,
      minutesRemaining: remaining,
      completionScore: dueSoon ? 35 : 20,
    );
  }

  static AssignmentSubmissionChecklist checklistFor({
    required AssignmentModel assignment,
    required String textAnswer,
    required List<AssignmentUploadFile> files,
    required List<Object> whiteboardStrokes,
  }) {
    final items = <String>[];
    final blockers = <String>[];
    final warnings = <String>[];
    final cleanText = textAnswer.trim();

    if (assignment.allowTextSubmission) {
      if (cleanText.isNotEmpty) {
        items.add('Text answer added');
        if (cleanText.length < 80) {
          warnings.add('Text answer is short; add more explanation where possible.');
        }
      } else {
        warnings.add('No text answer added.');
      }
    }

    if (assignment.allowFileSubmission) {
      if (files.isEmpty) {
        warnings.add('No file attached.');
      } else {
        items.add('${files.length} file(s) attached');
      }
      for (final file in files) {
        final ext = file.extension.trim().toLowerCase().replaceAll('.', '');
        if (!assignment.allowedExtensions.map((e) => e.toLowerCase()).contains(ext)) {
          blockers.add('${file.name} is not an allowed file type.');
        }
        if (file.sizeBytes > maxFileSizeBytes) {
          blockers.add('${file.name} is larger than 25 MB.');
        }
      }
    }

    if (assignment.whiteboardEnabled) {
      if (whiteboardStrokes.isNotEmpty) {
        items.add('Whiteboard diagram added');
      } else if (assignment.whiteboardRequired) {
        blockers.add('Whiteboard diagram is required.');
      } else {
        warnings.add('Whiteboard diagram is optional but not added.');
      }
    }

    final hasAnySubmission = cleanText.isNotEmpty || files.isNotEmpty || whiteboardStrokes.isNotEmpty;
    if (!hasAnySubmission) {
      blockers.add('Add at least one submission item before submitting.');
    }

    return AssignmentSubmissionChecklist(
      items: items,
      blockers: blockers,
      warnings: warnings,
      ready: blockers.isEmpty && hasAnySubmission,
    );
  }

  static AssignmentLecturerReviewSummary lecturerSummary({
    required List<AssignmentSubmissionModel> submissions,
    required List<AssignmentGradeModel> grades,
  }) {
    if (submissions.isEmpty) {
      return const AssignmentLecturerReviewSummary(
        totalSubmissions: 0,
        gradedSubmissions: 0,
        pendingGrading: 0,
        averageScore: 0,
        maxScore: 100,
      );
    }
    final graded = grades.where((grade) => grade.maxScore > 0).toList();
    final average = graded.isEmpty
        ? 0
        : (graded.fold<double>(0, (sum, grade) => sum + ((grade.score / grade.maxScore) * 100)) / graded.length).round();
    return AssignmentLecturerReviewSummary(
      totalSubmissions: submissions.length,
      gradedSubmissions: graded.length,
      pendingGrading: submissions.length - graded.length,
      averageScore: average,
      maxScore: 100,
    );
  }

  static String _relativeTime(DateTime target, DateTime now) {
    final diff = now.difference(target);
    if (diff.inMinutes.abs() < 1) return 'just now';
    if (diff.isNegative) return 'in ${_durationLabel(diff.inMinutes.abs())}';
    return '${_durationLabel(diff.inMinutes)} ago';
  }

  static String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes minute(s)';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours < 24) return mins == 0 ? '$hours hour(s)' : '$hours hour(s) $mins minute(s)';
    final days = hours ~/ 24;
    final remainHours = hours % 24;
    return remainHours == 0 ? '$days day(s)' : '$days day(s) $remainHours hour(s)';
  }
}
