import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/modules/proctoring/services/continuous_exam_monitoring_policy.dart';

void main() {
  test('look away policy allows four warnings and blocks on fifth', () {
    const policy = ContinuousExamMonitoringPolicy();

    var warnings = 0;
    for (var i = 0; i < 4; i++) {
      final result = policy.evaluateGaze(
        lookingAtScreen: false,
        currentWarnings: warnings,
      );
      warnings = result.warningCount;
      expect(result.allowedToContinue, true);
    }

    final fifth = policy.evaluateGaze(
      lookingAtScreen: false,
      currentWarnings: warnings,
    );

    expect(fifth.warningCount, 5);
    expect(fifth.allowedToContinue, false);
  });
}
