import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/integrity_models.dart';

class IntegrityLedgerService {
  IntegrityLedgerService._();

  static final _box = GetStorage();
  static final Map<String, Map<String, dynamic>> _memoryProfiles =
      <String, Map<String, dynamic>>{};
  static final Map<String, List<Map<String, dynamic>>> _memoryLedgers =
      <String, List<Map<String, dynamic>>>{};

  static const defaultStudentId = 'local-student';
  static const _profilePrefix = 'integrity.profile';
  static const _ledgerPrefix = 'integrity.ledger';
  static const _maxLedgerEntries = 1000;

  static bool get _useMemoryStore => Get.testMode;

  static String _profileKey(String studentId) => '$_profilePrefix.$studentId';
  static String _ledgerKey(String studentId) => '$_ledgerPrefix.$studentId';

  static String safeStudentId(String? studentId) {
    final normalized = studentId?.trim();
    if (normalized == null || normalized.isEmpty) return defaultStudentId;
    return normalized;
  }

  static String safeSessionId(String? sessionId) {
    final normalized = sessionId?.trim();
    if (normalized == null || normalized.isEmpty) return 'local-session';
    return normalized;
  }

  static String nextLedgerId({String prefix = 'proctoring-event'}) {
    final now = DateTime.now();
    return '$prefix-${now.microsecondsSinceEpoch}';
  }

  static IntegrityRiskProfile loadOrCreateProfile(String studentId) {
    final safeId = safeStudentId(studentId);
    final raw = _readProfilePayload(safeId);
    if (raw is Map) {
      return IntegrityRiskProfile.fromMap(Map<String, dynamic>.from(raw));
    }
    return IntegrityRiskProfile(
      studentId: safeId,
      riskTier: IntegrityRiskTier.low,
      cumulativeRiskScore: 0,
      totalViolations: 0,
      highSeverityViolations: 0,
      unsyncedLedgerCount: 0,
    );
  }

  static Future<void> saveProfile(IntegrityRiskProfile profile) async {
    await _writeProfilePayload(profile.studentId, profile.toMap());
  }

  static List<IntegrityLedgerEntry> loadLedger(String studentId) {
    final safeId = safeStudentId(studentId);
    final raw = _readLedgerPayload(safeId);
    return raw
        .whereType<Map>()
        .map((e) => IntegrityLedgerEntry.fromMap(Map<String, dynamic>.from(e)))
        .where((entry) => entry.id.trim().isNotEmpty)
        .toList();
  }

  static Future<void> saveLedger(
    String studentId,
    List<IntegrityLedgerEntry> entries,
  ) async {
    final safeId = safeStudentId(studentId);
    final payload = entries
        .take(_maxLedgerEntries)
        .map((entry) => entry.toMap())
        .toList();
    await _writeLedgerPayload(safeId, payload);
  }

  static IntegrityRiskTier tierForRiskScore(int score) {
    if (score >= 140) return IntegrityRiskTier.high;
    if (score >= 60) return IntegrityRiskTier.medium;
    return IntegrityRiskTier.low;
  }

  static int riskPointsForViolation({
    required String reason,
    required int penalty,
  }) {
    final lower = reason.toLowerCase();
    var base = 6;

    if (lower.contains('terminal violation')) {
      base = 30;
    } else if (lower.contains('remote desktop') ||
        lower.contains('screen sharing') ||
        lower.contains('recording') ||
        lower.contains('screenshot') ||
        lower.contains('mirroring')) {
      base = 25;
    } else if (lower.contains('multiple faces') ||
        lower.contains('multiple people') ||
        lower.contains('multiple voices') ||
        lower.contains('phone') ||
        lower.contains('peripheral')) {
      base = 22;
    } else if (lower.contains('speech') ||
        lower.contains('voice') ||
        lower.contains('network') ||
        lower.contains('forbidden') ||
        lower.contains('unauthorized')) {
      base = 16;
    } else if (lower.contains('movement') || lower.contains('gaze')) {
      base = 10;
    }

    final penaltyWeight = (penalty / 5).round().clamp(0, 20);
    return base + penaltyWeight;
  }

  static String buildEvidenceVaultToken(Map<String, dynamic> payload) {
    final json = jsonEncode(payload);
    return base64Encode(utf8.encode(json));
  }

  static Future<IntegrityRiskProfile> appendViolationRecord({
    required String studentId,
    required IntegrityLedgerEntry entry,
    required int riskPoints,
  }) async {
    final safeId = safeStudentId(studentId);
    final profile = loadOrCreateProfile(safeId);
    final effectiveRiskPoints = riskPoints.clamp(0, 1000).toInt();
    final nextRisk = profile.cumulativeRiskScore + effectiveRiskPoints;
    final nextTier = tierForRiskScore(nextRisk);
    final nextHighSeverity =
        profile.highSeverityViolations + (effectiveRiskPoints >= 20 ? 1 : 0);

    final updatedProfile = profile.copyWith(
      cumulativeRiskScore: nextRisk,
      riskTier: nextTier,
      totalViolations: profile.totalViolations + 1,
      highSeverityViolations: nextHighSeverity,
      lastViolationAt: entry.occurredAt,
      unsyncedLedgerCount: profile.unsyncedLedgerCount + 1,
    );

    final ledger = loadLedger(safeId);
    ledger.insert(0, entry);
    await saveLedger(safeId, ledger);
    await saveProfile(updatedProfile);
    return updatedProfile;
  }

  static List<IntegrityLedgerEntry> pendingLedgerEntries(String studentId) {
    return loadLedger(
      studentId,
    ).where((entry) => entry.syncedAt == null).toList();
  }

  static int pendingLedgerCount(String studentId) {
    return pendingLedgerEntries(studentId).length;
  }

  static Future<int> flushPendingLedger({
    required String studentId,
    required Future<bool> Function(List<Map<String, dynamic>>) uploader,
  }) async {
    final safeId = safeStudentId(studentId);
    final pending = pendingLedgerEntries(safeId);
    if (pending.isEmpty) return 0;

    final payload = pending.map((entry) => entry.toMap()).toList();
    var ok = false;
    String? failureReason;

    try {
      ok = await uploader(payload);
      if (!ok) failureReason = 'Uploader returned false.';
    } catch (error) {
      failureReason = error.toString();
    }

    if (!ok) {
      await _markPendingSyncFailure(
        studentId: safeId,
        pendingIds: pending.map((entry) => entry.id).toSet(),
        failureReason: failureReason ?? 'Unknown sync failure.',
      );
      return 0;
    }

    final now = DateTime.now();
    final pendingIds = pending.map((entry) => entry.id).toSet();
    final all = loadLedger(safeId);
    final updated = all.map((entry) {
      if (pendingIds.contains(entry.id)) {
        return entry.copyWith(
          syncedAt: now,
          clearLastSyncError: true,
        );
      }
      return entry;
    }).toList();
    await saveLedger(safeId, updated);

    final remaining = pendingLedgerEntries(safeId).length;
    final profile = loadOrCreateProfile(safeId).copyWith(
      lastSyncedAt: now,
      unsyncedLedgerCount: remaining,
    );
    await saveProfile(profile);
    return pending.length;
  }

  static Future<void> clearAllForStudent(String studentId) async {
    final safeId = safeStudentId(studentId);
    if (_useMemoryStore) {
      _memoryProfiles.remove(_profileKey(safeId));
      _memoryLedgers.remove(_ledgerKey(safeId));
      return;
    }
    await _box.remove(_profileKey(safeId));
    await _box.remove(_ledgerKey(safeId));
  }

  static Object? _readProfilePayload(String studentId) {
    final key = _profileKey(studentId);
    if (_useMemoryStore) return _memoryProfiles[key];
    return _box.read(key);
  }

  static List<dynamic> _readLedgerPayload(String studentId) {
    final key = _ledgerKey(studentId);
    if (_useMemoryStore) return List<Map<String, dynamic>>.from(
          _memoryLedgers[key] ?? const <Map<String, dynamic>>[],
        );
    return (_box.read(key) as List?) ?? const <dynamic>[];
  }

  static Future<void> _writeProfilePayload(
    String studentId,
    Map<String, dynamic> payload,
  ) async {
    final key = _profileKey(studentId);
    if (_useMemoryStore) {
      _memoryProfiles[key] = Map<String, dynamic>.from(payload);
      return;
    }
    await _box.write(key, payload);
  }

  static Future<void> _writeLedgerPayload(
    String studentId,
    List<Map<String, dynamic>> payload,
  ) async {
    final key = _ledgerKey(studentId);
    if (_useMemoryStore) {
      _memoryLedgers[key] = payload
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      return;
    }
    await _box.write(key, payload);
  }

  static Future<void> _markPendingSyncFailure({
    required String studentId,
    required Set<String> pendingIds,
    required String failureReason,
  }) async {
    final all = loadLedger(studentId);
    final updated = all.map((entry) {
      if (!pendingIds.contains(entry.id)) return entry;
      return entry.copyWith(
        syncAttemptCount: entry.syncAttemptCount + 1,
        lastSyncError: failureReason,
      );
    }).toList();
    await saveLedger(studentId, updated);

    final profile = loadOrCreateProfile(studentId).copyWith(
      unsyncedLedgerCount: pendingLedgerEntries(studentId).length,
    );
    await saveProfile(profile);
  }
}
