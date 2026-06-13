import '../models/live_session_models.dart';
import 'live_class_attendance_enforcement_service.dart';
import 'live_class_malpractice_report_service.dart';
import 'live_class_suspicious_behaviour_service.dart';
import 'live_screen_share_control_service.dart';

class LiveClassControlRoomSnapshot {
  const LiveClassControlRoomSnapshot({
    required this.room,
    required this.attendanceSummary,
    required this.incidentSummary,
    required this.autoAlerts,
    required this.pendingScreenShareRequests,
    required this.activeScreenShareRequests,
    required this.activeStudents,
    required this.activeLecturers,
    required this.riskScore,
  });

  final LiveSessionRoomState room;
  final LiveClassAttendanceSummary attendanceSummary;
  final LiveClassIncidentSummary incidentSummary;
  final List<LiveClassSuspiciousBehaviourAlert> autoAlerts;
  final int pendingScreenShareRequests;
  final int activeScreenShareRequests;
  final int activeStudents;
  final int activeLecturers;
  final int riskScore;

  LiveSessionModel get session => room.session;
  int get totalStudents => attendanceSummary.totalStudents;
  int get attendanceRisk => attendanceSummary.belowMinimumStudents;
  int get openIncidents => incidentSummary.open + incidentSummary.escalated;
  bool get hasRisk => riskScore > 0;

  String statusLabelAt(DateTime now) => session.statusLabelAt(now);

  String get riskLabel {
    if (riskScore >= 12) return 'Critical attention';
    if (riskScore >= 7) return 'High risk';
    if (riskScore >= 3) return 'Watch closely';
    return 'Stable';
  }
}

class LiveClassControlRoomSummary {
  const LiveClassControlRoomSummary({
    required this.totalClasses,
    required this.liveClasses,
    required this.activeStudents,
    required this.openIncidents,
    required this.autoAlerts,
    required this.attendanceRiskStudents,
    required this.pendingScreenShareRequests,
  });

  final int totalClasses;
  final int liveClasses;
  final int activeStudents;
  final int openIncidents;
  final int autoAlerts;
  final int attendanceRiskStudents;
  final int pendingScreenShareRequests;
}

class LiveClassControlRoomService {
  const LiveClassControlRoomService._();

  static LiveClassControlRoomSnapshot snapshotForRoom(LiveSessionRoomState room) {
    final attendance = LiveClassAttendanceEnforcementService.summaryFor(room: room);
    final incident = LiveClassMalpracticeReportService.summary(room.session.id);
    final alerts = LiveClassSuspiciousBehaviourService.evaluateRoom(room: room);
    final pendingShares = LiveScreenShareControlService.pendingRequests(room.session.id).length;
    final activeShares = LiveScreenShareControlService.activeRequests(room.session.id).length;
    final activeStudents = room.participants
        .where((item) => item.role == LiveSessionRole.student && item.isPresent)
        .length;
    final activeLecturers = room.participants
        .where((item) => item.role == LiveSessionRole.lecturer && item.isPresent)
        .length;
    final riskScore = _riskScore(
      attendance: attendance,
      incident: incident,
      autoAlerts: alerts.length,
      pendingShares: pendingShares,
      activeShares: activeShares,
    );

    return LiveClassControlRoomSnapshot(
      room: room,
      attendanceSummary: attendance,
      incidentSummary: incident,
      autoAlerts: alerts,
      pendingScreenShareRequests: pendingShares,
      activeScreenShareRequests: activeShares,
      activeStudents: activeStudents,
      activeLecturers: activeLecturers,
      riskScore: riskScore,
    );
  }

  static LiveClassControlRoomSummary summaryFor(
    List<LiveClassControlRoomSnapshot> snapshots,
  ) {
    final now = DateTime.now();
    return LiveClassControlRoomSummary(
      totalClasses: snapshots.length,
      liveClasses: snapshots.where((item) => item.session.isLiveAt(now)).length,
      activeStudents: snapshots.fold<int>(0, (sum, item) => sum + item.activeStudents),
      openIncidents: snapshots.fold<int>(0, (sum, item) => sum + item.openIncidents),
      autoAlerts: snapshots.fold<int>(0, (sum, item) => sum + item.autoAlerts.length),
      attendanceRiskStudents:
          snapshots.fold<int>(0, (sum, item) => sum + item.attendanceRisk),
      pendingScreenShareRequests: snapshots.fold<int>(
        0,
        (sum, item) => sum + item.pendingScreenShareRequests,
      ),
    );
  }

  static List<LiveClassControlRoomSnapshot> sortByRisk(
    List<LiveClassControlRoomSnapshot> snapshots,
  ) {
    final now = DateTime.now();
    final sorted = [...snapshots];
    sorted.sort((a, b) {
      final liveWeightA = a.session.isLiveAt(now) ? 0 : 1;
      final liveWeightB = b.session.isLiveAt(now) ? 0 : 1;
      if (liveWeightA != liveWeightB) return liveWeightA.compareTo(liveWeightB);
      if (a.riskScore != b.riskScore) return b.riskScore.compareTo(a.riskScore);
      return a.session.startTime.compareTo(b.session.startTime);
    });
    return sorted;
  }

  static int _riskScore({
    required LiveClassAttendanceSummary attendance,
    required LiveClassIncidentSummary incident,
    required int autoAlerts,
    required int pendingShares,
    required int activeShares,
  }) {
    return (attendance.belowMinimumStudents * 2) +
        (incident.open * 3) +
        (incident.escalated * 5) +
        (incident.critical * 5) +
        (autoAlerts * 2) +
        pendingShares +
        activeShares;
  }
}
