import '../models/live_session_models.dart';

class LiveClassMalpracticeBackendContract {
  const LiveClassMalpracticeBackendContract._();

  static const List<LiveSessionBackendPath> paths = [
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/malpractice-reports',
      description:
          'Create a suspicious-behaviour or malpractice incident report against a student during a live class.',
    ),
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/{sessionId}/malpractice-reports',
      description:
          'Load all live-class incident reports for lecturer, invigilator, exam officer, or audit review.',
    ),
    LiveSessionBackendPath(
      method: 'PATCH',
      path: '/api/v1/live-sessions/{sessionId}/malpractice-reports/{reportId}',
      description:
          'Update incident status such as open, escalated, resolved, or dismissed.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/malpractice-reports/{reportId}/evidence',
      description:
          'Attach evidence metadata such as screenshot reference, timestamp, proctoring flag, or screen-share event ID.',
    ),
  ];

  static Map<String, dynamic> createReportPayloadExample() => {
    'sessionId': 'live-csc305-main',
    'participantId': 'student-kasu-csc-001',
    'participantName': 'Student Name',
    'registrationNumber': 'KASU/CSC/001',
    'category': 'external_assistance',
    'severity': 'high',
    'description': 'Student appeared to receive help from another person during the live class.',
    'reportedBy': 'Course Lecturer',
    'reporterRole': 'lecturer',
    'reportedAt': '2026-06-13T10:35:00Z',
  };

  static Map<String, dynamic> evidencePayloadExample() => {
    'reportId': 'incident-001',
    'evidenceType': 'screenshot',
    'storageKey': 'wasabi/live-class/live-csc305-main/incident-001.png',
    'capturedAt': '2026-06-13T10:35:12Z',
    'note': 'Screen captured after lecturer flagged suspicious behaviour.',
  };
}
