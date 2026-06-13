import '../models/live_session_models.dart';

class LiveClassAttendancePolicy {
  const LiveClassAttendancePolicy({
    this.minimumPercentage = 75,
    this.lateJoinGraceMinutes = 10,
  });

  final int minimumPercentage;
  final int lateJoinGraceMinutes;
}

class LiveClassAttendanceStatus {
  const LiveClassAttendanceStatus({
    required this.participant,
    required this.attendanceMinutes,
    required this.attendancePercentage,
    required this.minimumPercentage,
    required this.isLateJoin,
    required this.isQualified,
    required this.receiptNumber,
  });

  final LiveSessionParticipant participant;
  final int attendanceMinutes;
  final int attendancePercentage;
  final int minimumPercentage;
  final bool isLateJoin;
  final bool isQualified;
  final String receiptNumber;

  String get statusLabel {
    if (isQualified && isLateJoin) return 'Qualified • Late join';
    if (isQualified) return 'Qualified';
    if (isLateJoin) return 'Below minimum • Late join';
    return 'Below minimum';
  }

  String get shortLabel => isQualified ? 'Valid attendance' : 'Needs more time';
}

class LiveClassAttendanceSummary {
  const LiveClassAttendanceSummary({
    required this.totalStudents,
    required this.qualifiedStudents,
    required this.lateStudents,
    required this.averagePercentage,
    required this.minimumPercentage,
  });

  final int totalStudents;
  final int qualifiedStudents;
  final int lateStudents;
  final int averagePercentage;
  final int minimumPercentage;

  int get belowMinimumStudents => totalStudents - qualifiedStudents;
}

class LiveClassAttendanceEnforcementService {
  const LiveClassAttendanceEnforcementService._();

  static const LiveClassAttendancePolicy defaultPolicy = LiveClassAttendancePolicy();

  static LiveClassAttendanceStatus statusFor({
    required LiveSessionModel session,
    required LiveSessionParticipant participant,
    DateTime? now,
    LiveClassAttendancePolicy policy = defaultPolicy,
  }) {
    final currentTime = now ?? DateTime.now();
    final duration = session.durationMinutes <= 0 ? 1 : session.durationMinutes;
    final rawMinutes = participant.attendanceMinutesAt(currentTime);
    final minutes = rawMinutes < 0 ? 0 : rawMinutes;
    final percentage = ((minutes / duration) * 100).round().clamp(0, 100);
    final lateJoin = _isLateJoin(
      session: session,
      participant: participant,
      policy: policy,
    );
    return LiveClassAttendanceStatus(
      participant: participant,
      attendanceMinutes: minutes,
      attendancePercentage: percentage,
      minimumPercentage: policy.minimumPercentage,
      isLateJoin: lateJoin,
      isQualified: !session.attendanceEnabled || percentage >= policy.minimumPercentage,
      receiptNumber: receiptNumber(session: session, participant: participant),
    );
  }

  static List<LiveClassAttendanceStatus> reportFor({
    required LiveSessionRoomState room,
    DateTime? now,
    LiveClassAttendancePolicy policy = defaultPolicy,
  }) {
    final currentTime = now ?? DateTime.now();
    final rows = room.participants
        .where((item) => item.role == LiveSessionRole.student)
        .map(
          (item) => statusFor(
            session: room.session,
            participant: item,
            now: currentTime,
            policy: policy,
          ),
        )
        .toList();
    rows.sort((a, b) {
      final status = a.isQualified == b.isQualified
          ? 0
          : a.isQualified
              ? 1
              : -1;
      if (status != 0) return status;
      return a.participant.displayName.compareTo(b.participant.displayName);
    });
    return rows;
  }

  static LiveClassAttendanceSummary summaryFor({
    required LiveSessionRoomState room,
    DateTime? now,
    LiveClassAttendancePolicy policy = defaultPolicy,
  }) {
    final rows = reportFor(room: room, now: now, policy: policy);
    if (rows.isEmpty) {
      return LiveClassAttendanceSummary(
        totalStudents: 0,
        qualifiedStudents: 0,
        lateStudents: 0,
        averagePercentage: 0,
        minimumPercentage: policy.minimumPercentage,
      );
    }
    final qualified = rows.where((item) => item.isQualified).length;
    final late = rows.where((item) => item.isLateJoin).length;
    final average = (rows.fold<int>(0, (sum, item) => sum + item.attendancePercentage) / rows.length).round();
    return LiveClassAttendanceSummary(
      totalStudents: rows.length,
      qualifiedStudents: qualified,
      lateStudents: late,
      averagePercentage: average,
      minimumPercentage: policy.minimumPercentage,
    );
  }

  static bool _isLateJoin({
    required LiveSessionModel session,
    required LiveSessionParticipant participant,
    required LiveClassAttendancePolicy policy,
  }) {
    final joined = participant.joinedAt;
    if (joined == null) return false;
    final latestOnTime = session.startTime.add(Duration(minutes: policy.lateJoinGraceMinutes));
    return joined.isAfter(latestOnTime);
  }

  static String receiptNumber({
    required LiveSessionModel session,
    required LiveSessionParticipant participant,
  }) {
    final course = _cleanId(session.courseCode);
    final sessionPart = _cleanId(session.id);
    final student = _cleanId(participant.registrationNumber ?? participant.id);
    return 'LIVE-$course-$sessionPart-$student';
  }

  static String _cleanId(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toUpperCase();
    return cleaned.isEmpty ? 'STUDENT' : cleaned;
  }
}
