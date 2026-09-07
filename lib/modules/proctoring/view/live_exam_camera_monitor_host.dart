import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/integrity_event_writer.dart';
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
      _startArmedListener();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_ensureMonitoringActive());
      });
    }
  }

  void _startArmedListener() {
    if (_armedSubscription != null) return;
    _armedSubscription = _proctoring.examMonitoringArmed.listen((armed) {
      if (armed) {
        unawaited(_ensureMonitoringActive());
      } else {
        _retryTimer?.cancel();
        unawaited(_runtime?.stop());
      }
    });
  }

  void _stopArmedListener() {
    final subscription = _armedSubscription;
    _armedSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  @override
  void didUpdateWidget(covariant LiveExamCameraMonitorHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) return;
    if (!widget.enabled) {
      _retryTimer?.cancel();
      _stopArmedListener();
      unawaited(_runtime?.stop());
      return;
    }
    _startArmedListener();
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

    await _reportMonitoringIssue();
    _scheduleRetry();
  }

  Future<void> _reportMonitoringIssue() async {
    if (_monitoringIssueReported) return;
    _monitoringIssueReported = true;

    const message =
        'Camera monitoring is unavailable. Please check camera access and keep the camera connected.';
    try {
      final profile = await IntegrityEventWriter.write(
        studentId: _proctoring.activeStudentId.value,
        sessionId: _proctoring.activeSessionId.value,
        reason: message,
        points: 0,
        level: _proctoring.currentLevel.value?.name,
        scoreAfter: _proctoring.integrityScore.value,
        strikesAfter: _proctoring.strictViolationStrikes.value,
        tier: _proctoring.riskTier.value,
        riskAfter: _proctoring.cumulativeRiskScore.value,
        type: 'camera_monitoring_unavailable',
        severity: 'high',
        alert: true,
        data: const <String, Object?>{
          'source': 'live_exam_runtime',
          'monitoring_state': 'unavailable',
          'technical_condition': true,
        },
      );
      _proctoring.pendingLedgerSyncCount.value = profile.unsyncedLedgerCount;
    } catch (_) {
      // Correction must still happen even if the local ledger is temporarily
      // unavailable. The retry path will attempt monitoring again.
    }

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
    _stopArmedListener();
    unawaited(_runtime?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
