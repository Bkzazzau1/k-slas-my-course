import 'dart:async';

import '../../../features/local_ai/local_ai.dart';
import '../controller/proctoring_controller.dart';

class LocalAiProctoringAdapter {
  LocalAiProctoringAdapter({
    required this.localAiEngine,
    required this.proctoringController,
  });

  final LocalAiEngine localAiEngine;
  final ProctoringController proctoringController;

  StreamSubscription<LocalAiEvent>? _subscription;

  bool get isRunning => _subscription != null;

  void start() {
    if (_subscription != null) return;
    _subscription = localAiEngine.events.listen(_handleEvent);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handleEvent(LocalAiEvent event) {
    if (event.riskPoints <= 0) return;

    final message = _messageFor(event);
    proctoringController.registerViolation(
      message,
      penalty: event.riskPoints,
      alert: event.shouldAlertInvigilator,
    );
  }

  String _messageFor(LocalAiEvent event) {
    if (event.message != null && event.message!.trim().isNotEmpty) {
      return event.message!;
    }

    switch (event.type) {
      case LocalAiEventType.faceMissing:
        return 'Face missing from camera view.';
      case LocalAiEventType.multipleFacesDetected:
        return 'Multiple faces detected.';
      case LocalAiEventType.phoneDetected:
        return 'Phone detected in camera view.';
      case LocalAiEventType.humanVoiceDetected:
        return 'Human voice detected during the exam.';
      case LocalAiEventType.voiceSourceEstimated:
        return 'External voice source suspected.';
      case LocalAiEventType.tabSwitchDetected:
        return 'Tab switching detected.';
      case LocalAiEventType.appSwitchDetected:
        return 'Application switching detected.';
      case LocalAiEventType.copyPasteDetected:
        return 'Copy or paste activity detected.';
      case LocalAiEventType.remoteDesktopDetected:
        return 'Remote desktop activity detected.';
      case LocalAiEventType.screenSharingDetected:
        return 'Screen sharing activity detected.';
      case LocalAiEventType.multipleMonitorDetected:
        return 'Multiple monitor activity detected.';
      default:
        return 'Local AI proctoring event detected: ${event.type.name}.';
    }
  }
}
