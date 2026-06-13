import '../models/live_session_models.dart';

class LiveClassControlRoomBackendContract {
  const LiveClassControlRoomBackendContract._();

  static const List<LiveSessionBackendPath> paths = [
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/control-room/overview',
      description:
          'Chief invigilator overview of all live sessions, active students, incidents, attendance risks, alerts, and screen-share activity.',
    ),
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/control-room/sessions/{sessionId}',
      description:
          'Detailed control-room snapshot for a single live class including attendance, incidents, alerts, and screen-share state.',
    ),
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/control-room/risk-feed',
      description:
          'Prioritized feed of high-risk live classes and students requiring chief invigilator attention.',
    ),
    LiveSessionBackendPath(
      method: 'WS',
      path: '/ws/v1/live-sessions/control-room',
      description:
          'Real-time push stream for live class status, automatic alerts, attendance risk, incident escalation, and screen-share requests.',
    ),
  ];

  static Map<String, dynamic> overviewPayloadExample() => {
    'totalClasses': 8,
    'liveClasses': 3,
    'activeStudents': 412,
    'openIncidents': 5,
    'autoAlerts': 9,
    'attendanceRiskStudents': 34,
    'pendingScreenShareRequests': 2,
    'sessions': [
      {
        'sessionId': 'live-csc305-main',
        'courseCode': 'CSC 305',
        'title': 'Software Engineering Live Class',
        'lecturerName': 'Course Lecturer',
        'activeStudents': 120,
        'openIncidents': 2,
        'autoAlerts': 4,
        'attendanceRiskStudents': 12,
        'pendingScreenShareRequests': 1,
        'riskScore': 35,
        'riskLabel': 'High risk',
      },
    ],
  };
}
