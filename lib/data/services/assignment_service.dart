import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/whiteboard/whiteboard_models.dart';
import '../models/assignment_model.dart';
import 'assignment_lecturer_storage.dart';
import 'course_catalog_service.dart';
import 'live_session_runtime_mode_service.dart';

abstract class AssignmentGateway {
  Future<List<AssignmentModel>> fetchAssignedAssignments();

  Future<bool> submitAssignment({
    required AssignmentModel assignment,
    required String textAnswer,
    required List<AssignmentUploadFile> files,
    required List<WhiteboardStroke> whiteboardStrokes,
    String? groupId,
  });

  Future<bool> submitPeerReview({
    required AssignmentModel assignment,
    required AssignmentPeerReviewConfig peerReview,
    required int score,
    required String feedback,
    required Map<String, bool> rubricChecks,
  });

  Future<bool> createAssignment(AssignmentModel assignment);

  Future<bool> saveGrade(AssignmentGradeModel grade);

  String get providerLabel;
}

class AssignmentService {
  AssignmentService._();

  static final AssignmentGateway _localGateway =
      LocalAssignmentGateway.instance;
  static final AssignmentGateway _remoteGateway = RemoteAssignmentGateway(
    fallbackGateway: LocalAssignmentGateway.instance,
  );

  static AssignmentGateway get gateway => _remoteGateway;

  static List<AssignmentModel> loadAssignedAssignments() {
    return LocalAssignmentGateway.instance.loadAssignedAssignments();
  }

  static Future<List<AssignmentModel>> fetchAssignedAssignments() {
    return gateway.fetchAssignedAssignments();
  }

  static Future<bool> submitAssignment({
    required AssignmentModel assignment,
    required String textAnswer,
    required List<AssignmentUploadFile> files,
    required List<WhiteboardStroke> whiteboardStrokes,
    String? groupId,
  }) {
    return gateway.submitAssignment(
      assignment: assignment,
      textAnswer: textAnswer,
      files: files,
      whiteboardStrokes: whiteboardStrokes,
      groupId: groupId,
    );
  }

  static Future<bool> submitPeerReview({
    required AssignmentModel assignment,
    required AssignmentPeerReviewConfig peerReview,
    required int score,
    required String feedback,
    required Map<String, bool> rubricChecks,
  }) {
    return gateway.submitPeerReview(
      assignment: assignment,
      peerReview: peerReview,
      score: score,
      feedback: feedback,
      rubricChecks: rubricChecks,
    );
  }

  static Future<bool> createAssignment(AssignmentModel assignment) {
    return gateway.createAssignment(assignment);
  }

  static Future<bool> saveGrade(AssignmentGradeModel grade) {
    return gateway.saveGrade(grade);
  }

  static List<AssignmentGroupChatMessage> loadInitialGroupMessages(
    AssignmentModel assignment,
  ) {
    if (_localGateway is LocalAssignmentGateway) {
      return (_localGateway as LocalAssignmentGateway).loadInitialGroupMessages(
        assignment,
      );
    }
    return const [];
  }
}

class LocalAssignmentGateway implements AssignmentGateway {
  LocalAssignmentGateway._();

  static final LocalAssignmentGateway instance = LocalAssignmentGateway._();

  @override
  String get providerLabel => 'Demo assignments';

  List<AssignmentModel> loadAssignedAssignments() {
    final now = DateTime.now();

    final seeded = [
      AssignmentModel(
        id: 'asmt-csc305-graphs',
        courseCode: 'CSC 305',
        title: 'Graph Algorithms Coursework',
        description:
            'Solve the assigned shortest-path and MST problems. Add your proof sketch for complexity analysis.',
        lecturerName: 'Dr. Musa',
        assignedAt: now.subtract(const Duration(days: 2)),
        deadline: now.add(const Duration(days: 2, hours: 6)),
        isGroupAssignment: true,
        groupId: 'grp-csc305-a',
        groupName: 'CSC 305 Group A',
        groupSource: AssignmentGroupSource.randomBackend,
        groupChatEnabled: true,
        whiteboardEnabled: true,
        whiteboardRequired: true,
        whiteboardPrompt:
            'Draw your graph representation and annotate the traversal path.',
        groupMembers: const [
          AssignmentGroupMember(id: 'std-zainab', name: 'Zainab Ibrahim'),
          AssignmentGroupMember(id: 'std-fatimah', name: 'Fatimah Lawal'),
          AssignmentGroupMember(id: 'std-sani', name: 'Sani Abdullahi'),
          AssignmentGroupMember(id: 'std-maryam', name: 'Maryam Aliyu'),
        ],
        peerReview: AssignmentPeerReviewConfig(
          id: 'peer-csc305-zainab-to-sani',
          target: const AssignmentPeerReviewTarget(
            id: 'std-sani',
            name: 'Sani Abdullahi',
            registrationNumber: 'KASU/CSC/21/104',
            submissionId: 'sub-csc305-sani',
            groupId: 'grp-csc305-a',
            groupName: 'CSC 305 Group A',
          ),
          deadline: now.add(const Duration(days: 3)),
          rubric: const [
            'Algorithm choice is justified',
            'Complexity analysis is clear',
            'Graph diagram matches the solution',
          ],
        ),
      ),
      AssignmentModel(
        id: 'asmt-mth202-matrix',
        courseCode: 'MTH 202',
        title: 'Matrix Decomposition Assignment',
        description:
            'Submit worked solutions for LU and QR decomposition using the provided question sheet.',
        lecturerName: 'Dr. Bala',
        assignedAt: now.subtract(const Duration(days: 3)),
        deadline: now.add(const Duration(days: 4, hours: 4)),
        isGroupAssignment: true,
        groupId: 'grp-mth202-c',
        groupName: 'MTH 202 Group C',
        groupSource: AssignmentGroupSource.lecturerSetBackend,
        groupChatEnabled: true,
        whiteboardEnabled: true,
        whiteboardRequired: true,
        whiteboardPrompt:
            'Sketch the decomposition flow and label each matrix transformation.',
        groupMembers: const [
          AssignmentGroupMember(id: 'std-zainab', name: 'Zainab Ibrahim'),
          AssignmentGroupMember(id: 'std-isa', name: 'Isa Muhammad'),
          AssignmentGroupMember(id: 'std-nana', name: 'Nana Yusuf'),
        ],
        peerReview: AssignmentPeerReviewConfig(
          id: 'peer-mth202-zainab-to-isa',
          target: const AssignmentPeerReviewTarget(
            id: 'std-isa',
            name: 'Isa Muhammad',
            registrationNumber: 'KASU/MTH/21/212',
            submissionId: 'sub-mth202-isa',
            groupId: 'grp-mth202-c',
            groupName: 'MTH 202 Group C',
          ),
          deadline: now.add(const Duration(days: 5)),
          rubric: const [
            'Matrix steps are shown in order',
            'Final decomposition is correct',
            'Notation is readable and consistent',
          ],
        ),
      ),
      AssignmentModel(
        id: 'asmt-gst201-essay',
        courseCode: 'GST 201',
        title: 'Academic Writing Reflection',
        description:
            'Write a short reflection (700-1000 words) and upload supporting source notes if used.',
        lecturerName: 'Ms. Grace',
        assignedAt: now.subtract(const Duration(days: 1)),
        deadline: now.add(const Duration(days: 6, hours: 8)),
        peerReview: AssignmentPeerReviewConfig(
          id: 'peer-gst201-zainab-to-blessing',
          target: const AssignmentPeerReviewTarget(
            id: 'std-blessing',
            name: 'Blessing Okafor',
            registrationNumber: 'KASU/GST/21/088',
            submissionId: 'sub-gst201-blessing',
          ),
          deadline: now.add(const Duration(days: 7)),
          rubric: const [
            'Reflection answers the prompt',
            'Paragraphs are coherent',
            'Sources are acknowledged where used',
          ],
        ),
      ),
    ];
    final created = AssignmentLecturerStorage.loadCreatedAssignments();
    return [...created, ...seeded];
  }

  @override
  Future<List<AssignmentModel>> fetchAssignedAssignments() async {
    return loadAssignedAssignments();
  }

  @override
  Future<bool> submitAssignment({
    required AssignmentModel assignment,
    required String textAnswer,
    required List<AssignmentUploadFile> files,
    required List<WhiteboardStroke> whiteboardStrokes,
    String? groupId,
  }) async {
    return true;
  }

  @override
  Future<bool> submitPeerReview({
    required AssignmentModel assignment,
    required AssignmentPeerReviewConfig peerReview,
    required int score,
    required String feedback,
    required Map<String, bool> rubricChecks,
  }) async {
    return true;
  }

  @override
  Future<bool> createAssignment(AssignmentModel assignment) async {
    await AssignmentLecturerStorage.saveCreatedAssignment(assignment);
    return true;
  }

  @override
  Future<bool> saveGrade(AssignmentGradeModel grade) async {
    await AssignmentLecturerStorage.saveGrade(grade);
    return true;
  }

  List<AssignmentGroupChatMessage> loadInitialGroupMessages(
    AssignmentModel assignment,
  ) {
    if (!assignment.hasGroupChat) return const [];

    final now = DateTime.now();
    final groupId = assignment.groupId!;

    if (assignment.id == 'asmt-csc305-graphs') {
      return [
        AssignmentGroupChatMessage(
          id: 'seed-csc305-1',
          assignmentId: assignment.id,
          groupId: groupId,
          senderId: 'lec-dr-musa',
          senderName: assignment.lecturerName,
          senderRole: AssignmentGroupChatSenderRole.lecturer,
          message:
              'Group A, share your task split here. I will review progress daily.',
          sentAt: now.subtract(const Duration(hours: 20)),
        ),
        AssignmentGroupChatMessage(
          id: 'seed-csc305-2',
          assignmentId: assignment.id,
          groupId: groupId,
          senderId: 'std-fatimah',
          senderName: 'Fatimah Lawal',
          senderRole: AssignmentGroupChatSenderRole.student,
          message: 'I can handle Dijkstra and write the complexity section.',
          sentAt: now.subtract(const Duration(hours: 18, minutes: 20)),
        ),
      ];
    }

    if (assignment.id == 'asmt-mth202-matrix') {
      return [
        AssignmentGroupChatMessage(
          id: 'seed-mth202-1',
          assignmentId: assignment.id,
          groupId: groupId,
          senderId: 'lec-dr-bala',
          senderName: assignment.lecturerName,
          senderRole: AssignmentGroupChatSenderRole.lecturer,
          message:
              'Group C was set from the backend. Submit one consolidated report.',
          sentAt: now.subtract(const Duration(hours: 12)),
        ),
      ];
    }

    return const [];
  }
}

class RemoteAssignmentGateway implements AssignmentGateway {
  RemoteAssignmentGateway({
    http.Client? client,
    CourseCatalogBackendConfig? config,
    AssignmentGateway? fallbackGateway,
  }) : _client = client ?? http.Client(),
       _config = config ?? CourseCatalogBackendConfig.fromRuntime(),
       _fallbackGateway = fallbackGateway ?? LocalAssignmentGateway.instance;

  final http.Client _client;
  final CourseCatalogBackendConfig _config;
  final AssignmentGateway _fallbackGateway;

  LiveSessionRuntimeMode get runtimeMode => LiveSessionRuntimeModeStore.load();
  bool get wantsProduction => runtimeMode == LiveSessionRuntimeMode.production;
  bool get isConfigured => wantsProduction && _config.isConfigured;

  @override
  String get providerLabel => wantsProduction
      ? 'Go assignments API (demo fallback)'
      : _fallbackGateway.providerLabel;

  @override
  Future<List<AssignmentModel>> fetchAssignedAssignments() async {
    if (!isConfigured) {
      return _fallbackGateway.fetchAssignedAssignments();
    }

    try {
      final payload = await _requestJson(
        method: 'GET',
        pathSegments: const ['api', 'assignments'],
        queryParameters: const {'status': 'published'},
      );
      final items =
          _asList(payload['items'])
              .map((item) => _assignmentFromJson(_asMap(item)))
              .where((item) => item.id.isNotEmpty)
              .toList()
            ..sort((a, b) => a.deadline.compareTo(b.deadline));

      if (items.isEmpty) {
        return _fallbackGateway.fetchAssignedAssignments();
      }
      return items;
    } catch (_) {
      return _fallbackGateway.fetchAssignedAssignments();
    }
  }

  @override
  Future<bool> submitAssignment({
    required AssignmentModel assignment,
    required String textAnswer,
    required List<AssignmentUploadFile> files,
    required List<WhiteboardStroke> whiteboardStrokes,
    String? groupId,
  }) async {
    if (!isConfigured) return true;

    final assignmentId = int.tryParse(assignment.id);
    if (assignmentId == null || assignmentId < 1) return true;

    try {
      await _requestJson(
        method: 'POST',
        pathSegments: ['api', 'assignments', '$assignmentId', 'submissions'],
        body: {
          'text_answer': textAnswer.trim(),
          'group_id': int.tryParse(groupId ?? ''),
          'whiteboard_data': jsonEncode(
            whiteboardStrokes.map((stroke) => stroke.toMap()).toList(),
          ),
          'files': files
              .map(
                (file) => {
                  'storage_path': file.path,
                  'original_file_name': file.name,
                  'stored_file_name':
                      '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
                  'mime_type': '',
                  'size_bytes': file.sizeBytes,
                },
              )
              .toList(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> submitPeerReview({
    required AssignmentModel assignment,
    required AssignmentPeerReviewConfig peerReview,
    required int score,
    required String feedback,
    required Map<String, bool> rubricChecks,
  }) async {
    if (!isConfigured) return true;

    final assignmentId = int.tryParse(assignment.id);
    final reviewId = int.tryParse(peerReview.id);
    if (assignmentId == null ||
        assignmentId < 1 ||
        reviewId == null ||
        reviewId < 1) {
      return true;
    }

    try {
      await _requestJson(
        method: 'POST',
        pathSegments: [
          'api',
          'assignments',
          '$assignmentId',
          'peer-reviews',
          '$reviewId',
        ],
        body: {
          'score': score,
          'feedback': feedback.trim(),
          'rubric_checks': rubricChecks,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> createAssignment(AssignmentModel assignment) async {
    if (!isConfigured) {
      return _fallbackGateway.createAssignment(assignment);
    }

    try {
      await _requestJson(
        method: 'POST',
        pathSegments: const ['api', 'assignments'],
        body: _assignmentToBackendJson(assignment),
      );
      return true;
    } catch (_) {
      await _fallbackGateway.createAssignment(assignment);
      return false;
    }
  }

  @override
  Future<bool> saveGrade(AssignmentGradeModel grade) async {
    if (!isConfigured) {
      return _fallbackGateway.saveGrade(grade);
    }

    final assignmentId = int.tryParse(grade.assignmentId);
    final submissionId = int.tryParse(grade.submissionId);
    if (assignmentId == null || submissionId == null) {
      return _fallbackGateway.saveGrade(grade);
    }

    try {
      await _requestJson(
        method: 'POST',
        pathSegments: ['api', 'assignments', '$assignmentId', 'grades'],
        body: {
          'submission_id': submissionId,
          'score': grade.score,
          'max_score': grade.maxScore,
          'grade': grade.displayGrade,
          'feedback': grade.feedback,
          'status': 'graded',
        },
      );
      return true;
    } catch (_) {
      await _fallbackGateway.saveGrade(grade);
      return false;
    }
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required List<String> pathSegments,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(pathSegments, queryParameters: queryParameters);
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: _headers),
      'POST' => await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(body ?? const {}),
      ),
      _ => throw UnsupportedError('Unsupported method: $method'),
    };

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _AssignmentBackendException(response.statusCode);
    }

    if (response.body.trim().isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Assignment response is not a JSON object.');
    }
    return decoded;
  }

  Uri _buildUri(
    List<String> pathSegments, {
    Map<String, String>? queryParameters,
  }) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    return base.replace(
      pathSegments: [...baseSegments, ...pathSegments],
      queryParameters: queryParameters,
    );
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_config.accessToken}',
  };

  AssignmentModel _assignmentFromJson(Map<String, dynamic> payload) {
    final groups = _asList(payload['groups']).map(_asMap).toList();
    final firstGroup = groups.isEmpty
        ? const <String, dynamic>{}
        : groups.first;
    final members = _asList(firstGroup['members']).map(_asMap).map((member) {
      final id = _readString(member['student_id']);
      return AssignmentGroupMember(
        id: id,
        name: id.isEmpty ? 'Student' : 'Student #$id',
      );
    }).toList();

    final peerReviews = _asList(payload['peer_reviews']).map(_asMap).toList();
    final firstPeer = peerReviews.isEmpty
        ? const <String, dynamic>{}
        : peerReviews.first;
    final targetId = _readString(firstPeer['target_student_id']);
    final peerReview = targetId.isEmpty
        ? null
        : AssignmentPeerReviewConfig(
            id: _readString(firstPeer['id']),
            target: AssignmentPeerReviewTarget(
              id: targetId,
              name: 'Student #$targetId',
              submissionId: _readString(firstPeer['target_submission_id']),
              groupId: _readString(firstGroup['id']),
              groupName: _readString(firstGroup['name']),
            ),
            deadline: _parseDateTime(payload['due_at']),
            maxScore: _readInt(payload['max_score'], fallback: 10),
            rubric: _asList(
              payload['peer_review_rubric'],
            ).map((item) => item.toString()).toList(),
          );

    final assignmentType = _readString(payload['assignment_type']);
    final submissionMode = _readString(payload['submission_mode']);
    final deadline =
        _parseDateTime(payload['due_at']) ??
        DateTime.now().add(const Duration(days: 7));

    return AssignmentModel(
      id: _readString(payload['id']),
      courseCode: _readString(payload['course_code']),
      title: _readString(payload['title']),
      description: _readString(payload['description']),
      lecturerName: 'Lecturer #${_readString(payload['created_by'])}',
      assignedAt:
          _parseDateTime(payload['created_at']) ??
          DateTime.now().subtract(const Duration(days: 1)),
      deadline: deadline,
      isGroupAssignment: assignmentType == 'group',
      groupId: _readNullableString(firstGroup['id']),
      groupName: _readNullableString(firstGroup['name']),
      groupSource: AssignmentGroupSourceX.fromRaw(
        _readString(
          payload['group_source'],
          fallback: _readString(firstGroup['source']),
        ),
      ),
      groupMembers: members,
      groupChatEnabled: assignmentType == 'group',
      whiteboardEnabled: payload['whiteboard_enabled'] == true,
      whiteboardRequired: payload['whiteboard_required'] == true,
      whiteboardPrompt: _readNullableString(payload['whiteboard_prompt']),
      allowTextSubmission:
          submissionMode == 'text' ||
          submissionMode == 'mixed' ||
          submissionMode.isEmpty,
      allowFileSubmission:
          submissionMode == 'file' ||
          submissionMode == 'mixed' ||
          submissionMode.isEmpty,
      allowedExtensions: _asList(payload['allowed_extensions'])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      peerReview: peerReview,
    );
  }

  Map<String, dynamic> _assignmentToBackendJson(AssignmentModel assignment) {
    final type = assignment.hasPeerReview
        ? 'peer_review'
        : assignment.isGroupAssignment
        ? 'group'
        : 'individual';
    final mode = assignment.whiteboardEnabled
        ? 'whiteboard'
        : assignment.allowTextSubmission && assignment.allowFileSubmission
        ? 'mixed'
        : assignment.allowFileSubmission
        ? 'file'
        : 'text';

    return {
      'course_code': assignment.courseCode,
      'title': assignment.title,
      'description': assignment.description,
      'instructions': assignment.description,
      'assignment_type': type,
      'submission_mode': mode,
      'max_score': 100,
      'due_at': assignment.deadline.toIso8601String(),
      'status': 'published',
      'allowed_extensions': assignment.allowedExtensions,
      'whiteboard_enabled': assignment.whiteboardEnabled,
      'whiteboard_required': assignment.whiteboardRequired,
      'whiteboard_prompt': assignment.whiteboardPrompt,
      'peer_review_enabled': assignment.hasPeerReview,
      'peer_review_rubric': assignment.peerReview?.rubric ?? const [],
      'group_source': assignment.groupSource?.raw,
      'groups': assignment.isGroupAssignment
          ? [
              {
                'name': assignment.groupName,
                'source': assignment.groupSource?.raw,
                'student_ids': assignment.groupMembers
                    .map((member) => int.tryParse(member.id))
                    .whereType<int>()
                    .toList(),
              },
            ]
          : const [],
      'peer_reviews': _peerReviewAssignmentsForBackend(assignment),
    };
  }

  List<Map<String, dynamic>> _peerReviewAssignmentsForBackend(
    AssignmentModel assignment,
  ) {
    if (!assignment.hasPeerReview) return const [];
    final numericMembers = assignment.groupMembers
        .map((member) => int.tryParse(member.id))
        .whereType<int>()
        .toList();
    if (numericMembers.length < 2) return const [];
    return [
      {
        'reviewer_id': numericMembers.first,
        'target_student_id': numericMembers[1],
      },
    ];
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return const {};
  }

  static List<dynamic> _asList(Object? value) {
    if (value is List) return value;
    return const [];
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _parseDateTime(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}

class _AssignmentBackendException implements Exception {
  const _AssignmentBackendException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Assignment backend request failed ($statusCode).';
}
