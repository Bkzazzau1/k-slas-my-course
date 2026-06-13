import 'package:get_storage/get_storage.dart';

import '../models/assignment_model.dart';

class AssignmentSubmissionStorage {
  AssignmentSubmissionStorage._();

  static final _box = GetStorage();

  static String _submissionKey(String assignmentId) =>
      'assignment.submission.$assignmentId';
  static String _draftKey(String assignmentId) => 'assignment.draft.$assignmentId';

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

  static AssignmentSubmissionModel? loadDraft(String assignmentId) {
    final raw = _box.read(_draftKey(assignmentId));
    if (raw is! Map) return null;
    return AssignmentSubmissionModel.fromMap(Map<String, dynamic>.from(raw));
  }

  static Future<void> saveDraft(AssignmentSubmissionModel draft) {
    return _box.write(_draftKey(draft.assignmentId), draft.toMap());
  }

  static Future<void> clearDraft(String assignmentId) {
    return _box.remove(_draftKey(assignmentId));
  }

  static Future<void> markSubmittedAndClearDraft(
    AssignmentSubmissionModel submission,
  ) async {
    await saveSubmission(submission);
    await clearDraft(submission.assignmentId);
  }
}
