import 'package:get_storage/get_storage.dart';

import '../models/live_session_models.dart';
import 'live_class_attendance_enforcement_service.dart';
import 'live_class_malpractice_report_service.dart';
import 'live_class_moderation_service.dart';
import 'live_screen_share_control_service.dart';

class LiveClassSuspiciousAlertType {
  const LiveClassSuspiciousAlertType._();

  static const String cameraOffTooLong = 'camera_off_too_long';
  static const String lowAttendance = 'low_attendance';
  static const String repeatedModeration = 'repeated_moderation';
  static const String lateJoin = 'late_join';
  static const String screenShareMisuse = 'screen_share_misuse';
}

class LiveClassSuspiciousBehaviourAlert {
  const LiveClassSuspiciousBehaviourAlert({
    required this.id,
    required this.sessionId,
    required this.participantId,
    required this.participantName,
    required this.type,
    required this.category,
    required this.severity,
    required this.title,
    required this.description,
    required this.detectedAt,
    this.registrationNumber,
  });

  final String id;
  final String sessionId;
  final String participantId;
  final String participantName;
  final String? registrationNumber;
  final String type;
  final String category;
  final String severity;
  final String title;
  final String description;
  final DateTime detectedAt;

  Map<String, dynamic> toDraftReportPayload({
    required String reportedBy,
    required String reporterRole,
  }) => {
    'sessionId': sessionId,
    'participantId': participantId,
    'participantName': participantName,
    'registrationNumber': registrationNumber,
    'category': category,
    'severity': severity,
    'description': description,
    'reportedBy': reportedBy,
    'reporterRole': reporterRole,
    'autoAlertId': id,
    'detectedAt': detectedAt.toIso8601String(),
  };
}

class LiveClassSuspiciousBehaviourService {
  LiveClassSuspiciousBehaviourService._();

  static final GetStorage _box = GetStorage();

  static String _dismissedKey(String sessionId) =>
      'live.classroom.suspicious.alerts.dismissed.${sessionId.trim()}';

  static List<LiveClassSuspiciousBehaviourAlert> evaluateRoom({
    required LiveSessionRoomState room,
    DateTime? now,
    LiveClassAttendancePolicy attendancePolicy =
        LiveClassAttendanceEnforcementService.defaultPolicy,
  }) {
    final currentTime = now ?? DateTime.now();
    final dismissed = _dismissedAlertIds(room.session.id).toSet();
    final alerts = <LiveClassSuspiciousBehaviourAlert>[];
    final moderationCommands = LiveClassModerationService.loadCommands(room.session.id);
    final screenShareRequests = LiveScreenShareControlService.loadRequests(room.session.id);

    for (final participant in room.participants.where((item) => item.role == LiveSessionRole.student)) {
      final candidateAlerts = <LiveClassSuspiciousBehaviourAlert>[
        ..._cameraAlerts(room: room, participant: participant, now: currentTime),
        ..._attendanceAlerts(
          room: room,
          participant: participant,
          now: currentTime,
          policy: attendancePolicy,
        ),
        ..._moderationAlerts(
          room: room,
          participant: participant,
          commands: moderationCommands,
          now: currentTime,
        ),
        ..._screenShareAlerts(
          room: room,
          participant: participant,
          requests: screenShareRequests,
          now: currentTime,
        ),
      ];
      alerts.addAll(candidateAlerts.where((item) => !dismissed.contains(item.id)));
    }

    alerts.sort((a, b) => _severityRank(b.severity).compareTo(_severityRank(a.severity)));
    return alerts;
  }

  static Future<void> dismissAlert({
    required String sessionId,
    required String alertId,
  }) async {
    final ids = _dismissedAlertIds(sessionId).toSet()..add(alertId);
    await _box.write(_dismissedKey(sessionId), ids.toList());
  }

  static Future<LiveClassMalpracticeReport> createReportFromAlert({
    required LiveClassSuspiciousBehaviourAlert alert,
    required String reportedBy,
    required String reporterRole,
  }) {
    return LiveClassMalpracticeReportService.createReport(
      sessionId: alert.sessionId,
      participantId: alert.participantId,
      participantName: alert.participantName,
      registrationNumber: alert.registrationNumber,
      category: alert.category,
      severity: alert.severity,
      description: '[Automatic alert] ${alert.description}',
      reportedBy: reportedBy,
      reporterRole: reporterRole,
    );
  }

  static List<LiveClassSuspiciousBehaviourAlert> _cameraAlerts({
    required LiveSessionRoomState room,
    required LiveSessionParticipant participant,
    required DateTime now,
  }) {
    if (!room.session.studentCameraRequired || participant.cameraEnabled || !participant.isPresent) {
      return const [];
    }
    final joined = participant.joinedAt;
    final minutesOff = joined == null ? 0 : now.difference(joined).inMinutes;
    if (minutesOff < 5) return const [];
    return [
      _alert(
        room: room,
        participant: participant,
        type: LiveClassSuspiciousAlertType.cameraOffTooLong,
        category: LiveClassIncidentCategory.cameraViolation,
        severity: minutesOff >= 15
            ? LiveClassIncidentSeverity.high
            : LiveClassIncidentSeverity.medium,
        title: 'Camera off too long',
        description:
            '${participant.displayName} has camera turned off for about $minutesOff minutes while camera is required.',
        now: now,
      ),
    ];
  }

  static List<LiveClassSuspiciousBehaviourAlert> _attendanceAlerts({
    required LiveSessionRoomState room,
    required LiveSessionParticipant participant,
    required DateTime now,
    required LiveClassAttendancePolicy policy,
  }) {
    final status = LiveClassAttendanceEnforcementService.statusFor(
      session: room.session,
      participant: participant,
      now: now,
      policy: policy,
    );
    final duration = room.session.durationMinutes <= 0 ? 1 : room.session.durationMinutes;
    final elapsed = now.difference(room.session.startTime).inMinutes.clamp(0, duration);
    final progressPercentage = ((elapsed / duration) * 100).round();
    final alerts = <LiveClassSuspiciousBehaviourAlert>[];

    if (status.isLateJoin) {
      alerts.add(
        _alert(
          room: room,
          participant: participant,
          type: LiveClassSuspiciousAlertType.lateJoin,
          category: LiveClassIncidentCategory.other,
          severity: LiveClassIncidentSeverity.low,
          title: 'Late join detected',
          description:
              '${participant.displayName} joined after the ${policy.lateJoinGraceMinutes}-minute grace period.',
          now: now,
        ),
      );
    }

    final shouldCheckLowAttendance = room.session.isCompletedAt(now) || progressPercentage >= 50;
    if (shouldCheckLowAttendance && !status.isQualified) {
      alerts.add(
        _alert(
          room: room,
          participant: participant,
          type: LiveClassSuspiciousAlertType.lowAttendance,
          category: LiveClassIncidentCategory.other,
          severity: room.session.isCompletedAt(now)
              ? LiveClassIncidentSeverity.high
              : LiveClassIncidentSeverity.medium,
          title: 'Low attendance risk',
          description:
              '${participant.displayName} currently has ${status.attendancePercentage}% attendance. Minimum required is ${status.minimumPercentage}%.',
          now: now,
        ),
      );
    }

    return alerts;
  }

  static List<LiveClassSuspiciousBehaviourAlert> _moderationAlerts({
    required LiveSessionRoomState room,
    required LiveSessionParticipant participant,
    required List<LiveClassModerationCommand> commands,
    required DateTime now,
  }) {
    final count = commands
        .where((item) => item.participantId == participant.id)
        .length;
    if (count < 2) return const [];
    return [
      _alert(
        room: room,
        participant: participant,
        type: LiveClassSuspiciousAlertType.repeatedModeration,
        category: LiveClassIncidentCategory.other,
        severity: count >= 4
            ? LiveClassIncidentSeverity.high
            : LiveClassIncidentSeverity.medium,
        title: 'Repeated lecturer control commands',
        description:
            '${participant.displayName} has received $count moderation commands during this live class.',
        now: now,
      ),
    ];
  }

  static List<LiveClassSuspiciousBehaviourAlert> _screenShareAlerts({
    required LiveSessionRoomState room,
    required LiveSessionParticipant participant,
    required List<LiveScreenShareRequest> requests,
    required DateTime now,
  }) {
    final participantRequests = requests.where((item) => item.participantId == participant.id).toList();
    final deniedCount = participantRequests.where((item) => item.isDenied).length;
    final active = participantRequests.where((item) => item.isActive).toList();
    final alerts = <LiveClassSuspiciousBehaviourAlert>[];

    if (deniedCount >= 2) {
      alerts.add(
        _alert(
          room: room,
          participant: participant,
          type: LiveClassSuspiciousAlertType.screenShareMisuse,
          category: LiveClassIncidentCategory.screenShareMisuse,
          severity: LiveClassIncidentSeverity.medium,
          title: 'Repeated denied screen-share requests',
          description:
              '${participant.displayName} has had $deniedCount screen-share requests denied in this live class.',
          now: now,
        ),
      );
    }

    for (final request in active) {
      final started = request.startedAt ?? request.reviewedAt ?? request.requestedAt;
      final activeMinutes = now.difference(started).inMinutes;
      if (activeMinutes >= 10) {
        alerts.add(
          _alert(
            room: room,
            participant: participant,
            type: LiveClassSuspiciousAlertType.screenShareMisuse,
            category: LiveClassIncidentCategory.screenShareMisuse,
            severity: activeMinutes >= 20
                ? LiveClassIncidentSeverity.high
                : LiveClassIncidentSeverity.medium,
            title: 'Screen share active for long period',
            description:
                '${participant.displayName} has been sharing screen for about $activeMinutes minutes. Review for relevance and misuse.',
            now: now,
          ),
        );
      }
    }

    return alerts;
  }

  static LiveClassSuspiciousBehaviourAlert _alert({
    required LiveSessionRoomState room,
    required LiveSessionParticipant participant,
    required String type,
    required String category,
    required String severity,
    required String title,
    required String description,
    required DateTime now,
  }) {
    return LiveClassSuspiciousBehaviourAlert(
      id: _alertId(
        sessionId: room.session.id,
        participantId: participant.id,
        type: type,
      ),
      sessionId: room.session.id,
      participantId: participant.id,
      participantName: participant.displayName,
      registrationNumber: participant.registrationNumber,
      type: type,
      category: category,
      severity: severity,
      title: title,
      description: description,
      detectedAt: now,
    );
  }

  static String _alertId({
    required String sessionId,
    required String participantId,
    required String type,
  }) {
    final raw = '$sessionId::$participantId::$type';
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').toLowerCase();
  }

  static List<String> _dismissedAlertIds(String sessionId) {
    final raw = _box.read<List>(_dismissedKey(sessionId)) ?? const [];
    return raw.map((item) => item.toString()).toList();
  }

  static int _severityRank(String severity) {
    return switch (severity) {
      LiveClassIncidentSeverity.critical => 4,
      LiveClassIncidentSeverity.high => 3,
      LiveClassIncidentSeverity.medium => 2,
      LiveClassIncidentSeverity.low => 1,
      _ => 0,
    };
  }
}
