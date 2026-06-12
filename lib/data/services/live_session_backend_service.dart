import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/live_session_models.dart';

abstract class LiveSessionBackendGateway {
  Future<List<LiveSessionModel>> fetchSessions({String? courseCode});

  Future<LiveSessionRoomState> fetchRoom(String sessionId);

  Future<LiveSessionModel> saveSession(LiveSessionModel session);

  Future<void> deleteSession(String sessionId);

  Future<LiveSessionRoomState> joinAsStudent({
    required String sessionId,
    required String displayName,
    required String registrationNumber,
  });

  Future<LiveSessionRoomState> joinAsLecturer({
    required String sessionId,
    required String lecturerName,
  });

  Future<LiveSessionRoomState> setCameraState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  });

  Future<LiveSessionRoomState> setMicrophoneState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  });

  Future<LiveSessionRoomState> setRecordingState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  });

  Future<LiveSessionRoomState> sendChat({
    required String sessionId,
    required String senderName,
    required String senderRole,
    required String message,
    String? registrationNumber,
  });

  Future<LiveSessionRoomState> askQuestion({
    required String sessionId,
    required String askedByName,
    required String question,
    String? registrationNumber,
  });

  Future<LiveSessionRoomState> answerQuestion({
    required String sessionId,
    required String questionId,
    required String answeredByName,
    required String answer,
  });

  List<LiveSessionBackendPath> get backendContract;
}

class LocalLiveSessionBackendGateway implements LiveSessionBackendGateway {
  LocalLiveSessionBackendGateway._();

  static final LocalLiveSessionBackendGateway instance =
      LocalLiveSessionBackendGateway._();

  static final GetStorage _box = GetStorage();
  static const Uuid _uuid = Uuid();

  static const String _kSessions = 'liveSessions.catalog';
  static const String _kRooms = 'liveSessions.rooms';

  @override
  List<LiveSessionBackendPath> get backendContract => const [
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/{sessionId}/room',
      description:
          'Load room state from the Go live-class API for the student app or lecturer portal.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/rooms',
      description:
          'Create or update a live session room through the Go live-class API.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/tokens',
      description:
          'Issue a Go-generated LiveKit/WebRTC access token for a student or lecturer.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/attendance/sync',
      description:
          'Sync registration number, join/leave events, camera state, and attendance minutes.',
    ),
    LiveSessionBackendPath(
      method: 'PATCH',
      path:
          '/api/v1/live-sessions/{sessionId}/participants/{participantId}/media',
      description:
          'Student self mute/unmute and camera/mic/recording state updates from the Go media service.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/chat/messages',
      description: 'Persist live chat messages from students and lecturer.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/questions',
      description: 'Create a student question in the live room.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/questions/{questionId}/answer',
      description: 'Answer a student question from the lecturer portal.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/recordings',
      description:
          'Start/stop lecturer or student recording and persist recording metadata through the Go media stack.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path:
          '/api/v1/live-sessions/{sessionId}/participants/{participantId}/audio/mute',
      description: 'Lecturer-side mute command for a student participant.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path:
          '/api/v1/live-sessions/{sessionId}/participants/{participantId}/audio/unmute',
      description: 'Lecturer-side unmute command for a student participant.',
    ),
    LiveSessionBackendPath(
      method: 'WS',
      path: '/ws/v1/live-sessions/{sessionId}',
      description:
          'Real-time room stream from the Go live-class service for video tiles, attendance updates, chat, and Q&A.',
    ),
  ];

  @override
  Future<List<LiveSessionModel>> fetchSessions({String? courseCode}) async {
    _ensureSeeded();
    final sessions = _loadSessions();
    final filtered = courseCode == null
        ? sessions
        : sessions
              .where(
                (session) =>
                    session.courseCode.toUpperCase() ==
                    courseCode.trim().toUpperCase(),
              )
              .toList();

    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }

  @override
  Future<LiveSessionRoomState> fetchRoom(String sessionId) async {
    _ensureSeeded();
    final rooms = _loadRooms();
    final room = rooms[sessionId];
    if (room != null) return room;

    final sessions = _loadSessions();
    final fallback = sessions.isNotEmpty
        ? sessions.first
        : LiveSessionModel(
            id: sessionId,
            courseCode: 'GEN 101',
            courseTitle: 'General Studies',
            title: 'Live Session',
            description: 'Live room waiting for backend data.',
            lecturerName: 'Course lecturer',
            roomLabel: 'Virtual Room',
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(hours: 1)),
            agenda: const [],
            materials: const [],
          );
    final session = sessions.firstWhere(
      (item) => item.id == sessionId,
      orElse: () => fallback,
    );
    final created = _emptyRoomFor(session);
    rooms[sessionId] = created;
    await _saveRooms(rooms);
    return created;
  }

  @override
  Future<LiveSessionModel> saveSession(LiveSessionModel session) async {
    _ensureSeeded();
    final sessions = _loadSessions();
    final now = DateTime.now();
    final item = session.copyWith(
      createdAt: session.createdAt ?? now,
      updatedAt: now,
    );
    final index = sessions.indexWhere((existing) => existing.id == session.id);
    if (index >= 0) {
      sessions[index] = item;
    } else {
      sessions.add(item);
    }
    await _saveSessions(sessions);

    final rooms = _loadRooms();
    final room = rooms[item.id];
    rooms[item.id] = (room ?? _emptyRoomFor(item)).copyWith(session: item);
    await _saveRooms(rooms);
    return item;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    _ensureSeeded();
    final sessions = _loadSessions()
      ..removeWhere((session) => session.id == sessionId);
    final rooms = _loadRooms()..remove(sessionId);
    await _saveSessions(sessions);
    await _saveRooms(rooms);
  }

  @override
  Future<LiveSessionRoomState> joinAsStudent({
    required String sessionId,
    required String displayName,
    required String registrationNumber,
  }) async {
    final room = await fetchRoom(sessionId);
    final now = DateTime.now();
    final participantId = 'student-${registrationNumber.toLowerCase()}';
    final existingIndex = room.participants.indexWhere(
      (participant) => participant.id == participantId,
    );
    final updatedParticipants = [...room.participants];
    final updated = LiveSessionParticipant(
      id: participantId,
      sessionId: sessionId,
      role: LiveSessionRole.student,
      displayName: displayName,
      registrationNumber: registrationNumber,
      cameraEnabled: room.session.studentCameraRequired,
      micEnabled: true,
      recordingEnabled: false,
      isPresent: true,
      joinedAt: now,
      attendanceMinutes: existingIndex >= 0
          ? updatedParticipants[existingIndex].attendanceMinutesAt(now)
          : 0,
      streamLabel: 'Student camera feed',
    );

    if (existingIndex >= 0) {
      updatedParticipants[existingIndex] = updated;
    } else {
      updatedParticipants.add(updated);
    }

    final updatedRoom = room.copyWith(participants: updatedParticipants);
    await _saveRoom(updatedRoom);
    return updatedRoom;
  }

  @override
  Future<LiveSessionRoomState> joinAsLecturer({
    required String sessionId,
    required String lecturerName,
  }) async {
    final room = await fetchRoom(sessionId);
    final now = DateTime.now();
    final participantId = 'lecturer-${sessionId.toLowerCase()}';
    final existingIndex = room.participants.indexWhere(
      (participant) => participant.id == participantId,
    );
    final updatedParticipants = [...room.participants];
    final updated = LiveSessionParticipant(
      id: participantId,
      sessionId: sessionId,
      role: LiveSessionRole.lecturer,
      displayName: lecturerName,
      cameraEnabled: true,
      micEnabled: true,
      recordingEnabled: room.session.allowLecturerRecording,
      isPresent: true,
      attendanceMinutes: existingIndex >= 0
          ? updatedParticipants[existingIndex].attendanceMinutesAt(now)
          : 0,
      joinedAt: now,
      streamLabel: 'Lecturer camera feed',
    );

    if (existingIndex >= 0) {
      updatedParticipants[existingIndex] = updated;
    } else {
      updatedParticipants.insert(0, updated);
    }

    final updatedRoom = room.copyWith(participants: updatedParticipants);
    await _saveRoom(updatedRoom);
    return updatedRoom;
  }

  @override
  Future<LiveSessionRoomState> setCameraState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  }) async {
    final room = await fetchRoom(sessionId);
    final participants = room.participants
        .map(
          (participant) => participant.id == participantId
              ? participant.copyWith(cameraEnabled: enabled)
              : participant,
        )
        .toList();
    final updatedRoom = room.copyWith(participants: participants);
    await _saveRoom(updatedRoom);
    return updatedRoom;
  }

  @override
  Future<LiveSessionRoomState> setMicrophoneState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  }) async {
    final room = await fetchRoom(sessionId);
    final participants = room.participants
        .map(
          (participant) => participant.id == participantId
              ? participant.copyWith(micEnabled: enabled)
              : participant,
        )
        .toList();
    final updatedRoom = room.copyWith(participants: participants);
    await _saveRoom(updatedRoom);
    return updatedRoom;
  }

  @override
  Future<LiveSessionRoomState> setRecordingState({
    required String sessionId,
    required String participantId,
    required bool enabled,
  }) async {
    final room = await fetchRoom(sessionId);
    if (room.participants.isEmpty) return room;

    final now = DateTime.now();
    final participant = room.participants.firstWhere(
      (item) => item.id == participantId,
      orElse: () => room.participants.first,
    );

    final participants = room.participants
        .map(
          (item) => item.id == participantId
              ? item.copyWith(recordingEnabled: enabled)
              : item,
        )
        .toList();

    final recordings = [...room.recordings];
    final activeIndex = recordings.indexWhere(
      (recording) =>
          recording.ownerName == participant.displayName &&
          recording.ownerRole == participant.role &&
          recording.isActive,
    );

    if (enabled) {
      if (activeIndex < 0) {
        recordings.insert(
          0,
          LiveSessionRecording(
            id: _uuid.v4(),
            sessionId: sessionId,
            ownerRole: participant.role,
            ownerName: participant.displayName,
            ownerRegistrationNumber: participant.registrationNumber,
            label: participant.role == LiveSessionRole.lecturer
                ? 'Lecturer recording'
                : 'Student capture',
            createdAt: now,
            minutesCaptured: 0,
            isActive: true,
          ),
        );
      }
    } else if (activeIndex >= 0) {
      recordings[activeIndex] = recordings[activeIndex].copyWith(
        isActive: false,
        minutesCaptured: participant.attendanceMinutesAt(now),
      );
    }

    final updatedRoom = room.copyWith(
      participants: participants,
      recordings: recordings,
    );
    await _saveRoom(updatedRoom);
    return updatedRoom;
  }

  @override
  Future<LiveSessionRoomState> sendChat({
    required String sessionId,
    required String senderName,
    required String senderRole,
    required String message,
    String? registrationNumber,
  }) async {
    final room = await fetchRoom(sessionId);
    final updatedRoom = room.copyWith(
      chatMessages: [
        LiveSessionChatMessage(
          id: _uuid.v4(),
          sessionId: sessionId,
          senderName: senderName,
          senderRole: senderRole,
          message: message.trim(),
          sentAt: DateTime.now(),
          registrationNumber: registrationNumber,
        ),
        ...room.chatMessages,
      ],
    );
    await _saveRoom(updatedRoom);
    return updatedRoom;
  }

  @override
  Future<LiveSessionRoomState> askQuestion({
    required String sessionId,
    required String askedByName,
    required String question,
    String? registrationNumber,
  }) async {
    final room = await fetchRoom(sessionId);
    final updatedRoom = room.copyWith(
      questions: [
        LiveSessionQuestion(
          id: _uuid.v4(),
          sessionId: sessionId,
          askedByName: askedByName,
          askedByRegistrationNumber: registrationNumber,
          question: question.trim(),
          askedAt: DateTime.now(),
        ),
        ...room.questions,
      ],
    );
    await _saveRoom(updatedRoom);
    return updatedRoom;
  }

  @override
  Future<LiveSessionRoomState> answerQuestion({
    required String sessionId,
    required String questionId,
    required String answeredByName,
    required String answer,
  }) async {
    final room = await fetchRoom(sessionId);
    final questions = room.questions
        .map(
          (question) => question.id == questionId
              ? question.copyWith(
                  answer: answer.trim(),
                  answeredByName: answeredByName,
                  answeredAt: DateTime.now(),
                )
              : question,
        )
        .toList();
    final updatedRoom = room.copyWith(questions: questions);
    await _saveRoom(updatedRoom);
    return updatedRoom;
  }

  void _ensureSeeded() {
    final rawSessions = _box.read(_kSessions);
    final sessions = _seedSessions();
    if (rawSessions == null) {
      final rooms = {
        for (final session in sessions) session.id: _seedRoomFor(session),
      };
      _saveSessions(sessions);
      _saveRooms(rooms);
      return;
    }

    final mergedSessions = {
      for (final session in _loadSessions()) session.id: session,
      for (final session in sessions) session.id: session,
    }.values.toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    final mergedRooms = _loadRooms();
    for (final session in sessions) {
      mergedRooms[session.id] = _seedRoomFor(session);
    }

    _saveSessions(mergedSessions);
    _saveRooms(mergedRooms);
  }

  List<LiveSessionModel> _loadSessions() {
    final raw = _box.read(_kSessions);
    if (raw == null) return [];
    try {
      final data = jsonDecode(raw) as List;
      return data
          .whereType<Map>()
          .map(
            (item) =>
                LiveSessionModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, LiveSessionRoomState> _loadRooms() {
    final raw = _box.read(_kRooms);
    if (raw == null) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map(
        (key, value) => MapEntry(
          key,
          LiveSessionRoomState.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveSessions(List<LiveSessionModel> sessions) async {
    final raw = jsonEncode(
      sessions.map((session) => session.toJson()).toList(),
    );
    await _box.write(_kSessions, raw);
  }

  Future<void> _saveRooms(Map<String, LiveSessionRoomState> rooms) async {
    final raw = jsonEncode(
      rooms.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _box.write(_kRooms, raw);
  }

  Future<void> _saveRoom(LiveSessionRoomState room) async {
    final rooms = _loadRooms();
    rooms[room.session.id] = room;
    await _saveRooms(rooms);
  }

  List<LiveSessionModel> _seedSessions() {
    final now = DateTime.now();
    final weekDayOffset = now.weekday - 1;
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekDayOffset));

    return [
      LiveSessionModel(
        id: 'live-csc305-main',
        courseCode: 'CSC 305',
        courseTitle: 'Data Structures',
        title: 'K-SLAS Smart Classroom Demo',
        description:
            'School-ready demo session with live teaching, whiteboard annotation, interaction tools, and recording controls.',
        lecturerName: 'Dr. Musa Ibrahim',
        roomLabel: 'Innovation Studio A',
        startTime: now.subtract(const Duration(minutes: 12)),
        endTime: now.add(const Duration(minutes: 58)),
        agenda: const [
          'Welcome, attendance sync, and demo-ready room setup.',
          'Slides, shared screen, and smart board mode switch.',
          'Air-writing overlay, annotation tools, and whiteboard workflow.',
          'Student interaction, live poll, and AI-ready notes capture.',
        ],
        materials: const [
          LiveSessionMaterial(
            title: 'Opening slide deck',
            subtitle: 'School presentation slides for the classroom showcase',
            status: 'Ready now',
          ),
          LiveSessionMaterial(
            title: 'Shared screen sample',
            subtitle: 'Used to demonstrate mixed mode and overlay annotation',
            status: 'During live session',
          ),
          LiveSessionMaterial(
            title: 'Whiteboard challenge page',
            subtitle: 'For live board writing, erasing, and page-based save',
            status: 'Board mode',
          ),
          LiveSessionMaterial(
            title: 'Quick poll card',
            subtitle: 'Demonstrates in-class quiz and poll launch',
            status: 'Interactive',
          ),
          LiveSessionMaterial(
            title: 'AI notes summary',
            subtitle: 'Reserved for generated lecture notes and translation',
            status: 'AI ready',
          ),
        ],
        studentCameraRequired: true,
        captureRegistrationNumber: true,
        allowStudentRecording: true,
        allowLecturerRecording: true,
        chatEnabled: true,
        questionsEnabled: true,
        attendanceEnabled: true,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(minutes: 20)),
      ),
      LiveSessionModel(
        id: 'live-csc305-replay',
        courseCode: 'CSC 305',
        courseTitle: 'Data Structures',
        title: 'Heap Operations Replay',
        description:
            'Completed session kept for replay, attendance audit, and question review.',
        lecturerName: 'Dr. Musa Ibrahim',
        roomLabel: 'Replay Archive A',
        startTime: monday
            .subtract(const Duration(days: 7))
            .add(const Duration(hours: 14)),
        endTime: monday
            .subtract(const Duration(days: 7))
            .add(const Duration(hours: 15, minutes: 20)),
        agenda: const [
          'Heap insertion and deletion drills.',
          'Replay notes and correction summary.',
        ],
        materials: const [
          LiveSessionMaterial(
            title: 'Heap correction sheet',
            subtitle: 'Updated after the lecturer review',
            status: 'Replay ready',
          ),
        ],
        allowStudentRecording: false,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      LiveSessionModel(
        id: 'live-mth202-upcoming',
        courseCode: 'MTH 202',
        courseTitle: 'Linear Algebra',
        title: 'Eigenvalues Drill Room',
        description:
            'Upcoming lecturer session with timed attendance, student cameras, and question queue.',
        lecturerName: 'Dr. Rose Etim',
        roomLabel: 'Math Studio 1',
        startTime: monday.add(const Duration(days: 3, hours: 14)),
        endTime: monday.add(const Duration(days: 3, hours: 15, minutes: 30)),
        agenda: const [
          'Diagonalisation warm-up.',
          'Guided worked problems.',
          'Live questions and short lecturer answers.',
        ],
        materials: const [
          LiveSessionMaterial(
            title: 'Matrix drill pack',
            subtitle: 'Shared from the lecturer portal',
            status: 'Ready now',
          ),
        ],
        studentCameraRequired: true,
        captureRegistrationNumber: true,
        allowStudentRecording: false,
        allowLecturerRecording: true,
        chatEnabled: true,
        questionsEnabled: true,
        attendanceEnabled: true,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      LiveSessionModel(
        id: 'live-gst201-upcoming',
        courseCode: 'GST 201',
        courseTitle: 'Use of English',
        title: 'Argument Structure Live Seminar',
        description:
            'Seminar room with registration capture, spoken Q&A, and moderated chat.',
        lecturerName: 'Mrs. Halima Yusuf',
        roomLabel: 'Seminar Room B',
        startTime: monday.add(const Duration(days: 4, hours: 10)),
        endTime: monday.add(const Duration(days: 4, hours: 11)),
        agenda: const [
          'Short reading sprint.',
          'Structure review and answer clinic.',
          'Student questions and lecturer corrections.',
        ],
        materials: const [
          LiveSessionMaterial(
            title: 'Reading passage pack',
            subtitle: 'Used for the live room discussion',
            status: 'Ready now',
          ),
          LiveSessionMaterial(
            title: 'Speaking prompt card',
            subtitle: 'For student participation',
            status: 'Bring to class',
          ),
        ],
        studentCameraRequired: true,
        captureRegistrationNumber: true,
        allowStudentRecording: true,
        allowLecturerRecording: true,
        chatEnabled: true,
        questionsEnabled: true,
        attendanceEnabled: true,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }

  LiveSessionRoomState _seedRoomFor(LiveSessionModel session) {
    final now = DateTime.now();
    final lecturer = LiveSessionParticipant(
      id: 'lecturer-${session.id.toLowerCase()}',
      sessionId: session.id,
      role: LiveSessionRole.lecturer,
      displayName: session.lecturerName,
      cameraEnabled: true,
      micEnabled: true,
      recordingEnabled: session.allowLecturerRecording,
      isPresent: true,
      attendanceMinutes: session.isCompletedAt(now)
          ? session.durationMinutes
          : 14,
      joinedAt: session.isCompletedAt(now)
          ? session.startTime
          : now.subtract(const Duration(minutes: 14)),
      streamLabel: 'Lecturer camera feed',
    );

    final students = [
      LiveSessionParticipant(
        id: 'student-kasu-cs-001',
        sessionId: session.id,
        role: LiveSessionRole.student,
        displayName: 'Zainab Ibrahim',
        registrationNumber: 'KASU/CS/23/001',
        cameraEnabled: true,
        micEnabled: true,
        attendanceMinutes: session.isCompletedAt(now) ? 62 : 11,
        joinedAt: session.isCompletedAt(now)
            ? session.startTime.add(const Duration(minutes: 3))
            : now.subtract(const Duration(minutes: 11)),
        streamLabel: 'Student camera feed',
      ),
      LiveSessionParticipant(
        id: 'student-kasu-cs-014',
        sessionId: session.id,
        role: LiveSessionRole.student,
        displayName: 'Maryam Aliyu',
        registrationNumber: 'KASU/CS/23/014',
        cameraEnabled: !session.isUpcomingAt(now),
        micEnabled: true,
        attendanceMinutes: session.isCompletedAt(now) ? 55 : 7,
        joinedAt: session.isCompletedAt(now)
            ? session.startTime.add(const Duration(minutes: 10))
            : now.subtract(const Duration(minutes: 7)),
        streamLabel: 'Student camera feed',
      ),
      LiveSessionParticipant(
        id: 'student-kasu-cs-021',
        sessionId: session.id,
        role: LiveSessionRole.student,
        displayName: 'David Emmanuel',
        registrationNumber: 'KASU/CS/23/021',
        cameraEnabled: session.isLiveAt(now),
        micEnabled: false,
        attendanceMinutes: session.isCompletedAt(now) ? 51 : 5,
        joinedAt: session.isCompletedAt(now)
            ? session.startTime.add(const Duration(minutes: 14))
            : now.subtract(const Duration(minutes: 5)),
        streamLabel: 'Student presentation feed',
      ),
    ];

    final chatMessages = [
      LiveSessionChatMessage(
        id: _uuid.v4(),
        sessionId: session.id,
        senderName: session.lecturerName,
        senderRole: LiveSessionRole.lecturer,
        message:
            'Welcome to the K-SLAS school demo. We will switch between slides, board mode, and student interaction tools.',
        sentAt: now.subtract(const Duration(minutes: 15)),
      ),
      LiveSessionChatMessage(
        id: _uuid.v4(),
        sessionId: session.id,
        senderName: 'Zainab Ibrahim',
        senderRole: LiveSessionRole.student,
        registrationNumber: 'KASU/CS/23/001',
        message: 'The annotation overlay is very clear from the student side.',
        sentAt: now.subtract(const Duration(minutes: 8)),
      ),
      LiveSessionChatMessage(
        id: _uuid.v4(),
        sessionId: session.id,
        senderName: 'David Emmanuel',
        senderRole: LiveSessionRole.student,
        registrationNumber: 'KASU/CS/23/021',
        message: 'Ready to demonstrate student presentation mode when needed.',
        sentAt: now.subtract(const Duration(minutes: 4)),
      ),
    ];

    final questions = [
      LiveSessionQuestion(
        id: _uuid.v4(),
        sessionId: session.id,
        askedByName: 'Maryam Aliyu',
        askedByRegistrationNumber: 'KASU/CS/23/014',
        question: 'Should students use chat or the Q&A panel during the demo?',
        askedAt: now.subtract(const Duration(minutes: 9)),
        answer:
            'Use the Q&A panel for tracked answers. Chat remains open for quick reactions and support.',
        answeredByName: session.lecturerName,
        answeredAt: now.subtract(const Duration(minutes: 6)),
      ),
      LiveSessionQuestion(
        id: _uuid.v4(),
        sessionId: session.id,
        askedByName: 'Zainab Ibrahim',
        askedByRegistrationNumber: 'KASU/CS/23/001',
        question:
            'Can the school see separate annotations for each slide page?',
        askedAt: now.subtract(const Duration(minutes: 3)),
        answer:
            'Yes. Each page keeps its own annotation layer so earlier notes come back when the lecturer revisits the page.',
        answeredByName: session.lecturerName,
        answeredAt: now.subtract(const Duration(minutes: 2)),
      ),
    ];

    final recordings = [
      if (session.allowLecturerRecording)
        LiveSessionRecording(
          id: _uuid.v4(),
          sessionId: session.id,
          ownerRole: LiveSessionRole.lecturer,
          ownerName: session.lecturerName,
          label: 'School demo master recording',
          createdAt: session.startTime,
          minutesCaptured: session.isCompletedAt(now)
              ? session.durationMinutes
              : 14,
          isActive: session.isLiveAt(now),
        ),
    ];

    return LiveSessionRoomState(
      session: session,
      participants: [lecturer, ...students],
      chatMessages: chatMessages,
      questions: questions,
      recordings: recordings,
    );
  }

  LiveSessionRoomState _emptyRoomFor(LiveSessionModel session) {
    return LiveSessionRoomState(
      session: session,
      participants: [
        LiveSessionParticipant(
          id: 'lecturer-${session.id.toLowerCase()}',
          sessionId: session.id,
          role: LiveSessionRole.lecturer,
          displayName: session.lecturerName,
          cameraEnabled: true,
          micEnabled: true,
          recordingEnabled: session.allowLecturerRecording,
          isPresent: false,
          attendanceMinutes: 0,
          streamLabel: 'Lecturer camera feed',
        ),
      ],
      chatMessages: const [],
      questions: const [],
      recordings: const [],
    );
  }
}
