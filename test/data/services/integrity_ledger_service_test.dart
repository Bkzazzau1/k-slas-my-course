import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/data/models/integrity_models.dart';
import 'package:my_courses/data/services/integrity_ledger_service.dart';

void main() {
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
}
