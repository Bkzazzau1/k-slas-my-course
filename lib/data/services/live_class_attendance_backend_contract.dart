import '../models/live_session_models.dart';

class LiveClassAttendanceBackendContract {
  const LiveClassAttendanceBackendContract._();

  static const List<LiveSessionBackendPath> paths = [
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/attendance/check-in',
      description:
          'Student check-in endpoint that records registration number, join time, device/app identity, and initial attendance state.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/attendance/heartbeat',
      description:
          'Periodic student heartbeat used to calculate accurate live attendance minutes and disconnection gaps.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/attendance/check-out',
      description:
          'Student check-out endpoint that finalizes attendance minutes and generates the attendance receipt.',
    ),
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/{sessionId}/attendance/report',
      description:
          'Lecturer and exam officer attendance report with minimum percentage, late-join flag, and receipt number per student.',
    ),
    LiveSessionBackendPath(
      method: 'PATCH',
      path: '/api/v1/live-sessions/{sessionId}/attendance/policy',
      description:
          'Configure minimum attendance percentage, late-join grace minutes, and attendance enforcement mode for a live class.',
    ),
  ];

  static Map<String, dynamic> checkInPayloadExample() => {
    'sessionId': 'live-csc305-main',
    'participantId': 'student-kasu-csc-001',
    'studentName': 'Student Name',
    'registrationNumber': 'KASU/CSC/001',
    'deviceId': 'desktop-app-id-or-browser-id',
    'joinedAt': '2026-06-13T10:00:00Z',
  };

  static Map<String, dynamic> reportRowExample() => {
    'sessionId': 'live-csc305-main',
    'participantId': 'student-kasu-csc-001',
    'studentName': 'Student Name',
    'registrationNumber': 'KASU/CSC/001',
    'attendanceMinutes': 48,
    'attendancePercentage': 80,
    'minimumPercentage': 75,
    'lateJoin': false,
    'qualified': true,
    'receiptNumber': 'LIVE-CSC305-LIVECSC305MAIN-KASUCSC001',
  };
}
