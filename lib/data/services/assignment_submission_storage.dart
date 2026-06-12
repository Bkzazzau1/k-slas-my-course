import 'package:get_storage/get_storage.dart';

import '../models/assignment_model.dart';

class AssignmentSubmissionStorage {
  AssignmentSubmissionStorage._();

  static final _box = GetStorage();

  static String _submissionKey(String assignmentId) =>
      'assignment.submission.$assignmentId';

  static AssignmentSubmissionModel? loadSubmission(String assignmentId) {
    final raw = _box.read(_submissionKey(assignmentId));
    if (raw is! Map) return null;
    return AssignmentSubmissionModel.fromMap(Map<String, dynamic>.from(raw));
  }

  static Future<void> saveSubmission(AssignmentSubmissionModel submission) {
    return _box.write(
      _submissionKey(submission.assignmentId),
      submission.toMap(),
    );
  }

  static Future<void> clearSubmission(String assignmentId) {
    return _box.remove(_submissionKey(assignmentId));
  }
}
