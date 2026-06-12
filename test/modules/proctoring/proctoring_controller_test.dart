import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
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
    'Should increment violation count and escalate strike logic to termination',
    () {
      controller.handleViolation('multiple people');
      expect(controller.strictViolationStrikes.value, 1);
      expect(controller.scanRequired.value, true);
      expect(controller.isExamPaused.value, true);
      expect(controller.sessionTerminated.value, false);

      controller.armExamMonitoring();
      controller.handleViolation('background speech');
      expect(controller.strictViolationStrikes.value, 2);
      expect(controller.sessionTerminated.value, false);

      controller.handleViolation('gaze diversion');
      expect(controller.strictViolationStrikes.value, 3);
      expect(controller.sessionTerminated.value, true);
      expect(
        controller.terminationReason.value,
        contains('Maximum violations reached'),
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
        contains('background during high-stakes exam'),
      );
    },
  );
}
