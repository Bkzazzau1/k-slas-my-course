import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/integrity_models.dart';

class IntegrityLedgerService {
  IntegrityLedgerService._();

  static final _box = GetStorage();
  static const _profilePrefix = 'integrity.profile';
  static const _ledgerPrefix = 'integrity.ledger';
  static const _maxLedgerEntries = 1000;

  static String _profileKey(String studentId) => '$_profilePrefix.$studentId';
  static String _ledgerKey(String studentId) => '$_ledgerPrefix.$studentId';

  static IntegrityRiskProfile loadOrCreateProfile(String studentId) {
    final raw = _box.read(_profileKey(studentId));
    if (raw is Map) {
      return IntegrityRiskProfile.fromMap(Map<String, dynamic>.from(raw));
    }
    return IntegrityRiskProfile(
      studentId: studentId,
      riskTier: IntegrityRiskTier.low,
      cumulativeRiskScore: 0,
      totalViolations: 0,
      highSeverityViolations: 0,
      unsyncedLedgerCount: 0,
    );
  }

  static Future<void> saveProfile(IntegrityRiskProfile profile) {
    return _box.write(_profileKey(profile.studentId), profile.toMap());
  }

  static List<IntegrityLedgerEntry> loadLedger(String studentId) {
    final raw = (_box.read(_ledgerKey(studentId)) as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => IntegrityLedgerEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveLedger(
    String studentId,
    List<IntegrityLedgerEntry> entries,
  ) {
    return _box.write(
      _ledgerKey(studentId),
      entries.take(_maxLedgerEntries).map((e) => e.toMap()).toList(),
    );
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
    } else if (lower.contains('recording') ||
        lower.contains('screenshot') ||
        lower.contains('mirroring')) {
      base = 22;
    } else if (lower.contains('multiple people') ||
        lower.contains('speech') ||
        lower.contains('peripheral') ||
        lower.contains('network')) {
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
    final profile = loadOrCreateProfile(studentId);
    final nextRisk = profile.cumulativeRiskScore + riskPoints;
    final nextTier = tierForRiskScore(nextRisk);
    final nextHighSeverity =
        profile.highSeverityViolations + (riskPoints >= 20 ? 1 : 0);

    final updatedProfile = profile.copyWith(
      cumulativeRiskScore: nextRisk,
      riskTier: nextTier,
      totalViolations: profile.totalViolations + 1,
      highSeverityViolations: nextHighSeverity,
      lastViolationAt: entry.occurredAt,
      unsyncedLedgerCount: profile.unsyncedLedgerCount + 1,
    );

    final ledger = loadLedger(studentId);
    ledger.insert(0, entry);
    await saveLedger(studentId, ledger);
    await saveProfile(updatedProfile);
    return updatedProfile;
  }

  static List<IntegrityLedgerEntry> pendingLedgerEntries(String studentId) {
    return loadLedger(
      studentId,
    ).where((entry) => entry.syncedAt == null).toList();
  }

  static Future<int> flushPendingLedger({
    required String studentId,
    required Future<bool> Function(List<Map<String, dynamic>>) uploader,
  }) async {
    final pending = pendingLedgerEntries(studentId);
    if (pending.isEmpty) return 0;

    final payload = pending.map((e) => e.toMap()).toList();
    final ok = await uploader(payload);
    if (!ok) return 0;

    final now = DateTime.now();
    final pendingIds = pending.map((e) => e.id).toSet();
    final all = loadLedger(studentId);
    final updated = all.map((entry) {
      if (pendingIds.contains(entry.id)) {
        return entry.copyWith(syncedAt: now);
      }
      return entry;
    }).toList();
    await saveLedger(studentId, updated);

    final profile = loadOrCreateProfile(
      studentId,
    ).copyWith(lastSyncedAt: now, unsyncedLedgerCount: 0);
    await saveProfile(profile);
    return pending.length;
  }

  static Future<void> clearAllForStudent(String studentId) async {
    if (Get.testMode) return;
    await _box.remove(_profileKey(studentId));
    await _box.remove(_ledgerKey(studentId));
  }
}
