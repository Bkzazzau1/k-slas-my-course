import '../models/live_session_models.dart';

class LiveClassAutoAlertBackendContract {
  const LiveClassAutoAlertBackendContract._();

  static const List<LiveSessionBackendPath> paths = [
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/{sessionId}/auto-alerts',
      description:
          'Load automatic suspicious-behaviour draft alerts generated from attendance, camera, moderation, and screen-share signals.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/auto-alerts/evaluate',
      description:
          'Run server-side suspicious-behaviour evaluation for a live class and return draft alerts for review.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/auto-alerts/{alertId}/dismiss',
      description:
          'Dismiss a draft suspicious-behaviour alert after lecturer or invigilator review.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/auto-alerts/{alertId}/convert-report',
      description:
          'Convert a reviewed automatic alert into an official malpractice incident report.',
    ),
    LiveSessionBackendPath(
      method: 'WS',
      path: '/ws/v1/live-sessions/{sessionId}/auto-alerts',
      description:
          'Push real-time draft suspicious-behaviour alerts to lecturer and invigilator dashboards.',
    ),
  ];

  static Map<String, dynamic> alertPayloadExample() => {
    'alertId': 'auto-live-csc305-main-student-kasu-csc-001-camera-off-too-long',
    'sessionId': 'live-csc305-main',
    'participantId': 'student-kasu-csc-001',
    'participantName': 'Student Name',
    'registrationNumber': 'KASU/CSC/001',
    'type': 'camera_off_too_long',
    'category': 'camera_violation',
    'severity': 'medium',
    'title': 'Camera off too long',
    'description': 'Student has camera turned off while camera is required.',
    'detectedAt': '2026-06-13T10:45:00Z',
    'status': 'draft',
  };
}
