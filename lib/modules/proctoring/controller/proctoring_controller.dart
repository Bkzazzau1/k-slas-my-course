import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/integrity_models.dart';
import '../../../data/services/integrity_event_writer.dart';
import '../../../data/services/integrity_ledger_service.dart';
import '../view/environment_scan_overlay.dart';
import '../view/exam_start_dialog.dart';

enum AssessmentIntegrityLevel {
  objectiveQuiz,
  gradedAssessment,
  highStakesExam,
}

class ProctoringController extends GetxController with WidgetsBindingObserver {
  final isPhoneMoved = false.obs;
  final isScreenRecorded = false.obs;
  final appInBackground = false.obs;
  final integrityScore = 100.obs;
  final violationCount = 0.obs;
  final copyPasteBlocked = false.obs;
  final shieldActive = false.obs;
  final currentLevel = Rxn<AssessmentIntegrityLevel>();
  final violationLog = <String>[].obs;

  final ultrasoundWatchdogActive = false.obs;
  final ultrasoundDbfs = RxnDouble();
  final accessoryWatchdogActive = false.obs;

  final multiFaceStrikes = 0.obs;
  final speechStrikes = 0.obs;
  final gazeWarnings = 0.obs;
  final strictViolationStrikes = 0.obs;
  final backgroundExitStrikes = 0.obs;

  final sessionTerminated = false.obs;
  final terminationReason = ''.obs;
  final examMonitoringArmed = false.obs;

  final scanRequired = false.obs;
  final scanInProgress = false.obs;
  final scanProgress = 0.0.obs;
  final scanReason = ''.obs;
  final scanAiChecksPassed = false.obs;
  final scanForbiddenObjects = <String>[].obs;
  final scanLightingScore = 0.0.obs;
  final scanRotationConfirmed = false.obs;
  final scanUnauthorizedItemsReviewed = false.obs;
  final isExamPaused = false.obs;
  final examStartupScanCompleted = false.obs;

  final riskTier = IntegrityRiskTier.low.obs;
  final cumulativeRiskScore = 0.obs;
  final pendingLedgerSyncCount = 0.obs;
  final activeSessionId = ''.obs;
  final activeStudentId = IntegrityLedgerService.defaultStudentId.obs;

  static const double _minimumLightingScore = 0.55;
  static const int _strictStrikeLimit = 2;
  static const int _multiFaceStrikeLimit = 2;
  static const int _integrityTerminationScore = 40;
  static const MethodChannel _clipboardChannel = MethodChannel(
    'k_slas/clipboard',
  );

  Timer? _scanTimer;
  VoidCallback? _onAutoSubmit;
  VoidCallback? _onSessionTerminated;
  VoidCallback? _onPauseExamTimer;
  VoidCallback? _onResumeExamTimer;
  Future<bool> Function(List<Map<String, dynamic>> payload)?
  _integrityLedgerUploader;
  Completer<bool>? _startupEnvironmentScanCompleter;
  bool _environmentDialogOpen = false;
  bool _terminationHandled = false;
  bool _autoSubmitted = false;

  double get minimumScanLightingScore => _minimumLightingScore;
  bool get _isStrictSession =>
      currentLevel.value == AssessmentIntegrityLevel.gradedAssessment ||
      currentLevel.value == AssessmentIntegrityLevel.highStakesExam;

  void registerExamTimerHooks({
    VoidCallback? onPauseTimer,
    VoidCallback? onResumeTimer,
  }) {
    _onPauseExamTimer = onPauseTimer;
    _onResumeExamTimer = onResumeTimer;
  }

  void clearExamTimerHooks() {
    _onPauseExamTimer = null;
    _onResumeExamTimer = null;
  }

  void configureIntegrityLedgerUploader(
    Future<bool> Function(List<Map<String, dynamic>> payload) uploader,
  ) {
    _integrityLedgerUploader = uploader;
  }

  Future<void> syncIntegrityLedger({String? studentId}) async {
    final safeStudentId = IntegrityLedgerService.safeStudentId(
      studentId ?? activeStudentId.value,
    );

    if (_integrityLedgerUploader == null) {
      pendingLedgerSyncCount.value = IntegrityLedgerService.pendingLedgerCount(
        safeStudentId,
      );
      return;
    }

    await IntegrityLedgerService.flushPendingLedger(
      studentId: safeStudentId,
      uploader: _integrityLedgerUploader!,
    );

    pendingLedgerSyncCount.value = IntegrityLedgerService.pendingLedgerCount(
      safeStudentId,
    );
  }

  Future<void> startSession({
    required AssessmentIntegrityLevel level,
    String? studentId,
    VoidCallback? onAutoSubmit,
    VoidCallback? onSessionTerminated,
  }) async {
    if (shieldActive.value && currentLevel.value == level) {
      _onAutoSubmit = onAutoSubmit;
      _onSessionTerminated = onSessionTerminated;
      return;
    }

    await stopSession(silent: true, closeOverlay: false);
    WidgetsBinding.instance.addObserver(this);

    currentLevel.value = level;
    shieldActive.value = true;
    integrityScore.value = 100;
    violationCount.value = 0;
    cumulativeRiskScore.value = 0;
    riskTier.value = IntegrityRiskTier.low;
    violationLog.clear();
    copyPasteBlocked.value = level != AssessmentIntegrityLevel.objectiveQuiz;
    sessionTerminated.value = false;
    terminationReason.value = '';
    examMonitoringArmed.value =
        level != AssessmentIntegrityLevel.highStakesExam;
    activeSessionId.value =
        '${DateTime.now().millisecondsSinceEpoch}-${level.name}';
    activeStudentId.value = IntegrityLedgerService.safeStudentId(studentId);
    pendingLedgerSyncCount.value = IntegrityLedgerService.pendingLedgerCount(
      activeStudentId.value,
    );
    _terminationHandled = false;
    _autoSubmitted = false;
    _onAutoSubmit = onAutoSubmit;
    _onSessionTerminated = onSessionTerminated;
    strictViolationStrikes.value = 0;
    multiFaceStrikes.value = 0;
    speechStrikes.value = 0;
    gazeWarnings.value = 0;
    backgroundExitStrikes.value = 0;

    _resetScanState(clearStartup: true);
  }

  bool hasActiveSessionFor(AssessmentIntegrityLevel level) {
    return shieldActive.value && currentLevel.value == level;
  }

  void attachSessionCallbacks({
    VoidCallback? onAutoSubmit,
    VoidCallback? onSessionTerminated,
  }) {
    _onAutoSubmit = onAutoSubmit;
    _onSessionTerminated = onSessionTerminated;
  }

  Future<void> stopSession({
    bool silent = false,
    bool closeOverlay = true,
  }) async {
    WidgetsBinding.instance.removeObserver(this);
    _scanTimer?.cancel();
    _scanTimer = null;
    _resolveStartupEnvironmentScan(success: false);
    if (closeOverlay) _closeEnvironmentScanOverlayIfNeeded();

    _onAutoSubmit = null;
    _onSessionTerminated = null;
    clearExamTimerHooks();
    _autoSubmitted = false;
    _terminationHandled = false;
    copyPasteBlocked.value = false;
    appInBackground.value = false;
    isPhoneMoved.value = false;
    isScreenRecorded.value = false;
    shieldActive.value = false;
    currentLevel.value = null;
    sessionTerminated.value = false;
    terminationReason.value = '';
    examMonitoringArmed.value = false;
    isExamPaused.value = false;
    activeSessionId.value = '';
    activeStudentId.value = IntegrityLedgerService.defaultStudentId;
    strictViolationStrikes.value = 0;
    multiFaceStrikes.value = 0;
    speechStrikes.value = 0;
    gazeWarnings.value = 0;
    backgroundExitStrikes.value = 0;
    _resetScanState(clearStartup: true);

    if (!silent) {
      _logViolation('Proctoring session closed.', penalty: 0, alert: false);
    }
  }

  Future<bool> startExamSequence(
    String examId, {
    String? studentId,
    VoidCallback? onVerified,
  }) async {
    await startSession(
      level: AssessmentIntegrityLevel.highStakesExam,
      studentId: studentId,
    );
    final verified =
        await Get.dialog<bool>(
          ExamStartDialog(examId: examId),
          barrierDismissible: false,
        ) ??
        false;

    if (!verified) {
      _logViolation(
        'Exam start sequence failed. Launch blocked.',
        penalty: 25,
        alert: true,
      );
      await stopSession(silent: true);
      return false;
    }

    if (!examStartupScanCompleted.value) {
      _logViolation(
        'Exam launch blocked: environment scan was not completed.',
        penalty: 25,
        alert: true,
      );
      await stopSession(silent: true);
      return false;
    }

    armExamMonitoring();
    onVerified?.call();
    return true;
  }

  Future<bool> startAssessmentSequence(
    String assessmentId, {
    String? studentId,
    VoidCallback? onVerified,
    VoidCallback? onAutoSubmit,
    VoidCallback? onSessionTerminated,
  }) async {
    await startSession(
      level: AssessmentIntegrityLevel.gradedAssessment,
      studentId: studentId,
      onAutoSubmit: onAutoSubmit,
      onSessionTerminated: onSessionTerminated,
    );

    final verified =
        await Get.dialog<bool>(
          ExamStartDialog(examId: assessmentId, sessionLabel: 'Assessment'),
          barrierDismissible: false,
        ) ??
        false;

    if (!verified) {
      _logViolation(
        'Graded assessment verification failed. Launch blocked.',
        penalty: 25,
        alert: true,
      );
      await stopSession(silent: true);
      return false;
    }

    if (!examStartupScanCompleted.value) {
      _logViolation(
        'Graded assessment blocked: environment scan was not completed.',
        penalty: 25,
        alert: true,
      );
      await stopSession(silent: true);
      return false;
    }

    armExamMonitoring();
    onVerified?.call();
    return true;
  }

  Future<bool> ensureFortressReady() async {
    shieldActive.value = true;
    if (_isStrictSession) copyPasteBlocked.value = true;
    return true;
  }

  Future<bool> verifyIdentityAndEnvironment() async {
    requestEnvironmentScan(
      'Complete the live environment scan before continuing.',
    );
    _startupEnvironmentScanCompleter = Completer<bool>();
    return _startupEnvironmentScanCompleter!.future.timeout(
      const Duration(minutes: 4),
      onTimeout: () {
        _logViolation('Environment scan timed out.', penalty: 20, alert: true);
        return false;
      },
    );
  }

  Future<bool> verifyAcousticTether() async {
    ultrasoundWatchdogActive.value = true;
    ultrasoundDbfs.value = -32.0;
    return true;
  }

  void armExamMonitoring() {
    examMonitoringArmed.value = true;
    isExamPaused.value = false;
    _onResumeExamTimer?.call();
  }

  Future<void> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      await _clipboardChannel.invokeMethod<void>('clear');
    } catch (_) {}
  }

  void registerViolation(
    String reason, {
    int penalty = 0,
    bool alert = false,
    bool persistToLedger = true,
    String? eventType,
    String? severity,
    double? confidence,
    String? evidencePath,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    if (reason.toLowerCase().startsWith('terminal violation')) {
      _terminateSession(
        reason,
        persistToLedger: persistToLedger,
        eventType: eventType ?? 'terminalViolation',
        severity: severity ?? 'critical',
        confidence: confidence,
        evidencePath: evidencePath,
        metadata: metadata,
      );
      return;
    }

    final effectivePenalty = _isStrictSession && penalty == 0 ? 8 : penalty;

    _logViolation(
      reason,
      penalty: effectivePenalty,
      alert: alert || _isStrictSession,
      persistToLedger: persistToLedger,
      eventType: eventType,
      severity: severity,
      confidence: confidence,
      evidencePath: evidencePath,
      metadata: metadata,
    );

    _terminateIfIntegrityTooLow(reason);
  }

  void handleViolation(String type) {
    strictViolationStrikes.value += 1;
    _logViolation(
      'Strict violation: unauthorized $type detected.',
      penalty: 25,
      alert: true,
    );
    if (strictViolationStrikes.value >= _strictStrikeLimit) {
      _terminateSession('Repeated strict violation: $type');
      return;
    }
    forceBackgroundScan(
      'Unauthorized $type detected. Complete a fresh environment scan before continuing.',
    );
  }

  Future<void> verifyNetworkIntegrity() async {
    if (_isStrictSession && !shieldActive.value) {
      _terminateSession('Security shield is not active.');
    }
  }

  void processDetectedFaces(List<dynamic> faces, {bool includeGaze = false}) {
    if (!_isStrictSession) return;
    if (faces.length > 1) {
      multiFaceStrikes.value += 1;
      _logViolation(
        'Multiple faces detected (${multiFaceStrikes.value}/$_multiFaceStrikeLimit).',
        penalty: 20,
        alert: true,
      );
      if (multiFaceStrikes.value >= _multiFaceStrikeLimit) {
        _terminateSession('Repeated multiple-face detection.');
        return;
      }
      forceBackgroundScan(
        'Multiple faces detected. Clear the environment and rescan.',
      );
    }
  }

  Future<void> registerEnvironmentFrameAnalysis({
    required List<String> objectLabels,
    required double lightingScore,
    required bool rotationCovered,
  }) async {
    if (!scanRequired.value) return;
    scanLightingScore.value = lightingScore.clamp(0.0, 1.0);
    if (rotationCovered) scanRotationConfirmed.value = true;
    final forbidden = objectLabels
        .where((label) {
          final lower = label.toLowerCase();
          return lower.contains('phone') ||
              lower.contains('mobile') ||
              lower.contains('tablet') ||
              lower.contains('laptop') ||
              lower.contains('monitor') ||
              lower.contains('screen') ||
              lower.contains('television') ||
              lower.contains('headphone') ||
              lower.contains('earphone') ||
              lower.contains('book') ||
              lower.contains('paper') ||
              lower.contains('note');
        })
        .toSet()
        .toList();
    scanForbiddenObjects.assignAll(forbidden);
  }

  void requestEnvironmentScan(String reason) {
    _forceEnvironmentScan(reason: reason);
  }

  void forceBackgroundScan(String reason) {
    _forceEnvironmentScan(reason: reason);
  }

  Future<void> completeEnvironmentScan() async {
    if (scanProgress.value < 1.0) return;
    if (!scanRotationConfirmed.value) {
      _logViolation(
        'Environment scan rejected: full room rotation not confirmed.',
        penalty: 15,
        alert: true,
      );
      return;
    }
    if (!scanUnauthorizedItemsReviewed.value) {
      _logViolation(
        'Environment scan rejected: unauthorized material scan not confirmed.',
        penalty: 15,
        alert: true,
      );
      return;
    }
    if (scanLightingScore.value < _minimumLightingScore) {
      _logViolation(
        'Environment scan rejected: lighting below strict threshold.',
        penalty: 15,
        alert: true,
      );
      return;
    }
    if (scanForbiddenObjects.isNotEmpty) {
      _logViolation(
        'Environment scan rejected: unauthorized item detected (${scanForbiddenObjects.join(', ')}).',
        penalty: 25,
        alert: true,
      );
      return;
    }

    _scanTimer?.cancel();
    _scanTimer = null;
    scanAiChecksPassed.value = true;
    scanRequired.value = false;
    scanInProgress.value = false;
    examStartupScanCompleted.value = true;
    _resumeExamClock();
    _resolveStartupEnvironmentScan(success: true);
    _logViolation(
      'Environment scan completed successfully.',
      penalty: 0,
      alert: false,
    );
  }

  Future<void> resumeExamAfterScan() async {
    if (!(scanAiChecksPassed.value && scanRotationConfirmed.value)) return;
    _resumeExamClock();
    _closeEnvironmentScanOverlayIfNeeded();
  }

  void _forceEnvironmentScan({required String reason}) {
    if (currentLevel.value == AssessmentIntegrityLevel.objectiveQuiz) return;
    scanReason.value = reason;
    scanRequired.value = true;
    scanInProgress.value = true;
    scanProgress.value = 0;
    scanAiChecksPassed.value = false;
    scanForbiddenObjects.clear();
    scanLightingScore.value = 0;
    scanRotationConfirmed.value = false;
    scanUnauthorizedItemsReviewed.value = false;
    _pauseExamClock();
    _startScanProgressTimer();

    if (_environmentDialogOpen || Get.context == null) return;
    _environmentDialogOpen = true;
    Get.dialog<void>(
      const EnvironmentScanOverlay(),
      barrierDismissible: false,
    ).whenComplete(() {
      _environmentDialogOpen = false;
    });
  }

  void _startScanProgressTimer() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!scanRequired.value || !scanInProgress.value) return;
      if (scanProgress.value >= 1.0 &&
          scanRotationConfirmed.value &&
          scanUnauthorizedItemsReviewed.value) {
        scanInProgress.value = false;
      }
    });
  }

  void _resetScanState({required bool clearStartup}) {
    _scanTimer?.cancel();
    _scanTimer = null;
    scanRequired.value = false;
    scanInProgress.value = false;
    scanProgress.value = 0;
    scanReason.value = '';
    scanAiChecksPassed.value = false;
    scanForbiddenObjects.clear();
    scanLightingScore.value = 0;
    scanRotationConfirmed.value = false;
    scanUnauthorizedItemsReviewed.value = false;
    if (clearStartup) examStartupScanCompleted.value = false;
  }

  void _pauseExamClock() {
    if (isExamPaused.value) return;
    isExamPaused.value = true;
    _onPauseExamTimer?.call();
  }

  void _resumeExamClock({bool notifyTimer = true}) {
    if (!isExamPaused.value) return;
    isExamPaused.value = false;
    if (notifyTimer) _onResumeExamTimer?.call();
  }

  void _resolveStartupEnvironmentScan({required bool success}) {
    final completer = _startupEnvironmentScanCompleter;
    _startupEnvironmentScanCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
  }

  void _closeEnvironmentScanOverlayIfNeeded() {
    if (_environmentDialogOpen && (Get.isDialogOpen ?? false)) {
      Get.back<void>();
    }
    _environmentDialogOpen = false;
  }

  void _terminateSession(
    String reason, {
    bool persistToLedger = true,
    String? eventType,
    String? severity,
    double? confidence,
    String? evidencePath,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    if (_terminationHandled) return;

    _terminationHandled = true;
    sessionTerminated.value = true;
    terminationReason.value = reason;
    _resolveStartupEnvironmentScan(success: false);

    _logViolation(
      'Session terminated: $reason',
      penalty: 100,
      alert: false,
      persistToLedger: persistToLedger,
      eventType: eventType ?? 'sessionTerminated',
      severity: severity ?? 'critical',
      confidence: confidence,
      evidencePath: evidencePath,
      metadata: metadata,
    );

    if (!_autoSubmitted) {
      _autoSubmitted = true;
      _onAutoSubmit?.call();
    }
    _onSessionTerminated?.call();
  }

  void _terminateIfIntegrityTooLow(String reason) {
    if (!_isStrictSession || _terminationHandled) return;
    if (integrityScore.value <= _integrityTerminationScore) {
      _terminateSession(
        'Integrity score fell below strict threshold after: $reason',
      );
    }
  }

  void _logViolation(
    String reason, {
    required int penalty,
    required bool alert,
    bool persistToLedger = true,
    String? eventType,
    String? severity,
    double? confidence,
    String? evidencePath,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final stamp = DateTime.now().toIso8601String();
    violationLog.insert(0, '$stamp • $reason');

    if (penalty > 0) {
      violationCount.value += 1;
      cumulativeRiskScore.value += penalty;
      integrityScore.value = (integrityScore.value - penalty).clamp(0, 100);

      if (cumulativeRiskScore.value >= 60) {
        riskTier.value = IntegrityRiskTier.high;
      } else if (cumulativeRiskScore.value >= 25) {
        riskTier.value = IntegrityRiskTier.medium;
      }

      if (persistToLedger) {
        unawaited(
          _writeControllerLedgerEvent(
            reason: reason,
            penalty: penalty,
            alert: alert,
            eventType: eventType,
            severity: severity,
            confidence: confidence,
            evidencePath: evidencePath,
            metadata: metadata,
          ),
        );
      }
    }

    if (alert && Get.context != null) {
      Get.snackbar(
        'Integrity warning',
        reason,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
    _terminateIfIntegrityTooLow(reason);
  }

  Future<void> _writeControllerLedgerEvent({
    required String reason,
    required int penalty,
    required bool alert,
    String? eventType,
    String? severity,
    double? confidence,
    String? evidencePath,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    final profile = await IntegrityEventWriter.write(
      studentId: activeStudentId.value,
      sessionId: activeSessionId.value,
      reason: reason,
      points: penalty,
      level: currentLevel.value?.name,
      scoreAfter: integrityScore.value,
      strikesAfter: strictViolationStrikes.value,
      tier: riskTier.value,
      riskAfter: cumulativeRiskScore.value,
      type: eventType ?? _eventTypeForReason(reason),
      severity: severity ?? _severityForPenalty(penalty),
      confidence: confidence,
      alert: alert,
      filePath: evidencePath,
      data: <String, Object?>{'source': 'proctoring_controller', ...metadata},
    );

    pendingLedgerSyncCount.value = profile.unsyncedLedgerCount;
  }

  String _eventTypeForReason(String reason) {
    final lower = reason.toLowerCase();

    if (lower.contains('app moved away') || lower.contains('background')) {
      return 'appBackgroundExit';
    }

    if (lower.contains('environment scan rejected') ||
        lower.contains('environment scan timed out')) {
      return 'environmentScanRejected';
    }

    if (lower.contains('environment scan') && lower.contains('blocked')) {
      return 'environmentScanBlocked';
    }

    if (lower.contains('session terminated')) {
      return 'sessionTerminated';
    }

    if (lower.contains('multiple faces')) {
      return 'multipleFacesDetected';
    }

    if (lower.contains('phone')) {
      return 'phoneDetected';
    }

    if (lower.contains('voice') || lower.contains('speech')) {
      return 'humanVoiceDetected';
    }

    if (lower.contains('copy') || lower.contains('paste')) {
      return 'copyPasteDetected';
    }

    if (lower.contains('strict violation')) {
      return 'strictViolation';
    }

    if (lower.contains('verification failed')) {
      return 'verificationFailed';
    }

    if (lower.contains('launch blocked')) {
      return 'launchBlocked';
    }

    return 'controllerViolation';
  }

  String _severityForPenalty(int penalty) {
    if (penalty >= 80) return 'critical';
    if (penalty >= 25) return 'high';
    if (penalty >= 10) return 'medium';
    return 'low';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!shieldActive.value || !examStartupScanCompleted.value) return;
    final leaving =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused;
    if (leaving) {
      appInBackground.value = true;
      backgroundExitStrikes.value += 1;
      final penalty =
          currentLevel.value == AssessmentIntegrityLevel.highStakesExam
          ? 35
          : 25;
      _logViolation(
        'App moved away from protected session (${backgroundExitStrikes.value}/$_strictStrikeLimit).',
        penalty: penalty,
        alert: true,
      );
      if (_isStrictSession &&
          backgroundExitStrikes.value >= _strictStrikeLimit) {
        _terminateSession('Repeated app background/focus loss.');
      }
    } else if (state == AppLifecycleState.resumed) {
      appInBackground.value = false;
    }
  }

  @override
  void onClose() {
    _scanTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
