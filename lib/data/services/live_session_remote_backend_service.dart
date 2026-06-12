import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../models/live_session_models.dart';
import 'live_session_backend_service.dart';
import 'live_session_runtime_mode_service.dart';

class LiveSessionBackendConfig {
  const LiveSessionBackendConfig({required this.apiBaseUrl});

  static const String _kApiBaseUrl = 'liveSessions.apiBaseUrl';
  static const String _kGoApiBaseEnv = 'LIVE_SESSION_GO_API_BASE_URL';
  static const String _kApiBaseEnv = 'LIVE_SESSION_API_BASE_URL';

  final String apiBaseUrl;

  bool get isConfigured => apiBaseUrl.isNotEmpty;

  factory LiveSessionBackendConfig.fromRuntime() {
    final box = GetStorage();
    final storedApiBaseUrl = box.read(_kApiBaseUrl)?.toString().trim() ?? '';
    final apiBaseUrl = storedApiBaseUrl.isNotEmpty
        ? storedApiBaseUrl
        : const String.fromEnvironment(_kGoApiBaseEnv).trim().isNotEmpty
        ? const String.fromEnvironment(_kGoApiBaseEnv).trim()
        : const String.fromEnvironment(_kApiBaseEnv).trim();
    return LiveSessionBackendConfig(apiBaseUrl: apiBaseUrl);
  }
}

class RemoteLiveSessionBackendGateway implements LiveSessionBackendGateway {
  RemoteLiveSessionBackendGateway({
    http.Client? client,
    LiveSessionBackendConfig? config,
    LiveSessionBackendGateway? catalogGateway,
  }) : _client = client ?? http.Client(),
       _config = config ?? LiveSessionBackendConfig.fromRuntime(),
       _catalogGateway =
           catalogGateway ?? LocalLiveSessionBackendGateway.instance;

  final http.Client _client;
  final LiveSessionBackendConfig _config;
  final LiveSessionBackendGateway _catalogGateway;

  LiveSessionRuntimeMode get runtimeMode => LiveSessionRuntimeModeStore.load();
  bool get wantsProduction => runtimeMode == LiveSessionRuntimeMode.production;
  bool get isConfigured => wantsProduction && _config.isConfigured;

  @override
  List<LiveSessionBackendPath> get backendContract =>
      _catalogGateway.backendContract;

  @override
  Future<List<LiveSessionModel>> fetchSessions({String? courseCode}) async {
    if (!isConfigured) {
      return _catalogGateway.fetchSessions(courseCode: courseCode);
    }

    final payload = await _requestJson(
      method: 'GET',
      pathSegments: ['api', 'v1', 'live-sessions', 'rooms'],
    );
    final code = courseCode?.trim().toUpperCase();
    final sessions =
        _asList(payload['sessions'])
            .map((item) => _sessionFromRemoteJson(_asMap(item)))
            .where(
              (session) =>
                  code == null || session.courseCode.toUpperCase() == code,
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }

  @override
  Future<LiveSessionModel> saveSession(LiveSessionModel session) async {
    if (!isConfigured) {
      return _catalogGateway.saveSession(session);
    }
    return _createOrUpdateRemoteRoom(session);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    if (!isConfigured) {
      return _catalogGateway.deleteSession(sessionId);
    }
    await _requestJson(
      method: 'DELETE',
      pathSegments: ['api', 'v1', 'live-sessions', 'rooms', sessionId],
    );
  }

  @override
  Future<LiveSessionRoomState> fetchRoom(String sessionId) async {
    if (!isConfigured) {
      return _catalogGateway.fetchRoom(sessionId);
    }
    return _fetchRemoteRoom(sessionId);
  }

  @override
  Future<LiveSessionRoomState> joinAsStudent({
    required String sessionId,
    required String displayName,
    required String registrationNumber,
  }) async {
    if (!isConfigured) {
      return _catalogGateway.joinAsStudent(
        sessionId: sessionId,
        displayName: displayName,
        registrationNumber: registrationNumber,
      );
    }

    final room = await _fetchRemoteRoom(sessionId);
    final now = DateTime.now().toUtc();
    final participantId = _studentParticipantId(registrationNumber);
    final participant = _participantById(room, participantId);

    await _syncAttendance(
      sessionId: sessionId,
      participantId: participantId,
      userId: registrationNumber,
      role: LiveSessionRole.student,
      displayName: displayName,
      registrationNumber: registrationNumber,
      cameraEnabled:
          participant?.cameraEnabled ?? room.session.studentCameraRequired,
      micEnabled: participant?.micEnabled ?? true,
      recordingEnabled: participant?.recordingEnabled ?? false,
      attendanceSeconds: _attendanceSecondsFor(participant, now),
      joinedAt: participant?.joinedAt?.toUtc() ?? now,
      leftAt: null,
      updatedAt: now,
    );

    return _fetchRemoteRoom(sessionId);
  }

  @override
  Future<LiveSessionRoomState> joinAsLecturer({
    required String sessionId,
    required String lecturerName,
  }) async {
    if (!isConfigured) {
      return _catalogGateway.joinAsLecturer(
        sessionId: sessionId,
        lecturerName: lecturerName,
      );
    }

    final room = await _fetchRemoteRoom(sessionId);
    final now = DateTime.now().toUtc();
    final participantId = _lecturerParticipantId(sessionId);
    final participant = _participantById(room, participantId);

    await _syncAttendance(
      sessionId: sessionId,
      participantId: participantId,
      userId: participantId,
      role: LiveSessionRole.lecturer,
      displayName: lecturerName,
      registrationNumber: null,
      cameraEnabled: participant?.cameraEnabled ?? true,
      micEnabled: participant?.micEnabled ?? true,
      recordingEnabled:
          participant?.recordingEnabled ?? room.session.allowLecturerRecording,
      attendanceSeconds: _attendanceSecondsFor(participant, now),
      joinedAt: participant?.joinedAt?.toUtc() ?? now,
      leftAt: null,
      updatedAt: now,
    );

    return _fetchRemoteRoom(sessionId);
  }

  @override
  Future<LiveSessionRoomState> setCameraState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  }) async {
    if (!isConfigured) {
      return _catalogGateway.setCameraState(
        sessionId: sessionId,
        participantId: participantId,
        enabled: enabled,
      );
    }

    final room = await _fetchRemoteRoom(sessionId);
    final participant = _participantById(room, participantId);

    await _updateParticipantMedia(
      sessionId: sessionId,
      participantId: participantId,
      cameraEnabled: enabled,
      micEnabled: participant?.micEnabled ?? true,
      recordingEnabled: participant?.recordingEnabled ?? false,
    );

    return _fetchRemoteRoom(sessionId);
  }

  @override
  Future<LiveSessionRoomState> setMicrophoneState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  }) async {
    if (!isConfigured) {
      return _catalogGateway.setMicrophoneState(
        sessionId: sessionId,
        participantId: participantId,
        enabled: enabled,
      );
    }

    final room = await _fetchRemoteRoom(sessionId);
    final participant = _participantById(room, participantId);

    await _updateParticipantMedia(
      sessionId: sessionId,
      participantId: participantId,
      cameraEnabled: participant?.cameraEnabled ?? false,
      micEnabled: enabled,
      recordingEnabled: participant?.recordingEnabled ?? false,
    );

    return _fetchRemoteRoom(sessionId);
  }

  @override
  Future<LiveSessionRoomState> setRecordingState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  }) async {
    if (!isConfigured) {
      return _catalogGateway.setRecordingState(
        sessionId: sessionId,
        participantId: participantId,
        enabled: enabled,
      );
    }

    final room = await _fetchRemoteRoom(sessionId);
    final participant = _participantById(room, participantId);
    final now = DateTime.now().toUtc();

    await _requestJson(
      method: 'POST',
      pathSegments: ['api', 'v1', 'live-sessions', sessionId, 'recordings'],
      body: {
        'sessionId': sessionId,
        'recordingId': enabled
            ? null
            : _activeRecordingIdFor(room, participantId),
        'triggeredByParticipantId': participantId,
        'triggeredByRole':
            participant?.role ?? _roleForParticipantId(participantId),
        'triggeredByName': participant?.displayName ?? 'Participant',
        'registrationNumber': participant?.registrationNumber,
        'action': enabled ? 'start' : 'stop',
        'requestedAt': now.toIso8601String(),
      },
    );

    await _updateParticipantMedia(
      sessionId: sessionId,
      participantId: participantId,
      cameraEnabled: participant?.cameraEnabled ?? false,
      micEnabled: participant?.micEnabled ?? true,
      recordingEnabled: enabled,
    );

    return _fetchRemoteRoom(sessionId);
  }

  @override
  Future<LiveSessionRoomState> sendChat({
    required String sessionId,
    required String senderName,
    required String senderRole,
    required String message,
    String? registrationNumber,
  }) async {
    if (!isConfigured) {
      return _catalogGateway.sendChat(
        sessionId: sessionId,
        senderName: senderName,
        senderRole: senderRole,
        message: message,
        registrationNumber: registrationNumber,
      );
    }

    final room = await _fetchRemoteRoom(sessionId);
    final participant = _participantForSender(
      room,
      senderRole: senderRole,
      senderName: senderName,
      registrationNumber: registrationNumber,
      sessionId: sessionId,
    );

    await _requestJson(
      method: 'POST',
      pathSegments: [
        'api',
        'v1',
        'live-sessions',
        sessionId,
        'chat',
        'messages',
      ],
      body: {
        'sessionId': sessionId,
        'senderParticipantId':
            participant?.id ??
            _participantIdForRole(
              role: senderRole,
              sessionId: sessionId,
              registrationNumber: registrationNumber,
            ),
        'senderRole': senderRole,
        'senderName': senderName,
        'registrationNumber': registrationNumber,
        'message': message.trim(),
        'sentAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    return _fetchRemoteRoom(sessionId);
  }

  @override
  Future<LiveSessionRoomState> askQuestion({
    required String sessionId,
    required String askedByName,
    required String question,
    String? registrationNumber,
  }) async {
    if (!isConfigured) {
      return _catalogGateway.askQuestion(
        sessionId: sessionId,
        askedByName: askedByName,
        question: question,
        registrationNumber: registrationNumber,
      );
    }

    final room = await _fetchRemoteRoom(sessionId);
    final participant = _participantForSender(
      room,
      senderRole: LiveSessionRole.student,
      senderName: askedByName,
      registrationNumber: registrationNumber,
      sessionId: sessionId,
    );

    await _requestJson(
      method: 'POST',
      pathSegments: ['api', 'v1', 'live-sessions', sessionId, 'questions'],
      body: {
        'sessionId': sessionId,
        'askedByParticipantId':
            participant?.id ??
            _studentParticipantId(registrationNumber ?? askedByName),
        'askedByName': askedByName,
        'registrationNumber': registrationNumber,
        'question': question.trim(),
        'askedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    return _fetchRemoteRoom(sessionId);
  }

  @override
  Future<LiveSessionRoomState> answerQuestion({
    required String sessionId,
    required String questionId,
    required String answeredByName,
    required String answer,
  }) async {
    if (!isConfigured) {
      return _catalogGateway.answerQuestion(
        sessionId: sessionId,
        questionId: questionId,
        answeredByName: answeredByName,
        answer: answer,
      );
    }

    final room = await _fetchRemoteRoom(sessionId);
    final lecturer = _lecturerParticipant(room, answeredByName, sessionId);

    await _requestJson(
      method: 'POST',
      pathSegments: [
        'api',
        'v1',
        'live-sessions',
        sessionId,
        'questions',
        questionId,
        'answer',
      ],
      body: {
        'sessionId': sessionId,
        'questionId': questionId,
        'answeredById': lecturer?.id ?? _lecturerParticipantId(sessionId),
        'answeredByName': answeredByName,
        'answer': answer.trim(),
        'answeredAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    return _fetchRemoteRoom(sessionId);
  }

  Future<LiveSessionModel> _createOrUpdateRemoteRoom(
    LiveSessionModel session,
  ) async {
    final payload = await _requestJson(
      method: 'POST',
      pathSegments: ['api', 'v1', 'live-sessions', 'rooms'],
      body: {
        'sessionId': session.id,
        'courseCode': session.courseCode,
        'courseTitle': session.courseTitle,
        'title': session.title,
        'description': session.description,
        'lecturerId': _lecturerUserId(session),
        'lecturerName': session.lecturerName,
        'roomName': session.roomLabel,
        'startTime': session.startTime.toUtc().toIso8601String(),
        'endTime': session.endTime.toUtc().toIso8601String(),
        'agenda': session.agenda,
        'materials': session.materials
            .map((material) => material.toJson())
            .toList(),
        'settings': {
          'studentCameraRequired': session.studentCameraRequired,
          'captureRegistrationNumber': session.captureRegistrationNumber,
          'allowStudentRecording': session.allowStudentRecording,
          'allowLecturerRecording': session.allowLecturerRecording,
          'attendanceEnabled': session.attendanceEnabled,
          'chatEnabled': session.chatEnabled,
          'questionsEnabled': session.questionsEnabled,
        },
      },
    );
    final remoteSession = _asMap(payload['session']);
    if (remoteSession.isEmpty) {
      return session;
    }
    return _sessionFromRemoteJson(remoteSession);
  }

  Future<void> _syncAttendance({
    required String sessionId,
    required String participantId,
    required String userId,
    required String role,
    required String displayName,
    required String? registrationNumber,
    required bool cameraEnabled,
    required bool micEnabled,
    required bool recordingEnabled,
    required int attendanceSeconds,
    required DateTime joinedAt,
    required DateTime? leftAt,
    required DateTime updatedAt,
  }) async {
    await _requestJson(
      method: 'POST',
      pathSegments: [
        'api',
        'v1',
        'live-sessions',
        sessionId,
        'attendance',
        'sync',
      ],
      body: {
        'sessionId': sessionId,
        'participantId': participantId,
        'userId': userId,
        'role': role,
        'displayName': displayName,
        'registrationNumber': registrationNumber,
        'cameraEnabled': cameraEnabled,
        'micEnabled': micEnabled,
        'recordingEnabled': recordingEnabled,
        'attendanceSeconds': attendanceSeconds,
        'joinedAt': joinedAt.toUtc().toIso8601String(),
        'leftAt': leftAt?.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _updateParticipantMedia({
    required String sessionId,
    required String participantId,
    required bool cameraEnabled,
    required bool micEnabled,
    required bool recordingEnabled,
  }) async {
    await _requestJson(
      method: 'PATCH',
      pathSegments: [
        'api',
        'v1',
        'live-sessions',
        sessionId,
        'participants',
        participantId,
        'media',
      ],
      body: {
        'sessionId': sessionId,
        'participantId': participantId,
        'cameraEnabled': cameraEnabled,
        'micEnabled': micEnabled,
        'recordingEnabled': recordingEnabled,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<LiveSessionRoomState> _fetchRemoteRoom(String sessionId) async {
    final payload = await _requestJson(
      method: 'GET',
      pathSegments: ['api', 'v1', 'live-sessions', sessionId, 'room'],
    );
    return _roomFromRemoteJson(payload);
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required List<String> pathSegments,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(pathSegments);
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: _jsonHeaders),
      'POST' => await _client.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode(body ?? const {}),
      ),
      'PATCH' => await _client.patch(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode(body ?? const {}),
      ),
      'DELETE' => await _client.delete(uri, headers: _jsonHeaders),
      _ => throw UnsupportedError('Unsupported method: $method'),
    };

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _LiveSessionBackendException(
        statusCode: response.statusCode,
        message: _errorMessageFor(response),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Live session backend response is not a JSON object.',
      );
    }
    return decoded;
  }

  Uri _buildUri(List<String> pathSegments) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    return base.replace(pathSegments: [...baseSegments, ...pathSegments]);
  }

  LiveSessionRoomState _roomFromRemoteJson(Map<String, dynamic> payload) {
    final session = _sessionFromRemoteJson(_asMap(payload['session']));
    final participants =
        (_asList(payload['participants']))
            .map((item) => _participantFromRemoteJson(session.id, _asMap(item)))
            .toList()
          ..sort(_compareParticipants);
    final chatMessages =
        (_asList(
            payload['chatMessages'],
          )).map((item) => _chatFromRemoteJson(_asMap(item))).toList()
          ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final questions =
        (_asList(
            payload['questions'],
          )).map((item) => _questionFromRemoteJson(_asMap(item))).toList()
          ..sort((a, b) => b.askedAt.compareTo(a.askedAt));
    final recordings =
        (_asList(
            payload['recordings'],
          )).map((item) => _recordingFromRemoteJson(_asMap(item))).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return LiveSessionRoomState(
      session: session,
      participants: participants,
      chatMessages: chatMessages,
      questions: questions,
      recordings: recordings,
    );
  }

  LiveSessionModel _sessionFromRemoteJson(Map<String, dynamic> payload) {
    final settings = _asMap(payload['settings']);
    final materials = _asList(
      payload['materials'],
    ).map((item) => LiveSessionMaterial.fromJson(_asMap(item))).toList();
    return LiveSessionModel(
      id: _readString(payload['sessionId']),
      courseCode: _readString(payload['courseCode']),
      courseTitle: _readString(payload['courseTitle']),
      title: _readString(payload['title']),
      description: _readString(payload['description']),
      lecturerName: _readString(payload['lecturerName']),
      roomLabel: _readString(payload['roomName']),
      startTime: _parseDateTime(payload['startTime']) ?? DateTime.now().toUtc(),
      endTime:
          _parseDateTime(payload['endTime']) ??
          DateTime.now().toUtc().add(const Duration(hours: 1)),
      agenda: _asList(
        payload['agenda'],
      ).map((item) => item.toString()).toList(),
      materials: materials,
      studentCameraRequired: settings['studentCameraRequired'] == true,
      captureRegistrationNumber: settings['captureRegistrationNumber'] != false,
      allowStudentRecording: settings['allowStudentRecording'] == true,
      allowLecturerRecording: settings['allowLecturerRecording'] != false,
      chatEnabled: settings['chatEnabled'] != false,
      questionsEnabled: settings['questionsEnabled'] != false,
      attendanceEnabled: settings['attendanceEnabled'] != false,
    );
  }

  LiveSessionParticipant _participantFromRemoteJson(
    String sessionId,
    Map<String, dynamic> payload,
  ) {
    final joinedAt = _parseDateTime(payload['joinedAt']);
    final leftAt = _parseDateTime(payload['leftAt']);
    final attendanceSeconds = _readInt(payload['attendanceSeconds']);
    return LiveSessionParticipant(
      id: _readString(payload['participantId']),
      sessionId: sessionId,
      role: _readString(payload['role'], fallback: LiveSessionRole.student),
      displayName: _readString(payload['displayName']),
      registrationNumber: _readNullableString(payload['registrationNumber']),
      cameraEnabled: payload['cameraEnabled'] != false,
      micEnabled: payload['micEnabled'] != false,
      recordingEnabled: payload['recordingEnabled'] == true,
      isPresent: leftAt == null,
      attendanceMinutes: attendanceSeconds < 1 ? 0 : attendanceSeconds ~/ 60,
      joinedAt: joinedAt,
      streamLabel: _streamLabelForRole(
        _readString(payload['role'], fallback: LiveSessionRole.student),
      ),
    );
  }

  LiveSessionChatMessage _chatFromRemoteJson(Map<String, dynamic> payload) {
    return LiveSessionChatMessage(
      id: _readString(payload['messageId']),
      sessionId: _readString(payload['sessionId']),
      senderName: _readString(payload['senderName']),
      senderRole: _readString(
        payload['senderRole'],
        fallback: LiveSessionRole.student,
      ),
      message: _readString(payload['message']),
      sentAt: _parseDateTime(payload['sentAt']) ?? DateTime.now().toUtc(),
      registrationNumber: _readNullableString(payload['registrationNumber']),
    );
  }

  LiveSessionQuestion _questionFromRemoteJson(Map<String, dynamic> payload) {
    return LiveSessionQuestion(
      id: _readString(payload['questionId']),
      sessionId: _readString(payload['sessionId']),
      askedByName: _readString(payload['askedByName']),
      question: _readString(payload['question']),
      askedAt: _parseDateTime(payload['askedAt']) ?? DateTime.now().toUtc(),
      askedByRegistrationNumber: _readNullableString(
        payload['registrationNumber'],
      ),
      answer: _readNullableString(payload['answer']),
      answeredByName: _readNullableString(payload['answeredByName']),
      answeredAt: _parseDateTime(payload['answeredAt']),
    );
  }

  LiveSessionRecording _recordingFromRemoteJson(Map<String, dynamic> payload) {
    final startedAt =
        _parseDateTime(payload['startedAt']) ?? DateTime.now().toUtc();
    final stoppedAt = _parseDateTime(payload['stoppedAt']);
    final minutesCaptured = stoppedAt == null
        ? 0
        : stoppedAt.difference(startedAt).inMinutes.clamp(0, 1 << 31).toInt();

    return LiveSessionRecording(
      id: _readString(payload['recordingId']),
      sessionId: _readString(payload['sessionId']),
      ownerRole: _readString(
        payload['triggeredByRole'],
        fallback: LiveSessionRole.student,
      ),
      ownerName: _readString(payload['triggeredByName']),
      ownerRegistrationNumber: _readNullableString(
        payload['registrationNumber'],
      ),
      label: _recordingLabelForRole(
        _readString(
          payload['triggeredByRole'],
          fallback: LiveSessionRole.student,
        ),
      ),
      createdAt: startedAt,
      minutesCaptured: minutesCaptured,
      isActive: payload['active'] == true,
    );
  }

  LiveSessionParticipant? _participantById(
    LiveSessionRoomState room,
    String participantId,
  ) {
    for (final participant in room.participants) {
      if (participant.id == participantId) {
        return participant;
      }
    }
    return null;
  }

  LiveSessionParticipant? _participantForSender(
    LiveSessionRoomState room, {
    required String senderRole,
    required String senderName,
    required String? registrationNumber,
    required String sessionId,
  }) {
    if (registrationNumber != null && registrationNumber.trim().isNotEmpty) {
      final participant = _participantById(
        room,
        _studentParticipantId(registrationNumber),
      );
      if (participant != null) {
        return participant;
      }
    }

    for (final participant in room.participants) {
      if (participant.role == senderRole &&
          participant.displayName.trim() == senderName.trim()) {
        return participant;
      }
    }

    return _participantById(
      room,
      _participantIdForRole(
        role: senderRole,
        sessionId: sessionId,
        registrationNumber: registrationNumber,
      ),
    );
  }

  LiveSessionParticipant? _lecturerParticipant(
    LiveSessionRoomState room,
    String answeredByName,
    String sessionId,
  ) {
    for (final participant in room.participants) {
      if (participant.role == LiveSessionRole.lecturer &&
          participant.displayName.trim() == answeredByName.trim()) {
        return participant;
      }
    }
    return _participantById(room, _lecturerParticipantId(sessionId));
  }

  String? _activeRecordingIdFor(
    LiveSessionRoomState room,
    String participantId,
  ) {
    final participant = _participantById(room, participantId);
    if (participant == null) return null;

    for (final recording in room.recordings) {
      if (recording.isActive &&
          recording.ownerName == participant.displayName &&
          recording.ownerRole == participant.role) {
        return recording.id;
      }
    }
    return null;
  }

  int _attendanceSecondsFor(LiveSessionParticipant? participant, DateTime now) {
    if (participant == null) return 0;
    return participant.attendanceMinutesAt(now) * 60;
  }

  int _compareParticipants(LiveSessionParticipant a, LiveSessionParticipant b) {
    if (a.role != b.role) {
      return a.role == LiveSessionRole.lecturer ? -1 : 1;
    }
    return a.displayName.compareTo(b.displayName);
  }

  String _lecturerUserId(LiveSessionModel session) {
    return _lecturerParticipantId(session.id);
  }

  String _lecturerParticipantId(String sessionId) {
    return 'lecturer-${sessionId.toLowerCase()}';
  }

  String _studentParticipantId(String key) {
    return 'student-${key.toLowerCase()}';
  }

  String _participantIdForRole({
    required String role,
    required String sessionId,
    String? registrationNumber,
  }) {
    if (role == LiveSessionRole.lecturer) {
      return _lecturerParticipantId(sessionId);
    }
    return _studentParticipantId(
      (registrationNumber == null || registrationNumber.trim().isEmpty)
          ? sessionId
          : registrationNumber,
    );
  }

  String _roleForParticipantId(String participantId) {
    return participantId.startsWith('lecturer-')
        ? LiveSessionRole.lecturer
        : LiveSessionRole.student;
  }

  String _streamLabelForRole(String role) {
    return role == LiveSessionRole.lecturer
        ? 'Lecturer camera feed'
        : 'Student camera feed';
  }

  String _recordingLabelForRole(String role) {
    return role == LiveSessionRole.lecturer
        ? 'Lecturer recording'
        : 'Student capture';
  }

  String _errorMessageFor(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['error']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Fall through to the generic error below.
    }
    return 'Live session backend request failed (${response.statusCode}).';
  }

  static Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
  };

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

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDateTime(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}

class _LiveSessionBackendException implements Exception {
  const _LiveSessionBackendException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
