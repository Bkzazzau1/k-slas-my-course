import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/cbt_models.dart';
import '../models/exam_models.dart';
import '../models/live_session_models.dart';

class SubmissionHistoryRecord {
  const SubmissionHistoryRecord({
    required this.receiptNumber,
    required this.courseCode,
    required this.title,
    required this.sessionType,
    required this.gradingType,
    required this.status,
    required this.submittedAt,
    required this.scoreLabel,
    required this.percentage,
    required this.proctored,
    required this.warningCount,
    required this.integrityScore,
  });

  final String receiptNumber;
  final String courseCode;
  final String title;
  final String sessionType;
  final String gradingType;
  final String status;
  final DateTime submittedAt;
  final String scoreLabel;
  final int percentage;
  final bool proctored;
  final int warningCount;
  final int? integrityScore;

  bool get isLiveClassAttendance => sessionType == SubmissionSessionType.liveClass;

  Map<String, dynamic> toJson() => {
        'receiptNumber': receiptNumber,
        'courseCode': courseCode,
        'title': title,
        'sessionType': sessionType,
        'gradingType': gradingType,
        'status': status,
        'submittedAt': submittedAt.toIso8601String(),
        'scoreLabel': scoreLabel,
        'percentage': percentage,
        'proctored': proctored,
        'warningCount': warningCount,
        'integrityScore': integrityScore,
      };

  static SubmissionHistoryRecord fromJson(Map<String, dynamic> json) {
    return SubmissionHistoryRecord(
      receiptNumber: json['receiptNumber']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? 'UNKNOWN',
      title: json['title']?.toString() ?? 'Submission',
      sessionType: json['sessionType']?.toString() ?? SessionType.assessment,
      gradingType: json['gradingType']?.toString() ?? GradingType.ungraded,
      status: json['status']?.toString() ?? 'Submitted Successfully',
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? '') ?? DateTime.now(),
      scoreLabel: json['scoreLabel']?.toString() ?? '0/0',
      percentage: _asInt(json['percentage']),
      proctored: json['proctored'] == true,
      warningCount: _asInt(json['warningCount']),
      integrityScore: json['integrityScore'] == null ? null : _asInt(json['integrityScore']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class SubmissionSessionType {
  SubmissionSessionType._();

  static const String liveClass = 'live_class';
}

class SubmissionHistoryService {
  SubmissionHistoryService._();

  static final GetStorage _box = GetStorage();
  static const String _key = 'student.submission.history';
  static const int _maxItems = 80;

  static List<SubmissionHistoryRecord> load() {
    final raw = _box.read(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw as String) as List;
      final records = list
          .whereType<Map>()
          .map((item) => SubmissionHistoryRecord.fromJson(item.cast<String, dynamic>()))
          .toList();
      records.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return records;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> upsert(SubmissionHistoryRecord record) async {
    final list = load().where((item) => item.receiptNumber != record.receiptNumber).toList();
    list.insert(0, record);
    await _box.write(_key, jsonEncode(list.take(_maxItems).map((e) => e.toJson()).toList()));
  }

  static Future<void> saveCbtAttempt(
    CBTAttemptModel attempt, {
    required String receiptNumber,
    required String status,
    int? integrityScore,
    int warningCount = 0,
  }) {
    return upsert(
      SubmissionHistoryRecord(
        receiptNumber: receiptNumber,
        courseCode: attempt.courseCode,
        title: attempt.gradingType == GradingType.graded ? 'Graded Assessment' : 'Ungraded Assessment',
        sessionType: attempt.sessionType,
        gradingType: attempt.gradingType,
        status: status,
        submittedAt: attempt.endedAt,
        scoreLabel: '${attempt.correct}/${attempt.totalQuestions}',
        percentage: attempt.scorePct,
        proctored: attempt.deliveryMode == ExamDeliveryMode.remoteProctored,
        warningCount: warningCount,
        integrityScore: integrityScore,
      ),
    );
  }

  static Future<void> saveExamResult(
    ExamResult result, {
    required String receiptNumber,
    required String status,
    int? integrityScore,
    int warningCount = 0,
  }) {
    final title = result.sessionType == SessionType.assessment ? 'Assessment' : 'Examination';
    return upsert(
      SubmissionHistoryRecord(
        receiptNumber: receiptNumber,
        courseCode: result.courseCode,
        title: title,
        sessionType: result.sessionType,
        gradingType: result.gradingType,
        status: status,
        submittedAt: result.endedAt,
        scoreLabel: '${result.scoredMarks}/${result.totalMarks}',
        percentage: result.pct,
        proctored: result.deliveryMode == ExamDeliveryMode.remoteProctored,
        warningCount: warningCount,
        integrityScore: integrityScore,
      ),
    );
  }

  static Future<void> saveLiveClassAttendance({
    required LiveSessionModel session,
    required String receiptNumber,
    required int attendanceMinutes,
    required int attendancePercentage,
    required String status,
  }) {
    return upsert(
      SubmissionHistoryRecord(
        receiptNumber: receiptNumber,
        courseCode: session.courseCode,
        title: 'Live Class Attendance • ${session.title}',
        sessionType: SubmissionSessionType.liveClass,
        gradingType: GradingType.ungraded,
        status: status,
        submittedAt: DateTime.now(),
        scoreLabel: '$attendanceMinutes/${session.durationMinutes} min',
        percentage: attendancePercentage,
        proctored: false,
        warningCount: 0,
        integrityScore: null,
      ),
    );
  }
}
