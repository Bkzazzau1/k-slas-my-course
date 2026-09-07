import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/modules/proctoring/controller/proctoring_controller.dart';
import 'package:my_courses/modules/proctoring/services/live_exam_camera_runtime.dart';
import 'package:my_courses/modules/proctoring/view/live_exam_camera_monitor_host.dart';

class _FakeLiveExamCameraRuntime implements LiveExamCameraRuntime {
  _FakeLiveExamCameraRuntime({this.startResult = true});

  final bool startResult;
  int startCount = 0;
  int stopCount = 0;
  bool active = false;

  @override
  bool get isActive => active;

  @override
  Future<bool> start() async {
    startCount += 1;
    active = startResult;
    return startResult;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    active = false;
  }
}

void main() {
  testWidgets('keeps one local camera runtime for the armed exam route', (
    tester,
  ) async {
    final proctoring = ProctoringController();
    proctoring.examMonitoringArmed.value = true;
    final runtime = _FakeLiveExamCameraRuntime();

    await tester.pumpWidget(
      MaterialApp(
        home: LiveExamCameraMonitorHost(
          enabled: true,
          proctoringController: proctoring,
          runtimeFactory: (_) => runtime,
          child: const Text('live exam'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('live exam'), findsOneWidget);
    expect(runtime.startCount, 1);
    expect(runtime.isActive, isTrue);

    // Rebuilds do not create another camera stream while the runtime is healthy.
    await tester.pump();
    expect(runtime.startCount, 1);

    proctoring.examMonitoringArmed.value = false;
    await tester.pump();
    expect(runtime.stopCount, 1);
    expect(runtime.isActive, isFalse);

    proctoring.examMonitoringArmed.value = true;
    await tester.pump();
    expect(runtime.startCount, 2);
    expect(runtime.isActive, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(runtime.stopCount, 2);
  });

  testWidgets('does not start camera monitoring when the route is disabled', (
    tester,
  ) async {
    final proctoring = ProctoringController();
    proctoring.examMonitoringArmed.value = true;
    final runtime = _FakeLiveExamCameraRuntime();

    await tester.pumpWidget(
      MaterialApp(
        home: LiveExamCameraMonitorHost(
          enabled: false,
          proctoringController: proctoring,
          runtimeFactory: (_) => runtime,
          child: const Text('normal session'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('normal session'), findsOneWidget);
    expect(runtime.startCount, 0);
    expect(runtime.stopCount, 0);
  });
}
