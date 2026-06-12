class LiveSessionRole {
  static const String lecturer = 'lecturer';
  static const String student = 'student';
}

class LiveSessionMaterial {
  const LiveSessionMaterial({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;

  LiveSessionMaterial copyWith({
    String? title,
    String? subtitle,
    String? status,
  }) {
    return LiveSessionMaterial(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'status': status,
  };

  factory LiveSessionMaterial.fromJson(Map<String, dynamic> json) {
    return LiveSessionMaterial(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class LiveSessionModel {
  const LiveSessionModel({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.title,
    required this.description,
    required this.lecturerName,
    required this.roomLabel,
    required this.startTime,
    required this.endTime,
    required this.agenda,
    required this.materials,
    this.studentCameraRequired = true,
    this.captureRegistrationNumber = true,
    this.allowStudentRecording = false,
    this.allowLecturerRecording = true,
    this.chatEnabled = true,
    this.questionsEnabled = true,
    this.attendanceEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String courseCode;
  final String courseTitle;
  final String title;
  final String description;
  final String lecturerName;
  final String roomLabel;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> agenda;
  final List<LiveSessionMaterial> materials;
  final bool studentCameraRequired;
  final bool captureRegistrationNumber;
  final bool allowStudentRecording;
  final bool allowLecturerRecording;
  final bool chatEnabled;
  final bool questionsEnabled;
  final bool attendanceEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool isLiveAt(DateTime now) {
    return !now.isBefore(startTime) && now.isBefore(endTime);
  }

  bool isUpcomingAt(DateTime now) => now.isBefore(startTime);

  bool isCompletedAt(DateTime now) => now.isAfter(endTime);

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  String statusLabelAt(DateTime now) {
    if (isLiveAt(now)) return 'Live now';
    if (isUpcomingAt(now)) return 'Upcoming';
    return 'Replay';
  }

  LiveSessionModel copyWith({
    String? id,
    String? courseCode,
    String? courseTitle,
    String? title,
    String? description,
    String? lecturerName,
    String? roomLabel,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? agenda,
    List<LiveSessionMaterial>? materials,
    bool? studentCameraRequired,
    bool? captureRegistrationNumber,
    bool? allowStudentRecording,
    bool? allowLecturerRecording,
    bool? chatEnabled,
    bool? questionsEnabled,
    bool? attendanceEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveSessionModel(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      lecturerName: lecturerName ?? this.lecturerName,
      roomLabel: roomLabel ?? this.roomLabel,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      agenda: agenda ?? this.agenda,
      materials: materials ?? this.materials,
      studentCameraRequired:
          studentCameraRequired ?? this.studentCameraRequired,
      captureRegistrationNumber:
          captureRegistrationNumber ?? this.captureRegistrationNumber,
      allowStudentRecording:
          allowStudentRecording ?? this.allowStudentRecording,
      allowLecturerRecording:
          allowLecturerRecording ?? this.allowLecturerRecording,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      questionsEnabled: questionsEnabled ?? this.questionsEnabled,
      attendanceEnabled: attendanceEnabled ?? this.attendanceEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'title': title,
    'description': description,
    'lecturerName': lecturerName,
    'roomLabel': roomLabel,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'agenda': agenda,
    'materials': materials.map((item) => item.toJson()).toList(),
    'studentCameraRequired': studentCameraRequired,
    'captureRegistrationNumber': captureRegistrationNumber,
    'allowStudentRecording': allowStudentRecording,
    'allowLecturerRecording': allowLecturerRecording,
    'chatEnabled': chatEnabled,
    'questionsEnabled': questionsEnabled,
    'attendanceEnabled': attendanceEnabled,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    final materialList = json['materials'] as List? ?? const [];

    return LiveSessionModel(
      id: json['id']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lecturerName: json['lecturerName']?.toString() ?? '',
      roomLabel: json['roomLabel']?.toString() ?? '',
      startTime:
          DateTime.tryParse(json['startTime']?.toString() ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(json['endTime']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      agenda: (json['agenda'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      materials: materialList
          .whereType<Map>()
          .map(
            (item) =>
                LiveSessionMaterial.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      studentCameraRequired: json['studentCameraRequired'] == true,
      captureRegistrationNumber: json['captureRegistrationNumber'] != false,
      allowStudentRecording: json['allowStudentRecording'] == true,
      allowLecturerRecording: json['allowLecturerRecording'] != false,
      chatEnabled: json['chatEnabled'] != false,
      questionsEnabled: json['questionsEnabled'] != false,
      attendanceEnabled: json['attendanceEnabled'] != false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class LiveSessionParticipant {
  const LiveSessionParticipant({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.displayName,
    this.registrationNumber,
    this.cameraEnabled = true,
    this.micEnabled = true,
    this.recordingEnabled = false,
    this.isPresent = true,
    this.attendanceMinutes = 0,
    this.joinedAt,
    this.streamLabel,
  });

  final String id;
  final String sessionId;
  final String role;
  final String displayName;
  final String? registrationNumber;
  final bool cameraEnabled;
  final bool micEnabled;
  final bool recordingEnabled;
  final bool isPresent;
  final int attendanceMinutes;
  final DateTime? joinedAt;
  final String? streamLabel;

  int attendanceMinutesAt(DateTime now) {
    final joined = joinedAt;
    if (joined == null || !isPresent) return attendanceMinutes;
    final extra = now.difference(joined).inMinutes;
    return attendanceMinutes + (extra < 0 ? 0 : extra);
  }

  LiveSessionParticipant copyWith({
    String? id,
    String? sessionId,
    String? role,
    String? displayName,
    String? registrationNumber,
    bool? cameraEnabled,
    bool? micEnabled,
    bool? recordingEnabled,
    bool? isPresent,
    int? attendanceMinutes,
    DateTime? joinedAt,
    String? streamLabel,
  }) {
    return LiveSessionParticipant(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      micEnabled: micEnabled ?? this.micEnabled,
      recordingEnabled: recordingEnabled ?? this.recordingEnabled,
      isPresent: isPresent ?? this.isPresent,
      attendanceMinutes: attendanceMinutes ?? this.attendanceMinutes,
      joinedAt: joinedAt ?? this.joinedAt,
      streamLabel: streamLabel ?? this.streamLabel,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'role': role,
    'displayName': displayName,
    'registrationNumber': registrationNumber,
    'cameraEnabled': cameraEnabled,
    'micEnabled': micEnabled,
    'recordingEnabled': recordingEnabled,
    'isPresent': isPresent,
    'attendanceMinutes': attendanceMinutes,
    'joinedAt': joinedAt?.toIso8601String(),
    'streamLabel': streamLabel,
  };

  factory LiveSessionParticipant.fromJson(Map<String, dynamic> json) {
    return LiveSessionParticipant(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      role: json['role']?.toString() ?? LiveSessionRole.student,
      displayName: json['displayName']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString(),
      cameraEnabled: json['cameraEnabled'] != false,
      micEnabled: json['micEnabled'] != false,
      recordingEnabled: json['recordingEnabled'] == true,
      isPresent: json['isPresent'] != false,
      attendanceMinutes: json['attendanceMinutes'] is int
          ? json['attendanceMinutes'] as int
          : int.tryParse(json['attendanceMinutes']?.toString() ?? '') ?? 0,
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
      streamLabel: json['streamLabel']?.toString(),
    );
  }
}

class LiveSessionChatMessage {
  const LiveSessionChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.sentAt,
    this.registrationNumber,
  });

  final String id;
  final String sessionId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime sentAt;
  final String? registrationNumber;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'senderName': senderName,
    'senderRole': senderRole,
    'message': message,
    'sentAt': sentAt.toIso8601String(),
    'registrationNumber': registrationNumber,
  };

  factory LiveSessionChatMessage.fromJson(Map<String, dynamic> json) {
    return LiveSessionChatMessage(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? LiveSessionRole.student,
      message: json['message']?.toString() ?? '',
      sentAt:
          DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
      registrationNumber: json['registrationNumber']?.toString(),
    );
  }
}

class LiveSessionQuestion {
  const LiveSessionQuestion({
    required this.id,
    required this.sessionId,
    required this.askedByName,
    required this.question,
    required this.askedAt,
    this.askedByRegistrationNumber,
    this.answer,
    this.answeredByName,
    this.answeredAt,
  });

  final String id;
  final String sessionId;
  final String askedByName;
  final String question;
  final DateTime askedAt;
  final String? askedByRegistrationNumber;
  final String? answer;
  final String? answeredByName;
  final DateTime? answeredAt;

  bool get isAnswered => (answer ?? '').trim().isNotEmpty;

  LiveSessionQuestion copyWith({
    String? id,
    String? sessionId,
    String? askedByName,
    String? question,
    DateTime? askedAt,
    String? askedByRegistrationNumber,
    String? answer,
    String? answeredByName,
    DateTime? answeredAt,
  }) {
    return LiveSessionQuestion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      askedByName: askedByName ?? this.askedByName,
      question: question ?? this.question,
      askedAt: askedAt ?? this.askedAt,
      askedByRegistrationNumber:
          askedByRegistrationNumber ?? this.askedByRegistrationNumber,
      answer: answer ?? this.answer,
      answeredByName: answeredByName ?? this.answeredByName,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'askedByName': askedByName,
    'question': question,
    'askedAt': askedAt.toIso8601String(),
    'askedByRegistrationNumber': askedByRegistrationNumber,
    'answer': answer,
    'answeredByName': answeredByName,
    'answeredAt': answeredAt?.toIso8601String(),
  };

  factory LiveSessionQuestion.fromJson(Map<String, dynamic> json) {
    return LiveSessionQuestion(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      askedByName: json['askedByName']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      askedAt:
          DateTime.tryParse(json['askedAt']?.toString() ?? '') ??
          DateTime.now(),
      askedByRegistrationNumber: json['askedByRegistrationNumber']?.toString(),
      answer: json['answer']?.toString(),
      answeredByName: json['answeredByName']?.toString(),
      answeredAt: DateTime.tryParse(json['answeredAt']?.toString() ?? ''),
    );
  }
}

class LiveSessionRecording {
  const LiveSessionRecording({
    required this.id,
    required this.sessionId,
    required this.ownerRole,
    required this.ownerName,
    required this.label,
    required this.createdAt,
    this.ownerRegistrationNumber,
    this.minutesCaptured = 0,
    this.isActive = false,
  });

  final String id;
  final String sessionId;
  final String ownerRole;
  final String ownerName;
  final String label;
  final DateTime createdAt;
  final String? ownerRegistrationNumber;
  final int minutesCaptured;
  final bool isActive;

  LiveSessionRecording copyWith({
    String? id,
    String? sessionId,
    String? ownerRole,
    String? ownerName,
    String? label,
    DateTime? createdAt,
    String? ownerRegistrationNumber,
    int? minutesCaptured,
    bool? isActive,
  }) {
    return LiveSessionRecording(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      ownerRole: ownerRole ?? this.ownerRole,
      ownerName: ownerName ?? this.ownerName,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      ownerRegistrationNumber:
          ownerRegistrationNumber ?? this.ownerRegistrationNumber,
      minutesCaptured: minutesCaptured ?? this.minutesCaptured,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'ownerRole': ownerRole,
    'ownerName': ownerName,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
    'ownerRegistrationNumber': ownerRegistrationNumber,
    'minutesCaptured': minutesCaptured,
    'isActive': isActive,
  };

  factory LiveSessionRecording.fromJson(Map<String, dynamic> json) {
    return LiveSessionRecording(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      ownerRole: json['ownerRole']?.toString() ?? LiveSessionRole.student,
      ownerName: json['ownerName']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      ownerRegistrationNumber: json['ownerRegistrationNumber']?.toString(),
      minutesCaptured: json['minutesCaptured'] is int
          ? json['minutesCaptured'] as int
          : int.tryParse(json['minutesCaptured']?.toString() ?? '') ?? 0,
      isActive: json['isActive'] == true,
    );
  }
}

class LiveSessionRoomState {
  const LiveSessionRoomState({
    required this.session,
    required this.participants,
    required this.chatMessages,
    required this.questions,
    required this.recordings,
  });

  final LiveSessionModel session;
  final List<LiveSessionParticipant> participants;
  final List<LiveSessionChatMessage> chatMessages;
  final List<LiveSessionQuestion> questions;
  final List<LiveSessionRecording> recordings;

  LiveSessionRoomState copyWith({
    LiveSessionModel? session,
    List<LiveSessionParticipant>? participants,
    List<LiveSessionChatMessage>? chatMessages,
    List<LiveSessionQuestion>? questions,
    List<LiveSessionRecording>? recordings,
  }) {
    return LiveSessionRoomState(
      session: session ?? this.session,
      participants: participants ?? this.participants,
      chatMessages: chatMessages ?? this.chatMessages,
      questions: questions ?? this.questions,
      recordings: recordings ?? this.recordings,
    );
  }

  Map<String, dynamic> toJson() => {
    'session': session.toJson(),
    'participants': participants.map((item) => item.toJson()).toList(),
    'chatMessages': chatMessages.map((item) => item.toJson()).toList(),
    'questions': questions.map((item) => item.toJson()).toList(),
    'recordings': recordings.map((item) => item.toJson()).toList(),
  };

  factory LiveSessionRoomState.fromJson(Map<String, dynamic> json) {
    final participantList = json['participants'] as List? ?? const [];
    final chatList = json['chatMessages'] as List? ?? const [];
    final questionList = json['questions'] as List? ?? const [];
    final recordingList = json['recordings'] as List? ?? const [];

    return LiveSessionRoomState(
      session: LiveSessionModel.fromJson(
        Map<String, dynamic>.from(json['session'] as Map? ?? const {}),
      ),
      participants: participantList
          .whereType<Map>()
          .map(
            (item) => LiveSessionParticipant.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      chatMessages: chatList
          .whereType<Map>()
          .map(
            (item) => LiveSessionChatMessage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      questions: questionList
          .whereType<Map>()
          .map(
            (item) =>
                LiveSessionQuestion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      recordings: recordingList
          .whereType<Map>()
          .map(
            (item) =>
                LiveSessionRecording.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class LiveSessionBackendPath {
  const LiveSessionBackendPath({
    required this.method,
    required this.path,
    required this.description,
  });

  final String method;
  final String path;
  final String description;
}
