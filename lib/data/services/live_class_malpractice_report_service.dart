import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class LiveClassIncidentCategory {
  const LiveClassIncidentCategory._();

  static const String cameraViolation = 'camera_violation';
  static const String audioDisturbance = 'audio_disturbance';
  static const String absentFromScreen = 'absent_from_screen';
  static const String screenShareMisuse = 'screen_share_misuse';
  static const String suspectedImpersonation = 'suspected_impersonation';
  static const String externalAssistance = 'external_assistance';
  static const String networkTampering = 'network_tampering';
  static const String other = 'other';

  static const List<String> values = [
    cameraViolation,
    audioDisturbance,
    absentFromScreen,
    screenShareMisuse,
    suspectedImpersonation,
    externalAssistance,
    networkTampering,
    other,
  ];

  static String label(String value) {
    return switch (value) {
      cameraViolation => 'Camera violation',
      audioDisturbance => 'Audio disturbance',
      absentFromScreen => 'Absent from screen',
      screenShareMisuse => 'Screen-share misuse',
      suspectedImpersonation => 'Suspected impersonation',
      externalAssistance => 'External assistance',
      networkTampering => 'Network tampering',
      other => 'Other issue',
      _ => 'Incident',
    };
  }
}

class LiveClassIncidentSeverity {
  const LiveClassIncidentSeverity._();

  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const List<String> values = [low, medium, high, critical];

  static String label(String value) {
    return switch (value) {
      low => 'Low',
      medium => 'Medium',
      high => 'High',
      critical => 'Critical',
      _ => 'Medium',
    };
  }
}

class LiveClassIncidentStatus {
  const LiveClassIncidentStatus._();

  static const String open = 'open';
  static const String escalated = 'escalated';
  static const String resolved = 'resolved';
  static const String dismissed = 'dismissed';
}

class LiveClassMalpracticeReport {
  const LiveClassMalpracticeReport({
    required this.id,
    required this.sessionId,
    required this.participantId,
    required this.participantName,
    required this.category,
    required this.severity,
    required this.description,
    required this.reportedBy,
    required this.reportedAt,
    required this.status,
    this.registrationNumber,
    this.reporterRole,
    this.resolutionNote,
    this.resolvedAt,
  });

  final String id;
  final String sessionId;
  final String participantId;
  final String participantName;
  final String? registrationNumber;
  final String category;
  final String severity;
  final String description;
  final String reportedBy;
  final String? reporterRole;
  final DateTime reportedAt;
  final String status;
  final String? resolutionNote;
  final DateTime? resolvedAt;

  bool get isOpen => status == LiveClassIncidentStatus.open;
  bool get isEscalated => status == LiveClassIncidentStatus.escalated;
  bool get isResolved => status == LiveClassIncidentStatus.resolved;
  bool get isDismissed => status == LiveClassIncidentStatus.dismissed;

  String get categoryLabel => LiveClassIncidentCategory.label(category);
  String get severityLabel => LiveClassIncidentSeverity.label(severity);

  LiveClassMalpracticeReport copyWith({
    String? id,
    String? sessionId,
    String? participantId,
    String? participantName,
    String? registrationNumber,
    String? category,
    String? severity,
    String? description,
    String? reportedBy,
    String? reporterRole,
    DateTime? reportedAt,
    String? status,
    String? resolutionNote,
    DateTime? resolvedAt,
  }) {
    return LiveClassMalpracticeReport(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterRole: reporterRole ?? this.reporterRole,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'participantId': participantId,
    'participantName': participantName,
    'registrationNumber': registrationNumber,
    'category': category,
    'severity': severity,
    'description': description,
    'reportedBy': reportedBy,
    'reporterRole': reporterRole,
    'reportedAt': reportedAt.toIso8601String(),
    'status': status,
    'resolutionNote': resolutionNote,
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory LiveClassMalpracticeReport.fromJson(Map<String, dynamic> json) {
    return LiveClassMalpracticeReport(
      id: json['id']?.toString() ?? LiveClassMalpracticeReportService.newId(),
      sessionId: json['sessionId']?.toString() ?? '',
      participantId: json['participantId']?.toString() ?? '',
      participantName: json['participantName']?.toString() ?? 'Student',
      registrationNumber: _nullable(json['registrationNumber']),
      category: json['category']?.toString() ?? LiveClassIncidentCategory.other,
      severity: json['severity']?.toString() ?? LiveClassIncidentSeverity.medium,
      description: json['description']?.toString() ?? '',
      reportedBy: json['reportedBy']?.toString() ?? 'Lecturer',
      reporterRole: _nullable(json['reporterRole']),
      reportedAt: DateTime.tryParse(json['reportedAt']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? LiveClassIncidentStatus.open,
      resolutionNote: _nullable(json['resolutionNote']),
      resolvedAt: DateTime.tryParse(json['resolvedAt']?.toString() ?? ''),
    );
  }

  static String? _nullable(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class LiveClassIncidentSummary {
  const LiveClassIncidentSummary({
    required this.total,
    required this.open,
    required this.escalated,
    required this.resolved,
    required this.critical,
  });

  final int total;
  final int open;
  final int escalated;
  final int resolved;
  final int critical;
}

class LiveClassMalpracticeReportService {
  LiveClassMalpracticeReportService._();

  static final GetStorage _box = GetStorage();
  static final Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();
  static String _key(String sessionId) =>
      'live.classroom.malpractice.reports.${sessionId.trim()}';

  static List<LiveClassMalpracticeReport> loadReports(String sessionId) {
    final raw = _box.read<List>(_key(sessionId)) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((item) => LiveClassMalpracticeReport.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.sessionId == sessionId)
        .toList();
    items.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return items;
  }

  static LiveClassIncidentSummary summary(String sessionId) {
    final reports = loadReports(sessionId);
    return LiveClassIncidentSummary(
      total: reports.length,
      open: reports.where((item) => item.isOpen).length,
      escalated: reports.where((item) => item.isEscalated).length,
      resolved: reports.where((item) => item.isResolved).length,
      critical: reports.where((item) => item.severity == LiveClassIncidentSeverity.critical).length,
    );
  }

  static Future<LiveClassMalpracticeReport> createReport({
    required String sessionId,
    required String participantId,
    required String participantName,
    String? registrationNumber,
    required String category,
    required String severity,
    required String description,
    required String reportedBy,
    String? reporterRole,
  }) async {
    final report = LiveClassMalpracticeReport(
      id: _uuid.v4(),
      sessionId: sessionId,
      participantId: participantId,
      participantName: participantName,
      registrationNumber: registrationNumber,
      category: category,
      severity: severity,
      description: description.trim().isEmpty
          ? LiveClassIncidentCategory.label(category)
          : description.trim(),
      reportedBy: reportedBy,
      reporterRole: reporterRole,
      reportedAt: DateTime.now(),
      status: severity == LiveClassIncidentSeverity.critical
          ? LiveClassIncidentStatus.escalated
          : LiveClassIncidentStatus.open,
    );
    final reports = loadReports(sessionId)..insert(0, report);
    await _write(sessionId, reports);
    return report;
  }

  static Future<LiveClassMalpracticeReport?> updateStatus({
    required String sessionId,
    required String reportId,
    required String status,
    String? resolutionNote,
  }) async {
    final reports = loadReports(sessionId);
    final index = reports.indexWhere((item) => item.id == reportId);
    if (index < 0) return null;
    final now = DateTime.now();
    final updated = reports[index].copyWith(
      status: status,
      resolutionNote: resolutionNote,
      resolvedAt: status == LiveClassIncidentStatus.resolved ||
              status == LiveClassIncidentStatus.dismissed
          ? now
          : reports[index].resolvedAt,
    );
    reports[index] = updated;
    await _write(sessionId, reports);
    return updated;
  }

  static Future<void> _write(
    String sessionId,
    List<LiveClassMalpracticeReport> reports,
  ) async {
    reports.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    await _box.write(_key(sessionId), reports.map((item) => item.toJson()).toList());
  }
}
