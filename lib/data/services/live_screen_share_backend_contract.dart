import '../models/live_session_models.dart';

class LiveScreenShareBackendContract {
  const LiveScreenShareBackendContract._();

  static const List<LiveSessionBackendPath> paths = [
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/screen-share/request',
      description:
          'Student requests permission to share screen during a live class. Lecturer or policy can approve automatically.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/screen-share/approve',
      description:
          'Lecturer approves a student screen-share request before the screen stream is published.',
    ),
    LiveSessionBackendPath(
      method: 'PATCH',
      path: '/api/v1/live-sessions/{sessionId}/participants/{participantId}/screen-share',
      description:
          'Sync participant screen-share state, including started, stopped, denied, or force-stopped status.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/screen-share/stop',
      description:
          'Lecturer or student stops an active screen share. Used for classroom control and audit logs.',
    ),
  ];

  static Map<String, dynamic> requestPayloadExample() => {
    'sessionId': 'live-csc305-main',
    'participantId': 'student-kasu-csc-001',
    'studentName': 'Student Name',
    'registrationNumber': 'KASU/CSC/001',
    'reason': 'Student wants to show assignment solution or coding error.',
    'requestedAt': '2026-06-13T10:00:00Z',
  };

  static Map<String, dynamic> statePayloadExample() => {
    'sessionId': 'live-csc305-main',
    'participantId': 'student-kasu-csc-001',
    'screenShareEnabled': true,
    'status': 'started',
    'updatedAt': '2026-06-13T10:01:00Z',
  };
}
