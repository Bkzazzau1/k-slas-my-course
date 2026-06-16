import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_courses/data/services/integrity_ledger_service.dart';
import 'package:my_courses/modules/proctoring/controller/proctoring_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProctoringController controller;

  setUp(() {
    Get.testMode = true;
    controller = ProctoringController();
    controller.currentLevel.value = AssessmentIntegrityLevel.highStakesExam;
    controller.shieldActive.value = true;
  });

  tearDown(() async {
    await controller.stopSession(silent: true);
    controller.onClose();
  });

  test(
    'Should increment violation count and terminate on strict strike limit',
    () {
      controller.handleViolation('multiple people');
      expect(controller.strictViolationStrikes.value, 1);
      expect(controller.scanRequired.value, true);
      expect(controller.isExamPaused.value, true);
      expect(controller.sessionTerminated.value, false);

      controller.armExamMonitoring();
      controller.handleViolation('background speech');
      expect(controller.strictViolationStrikes.value, 2);
      expect(controller.sessionTerminated.value, true);
      expect(
        controller.terminationReason.value,
        contains('Repeated strict violation'),
      );
    },
  );

  test('Should resume paused exam only after scan checks pass', () async {
    controller.handleViolation('multiple people');
    expect(controller.isExamPaused.value, true);

    controller.scanRotationConfirmed.value = true;
    controller.scanAiChecksPassed.value = true;
    await controller.resumeExamAfterScan();

    expect(controller.isExamPaused.value, false);
  });

  test(
    'Should terminate session immediately on terminal hardware detection',
    () {
      controller.registerViolation(
        'Terminal violation: unauthorized peripheral HDMI Display',
        penalty: 100,
      );

      expect(controller.sessionTerminated.value, true);
      expect(controller.integrityScore.value, 0);
      expect(
        controller.terminationReason.value,
        contains('Terminal violation'),
      );
    },
  );

  test(
    'Should ignore background violations until exam startup scan completes',
    () {
      controller.examStartupScanCompleted.value = false;

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(controller.appInBackground.value, false);
      expect(controller.violationCount.value, 0);

      controller.examStartupScanCompleted.value = true;
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(controller.appInBackground.value, true);
      expect(controller.violationCount.value, 1);
      expect(
        controller.violationLog.join(' '),
        contains('App moved away from protected session'),
      );
    },
  );

  test('controller violations should be written to integrity ledger', () async {
    Get.testMode = true;
    await IntegrityLedgerService.clearAllForStudent('KASU/CSC/001');

    final controller = ProctoringController();

    await controller.startSession(
      level: AssessmentIntegrityLevel.highStakesExam,
      studentId: 'KASU/CSC/001',
    );

    controller.registerViolation(
      'Environment scan rejected: lighting below strict threshold.',
      penalty: 15,
      alert: false,
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    final pending = IntegrityLedgerService.pendingLedgerEntries('KASU/CSC/001');

    expect(pending, isNotEmpty);
    expect(pending.first.eventType, 'environmentScanRejected');
    expect(pending.first.severity, 'medium');
    expect(pending.first.metadata['source'], 'proctoring_controller');

    await controller.stopSession(silent: true);
  });
}
