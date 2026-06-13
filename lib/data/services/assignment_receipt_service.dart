import '../models/assignment_model.dart';

class AssignmentSubmissionReceipt {
  const AssignmentSubmissionReceipt({
    required this.receiptNumber,
    required this.assignmentId,
    required this.courseCode,
    required this.submittedBy,
    required this.submittedAt,
    required this.fileCount,
    required this.hasTextAnswer,
    required this.hasWhiteboard,
    required this.groupId,
  });

  final String receiptNumber;
  final String assignmentId;
  final String courseCode;
  final String submittedBy;
  final DateTime submittedAt;
  final int fileCount;
  final bool hasTextAnswer;
  final bool hasWhiteboard;
  final String? groupId;

  String get submissionModeLabel {
    final parts = <String>[];
    if (hasTextAnswer) parts.add('Text');
    if (fileCount > 0) parts.add('$fileCount file(s)');
    if (hasWhiteboard) parts.add('Whiteboard');
    return parts.isEmpty ? 'No content' : parts.join(' + ');
  }
}

class AssignmentReceiptService {
  const AssignmentReceiptService._();

  static AssignmentSubmissionReceipt buildReceipt({
    required AssignmentModel assignment,
    required AssignmentSubmissionModel submission,
  }) {
    return AssignmentSubmissionReceipt(
      receiptNumber: receiptNumber(
        assignmentId: assignment.id,
        studentId: submission.submittedById ?? submission.groupId ?? 'student',
        submittedAt: submission.submittedAt,
      ),
      assignmentId: assignment.id,
      courseCode: assignment.courseCode,
      submittedBy: submission.submittedByName ?? submission.submittedById ?? 'Student',
      submittedAt: submission.submittedAt,
      fileCount: submission.files.length,
      hasTextAnswer: (submission.textAnswer ?? '').trim().isNotEmpty,
      hasWhiteboard: submission.whiteboardStrokes.isNotEmpty,
      groupId: submission.groupId,
    );
  }

  static String receiptNumber({
    required String assignmentId,
    required String studentId,
    required DateTime submittedAt,
  }) {
    final assignment = _clean(assignmentId);
    final student = _clean(studentId);
    final stamp = submittedAt.microsecondsSinceEpoch.toString();
    final suffix = stamp.substring(stamp.length - 6);
    return 'KSLAS-ASMT-$assignment-$student-$suffix';
  }

  static String _clean(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toUpperCase();
    if (cleaned.isEmpty) return 'SUB';
    if (cleaned.length <= 12) return cleaned;
    return cleaned.substring(0, 12);
  }
}
