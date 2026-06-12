import 'package:get_storage/get_storage.dart';

import '../models/assignment_model.dart';

class AssignmentPeerReviewStorage {
  AssignmentPeerReviewStorage._();

  static final _box = GetStorage();

  static String _reviewKey({
    required String assignmentId,
    required String peerAssignmentId,
  }) => 'assignment.peer-review.$assignmentId.$peerAssignmentId';

  static AssignmentPeerReviewSubmission? loadReview({
    required String assignmentId,
    required String peerAssignmentId,
  }) {
    final raw = _box.read(
      _reviewKey(
        assignmentId: assignmentId,
        peerAssignmentId: peerAssignmentId,
      ),
    );
    if (raw is! Map) return null;
    return AssignmentPeerReviewSubmission.fromMap(
      Map<String, dynamic>.from(raw),
    );
  }

  static Future<void> saveReview(AssignmentPeerReviewSubmission review) {
    return _box.write(
      _reviewKey(
        assignmentId: review.assignmentId,
        peerAssignmentId: review.peerAssignmentId,
      ),
      review.toMap(),
    );
  }

  static Future<void> clearReview({
    required String assignmentId,
    required String peerAssignmentId,
  }) {
    return _box.remove(
      _reviewKey(
        assignmentId: assignmentId,
        peerAssignmentId: peerAssignmentId,
      ),
    );
  }
}
