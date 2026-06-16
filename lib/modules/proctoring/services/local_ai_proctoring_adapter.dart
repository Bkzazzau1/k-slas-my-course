import 'dart:async';

import '../../../data/models/integrity_models.dart';
import '../../../data/services/integrity_ledger_service.dart';
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

    unawaited(_appendToLedger(event, message));
  }

  Future<void> _appendToLedger(LocalAiEvent event, String message) async {
    final studentId = IntegrityLedgerService.safeStudentId(event.studentId);
    final sessionId = IntegrityLedgerService.safeSessionId(
      event.sessionId ?? proctoringController.activeSessionId.value,
    );
    final occurredAt = event.timestamp;
    final riskScoreAfter = proctoringController.cumulativeRiskScore.value;
    final riskTierAtEvent = proctoringController.riskTier.value;
    final evidencePayload = <String, dynamic>{
      'event': event.toJson(),
      'message': message,
      'sessionId': sessionId,
      'studentId': studentId,
      'integrityScoreAfter': proctoringController.integrityScore.value,
      'riskScoreAfter': riskScoreAfter,
      'riskTierAtEvent': riskTierAtEvent.name,
    };

    final entry = IntegrityLedgerEntry(
      id: IntegrityLedgerService.nextLedgerId(prefix: event.type.name),
      studentId: studentId,
      sessionId: sessionId,
      occurredAt: occurredAt,
      reason: message,
      penalty: event.riskPoints,
      level: proctoringController.currentLevel.value?.name,
      integrityScoreAfter: proctoringController.integrityScore.value,
      strictStrikesAfter: proctoringController.strictViolationStrikes.value,
      riskTierAtEvent: riskTierAtEvent,
      riskScoreAfter: riskScoreAfter,
      evidenceVault: IntegrityLedgerService.buildEvidenceVaultToken(
        evidencePayload,
      ),
      eventType: event.type.name,
      severity: event.severity.name,
      confidence: event.confidence,
      shouldAlert: event.shouldAlertInvigilator,
      evidencePath: event.evidencePath,
      metadata: event.metadata,
    );

    final profile = await IntegrityLedgerService.appendViolationRecord(
      studentId: studentId,
      entry: entry,
      riskPoints: event.riskPoints,
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
