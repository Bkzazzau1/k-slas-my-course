import '../models/integrity_models.dart';
import 'integrity_ledger_service.dart';

class IntegrityEventWriter {
  const IntegrityEventWriter._();

  static Future<IntegrityRiskProfile> write({
    required String studentId,
    required String sessionId,
    required String reason,
    required int points,
    required String? level,
    required int scoreAfter,
    required int strikesAfter,
    required IntegrityRiskTier tier,
    required int riskAfter,
    required String type,
    required String severity,
    double? confidence,
    bool alert = false,
    String? filePath,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    final safeStudentId = IntegrityLedgerService.safeStudentId(studentId);
    final safeSessionId = IntegrityLedgerService.safeSessionId(sessionId);
    final entry = IntegrityLedgerEntry(
      id: IntegrityLedgerService.nextLedgerId(prefix: type),
      studentId: safeStudentId,
      sessionId: safeSessionId,
      occurredAt: DateTime.now(),
      reason: reason,
      penalty: points,
      level: level,
      integrityScoreAfter: scoreAfter,
      strictStrikesAfter: strikesAfter,
      riskTierAtEvent: tier,
      riskScoreAfter: riskAfter,
      evidenceVault: IntegrityLedgerService.buildEvidenceVaultToken({
        'type': type,
        'severity': severity,
        'reason': reason,
        'points': points,
        'studentId': safeStudentId,
        'sessionId': safeSessionId,
        'data': data,
      }),
      eventType: type,
      severity: severity,
      confidence: confidence,
      shouldAlert: alert,
      evidencePath: filePath,
      metadata: data,
    );

    return IntegrityLedgerService.appendViolationRecord(
      studentId: safeStudentId,
      entry: entry,
      riskPoints: points,
    );
  }
}
