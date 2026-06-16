import 'dart:async';

import '../../../data/services/integrity_event_writer.dart';
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
      persistToLedger: false,
    );

    unawaited(_writeEvent(event, message));
  }

  Future<void> _writeEvent(LocalAiEvent event, String message) async {
    final profile = await IntegrityEventWriter.write(
      studentId: event.studentId ?? proctoringController.activeStudentId.value,
      sessionId: event.sessionId ?? proctoringController.activeSessionId.value,
      reason: message,
      points: event.riskPoints,
      level: proctoringController.currentLevel.value?.name,
      scoreAfter: proctoringController.integrityScore.value,
      strikesAfter: proctoringController.strictViolationStrikes.value,
      tier: proctoringController.riskTier.value,
      riskAfter: proctoringController.cumulativeRiskScore.value,
      type: event.type.name,
      severity: event.severity.name,
      confidence: event.confidence,
      alert: event.shouldAlertInvigilator,
      filePath: event.evidencePath,
      data: <String, Object?>{'source': 'local_ai', 'rawEvent': event.toJson()},
    );
    proctoringController.pendingLedgerSyncCount.value =
        profile.unsyncedLedgerCount;
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
        return 'Human voice detected during the session.';
      case LocalAiEventType.voiceSourceEstimated:
        return 'External voice source suspected.';
      case LocalAiEventType.tabSwitchDetected:
        return 'Tab switching detected.';
      case LocalAiEventType.appSwitchDetected:
        return 'Application switching detected.';
      case LocalAiEventType.copyPasteDetected:
        return 'Copy or paste activity detected.';
      case LocalAiEventType.remoteDesktopDetected:
      case LocalAiEventType.screenSharingDetected:
        return 'External screen-control activity detected.';
      case LocalAiEventType.multipleMonitorDetected:
        return 'Multiple display activity detected.';
      default:
        return 'Local integrity event detected: ${event.type.name}.';
    }
  }
}
