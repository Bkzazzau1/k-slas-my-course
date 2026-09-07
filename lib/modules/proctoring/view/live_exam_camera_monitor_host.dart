import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/proctoring_controller.dart';
import '../services/live_exam_camera_runtime.dart';

typedef LiveExamCameraRuntimeFactory =
    LiveExamCameraRuntime Function(ProctoringController controller);

/// Keeps on-device camera monitoring alive for the full live exam route.
///
/// Section pages are pushed above this host, so the same local camera runtime
/// remains active while the candidate moves between objective, fill-blank and
/// theory sections.
class LiveExamCameraMonitorHost extends StatefulWidget {
  const LiveExamCameraMonitorHost({
    super.key,
    required this.enabled,
    required this.child,
    this.runtimeFactory,
    this.proctoringController,
    this.retryDelay = const Duration(seconds: 5),
  });

  final bool enabled;
  final Widget child;
  final LiveExamCameraRuntimeFactory? runtimeFactory;
  final ProctoringController? proctoringController;
  final Duration retryDelay;

  @override
  State<LiveExamCameraMonitorHost> createState() =>
      _LiveExamCameraMonitorHostState();
}

class _LiveExamCameraMonitorHostState extends State<LiveExamCameraMonitorHost>
    with WidgetsBindingObserver {
  late final ProctoringController _proctoring;
  LiveExamCameraRuntime? _runtime;
  StreamSubscription<bool>? _armedSubscription;
  Timer? _retryTimer;
  bool _starting = false;
  bool _monitoringIssueReported = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _proctoring =
        widget.proctoringController ??
        (Get.isRegistered<ProctoringController>()
            ? Get.find<ProctoringController>()
            : Get.put(ProctoringController(), permanent: true));

    if (widget.enabled) {
      _armedSubscription = _proctoring.examMonitoringArmed.listen((armed) {
        if (armed) {
          unawaited(_ensureMonitoringActive());
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_ensureMonitoringActive());
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiveExamCameraMonitorHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) return;
    if (!widget.enabled) {
      _retryTimer?.cancel();
      unawaited(_runtime?.stop());
      return;
    }
    unawaited(_ensureMonitoringActive());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureMonitoringActive());
    }
  }

  LiveExamCameraRuntime _resolveRuntime() {
    return _runtime ??=
        widget.runtimeFactory?.call(_proctoring) ??
        LocalLiveExamCameraRuntime(proctoringController: _proctoring);
  }

  Future<void> _ensureMonitoringActive() async {
    if (_disposed || !mounted || !widget.enabled || _starting) return;
    if (!_proctoring.examMonitoringArmed.value) return;

    // A room/camera correction flow may temporarily own the camera. Retry after
    // that flow completes rather than competing for the device.
    if (_proctoring.scanRequired.value || _proctoring.scanInProgress.value) {
      _scheduleRetry();
      return;
    }

    final runtime = _resolveRuntime();
    if (runtime.isActive) {
      _monitoringIssueReported = false;
      _retryTimer?.cancel();
      return;
    }

    _starting = true;
    final started = await runtime.start();
    _starting = false;
    if (_disposed || !mounted) return;

    if (started && runtime.isActive) {
      _monitoringIssueReported = false;
      _retryTimer?.cancel();
      return;
    }

    _reportMonitoringIssue();
    _scheduleRetry();
  }

  void _reportMonitoringIssue() {
    if (_monitoringIssueReported) return;
    _monitoringIssueReported = true;

    _proctoring.registerViolation(
      'Camera monitoring is unavailable. Please check camera access and keep the camera connected.',
      penalty: 0,
      alert: true,
      eventType: 'camera_monitoring_unavailable',
      severity: 'high',
      metadata: const <String, Object?>{
        'source': 'live_exam_runtime',
        'monitoring_state': 'unavailable',
      },
    );

    if (!_proctoring.scanRequired.value &&
        !_proctoring.scanInProgress.value &&
        !_proctoring.sessionTerminated.value) {
      _proctoring.forceBackgroundScan(
        'Camera monitoring needs to be restored before continuing.',
      );
    }
  }

  void _scheduleRetry() {
    if (_disposed || !widget.enabled || _retryTimer?.isActive == true) return;
    _retryTimer = Timer(widget.retryDelay, () {
      unawaited(_ensureMonitoringActive());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _armedSubscription?.cancel();
    unawaited(_runtime?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
