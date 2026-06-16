enum IntegrityRiskTier { low, medium, high }

class IntegrityRiskProfile {
  const IntegrityRiskProfile({
    required this.studentId,
    required this.riskTier,
    required this.cumulativeRiskScore,
    required this.totalViolations,
    required this.highSeverityViolations,
    this.lastViolationAt,
    this.lastSyncedAt,
    this.unsyncedLedgerCount = 0,
  });

  final String studentId;
  final IntegrityRiskTier riskTier;
  final int cumulativeRiskScore;
  final int totalViolations;
  final int highSeverityViolations;
  final DateTime? lastViolationAt;
  final DateTime? lastSyncedAt;
  final int unsyncedLedgerCount;

  IntegrityRiskProfile copyWith({
    String? studentId,
    IntegrityRiskTier? riskTier,
    int? cumulativeRiskScore,
    int? totalViolations,
    int? highSeverityViolations,
    DateTime? lastViolationAt,
    bool clearLastViolationAt = false,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? unsyncedLedgerCount,
  }) {
    return IntegrityRiskProfile(
      studentId: studentId ?? this.studentId,
      riskTier: riskTier ?? this.riskTier,
      cumulativeRiskScore: cumulativeRiskScore ?? this.cumulativeRiskScore,
      totalViolations: totalViolations ?? this.totalViolations,
      highSeverityViolations:
          highSeverityViolations ?? this.highSeverityViolations,
      lastViolationAt: clearLastViolationAt
          ? null
          : (lastViolationAt ?? this.lastViolationAt),
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      unsyncedLedgerCount: unsyncedLedgerCount ?? this.unsyncedLedgerCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'riskTier': riskTier.name,
      'cumulativeRiskScore': cumulativeRiskScore,
      'totalViolations': totalViolations,
      'highSeverityViolations': highSeverityViolations,
      'lastViolationAt': lastViolationAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'unsyncedLedgerCount': unsyncedLedgerCount,
    };
  }

  factory IntegrityRiskProfile.fromMap(Map<String, dynamic> map) {
    final riskName = (map['riskTier'] ?? IntegrityRiskTier.low.name).toString();
    final riskTier = IntegrityRiskTier.values.firstWhere(
      (tier) => tier.name == riskName,
      orElse: () => IntegrityRiskTier.low,
    );
    return IntegrityRiskProfile(
      studentId: (map['studentId'] ?? '').toString(),
      riskTier: riskTier,
      cumulativeRiskScore: _asInt(map['cumulativeRiskScore']),
      totalViolations: _asInt(map['totalViolations']),
      highSeverityViolations: _asInt(map['highSeverityViolations']),
      lastViolationAt: DateTime.tryParse(
        (map['lastViolationAt'] ?? '').toString(),
      ),
      lastSyncedAt: DateTime.tryParse((map['lastSyncedAt'] ?? '').toString()),
      unsyncedLedgerCount: _asInt(map['unsyncedLedgerCount']),
    );
  }
}

class IntegrityLedgerEntry {
  const IntegrityLedgerEntry({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.occurredAt,
    required this.reason,
    required this.penalty,
    required this.level,
    required this.integrityScoreAfter,
    required this.strictStrikesAfter,
    required this.riskTierAtEvent,
    required this.riskScoreAfter,
    required this.evidenceVault,
    this.eventType = 'integrity_violation',
    this.severity = 'medium',
    this.confidence,
    this.shouldAlert = false,
    this.evidencePath,
    this.metadata = const <String, Object?>{},
    this.syncAttemptCount = 0,
    this.lastSyncError,
    this.syncedAt,
  });

  final String id;
  final String studentId;
  final String sessionId;
  final DateTime occurredAt;
  final String reason;
  final int penalty;
  final String? level;
  final int integrityScoreAfter;
  final int strictStrikesAfter;
  final IntegrityRiskTier riskTierAtEvent;
  final int riskScoreAfter;
  final String evidenceVault;
  final String eventType;
  final String severity;
  final double? confidence;
  final bool shouldAlert;
  final String? evidencePath;
  final Map<String, Object?> metadata;
  final int syncAttemptCount;
  final String? lastSyncError;
  final DateTime? syncedAt;

  IntegrityLedgerEntry copyWith({
    DateTime? syncedAt,
    bool clearSyncedAt = false,
    int? syncAttemptCount,
    String? lastSyncError,
    bool clearLastSyncError = false,
  }) {
    return IntegrityLedgerEntry(
      id: id,
      studentId: studentId,
      sessionId: sessionId,
      occurredAt: occurredAt,
      reason: reason,
      penalty: penalty,
      level: level,
      integrityScoreAfter: integrityScoreAfter,
      strictStrikesAfter: strictStrikesAfter,
      riskTierAtEvent: riskTierAtEvent,
      riskScoreAfter: riskScoreAfter,
      evidenceVault: evidenceVault,
      eventType: eventType,
      severity: severity,
      confidence: confidence,
      shouldAlert: shouldAlert,
      evidencePath: evidencePath,
      metadata: metadata,
      syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
      lastSyncError: clearLastSyncError
          ? null
          : (lastSyncError ?? this.lastSyncError),
      syncedAt: clearSyncedAt ? null : (syncedAt ?? this.syncedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'sessionId': sessionId,
      'occurredAt': occurredAt.toIso8601String(),
      'reason': reason,
      'penalty': penalty,
      'level': level,
      'integrityScoreAfter': integrityScoreAfter,
      'strictStrikesAfter': strictStrikesAfter,
      'riskTierAtEvent': riskTierAtEvent.name,
      'riskScoreAfter': riskScoreAfter,
      'evidenceVault': evidenceVault,
      'eventType': eventType,
      'severity': severity,
      'confidence': confidence,
      'shouldAlert': shouldAlert,
      'evidencePath': evidencePath,
      'metadata': metadata,
      'syncAttemptCount': syncAttemptCount,
      'lastSyncError': lastSyncError,
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  factory IntegrityLedgerEntry.fromMap(Map<String, dynamic> map) {
    final riskName = (map['riskTierAtEvent'] ?? IntegrityRiskTier.low.name)
        .toString();
    final riskTier = IntegrityRiskTier.values.firstWhere(
      (tier) => tier.name == riskName,
      orElse: () => IntegrityRiskTier.low,
    );

    return IntegrityLedgerEntry(
      id: (map['id'] ?? '').toString(),
      studentId: (map['studentId'] ?? '').toString(),
      sessionId: (map['sessionId'] ?? '').toString(),
      occurredAt:
          DateTime.tryParse((map['occurredAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reason: (map['reason'] ?? '').toString(),
      penalty: _asInt(map['penalty']),
      level: map['level']?.toString(),
      integrityScoreAfter: _asInt(map['integrityScoreAfter']),
      strictStrikesAfter: _asInt(map['strictStrikesAfter']),
      riskTierAtEvent: riskTier,
      riskScoreAfter: _asInt(map['riskScoreAfter']),
      evidenceVault: (map['evidenceVault'] ?? '').toString(),
      eventType: (map['eventType'] ?? 'integrity_violation').toString(),
      severity: (map['severity'] ?? 'medium').toString(),
      confidence: _asDouble(map['confidence']),
      shouldAlert: _asBool(map['shouldAlert']),
      evidencePath: map['evidencePath']?.toString(),
      metadata: _asStringObjectMap(map['metadata']),
      syncAttemptCount: _asInt(map['syncAttemptCount']),
      lastSyncError: map['lastSyncError']?.toString(),
      syncedAt: DateTime.tryParse((map['syncedAt'] ?? '').toString()),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().toLowerCase().trim();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

Map<String, Object?> _asStringObjectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  return const <String, Object?>{};
}
