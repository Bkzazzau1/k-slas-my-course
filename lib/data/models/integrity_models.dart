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
  final DateTime? syncedAt;

  IntegrityLedgerEntry copyWith({DateTime? syncedAt}) {
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
      syncedAt: syncedAt ?? this.syncedAt,
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
      syncedAt: DateTime.tryParse((map['syncedAt'] ?? '').toString()),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
