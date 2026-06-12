import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../core/whiteboard/whiteboard_models.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/services/assignment_group_chat_storage.dart';
import '../../../data/services/assignment_lecturer_storage.dart';
import '../../../data/services/assignment_peer_review_storage.dart';
import '../../../data/services/assignment_service.dart';
import '../../../data/services/assignment_submission_storage.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../features/dashboard/controller/dashboard_controller.dart';

enum AssignmentSubmissionState { pending, submitted, overdue }

class AssignmentsController extends GetxController {
  final assignments = <AssignmentModel>[].obs;
  final submissions = <String, AssignmentSubmissionModel>{}.obs;
  final peerReviews = <String, AssignmentPeerReviewSubmission>{}.obs;
  final grades = <String, AssignmentGradeModel>{}.obs;
  final groupChatMessages = <String, List<AssignmentGroupChatMessage>>{}.obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final providerLabel = AssignmentService.gateway.providerLabel.obs;
  final isLecturerMode = false.obs;
  final currentActorId = 'student-self'.obs;
  final currentActorName = 'Student Member'.obs;
  final filterCourseCode = RxnString();

  @override
  void onInit() {
    super.onInit();
    _resolveActorContext();
    unawaited(loadAssignments());
  }

  AssignmentGroupChatSenderRole get activeChatSenderRole => isLecturerMode.value
      ? AssignmentGroupChatSenderRole.lecturer
      : AssignmentGroupChatSenderRole.student;

  void _resolveActorContext() {
    final args = Get.arguments;
    if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      final roleRaw = (map['actorRole'] ?? map['role'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final actorNameRaw = (map['actorName'] ?? map['name'] ?? '')
          .toString()
          .trim();

      if (roleRaw == 'lecturer') {
        isLecturerMode.value = true;
        currentActorId.value = (map['actorId'] ?? map['id'] ?? '')
            .toString()
            .trim();
        if (currentActorId.value.isEmpty) {
          currentActorId.value = 'lecturer';
        }
        currentActorName.value = actorNameRaw.isNotEmpty
            ? actorNameRaw
            : 'Lecturer';
        return;
      }
    }

    final profile = StudentProfileStorage.load();
    final profileName = profile?.fullName.trim() ?? '';
    final profileId = profile?.matricNo?.trim() ?? '';
    currentActorId.value = profileId.isNotEmpty ? profileId : 'student-self';
    currentActorName.value = profileName.isNotEmpty
        ? profileName
        : 'Student Member';
  }

  Future<void> loadAssignments() async {
    isLoading.value = true;
    try {
      final items = await AssignmentService.fetchAssignedAssignments()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
      providerLabel.value = AssignmentService.gateway.providerLabel;
      assignments.assignAll(items);
      _loadSubmissions();
      _loadPeerReviews();
      _loadGrades();
      _loadGroupChats();
    } finally {
      isLoading.value = false;
    }
  }

  void _loadSubmissions() {
    final map = <String, AssignmentSubmissionModel>{};
    for (final assignment in assignments) {
      final submission = AssignmentSubmissionStorage.loadSubmission(
        assignment.id,
      );
      if (submission != null) {
        map[assignment.id] = submission;
      }
    }
    if (isLecturerMode.value) {
      for (final submission in _demoLecturerSubmissions()) {
        map.putIfAbsent(submission.assignmentId, () => submission);
      }
    }
    submissions.assignAll(map);
  }

  void _loadPeerReviews() {
    final map = <String, AssignmentPeerReviewSubmission>{};
    for (final assignment in assignments) {
      final peerReview = assignment.peerReview;
      if (peerReview == null) continue;

      final review = AssignmentPeerReviewStorage.loadReview(
        assignmentId: assignment.id,
        peerAssignmentId: peerReview.id,
      );
      if (review != null) {
        map[assignment.id] = review;
      }
    }
    peerReviews.assignAll(map);
  }

  void _loadGrades() {
    final map = <String, AssignmentGradeModel>{};
    for (final grade in AssignmentLecturerStorage.loadGrades()) {
      map[_gradeKey(grade.assignmentId, grade.submissionId)] = grade;
    }
    if (isLecturerMode.value) {
      for (final grade in _demoLecturerGrades()) {
        map.putIfAbsent(
          _gradeKey(grade.assignmentId, grade.submissionId),
          () => grade,
        );
      }
    }
    grades.assignAll(map);
  }

  void _loadGroupChats() {
    final map = <String, List<AssignmentGroupChatMessage>>{};
    for (final assignment in assignments) {
      if (!assignment.hasGroupChat || assignment.groupId == null) {
        continue;
      }

      final messages = AssignmentGroupChatStorage.loadMessages(
        assignmentId: assignment.id,
        groupId: assignment.groupId!,
      );
      if (messages.isNotEmpty) {
        map[assignment.id] = messages;
        continue;
      }

      final seeded = AssignmentService.loadInitialGroupMessages(assignment);
      if (seeded.isNotEmpty) {
        map[assignment.id] = seeded;
        unawaited(
          AssignmentGroupChatStorage.saveMessages(
            assignmentId: assignment.id,
            groupId: assignment.groupId!,
            messages: seeded,
          ),
        );
      }
    }
    groupChatMessages.assignAll(map);
  }

  List<AssignmentModel> get visibleAssignments {
    final filter = filterCourseCode.value;
    if (filter == null || filter.trim().isEmpty) {
      return assignments;
    }
    return assignments.where((a) => a.courseCode == filter).toList();
  }

  AssignmentSubmissionModel? submissionFor(String assignmentId) {
    return submissions[assignmentId];
  }

  AssignmentPeerReviewSubmission? peerReviewFor(String assignmentId) {
    return peerReviews[assignmentId];
  }

  List<AssignmentSubmissionModel> submissionsForAssignment(
    AssignmentModel assignment,
  ) {
    final submission = submissions[assignment.id];
    if (submission == null) return const [];
    return [submission];
  }

  AssignmentGradeModel? gradeFor({
    required String assignmentId,
    required String submissionId,
  }) {
    return grades[_gradeKey(assignmentId, submissionId)];
  }

  AssignmentGradeModel? gradeForStudentAssignment(AssignmentModel assignment) {
    final submission = submissions[assignment.id];
    if (submission == null) return _demoStudentGrade(assignment);
    return gradeFor(
      assignmentId: assignment.id,
      submissionId: _submissionId(submission),
    );
  }

  void switchDemoRole({required bool lecturer}) {
    isLecturerMode.value = lecturer;
    if (lecturer) {
      currentActorId.value = 'lecturer-demo';
      currentActorName.value = 'Dr. Musa';
    } else {
      currentActorId.value = 'KASU/GST/21/088';
      currentActorName.value = 'Blessing Okafor';
    }
    _loadSubmissions();
    _loadGrades();
    _loadGroupChats();
  }

  bool canOpenGroupChat(AssignmentModel assignment) {
    return assignment.hasGroupChat;
  }

  List<AssignmentGroupChatMessage> messagesForAssignmentGroup(
    AssignmentModel assignment,
  ) {
    return groupChatMessages[assignment.id] ?? const [];
  }

  Future<void> sendGroupMessage({
    required AssignmentModel assignment,
    required String message,
    AssignmentGroupChatSenderRole senderRole =
        AssignmentGroupChatSenderRole.student,
    String? senderId,
    String? senderName,
  }) async {
    if (!canOpenGroupChat(assignment) || assignment.groupId == null) {
      return;
    }

    final cleaned = message.trim();
    if (cleaned.isEmpty) return;
    final effectiveSenderName = senderName?.trim().isNotEmpty == true
        ? senderName!.trim()
        : (senderRole == AssignmentGroupChatSenderRole.lecturer
              ? assignment.lecturerName
              : currentActorName.value);

    final effectiveSenderId = senderId?.trim().isNotEmpty == true
        ? senderId!.trim()
        : (senderRole == AssignmentGroupChatSenderRole.lecturer
              ? 'lecturer-${assignment.id}'
              : currentActorId.value);

    final entry = AssignmentGroupChatMessage(
      id: '${assignment.id}-${DateTime.now().microsecondsSinceEpoch}',
      assignmentId: assignment.id,
      groupId: assignment.groupId!,
      senderId: effectiveSenderId,
      senderName: effectiveSenderName,
      senderRole: senderRole,
      message: cleaned,
      sentAt: DateTime.now(),
    );

    final next = List<AssignmentGroupChatMessage>.from(
      groupChatMessages[assignment.id] ?? const [],
    )..add(entry);

    next.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    groupChatMessages[assignment.id] = next;
    groupChatMessages.refresh();

    await AssignmentGroupChatStorage.saveMessages(
      assignmentId: assignment.id,
      groupId: assignment.groupId!,
      messages: next,
    );
  }

  bool isOverdue(AssignmentModel assignment) {
    return DateTime.now().isAfter(assignment.deadline);
  }

  AssignmentSubmissionState submissionState(AssignmentModel assignment) {
    final hasSubmission = submissions.containsKey(assignment.id);
    if (hasSubmission) return AssignmentSubmissionState.submitted;
    if (isOverdue(assignment)) return AssignmentSubmissionState.overdue;
    return AssignmentSubmissionState.pending;
  }

  Future<List<AssignmentUploadFile>> pickAllowedFiles(
    AssignmentModel assignment,
  ) async {
    if (!assignment.allowFileSubmission) return const [];

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: assignment.allowedExtensions,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return const [];

    return result.files.where((file) => file.path != null).map((file) {
      final path = file.path!;
      final ext = path.split('.').last.toLowerCase();
      return AssignmentUploadFile(
        path: path,
        name: file.name,
        sizeBytes: file.size,
        extension: ext,
      );
    }).toList();
  }

  Future<bool> submitAssignment({
    required AssignmentModel assignment,
    required String textAnswer,
    required List<AssignmentUploadFile> files,
    required List<WhiteboardStroke> whiteboardStrokes,
  }) async {
    if (isOverdue(assignment)) {
      Get.snackbar(
        'Deadline reached',
        'Submission for ${assignment.courseCode} has passed the deadline.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final hasText = textAnswer.trim().isNotEmpty;
    final hasFiles = files.isNotEmpty;
    final hasWhiteboard = whiteboardStrokes.isNotEmpty;
    if (!hasText && !hasFiles && !hasWhiteboard) {
      Get.snackbar(
        'Submission incomplete',
        'Add a text answer, a file, or a whiteboard diagram before submitting.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (assignment.whiteboardRequired && !hasWhiteboard) {
      Get.snackbar(
        'Whiteboard required',
        'This assignment requires a whiteboard diagram.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    for (final file in files) {
      if (!File(file.path).existsSync()) {
        Get.snackbar(
          'File missing',
          'One or more selected files are no longer available on disk.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }

    isSubmitting.value = true;
    try {
      final remoteSaved = await AssignmentService.submitAssignment(
        assignment: assignment,
        textAnswer: textAnswer,
        files: files,
        whiteboardStrokes: whiteboardStrokes,
        groupId: assignment.isGroupAssignment ? assignment.groupId : null,
      );

      final submission = AssignmentSubmissionModel(
        assignmentId: assignment.id,
        submittedAt: DateTime.now(),
        textAnswer: hasText ? textAnswer.trim() : null,
        files: files,
        whiteboardStrokes: whiteboardStrokes,
        groupId: assignment.isGroupAssignment ? assignment.groupId : null,
        submittedById: currentActorId.value,
        submittedByName: currentActorName.value,
      );

      await AssignmentSubmissionStorage.saveSubmission(submission);
      submissions[assignment.id] = submission;
      submissions.refresh();

      if (Get.isRegistered<DashboardController>()) {
        unawaited(Get.find<DashboardController>().refreshAssignmentsBoard());
      }

      Get.snackbar(
        'Submission saved',
        remoteSaved
            ? 'Assignment submitted successfully.'
            : 'Saved locally. Backend sync will be retried later.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> createAssignment({
    required String courseCode,
    required String title,
    required String description,
    required DateTime deadline,
    required bool isGroupAssignment,
    required bool peerReviewEnabled,
    required bool allowTextSubmission,
    required bool allowFileSubmission,
    required bool whiteboardEnabled,
    required bool whiteboardRequired,
    required String whiteboardPrompt,
    required String allowedExtensions,
    required List<AssignmentGroupMember> groupMembers,
    required List<String> peerRubric,
  }) async {
    if (!isLecturerMode.value) return false;

    final cleanCourseCode = courseCode.trim().toUpperCase();
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    if (cleanCourseCode.isEmpty ||
        cleanTitle.isEmpty ||
        cleanDescription.isEmpty) {
      Get.snackbar(
        'Missing details',
        'Course, title, and assignment instructions are required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (deadline.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      Get.snackbar(
        'Deadline too soon',
        'Choose a deadline later than the current time.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!allowTextSubmission && !allowFileSubmission && !whiteboardEnabled) {
      Get.snackbar(
        'Submission type required',
        'Enable text, file, or whiteboard submission.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final cleanMembers = groupMembers
        .where(
          (member) =>
              member.id.trim().isNotEmpty && member.name.trim().isNotEmpty,
        )
        .toList();
    if (isGroupAssignment && cleanMembers.length < 2) {
      Get.snackbar(
        'Group members needed',
        'Add at least two backend-assigned group members.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final extensions = allowedExtensions
        .split(',')
        .map((item) => item.trim().replaceAll('.', '').toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    final assignmentId = 'demo-asmt-${DateTime.now().microsecondsSinceEpoch}';
    final groupId = isGroupAssignment ? 'demo-grp-$assignmentId' : null;
    final peerTarget = cleanMembers.isNotEmpty ? cleanMembers.first : null;

    final assignment = AssignmentModel(
      id: assignmentId,
      courseCode: cleanCourseCode,
      title: cleanTitle,
      description: cleanDescription,
      lecturerName: currentActorName.value,
      assignedAt: DateTime.now(),
      deadline: deadline,
      isGroupAssignment: isGroupAssignment,
      groupId: groupId,
      groupName: isGroupAssignment ? '$cleanCourseCode Group' : null,
      groupSource: isGroupAssignment
          ? AssignmentGroupSource.lecturerSetBackend
          : null,
      groupMembers: cleanMembers,
      groupChatEnabled: isGroupAssignment,
      whiteboardEnabled: whiteboardEnabled,
      whiteboardRequired: whiteboardRequired,
      whiteboardPrompt: whiteboardPrompt.trim().isEmpty
          ? null
          : whiteboardPrompt.trim(),
      allowTextSubmission: allowTextSubmission,
      allowFileSubmission: allowFileSubmission,
      allowedExtensions: extensions.isEmpty
          ? const ['pdf', 'doc', 'docx', 'png']
          : extensions,
      peerReview: peerReviewEnabled && peerTarget != null
          ? AssignmentPeerReviewConfig(
              id: 'demo-peer-$assignmentId',
              target: AssignmentPeerReviewTarget(
                id: peerTarget.id,
                name: peerTarget.name,
                submissionId: 'demo-sub-$assignmentId-${peerTarget.id}',
                groupId: groupId,
                groupName: isGroupAssignment ? '$cleanCourseCode Group' : null,
              ),
              deadline: deadline.add(const Duration(days: 1)),
              rubric: peerRubric
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList(),
            )
          : null,
    );

    isSubmitting.value = true;
    try {
      final remoteSaved = await AssignmentService.createAssignment(assignment);
      assignments.insert(0, assignment);
      assignments.sort((a, b) => a.deadline.compareTo(b.deadline));
      assignments.refresh();

      Get.snackbar(
        'Assignment published',
        remoteSaved
            ? 'Assignment is available to students.'
            : 'Saved locally for demo. Backend sync will be retried later.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> gradeSubmission({
    required AssignmentModel assignment,
    required AssignmentSubmissionModel submission,
    required int score,
    required int maxScore,
    required String feedback,
  }) async {
    if (!isLecturerMode.value) return false;
    if (maxScore < 1 || score < 0 || score > maxScore) {
      Get.snackbar(
        'Invalid mark',
        'Score must be between 0 and the maximum mark.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final cleanFeedback = feedback.trim();
    if (cleanFeedback.length < 5) {
      Get.snackbar(
        'Feedback needed',
        'Add short feedback before saving the grade.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final submissionId = _submissionId(submission);
    final grade = AssignmentGradeModel(
      assignmentId: assignment.id,
      submissionId: submissionId,
      studentId: submission.submittedById ?? 'student',
      studentName: submission.submittedByName ?? 'Student',
      score: score,
      maxScore: maxScore,
      feedback: cleanFeedback,
      gradedById: currentActorId.value,
      gradedByName: currentActorName.value,
      gradedAt: DateTime.now(),
    );

    isSubmitting.value = true;
    try {
      final remoteSaved = await AssignmentService.saveGrade(grade);
      await AssignmentLecturerStorage.saveGrade(grade);
      grades[_gradeKey(assignment.id, submissionId)] = grade;
      grades.refresh();

      Get.snackbar(
        'Grade saved',
        remoteSaved
            ? 'Mark and feedback were saved.'
            : 'Saved locally for demo. Backend sync will be retried later.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> submitPeerReview({
    required AssignmentModel assignment,
    required int score,
    required String feedback,
    required Map<String, bool> rubricChecks,
  }) async {
    final peerReview = assignment.peerReview;
    if (peerReview == null) return false;

    final deadline = peerReview.deadline;
    if (deadline != null && DateTime.now().isAfter(deadline)) {
      Get.snackbar(
        'Peer review closed',
        'The peer-review deadline for ${assignment.courseCode} has passed.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final cleanedFeedback = feedback.trim();
    if (cleanedFeedback.length < 20) {
      Get.snackbar(
        'Feedback too short',
        'Write at least two helpful sentences for your assigned peer.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (score < peerReview.minScore || score > peerReview.maxScore) {
      Get.snackbar(
        'Invalid score',
        'Score must be between ${peerReview.minScore} and ${peerReview.maxScore}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final review = AssignmentPeerReviewSubmission(
      assignmentId: assignment.id,
      peerAssignmentId: peerReview.id,
      targetSubmissionId: peerReview.target.submissionId,
      targetStudentId: peerReview.target.id,
      targetStudentName: peerReview.target.name,
      reviewerId: currentActorId.value,
      reviewerName: currentActorName.value,
      score: score,
      feedback: cleanedFeedback,
      submittedAt: DateTime.now(),
      rubricChecks: rubricChecks,
    );

    final remoteSaved = await AssignmentService.submitPeerReview(
      assignment: assignment,
      peerReview: peerReview,
      score: score,
      feedback: cleanedFeedback,
      rubricChecks: rubricChecks,
    );

    await AssignmentPeerReviewStorage.saveReview(review);
    peerReviews[assignment.id] = review;
    peerReviews.refresh();

    Get.snackbar(
      'Peer review saved',
      remoteSaved
          ? 'Your review for ${peerReview.target.name} has been submitted.'
          : 'Saved locally. Backend sync will be retried later.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return true;
  }

  static String _submissionId(AssignmentSubmissionModel submission) {
    final student = submission.submittedById?.trim();
    if (student != null && student.isNotEmpty) {
      return '${submission.assignmentId}-$student';
    }
    return '${submission.assignmentId}-${submission.submittedAt.microsecondsSinceEpoch}';
  }

  static String submissionIdForGrade(AssignmentSubmissionModel submission) {
    return _submissionId(submission);
  }

  static String _gradeKey(String assignmentId, String submissionId) {
    return '$assignmentId::$submissionId';
  }

  List<AssignmentSubmissionModel> _demoLecturerSubmissions() {
    final now = DateTime.now();
    final samples = <String, AssignmentSubmissionModel>{
      'asmt-csc305-graphs': AssignmentSubmissionModel(
        assignmentId: 'asmt-csc305-graphs',
        submittedAt: now.subtract(const Duration(hours: 7, minutes: 20)),
        textAnswer:
            'We used Dijkstra for the weighted graph and Kruskal for the MST. The attached diagram explains the edge ordering and final traversal path.',
        files: const [
          AssignmentUploadFile(
            path: 'demo/csc305_group_a_report.pdf',
            name: 'CSC305_Group_A_Report.pdf',
            sizeBytes: 412000,
            extension: 'pdf',
          ),
        ],
        groupId: 'grp-csc305-a',
        submittedById: 'grp-csc305-a',
        submittedByName: 'CSC 305 Group A',
      ),
      'asmt-mth202-matrix': AssignmentSubmissionModel(
        assignmentId: 'asmt-mth202-matrix',
        submittedAt: now.subtract(const Duration(hours: 3, minutes: 45)),
        textAnswer:
            'The LU decomposition is solved by row elimination, then checked by multiplying L and U. QR steps are included in the uploaded worksheet.',
        files: const [
          AssignmentUploadFile(
            path: 'demo/mth202_group_c_workings.docx',
            name: 'MTH202_Group_C_Workings.docx',
            sizeBytes: 288000,
            extension: 'docx',
          ),
        ],
        groupId: 'grp-mth202-c',
        submittedById: 'grp-mth202-c',
        submittedByName: 'MTH 202 Group C',
      ),
      'asmt-gst201-essay': AssignmentSubmissionModel(
        assignmentId: 'asmt-gst201-essay',
        submittedAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        textAnswer:
            'Academic writing improves when students plan their argument, cite carefully, and revise paragraphs for clarity.',
        submittedById: 'KASU/GST/21/088',
        submittedByName: 'Blessing Okafor',
      ),
    };

    return assignments
        .map((assignment) => samples[assignment.id])
        .whereType<AssignmentSubmissionModel>()
        .toList();
  }

  AssignmentGradeModel? _demoStudentGrade(AssignmentModel assignment) {
    if (isLecturerMode.value || assignment.id != 'asmt-gst201-essay') {
      return null;
    }
    return AssignmentGradeModel(
      assignmentId: assignment.id,
      submissionId: 'demo-student-grade-${assignment.id}',
      studentId: currentActorId.value,
      studentName: currentActorName.value,
      score: 82,
      maxScore: 100,
      feedback:
          'Strong reflection with clear paragraphs. Add one more source example in the final version.',
      gradedById: 'lecturer-demo',
      gradedByName: 'Ms. Grace',
      gradedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  List<AssignmentGradeModel> _demoLecturerGrades() {
    final cscSubmission = AssignmentSubmissionModel(
      assignmentId: 'asmt-csc305-graphs',
      submittedAt: DateTime.now().subtract(const Duration(hours: 7)),
      submittedById: 'grp-csc305-a',
      submittedByName: 'CSC 305 Group A',
    );
    return [
      AssignmentGradeModel(
        assignmentId: 'asmt-csc305-graphs',
        submissionId: _submissionId(cscSubmission),
        studentId: 'grp-csc305-a',
        studentName: 'CSC 305 Group A',
        score: 88,
        maxScore: 100,
        feedback:
            'Excellent algorithm selection and readable graph diagram. Tighten the proof sketch for the MST section.',
        gradedById: currentActorId.value,
        gradedByName: currentActorName.value,
        gradedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
