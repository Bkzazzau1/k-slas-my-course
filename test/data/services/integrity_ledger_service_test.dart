import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_courses/data/models/integrity_models.dart';
import 'package:my_courses/data/services/integrity_ledger_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() async {
    await IntegrityLedgerService.clearAllForStudent('KASU/CSC/001');
  });

  test('tierForRiskScore should map low/medium/high thresholds', () {
    expect(IntegrityLedgerService.tierForRiskScore(20), IntegrityRiskTier.low);
    expect(
      IntegrityLedgerService.tierForRiskScore(80),
      IntegrityRiskTier.medium,
    );
    expect(
      IntegrityLedgerService.tierForRiskScore(180),
      IntegrityRiskTier.high,
    );
  });

  test('riskPointsForViolation should be severe for terminal violations', () {
    final terminal = IntegrityLedgerService.riskPointsForViolation(
      reason: 'Terminal violation: unauthorized peripheral',
      penalty: 100,
    );
    final minor = IntegrityLedgerService.riskPointsForViolation(
      reason: 'Physical movement detected.',
      penalty: 0,
    );

    expect(terminal, greaterThan(minor));
  });

  test('appendViolationRecord should persist pending proctoring event', () async {
    final entry = _entry(
      eventType: 'phoneDetected',
      severity: 'high',
      riskScoreAfter: 30,
    );

    final profile = await IntegrityLedgerService.appendViolationRecord(
      studentId: entry.studentId,
      entry: entry,
      riskPoints: 30,
    );

    expect(profile.totalViolations, 1);
    expect(profile.unsyncedLedgerCount, 1);
    expect(profile.riskTier, IntegrityRiskTier.low);

    final pending = IntegrityLedgerService.pendingLedgerEntries(entry.studentId);
    expect(pending, hasLength(1));
    expect(pending.single.eventType, 'phoneDetected');
    expect(pending.single.severity, 'high');
    expect(pending.single.syncedAt, isNull);
  });

  test('flushPendingLedger should mark uploaded events as synced', () async {
    final entry = _entry(
      eventType: 'multipleFacesDetected',
      severity: 'high',
      riskScoreAfter: 25,
    );
    await IntegrityLedgerService.appendViolationRecord(
      studentId: entry.studentId,
      entry: entry,
      riskPoints: 25,
    );

    final uploaded = await IntegrityLedgerService.flushPendingLedger(
      studentId: entry.studentId,
      uploader: (payload) async {
        expect(payload, hasLength(1));
        expect(payload.single['eventType'], 'multipleFacesDetected');
        return true;
      },
    );

    expect(uploaded, 1);
    expect(
      IntegrityLedgerService.pendingLedgerEntries(entry.studentId),
      isEmpty,
    );
    expect(
      IntegrityLedgerService.loadLedger(entry.studentId).single.syncedAt,
      isNotNull,
    );
  });

  test('flushPendingLedger should keep failed events pending with retry state', () async {
    final entry = _entry(
      eventType: 'screenSharingDetected',
      severity: 'critical',
      riskScoreAfter: 50,
    );
    await IntegrityLedgerService.appendViolationRecord(
      studentId: entry.studentId,
      entry: entry,
      riskPoints: 50,
    );

    final uploaded = await IntegrityLedgerService.flushPendingLedger(
      studentId: entry.studentId,
      uploader: (_) async => false,
    );

    expect(uploaded, 0);
    final pending = IntegrityLedgerService.pendingLedgerEntries(entry.studentId);
    expect(pending, hasLength(1));
    expect(pending.single.syncAttemptCount, 1);
    expect(pending.single.lastSyncError, isNotNull);
  });
}

IntegrityLedgerEntry _entry({
  required String eventType,
  required String severity,
  required int riskScoreAfter,
}) {
  return IntegrityLedgerEntry(
    id: IntegrityLedgerService.nextLedgerId(prefix: eventType),
    studentId: 'KASU/CSC/001',
    sessionId: 'session-001',
    occurredAt: DateTime.now(),
    reason: 'Test proctoring event: $eventType',
    penalty: riskScoreAfter,
    level: 'highStakesExam',
    integrityScoreAfter: (100 - riskScoreAfter).clamp(0, 100).toInt(),
    strictStrikesAfter: 0,
    riskTierAtEvent: IntegrityLedgerService.tierForRiskScore(riskScoreAfter),
    riskScoreAfter: riskScoreAfter,
    evidenceVault: IntegrityLedgerService.buildEvidenceVaultToken({
      'eventType': eventType,
      'severity': severity,
    }),
    eventType: eventType,
    severity: severity,
    confidence: 0.86,
    shouldAlert: severity == 'high' || severity == 'critical',
    metadata: <String, Object?>{'source': 'test'},
  );
}
