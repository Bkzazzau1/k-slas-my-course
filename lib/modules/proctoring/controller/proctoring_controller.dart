import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/integrity_models.dart';
import '../../../data/services/storage_service.dart';
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
  final isExamPaused = false.obs;
  final examStartupScanCompleted = false.obs;

  final riskTier = IntegrityRiskTier.low.obs;
  final cumulativeRiskScore = 0.obs;
  final pendingLedgerSyncCount = 0.obs;
  final activeSessionId = ''.obs;

  static const double _minimumLightingScore = 0.35;
  static const MethodChannel _clipboardChannel = MethodChannel('k_slas/clipboard');

  Timer? _scanTimer;
  VoidCallback? _onAutoSubmit;
  VoidCallback? _onSessionTerminated;
  VoidCallback? _onPauseExamTimer;
  VoidCallback? _onResumeExamTimer;
  Completer<bool>? _startupEnvironmentScanCompleter;
  bool _environmentDialogOpen = false;
  bool _terminationHandled = false;
  bool _autoSubmitted = false;

  double get minimumScanLightingScore => _minimumLightingScore;

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

  Future<void> syncIntegrityLedger() async {}

  Future<void> startSession({
    required AssessmentIntegrityLevel level,
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
    violationLog.clear();
    copyPasteBlocked.value = level != AssessmentIntegrityLevel.objectiveQuiz;
    sessionTerminated.value = false;
    terminationReason.value = '';
    examMonitoringArmed.value = level != AssessmentIntegrityLevel.highStakesExam;
    activeSessionId.value = '${DateTime.now().millisecondsSinceEpoch}-${level.name}';
    _terminationHandled = false;
    _autoSubmitted = false;
    _onAutoSubmit = onAutoSubmit;
    _onSessionTerminated = onSessionTerminated;

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
    strictViolationStrikes.value = 0;
    _resetScanState(clearStartup: true);

    if (!silent) {
      _logViolation('Proctoring session closed.', penalty: 0, alert: false);
    }
  }

  Future<bool> startExamSequence(
    String examId, {
    VoidCallback? onVerified,
  }) async {
    await startSession(level: AssessmentIntegrityLevel.highStakesExam);
    final verified = await Get.dialog<bool>(
          ExamStartDialog(examId: examId),
          barrierDismissible: false,
        ) ??
        false;

    if (!verified) {
      final demoMode = StorageService.getDemoMode();
      _logViolation(
        demoMode
            ? 'Demo mode: exam start sequence not verified. Proceeding by override.'
            : 'Exam start sequence not verified. Exam launch blocked.',
        penalty: 10,
        alert: true,
      );
      if (!demoMode) {
        await stopSession(silent: true);
        return false;
      }
    }

    armExamMonitoring();
    onVerified?.call();
    return true;
  }

  Future<bool> startAssessmentSequence(
    String assessmentId, {
    VoidCallback? onVerified,
    VoidCallback? onAutoSubmit,
    VoidCallback? onSessionTerminated,
  }) async {
    await startSession(
      level: AssessmentIntegrityLevel.gradedAssessment,
      onAutoSubmit: onAutoSubmit,
      onSessionTerminated: onSessionTerminated,
    );

    final verified = await Get.dialog<bool>(
          ExamStartDialog(
            examId: assessmentId,
            sessionLabel: 'Assessment',
          ),
          barrierDismissible: false,
        ) ??
        false;

    if (!verified) {
      final demoMode = StorageService.getDemoMode();
      if (!demoMode) {
        await stopSession(silent: true);
        return false;
      }
    }

    armExamMonitoring();
    onVerified?.call();
    return true;
  }

  Future<bool> ensureFortressReady() async {
    shieldActive.value = true;
    return true;
  }

  Future<bool> verifyIdentityAndEnvironment() async {
    requestEnvironmentScan('Complete the live environment scan before continuing.');
    _startupEnvironmentScanCompleter = Completer<bool>();
    return _startupEnvironmentScanCompleter!.future.timeout(
      const Duration(minutes: 4),
      onTimeout: () => false,
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

  void registerViolation(String reason, {int penalty = 0, bool alert = false}) {
    if (reason.toLowerCase().startsWith('terminal violation')) {
      _terminateSession(reason);
      return;
    }
    _logViolation(reason, penalty: penalty, alert: alert);
  }

  void handleViolation(String type) {
    strictViolationStrikes.value += 1;
    _logViolation('Unauthorized $type detected.', penalty: 12, alert: true);
    if (strictViolationStrikes.value >= 3) {
      _terminateSession('Maximum violations reached: $type');
      return;
    }
    forceBackgroundScan('Unauthorized $type detected. Complete an environment scan.');
  }

  Future<void> verifyNetworkIntegrity() async {}

  void processDetectedFaces(List<dynamic> faces, {bool includeGaze = false}) {
    if (faces.length > 1) {
      _logViolation('Multiple faces detected.', penalty: 10, alert: true);
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
          return lower.contains('phone') || lower.contains('laptop');
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
      _logViolation('Environment scan rejected: full room rotation not confirmed.', penalty: 6, alert: true);
      return;
    }
    if (scanLightingScore.value < _minimumLightingScore) {
      _logViolation('Environment scan rejected: insufficient lighting.', penalty: 6, alert: true);
      return;
    }
    if (scanForbiddenObjects.isNotEmpty) {
      _logViolation('Environment scan rejected: unauthorized item detected.', penalty: 12, alert: true);
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
    _logViolation('Environment scan completed successfully.', penalty: 0, alert: false);
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
    scanLightingScore.value = 1.0;
    scanRotationConfirmed.value = false;
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
      scanProgress.value = (scanProgress.value + 0.08).clamp(0.0, 1.0);
      if (scanProgress.value >= 1.0) {
        scanRotationConfirmed.value = true;
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

  void _terminateSession(String reason) {
    if (_terminationHandled) return;
    _terminationHandled = true;
    sessionTerminated.value = true;
    terminationReason.value = reason;
    _resolveStartupEnvironmentScan(success: false);
    _logViolation('Session terminated: $reason', penalty: 100, alert: false);
    _onSessionTerminated?.call();
  }

  void _logViolation(String reason, {required int penalty, required bool alert}) {
    final stamp = DateTime.now().toIso8601String();
    violationLog.insert(0, '$stamp • $reason');
    if (penalty > 0) {
      violationCount.value += 1;
      cumulativeRiskScore.value += penalty;
      integrityScore.value = (integrityScore.value - penalty).clamp(0, 100);
      if (cumulativeRiskScore.value >= 80) {
        riskTier.value = IntegrityRiskTier.high;
      } else if (cumulativeRiskScore.value >= 35) {
        riskTier.value = IntegrityRiskTier.medium;
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!shieldActive.value || !examStartupScanCompleted.value) return;
    final leaving = state == AppLifecycleState.inactive || state == AppLifecycleState.paused;
    if (leaving) {
      appInBackground.value = true;
      _logViolation('App moved away from protected session.', penalty: 8, alert: true);
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
