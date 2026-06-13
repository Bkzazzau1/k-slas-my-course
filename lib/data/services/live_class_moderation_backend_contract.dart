import '../models/live_session_models.dart';

class LiveClassModerationBackendContract {
  const LiveClassModerationBackendContract._();

  static const List<LiveSessionBackendPath> paths = [
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/participants/{participantId}/moderation/mute',
      description:
          'Lecturer force-mutes a student microphone during a live class and stores an audit event.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/participants/{participantId}/moderation/camera-off',
      description:
          'Lecturer turns off a student camera during a live class and stores an audit event.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/participants/{participantId}/moderation/remove',
      description:
          'Lecturer removes a student from the live room and prevents immediate rejoin unless allowed.',
    ),
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/{sessionId}/moderation/commands',
      description:
          'Student app polls or subscribes to pending moderation commands when WebSocket is not available.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/moderation/commands/{commandId}/ack',
      description:
          'Student app acknowledges that a moderation command has been applied.',
    ),
  ];

  static Map<String, dynamic> commandPayloadExample() => {
    'sessionId': 'live-csc305-main',
    'participantId': 'student-kasu-csc-001',
    'participantName': 'Student Name',
    'action': 'mute_microphone',
    'issuedBy': 'Course Lecturer',
    'reason': 'Classroom discipline or noise control',
    'issuedAt': '2026-06-13T10:05:00Z',
  };

  static Map<String, dynamic> acknowledgementPayloadExample() => {
    'sessionId': 'live-csc305-main',
    'commandId': 'cmd-001',
    'participantId': 'student-kasu-csc-001',
    'status': 'applied',
    'appliedAt': '2026-06-13T10:05:04Z',
  };
}
