import '../../core/whiteboard/whiteboard_models.dart';

enum AssignmentGroupSource { randomBackend, lecturerSetBackend }

extension AssignmentGroupSourceX on AssignmentGroupSource {
  String get backendLabel {
    switch (this) {
      case AssignmentGroupSource.randomBackend:
        return 'Random from backend';
      case AssignmentGroupSource.lecturerSetBackend:
        return 'Lecturer-set from backend';
    }
  }

  String get raw {
    switch (this) {
      case AssignmentGroupSource.randomBackend:
        return 'random_backend';
      case AssignmentGroupSource.lecturerSetBackend:
        return 'lecturer_set_backend';
    }
  }

  static AssignmentGroupSource? fromRaw(String? raw) {
    switch (raw) {
      case 'random_backend':
        return AssignmentGroupSource.randomBackend;
      case 'lecturer_set_backend':
        return AssignmentGroupSource.lecturerSetBackend;
      default:
        return null;
    }
  }
}

enum AssignmentPeerReviewSource { backendAssigned }

extension AssignmentPeerReviewSourceX on AssignmentPeerReviewSource {
  String get backendLabel {
    switch (this) {
      case AssignmentPeerReviewSource.backendAssigned:
        return 'Peer assigned from backend';
    }
  }

  String get raw {
    switch (this) {
      case AssignmentPeerReviewSource.backendAssigned:
        return 'backend_assigned';
    }
  }

  static AssignmentPeerReviewSource? fromRaw(String? raw) {
    switch (raw) {
      case 'backend_assigned':
        return AssignmentPeerReviewSource.backendAssigned;
      default:
        return null;
    }
  }
}

enum AssignmentGroupMemberRole { student, lecturer }

extension AssignmentGroupMemberRoleX on AssignmentGroupMemberRole {
  String get raw {
    switch (this) {
      case AssignmentGroupMemberRole.student:
        return 'student';
      case AssignmentGroupMemberRole.lecturer:
        return 'lecturer';
    }
  }

  static AssignmentGroupMemberRole fromRaw(String? raw) {
    switch (raw) {
      case 'lecturer':
        return AssignmentGroupMemberRole.lecturer;
      case 'student':
      default:
        return AssignmentGroupMemberRole.student;
    }
  }
}

class AssignmentGroupMember {
  const AssignmentGroupMember({
    required this.id,
    required this.name,
    this.role = AssignmentGroupMemberRole.student,
  });

  final String id;
  final String name;
  final AssignmentGroupMemberRole role;

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'role': role.raw};
  }

  factory AssignmentGroupMember.fromMap(Map<String, dynamic> map) {
    return AssignmentGroupMember(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      role: AssignmentGroupMemberRoleX.fromRaw(map['role']?.toString()),
    );
  }
}

class AssignmentPeerReviewTarget {
  const AssignmentPeerReviewTarget({
    required this.id,
    required this.name,
    required this.submissionId,
    this.registrationNumber,
    this.groupId,
    this.groupName,
  });

  final String id;
  final String name;
  final String submissionId;
  final String? registrationNumber;
  final String? groupId;
  final String? groupName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'submissionId': submissionId,
      'registrationNumber': registrationNumber,
      'groupId': groupId,
      'groupName': groupName,
    };
  }

  factory AssignmentPeerReviewTarget.fromMap(Map<String, dynamic> map) {
    return AssignmentPeerReviewTarget(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      submissionId: (map['submissionId'] ?? '').toString(),
      registrationNumber: map['registrationNumber']?.toString(),
      groupId: map['groupId']?.toString(),
      groupName: map['groupName']?.toString(),
    );
  }
}

class AssignmentPeerReviewConfig {
  const AssignmentPeerReviewConfig({
    required this.id,
    required this.target,
    this.source = AssignmentPeerReviewSource.backendAssigned,
    this.rubric = const [],
    this.deadline,
    this.minScore = 0,
    this.maxScore = 10,
  });

  final String id;
  final AssignmentPeerReviewSource source;
  final AssignmentPeerReviewTarget target;
  final List<String> rubric;
  final DateTime? deadline;
  final int minScore;
  final int maxScore;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source.raw,
      'target': target.toMap(),
      'rubric': rubric,
      'deadline': deadline?.toIso8601String(),
      'minScore': minScore,
      'maxScore': maxScore,
    };
  }

  factory AssignmentPeerReviewConfig.fromMap(Map<String, dynamic> map) {
    final rawRubric = (map['rubric'] as List?) ?? const [];
    final rawMin = map['minScore'];
    final rawMax = map['maxScore'];
    return AssignmentPeerReviewConfig(
      id: (map['id'] ?? '').toString(),
      source:
          AssignmentPeerReviewSourceX.fromRaw(map['source']?.toString()) ??
          AssignmentPeerReviewSource.backendAssigned,
      target: AssignmentPeerReviewTarget.fromMap(
        Map<String, dynamic>.from(map['target'] as Map? ?? const {}),
      ),
      rubric: rawRubric.map((item) => item.toString()).toList(),
      deadline: DateTime.tryParse((map['deadline'] ?? '').toString()),
      minScore: rawMin is num ? rawMin.toInt() : 0,
      maxScore: rawMax is num ? rawMax.toInt() : 10,
    );
  }
}

class AssignmentModel {
  const AssignmentModel({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.lecturerName,
    required this.assignedAt,
    required this.deadline,
    this.isGroupAssignment = false,
    this.groupId,
    this.groupName,
    this.groupSource,
    this.groupMembers = const [],
    this.groupChatEnabled = false,
    this.lecturerCanWriteInGroupChat = true,
    this.whiteboardEnabled = false,
    this.whiteboardRequired = false,
    this.whiteboardPrompt,
    this.allowTextSubmission = true,
    this.allowFileSubmission = true,
    this.allowedExtensions = const ['pdf', 'txt', 'doc', 'docx', 'png'],
    this.peerReview,
  });

  final String id;
  final String courseCode;
  final String title;
  final String description;
  final String lecturerName;
  final DateTime assignedAt;
  final DateTime deadline;
  final bool isGroupAssignment;
  final String? groupId;
  final String? groupName;
  final AssignmentGroupSource? groupSource;
  final List<AssignmentGroupMember> groupMembers;
  final bool groupChatEnabled;
  final bool lecturerCanWriteInGroupChat;
  final bool whiteboardEnabled;
  final bool whiteboardRequired;
  final String? whiteboardPrompt;
  final bool allowTextSubmission;
  final bool allowFileSubmission;
  final List<String> allowedExtensions;
  final AssignmentPeerReviewConfig? peerReview;

  bool get hasGroupChat =>
      isGroupAssignment &&
      groupChatEnabled &&
      (groupId?.trim().isNotEmpty ?? false);

  bool get hasPeerReview =>
      peerReview != null && peerReview!.target.id.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseCode': courseCode,
      'title': title,
      'description': description,
      'lecturerName': lecturerName,
      'assignedAt': assignedAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'isGroupAssignment': isGroupAssignment,
      'groupId': groupId,
      'groupName': groupName,
      'groupSource': groupSource?.raw,
      'groupMembers': groupMembers.map((member) => member.toMap()).toList(),
      'groupChatEnabled': groupChatEnabled,
      'lecturerCanWriteInGroupChat': lecturerCanWriteInGroupChat,
      'whiteboardEnabled': whiteboardEnabled,
      'whiteboardRequired': whiteboardRequired,
      'whiteboardPrompt': whiteboardPrompt,
      'allowTextSubmission': allowTextSubmission,
      'allowFileSubmission': allowFileSubmission,
      'allowedExtensions': allowedExtensions,
      'peerReview': peerReview?.toMap(),
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    final rawMembers = (map['groupMembers'] as List?) ?? const [];
    final rawExtensions = (map['allowedExtensions'] as List?) ?? const [];
    final rawPeerReview = map['peerReview'];
    return AssignmentModel(
      id: (map['id'] ?? '').toString(),
      courseCode: (map['courseCode'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      lecturerName: (map['lecturerName'] ?? '').toString(),
      assignedAt:
          DateTime.tryParse((map['assignedAt'] ?? '').toString()) ??
          DateTime.now(),
      deadline:
          DateTime.tryParse((map['deadline'] ?? '').toString()) ??
          DateTime.now().add(const Duration(days: 7)),
      isGroupAssignment: map['isGroupAssignment'] == true,
      groupId: map['groupId']?.toString(),
      groupName: map['groupName']?.toString(),
      groupSource: AssignmentGroupSourceX.fromRaw(
        map['groupSource']?.toString(),
      ),
      groupMembers: rawMembers
          .whereType<Map>()
          .map(
            (e) => AssignmentGroupMember.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      groupChatEnabled: map['groupChatEnabled'] == true,
      lecturerCanWriteInGroupChat: map['lecturerCanWriteInGroupChat'] != false,
      whiteboardEnabled: map['whiteboardEnabled'] == true,
      whiteboardRequired: map['whiteboardRequired'] == true,
      whiteboardPrompt: map['whiteboardPrompt']?.toString(),
      allowTextSubmission: map['allowTextSubmission'] != false,
      allowFileSubmission: map['allowFileSubmission'] != false,
      allowedExtensions: rawExtensions
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      peerReview: rawPeerReview is Map
          ? AssignmentPeerReviewConfig.fromMap(
              Map<String, dynamic>.from(rawPeerReview),
            )
          : null,
    );
  }
}

class AssignmentUploadFile {
  const AssignmentUploadFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.extension,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String extension;

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'sizeBytes': sizeBytes,
      'extension': extension,
    };
  }

  factory AssignmentUploadFile.fromMap(Map<String, dynamic> map) {
    final rawSize = map['sizeBytes'];
    final sizeBytes = rawSize is num ? rawSize.toInt() : 0;
    return AssignmentUploadFile(
      path: (map['path'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      sizeBytes: sizeBytes,
      extension: (map['extension'] ?? '').toString(),
    );
  }
}

enum AssignmentGroupChatSenderRole { student, lecturer }

extension AssignmentGroupChatSenderRoleX on AssignmentGroupChatSenderRole {
  String get raw {
    switch (this) {
      case AssignmentGroupChatSenderRole.student:
        return 'student';
      case AssignmentGroupChatSenderRole.lecturer:
        return 'lecturer';
    }
  }

  static AssignmentGroupChatSenderRole fromRaw(String? raw) {
    switch (raw) {
      case 'lecturer':
        return AssignmentGroupChatSenderRole.lecturer;
      case 'student':
      default:
        return AssignmentGroupChatSenderRole.student;
    }
  }
}

class AssignmentGroupChatMessage {
  const AssignmentGroupChatMessage({
    required this.id,
    required this.assignmentId,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.sentAt,
  });

  final String id;
  final String assignmentId;
  final String groupId;
  final String senderId;
  final String senderName;
  final AssignmentGroupChatSenderRole senderRole;
  final String message;
  final DateTime sentAt;

  bool get isLecturer => senderRole == AssignmentGroupChatSenderRole.lecturer;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole.raw,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  factory AssignmentGroupChatMessage.fromMap(Map<String, dynamic> map) {
    return AssignmentGroupChatMessage(
      id: (map['id'] ?? '').toString(),
      assignmentId: (map['assignmentId'] ?? '').toString(),
      groupId: (map['groupId'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      senderName: (map['senderName'] ?? '').toString(),
      senderRole: AssignmentGroupChatSenderRoleX.fromRaw(
        map['senderRole']?.toString(),
      ),
      message: (map['message'] ?? '').toString(),
      sentAt:
          DateTime.tryParse((map['sentAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AssignmentSubmissionModel {
  const AssignmentSubmissionModel({
    required this.assignmentId,
    required this.submittedAt,
    this.textAnswer,
    this.files = const [],
    this.whiteboardStrokes = const [],
    this.groupId,
    this.submittedById,
    this.submittedByName,
  });

  final String assignmentId;
  final DateTime submittedAt;
  final String? textAnswer;
  final List<AssignmentUploadFile> files;
  final List<WhiteboardStroke> whiteboardStrokes;
  final String? groupId;
  final String? submittedById;
  final String? submittedByName;

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'submittedAt': submittedAt.toIso8601String(),
      'textAnswer': textAnswer,
      'files': files.map((f) => f.toMap()).toList(),
      'whiteboardStrokes': whiteboardStrokes.map((s) => s.toMap()).toList(),
      'groupId': groupId,
      'submittedById': submittedById,
      'submittedByName': submittedByName,
    };
  }

  factory AssignmentSubmissionModel.fromMap(Map<String, dynamic> map) {
    final rawFiles = (map['files'] as List?) ?? const [];
    final rawStrokes = (map['whiteboardStrokes'] as List?) ?? const [];
    return AssignmentSubmissionModel(
      assignmentId: (map['assignmentId'] ?? '').toString(),
      submittedAt:
          DateTime.tryParse((map['submittedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      textAnswer: map['textAnswer']?.toString(),
      files: rawFiles
          .whereType<Map>()
          .map(
            (e) => AssignmentUploadFile.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      whiteboardStrokes: rawStrokes
          .whereType<Map>()
          .map((e) => WhiteboardStroke.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      groupId: map['groupId']?.toString(),
      submittedById: map['submittedById']?.toString(),
      submittedByName: map['submittedByName']?.toString(),
    );
  }
}

class AssignmentPeerReviewSubmission {
  const AssignmentPeerReviewSubmission({
    required this.assignmentId,
    required this.peerAssignmentId,
    required this.targetSubmissionId,
    required this.targetStudentId,
    required this.targetStudentName,
    required this.reviewerId,
    required this.reviewerName,
    required this.score,
    required this.feedback,
    required this.submittedAt,
    this.rubricChecks = const {},
  });

  final String assignmentId;
  final String peerAssignmentId;
  final String targetSubmissionId;
  final String targetStudentId;
  final String targetStudentName;
  final String reviewerId;
  final String reviewerName;
  final int score;
  final String feedback;
  final DateTime submittedAt;
  final Map<String, bool> rubricChecks;

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'peerAssignmentId': peerAssignmentId,
      'targetSubmissionId': targetSubmissionId,
      'targetStudentId': targetStudentId,
      'targetStudentName': targetStudentName,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'score': score,
      'feedback': feedback,
      'submittedAt': submittedAt.toIso8601String(),
      'rubricChecks': rubricChecks,
    };
  }

  factory AssignmentPeerReviewSubmission.fromMap(Map<String, dynamic> map) {
    final rawScore = map['score'];
    final rawChecks = map['rubricChecks'];
    return AssignmentPeerReviewSubmission(
      assignmentId: (map['assignmentId'] ?? '').toString(),
      peerAssignmentId: (map['peerAssignmentId'] ?? '').toString(),
      targetSubmissionId: (map['targetSubmissionId'] ?? '').toString(),
      targetStudentId: (map['targetStudentId'] ?? '').toString(),
      targetStudentName: (map['targetStudentName'] ?? '').toString(),
      reviewerId: (map['reviewerId'] ?? '').toString(),
      reviewerName: (map['reviewerName'] ?? '').toString(),
      score: rawScore is num ? rawScore.toInt() : 0,
      feedback: (map['feedback'] ?? '').toString(),
      submittedAt:
          DateTime.tryParse((map['submittedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      rubricChecks: rawChecks is Map
          ? rawChecks.map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : const {},
    );
  }
}

class AssignmentGradeModel {
  const AssignmentGradeModel({
    required this.assignmentId,
    required this.submissionId,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.maxScore,
    required this.feedback,
    required this.gradedById,
    required this.gradedByName,
    required this.gradedAt,
    this.letterGrade,
  });

  final String assignmentId;
  final String submissionId;
  final String studentId;
  final String studentName;
  final int score;
  final int maxScore;
  final String feedback;
  final String gradedById;
  final String gradedByName;
  final DateTime gradedAt;
  final String? letterGrade;

  String get displayGrade {
    final letter = letterGrade?.trim();
    if (letter != null && letter.isNotEmpty) return letter;
    if (maxScore <= 0) return '$score';
    final pct = (score / maxScore) * 100;
    if (pct >= 70) return 'A';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 45) return 'D';
    if (pct >= 40) return 'E';
    return 'F';
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'submissionId': submissionId,
      'studentId': studentId,
      'studentName': studentName,
      'score': score,
      'maxScore': maxScore,
      'feedback': feedback,
      'gradedById': gradedById,
      'gradedByName': gradedByName,
      'gradedAt': gradedAt.toIso8601String(),
      'letterGrade': letterGrade,
    };
  }

  factory AssignmentGradeModel.fromMap(Map<String, dynamic> map) {
    final rawScore = map['score'];
    final rawMax = map['maxScore'];
    return AssignmentGradeModel(
      assignmentId: (map['assignmentId'] ?? '').toString(),
      submissionId: (map['submissionId'] ?? '').toString(),
      studentId: (map['studentId'] ?? '').toString(),
      studentName: (map['studentName'] ?? '').toString(),
      score: rawScore is num ? rawScore.toInt() : 0,
      maxScore: rawMax is num ? rawMax.toInt() : 100,
      feedback: (map['feedback'] ?? '').toString(),
      gradedById: (map['gradedById'] ?? '').toString(),
      gradedByName: (map['gradedByName'] ?? '').toString(),
      gradedAt:
          DateTime.tryParse((map['gradedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      letterGrade: map['letterGrade']?.toString(),
    );
  }
}
