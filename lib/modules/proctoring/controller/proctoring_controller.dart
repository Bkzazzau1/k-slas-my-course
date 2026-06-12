import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/rust/rust_brain_service.dart';
import '../../../data/models/integrity_models.dart';
import '../../../data/services/exam_proctoring_backend_service.dart';
import '../../../data/services/integrity_ledger_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/student_profile_storage.dart';
import 'acoustic_watchdog.dart';
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

  // Acoustic watchdog
  final ultrasoundWatchdogActive = false.obs;
  final ultrasoundDbfs = RxnDouble();

  // Zero-trust hardware watchdog
  final accessoryWatchdogActive = false.obs;

  // Strike tracking
  final multiFaceStrikes = 0.obs;
  final speechStrikes = 0.obs;
  final gazeWarnings = 0.obs;
  final strictViolationStrikes = 0.obs;

  // Session termination state
  final sessionTerminated = false.obs;
  final terminationReason = ''.obs;
  final examMonitoringArmed = false.obs;

  // Forced environment scan state
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

  // Persistent risk profile
  final riskTier = IntegrityRiskTier.low.obs;
  final cumulativeRiskScore = 0.obs;
  final pendingLedgerSyncCount = 0.obs;
  final activeSessionId = ''.obs;

  // Native channels (implemented per platform app targets).
  static const MethodChannel _hardwareChannel = MethodChannel(
    'kasu_integrity_shield/hardware',
  );
  static const MethodChannel _acousticAnalysisChannel = MethodChannel(
    'acoustic_analysis_channel',
  );

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _scanGyroscopeSubscription;
  Timer? _recordingPoller;
  Timer? _scanFallbackTimer;
  Timer? _hardwarePoller;
  VoidCallback? _onAutoSubmit;
  VoidCallback? _onSessionTerminated;
  VoidCallback? _onPauseExamTimer;
  VoidCallback? _onResumeExamTimer;
  Completer<bool>? _startupEnvironmentScanCompleter;

  AcousticWatchdog? _acousticWatchdog;
  final NetworkInfo _networkInfo = NetworkInfo();
  Future<bool> Function(List<Map<String, dynamic>> payload)? _ledgerUploader;

  String? _trustedGatewayIp;
  String _studentId = 'anonymous-student';

  DateTime _lastMotionViolation = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastBackgroundViolation = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastScreenshotViolation = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastScreenRecordViolation = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastForcedScanAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _motionBurstWindowStart = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSpeechStrikeAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastMultiFaceStrikeAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastGazeWarningAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastStrictViolationAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _gazeAwayStartedAt;
  String _lastStrictViolationType = '';

  bool _autoSubmitted = false;
  bool _iosScreenshotListenerAttached = false;
  bool _environmentDialogOpen = false;
  bool _terminationHandled = false;

  int _motionBurstCount = 0;
  int _acousticSignalLossStreak = 0;
  int _acousticSpeechStreak = 0;
  double _acousticWhisperThresholdDb = -40.0;
  int _acousticSpeechSamplesToTrigger = 5;

  static const _storageKey = 'proctoring.violations';
  static const _acousticLossThresholdDbfs = -48.0;
  static const _acousticLossSamples = 4;
  static const _minimumLightingScore = 0.35;

  static const Set<String> _forbiddenObjectKeywords = {
    'cell phone',
    'mobile phone',
    'phone',
    'laptop',
  };

  bool get _supportsAcousticWatchdog => !kIsWeb;

  double get minimumScanLightingScore => _minimumLightingScore;

  @override
  void onInit() {
    super.onInit();
    _studentId = _resolveStudentId();
    _hydrateRiskProfile();
  }

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

  void setIntegrityLedgerUploader(
    Future<bool> Function(List<Map<String, dynamic>> payload)? uploader,
  ) {
    _ledgerUploader = uploader;
  }

  Future<void> syncIntegrityLedger() async {
    final uploader = _ledgerUploader;
    if (uploader == null) return;

    try {
      final synced = await IntegrityLedgerService.flushPendingLedger(
        studentId: _studentId,
        uploader: uploader,
      );
      if (synced > 0) {
        _hydrateRiskProfile();
      }
    } catch (_) {
      // Keep local queue if sync fails.
    }
  }

  String _resolveStudentId() {
    final profile = StudentProfileStorage.load();
    final matric = profile?.matricNo?.trim() ?? '';
    if (matric.isNotEmpty) return matric;

    final fullName = profile?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName.toLowerCase().replaceAll(' ', '_');
    }

    return 'anonymous-student';
  }

  void _hydrateRiskProfile() {
    if (Get.testMode) return;

    final profile = IntegrityLedgerService.loadOrCreateProfile(_studentId);
    riskTier.value = profile.riskTier;
    cumulativeRiskScore.value = profile.cumulativeRiskScore;
    pendingLedgerSyncCount.value = profile.unsyncedLedgerCount;
  }

  void _configureRiskAdaptiveSensitivity(AssessmentIntegrityLevel level) {
    switch (riskTier.value) {
      case IntegrityRiskTier.low:
        _acousticWhisperThresholdDb = -40.0;
        _acousticSpeechSamplesToTrigger = 5;
        break;
      case IntegrityRiskTier.medium:
        _acousticWhisperThresholdDb = -43.0;
        _acousticSpeechSamplesToTrigger = 4;
        break;
      case IntegrityRiskTier.high:
        _acousticWhisperThresholdDb = -46.0;
        _acousticSpeechSamplesToTrigger = 3;
        break;
    }

    if (level != AssessmentIntegrityLevel.highStakesExam) {
      _acousticSpeechSamplesToTrigger += 1;
    }

    if (_acousticSpeechSamplesToTrigger < 2) {
      _acousticSpeechSamplesToTrigger = 2;
    }
  }

  Future<void> startSession({
    required AssessmentIntegrityLevel level,
    VoidCallback? onAutoSubmit,
    VoidCallback? onSessionTerminated,
  }) async {
    // Reuse an identical active session; only update callbacks.
    if (shieldActive.value && currentLevel.value == level) {
      _onAutoSubmit = onAutoSubmit;
      _onSessionTerminated = onSessionTerminated;
      return;
    }

    await stopSession(silent: true);
    _studentId = _resolveStudentId();
    _hydrateRiskProfile();
    _configureRiskAdaptiveSensitivity(level);
    activeSessionId.value =
        '${DateTime.now().millisecondsSinceEpoch}-${level.name}';

    currentLevel.value = level;
    integrityScore.value = 100;
    violationCount.value = 0;
    violationLog.clear();
    isPhoneMoved.value = false;
    isScreenRecorded.value = false;
    appInBackground.value = false;
    _autoSubmitted = false;
    _terminationHandled = false;
    _onAutoSubmit = onAutoSubmit;
    _onSessionTerminated = onSessionTerminated;
    copyPasteBlocked.value = level != AssessmentIntegrityLevel.objectiveQuiz;
    shieldActive.value = true;
    sessionTerminated.value = false;
    terminationReason.value = '';
    examMonitoringArmed.value =
        level != AssessmentIntegrityLevel.highStakesExam;
    isExamPaused.value = false;

    multiFaceStrikes.value = 0;
    speechStrikes.value = 0;
    gazeWarnings.value = 0;
    strictViolationStrikes.value = 0;
    _lastMotionViolation = DateTime.fromMillisecondsSinceEpoch(0);
    _motionBurstWindowStart = DateTime.fromMillisecondsSinceEpoch(0);
    _motionBurstCount = 0;
    _lastSpeechStrikeAt = DateTime.fromMillisecondsSinceEpoch(0);
    _lastMultiFaceStrikeAt = DateTime.fromMillisecondsSinceEpoch(0);
    _lastGazeWarningAt = DateTime.fromMillisecondsSinceEpoch(0);
    _gazeAwayStartedAt = null;
    _lastStrictViolationType = '';
    _lastStrictViolationAt = DateTime.fromMillisecondsSinceEpoch(0);
    _lastForcedScanAt = DateTime.fromMillisecondsSinceEpoch(0);
    _acousticSignalLossStreak = 0;
    _acousticSpeechStreak = 0;

    scanRequired.value = false;
    scanInProgress.value = false;
    scanProgress.value = 0;
    scanReason.value = '';
    scanAiChecksPassed.value = false;
    scanForbiddenObjects.clear();
    scanLightingScore.value = 0;
    scanRotationConfirmed.value = false;
    examStartupScanCompleted.value = false;

    WidgetsBinding.instance.addObserver(this);
    await enableScreenshotProtection();

    if (level == AssessmentIntegrityLevel.highStakesExam) {
      _startMotionDetection(highSensitivity: true);
      await _stopUltrasoundBackgroundCheck(disposeWatchdog: false);
      await startAccessoryWatchdog();
    } else if (level == AssessmentIntegrityLevel.gradedAssessment) {
      _startMotionDetection(highSensitivity: false);
      await _stopUltrasoundBackgroundCheck(disposeWatchdog: false);
      await startAccessoryWatchdog();
    } else {
      await _stopUltrasoundBackgroundCheck(disposeWatchdog: false);
      await stopAccessoryWatchdog();
    }

    _startRecordingMonitor(
      interval: level == AssessmentIntegrityLevel.highStakesExam
          ? const Duration(seconds: 2)
          : const Duration(seconds: 5),
    );
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

  Future<void> stopSession({bool silent = false}) async {
    WidgetsBinding.instance.removeObserver(this);

    _recordingPoller?.cancel();
    _recordingPoller = null;

    _scanFallbackTimer?.cancel();
    _scanFallbackTimer = null;

    _hardwarePoller?.cancel();
    _hardwarePoller = null;

    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    await _scanGyroscopeSubscription?.cancel();
    _scanGyroscopeSubscription = null;

    await _stopUltrasoundBackgroundCheck(disposeWatchdog: true);
    await stopAccessoryWatchdog();
    _resolveStartupEnvironmentScan(success: false);
    _closeEnvironmentScanOverlayIfNeeded();

    await disableScreenshotProtection();

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
    _resumeExamClock(notifyTimer: false);
    activeSessionId.value = '';
    strictViolationStrikes.value = 0;
    _gazeAwayStartedAt = null;
    _lastStrictViolationType = '';
    scanRequired.value = false;
    scanInProgress.value = false;
    scanProgress.value = 0;
    scanReason.value = '';
    scanAiChecksPassed.value = false;
    scanForbiddenObjects.clear();
    scanLightingScore.value = 0;
    scanRotationConfirmed.value = false;
    examStartupScanCompleted.value = false;

    if (!silent) {
      // Keep final session summary available to UI after session closes.
      _logViolation('Proctoring session closed.', penalty: 0, alert: false);
    }
  }

  Future<bool> startExamSequence(
    String examId, {
    VoidCallback? onVerified,
  }) async {
    await startSession(level: AssessmentIntegrityLevel.highStakesExam);

    final verified =
        await Get.dialog<bool>(
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

    if (onVerified != null) {
      onVerified();
    } else {
      Get.offNamed('/exam/run', arguments: examId);
    }
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

    final verified =
        await Get.dialog<bool>(
          ExamStartDialog(examId: assessmentId, sessionLabel: 'Assessment'),
          barrierDismissible: false,
        ) ??
        false;

    if (!verified) {
      final demoMode = StorageService.getDemoMode();
      _logViolation(
        demoMode
            ? 'Demo mode: assessment start sequence not verified. Proceeding by override.'
            : 'Assessment start sequence not verified. Assessment launch blocked.',
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

  void armExamMonitoring() {
    if (currentLevel.value == null) return;
    _resetAcousticDetectionState(clearDbfs: false);
    examMonitoringArmed.value = true;
  }

  Future<bool> ensureFortressReady() async {
    try {
      await enableScreenshotProtection();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyAcousticTether({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!_supportsAcousticWatchdog) {
      // Non-mobile fallback: allow launch while keeping other checks active.
      return true;
    }
    if (_isAcousticDetectionBlocked) {
      return false;
    }

    await _startUltrasoundBackgroundCheck();

    final started = DateTime.now();
    while (DateTime.now().difference(started) < timeout) {
      final db = ultrasoundDbfs.value;
      if (db != null && db > _acousticLossThresholdDbfs) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (examMonitoringArmed.value) {
      _logViolation(
        'Acoustic tether check failed during active exam monitoring.',
        penalty: 14,
        alert: true,
      );
      _forceEnvironmentScan(
        reason:
            'Acoustic handshake missing. Rotate your device to revalidate the environment.',
      );
    }
    return false;
  }

  Future<bool> verifyIdentityAndEnvironment() async {
    await verifyNetworkIntegrity();
    if (!(GetPlatform.isAndroid || GetPlatform.isIOS)) {
      final checks = await _runRustVisionWarmupChecks();
      if (!checks) {
        _logViolation(
          'Rust vision engine unavailable. Continuing with reduced assurance.',
          penalty: 0,
          alert: false,
        );
      }
      examStartupScanCompleted.value = true;
      return true;
    }

    if (examStartupScanCompleted.value) {
      return true;
    }

    final existingScan = _startupEnvironmentScanCompleter;
    if (existingScan != null) {
      return existingScan.future;
    }

    final completer = Completer<bool>();
    _startupEnvironmentScanCompleter = completer;
    _forceEnvironmentScan(
      reason:
          'Complete the camera environment scan before audio verification can begin.',
    );
    return completer.future;
  }

  Future<void> startAccessoryWatchdog() async {
    if (kIsWeb) return;
    final level = currentLevel.value;
    if (level == null || level == AssessmentIntegrityLevel.objectiveQuiz) {
      return;
    }

    accessoryWatchdogActive.value = true;

    _hardwareChannel.setMethodCallHandler(_handleHardwareCall);
    _acousticAnalysisChannel.setMethodCallHandler(_handleAcousticCall);

    _hardwarePoller?.cancel();
    _hardwarePoller = Timer.periodic(const Duration(seconds: 6), (_) {
      _checkHardwareRegistry();
    });
    await _checkHardwareRegistry();
  }

  Future<void> stopAccessoryWatchdog() async {
    accessoryWatchdogActive.value = false;
    _hardwarePoller?.cancel();
    _hardwarePoller = null;

    _hardwareChannel.setMethodCallHandler(null);
    _acousticAnalysisChannel.setMethodCallHandler(null);
  }

  Future<dynamic> _handleHardwareCall(MethodCall call) async {
    if (!accessoryWatchdogActive.value) return null;

    final args = Map<String, dynamic>.from((call.arguments as Map?) ?? {});

    if (call.method == 'audioRouteChanged') {
      final isHeadset = args['isHeadset'] == true;
      if (isHeadset) {
        handleViolation('audio accessory');
      }
      return null;
    }

    if (call.method == 'bluetoothDeviceDetected' ||
        call.method == 'usbDeviceDetected' ||
        call.method == 'peripheralDetected') {
      final authorized = args['authorized'] == true;
      if (!authorized) {
        final label = (args['name'] ?? args['device'] ?? 'Unknown peripheral')
            .toString();
        final lower = label.toLowerCase();
        if (lower.contains('usb') ||
            lower.contains('monitor') ||
            lower.contains('display')) {
          _terminateSession(
            'Terminal violation: unauthorized peripheral $label',
          );
        } else {
          handleViolation('peripheral: $label');
        }
      }
      return null;
    }

    if (call.method == 'hardwareRegistryChanged') {
      final raw = (args['unauthorizedDevices'] as List?) ?? const [];
      if (raw.isEmpty) return;
      final list = raw.map((e) => e.toString()).toList();
      final hasTerminal = list.any(
        (d) =>
            d.toLowerCase().contains('usb') ||
            d.toLowerCase().contains('monitor') ||
            d.toLowerCase().contains('display'),
      );
      if (hasTerminal) {
        _terminateSession(
          'Terminal violation: unauthorized hardware detected.',
        );
      } else {
        handleViolation('hardware accessory');
      }
      return null;
    }

    return null;
  }

  Future<dynamic> _handleAcousticCall(MethodCall call) async {
    if (!shieldActive.value) return null;
    if (_isAcousticDetectionBlocked) return null;
    if (!examMonitoringArmed.value) return null;

    if (call.method == 'speechFormantDetected' ||
        call.method == 'multipleVoicesDetected') {
      final now = DateTime.now();
      if (now.difference(_lastSpeechStrikeAt) < const Duration(seconds: 8)) {
        return null;
      }
      _lastSpeechStrikeAt = now;
      _handleSpeechStrike('Speech formants detected in exam environment.');
      return null;
    }

    if (call.method == 'acousticTetherLost') {
      _forceEnvironmentScan(
        reason: 'Acoustic tether lost. Perform a full 360° environment scan.',
      );
      return null;
    }

    return null;
  }

  Future<void> _checkHardwareRegistry() async {
    if (!accessoryWatchdogActive.value) return;

    try {
      final accessory = await _hardwareChannel.invokeMethod<bool>(
        'isAccessoryConnected',
      );
      if (accessory == true) {
        handleViolation('audio accessory');
        return;
      }
    } on MissingPluginException {
      // Platform implementation may not exist yet.
    } catch (_) {
      // Ignore transient channel errors.
    }

    try {
      final raw = await _hardwareChannel.invokeMethod<List<dynamic>>(
        'checkUnauthorizedPeripherals',
      );
      final list = (raw ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isEmpty) return;
      final hasTerminal = list.any(
        (d) =>
            d.toLowerCase().contains('usb') ||
            d.toLowerCase().contains('monitor') ||
            d.toLowerCase().contains('display'),
      );
      if (hasTerminal) {
        _terminateSession(
          'Terminal violation: unauthorized peripheral detected: ${list.join(", ")}.',
        );
      } else {
        handleViolation('audio accessory');
      }
    } on MissingPluginException {
      // Platform implementation may not exist yet.
    } catch (_) {
      // Ignore transient channel errors.
    }
  }

  void processDetectedFaces(
    List<VisionFaceObservation> faces, {
    bool includeGaze = true,
  }) {
    if (!shieldActive.value || faces.isEmpty) return;
    final now = DateTime.now();
    final face = faces.first;
    final decision = RustBrainService.instance.analyzeFaceState(
      faceCount: faces.length,
      includeGaze: includeGaze,
      yaw: face.yaw,
      pitch: face.pitch,
      now: now,
      lastMultiFaceStrikeAt: _lastMultiFaceStrikeAt,
      multiFaceCooldownMs: 6000,
      gazeAwayStartedAt: _gazeAwayStartedAt,
      gazeAwayDurationMs: 3000,
      lastGazeWarningAt: _lastGazeWarningAt,
      gazeWarningCooldownMs: 5000,
    );

    _lastMultiFaceStrikeAt = decision.updatedLastMultiFaceStrikeAt;
    _lastGazeWarningAt = decision.updatedLastGazeWarningAt;
    _gazeAwayStartedAt = decision.updatedGazeAwayStartedAt;

    if (decision.shouldFlagMultiFace) {
      _handleMultiFaceStrike(faces.length);
    }

    if (decision.shouldWarnGaze) {
      _issueGazeWarning();
    }
  }

  void onFaceDetected(VisionFaceObservation face) {
    processDetectedFaces([face], includeGaze: true);
  }

  void _issueGazeWarning() {
    gazeWarnings.value += 1;
    unawaited(
      _triggerVoiceWarning(
        'Please look at the screen. Unauthorized gaze movement detected.',
      ),
    );
    handleViolation('gaze diversion');
  }

  void _handleMultiFaceStrike(int faceCount) {
    multiFaceStrikes.value += 1;
    handleViolation('multiple people');
    _logViolation(
      'Multiple faces detected in frame: $faceCount',
      penalty: 0,
      alert: false,
    );
  }

  void _handleSpeechStrike(String reason) {
    if (!examMonitoringArmed.value) {
      _resetAcousticDetectionState(clearDbfs: false);
      return;
    }
    speechStrikes.value += 1;
    handleViolation('background speech');
    _logViolation(reason, penalty: 0, alert: false);
  }

  Future<void> registerEnvironmentFrameAnalysis({
    required List<String> objectLabels,
    required double lightingScore,
    required bool rotationCovered,
  }) async {
    if (!scanRequired.value) return;
    final decision = RustBrainService.instance.analyzeEnvironmentFrame(
      objectLabels: objectLabels,
      lightingScore: lightingScore,
      rotationCovered: rotationCovered,
      forbiddenKeywords: _forbiddenObjectKeywords.toList(),
    );

    scanLightingScore.value = decision.normalizedLightingScore;
    if (decision.rotationConfirmed) {
      scanRotationConfirmed.value = true;
    }
    scanForbiddenObjects.assignAll(decision.forbiddenObjects);
  }

  void requestEnvironmentScan(String reason) {
    _forceEnvironmentScan(reason: reason);
  }

  Future<void> completeEnvironmentScan() async {
    if (scanProgress.value < 1.0) return;
    if (!scanRotationConfirmed.value) {
      _logViolation(
        'Environment scan rejected: full 360° rotation not confirmed.',
        penalty: 6,
        alert: true,
      );
      return;
    }
    if (scanLightingScore.value < _minimumLightingScore) {
      _logViolation(
        'Environment scan rejected: insufficient lighting.',
        penalty: 6,
        alert: true,
      );
      return;
    }
    if (scanForbiddenObjects.isNotEmpty) {
      _terminateSession(
        'Forbidden objects detected during scan: ${scanForbiddenObjects.join(", ")}.',
      );
      return;
    }

    scanInProgress.value = true;
    final aiChecks = await _runRustVisionWarmupChecks();
    scanAiChecksPassed.value =
        aiChecks || !(GetPlatform.isAndroid || GetPlatform.isIOS);

    if (!scanAiChecksPassed.value) {
      scanInProgress.value = false;
      _logViolation(
        'Environment scan rejected: AI integrity checks failed.',
        penalty: 8,
        alert: true,
      );
      return;
    }

    await _scanGyroscopeSubscription?.cancel();
    _scanGyroscopeSubscription = null;
    _scanFallbackTimer?.cancel();
    _scanFallbackTimer = null;

    scanRequired.value = false;
    scanInProgress.value = false;
    _resetAcousticDetectionState();
    final isStartupScan = !examStartupScanCompleted.value;
    if (isStartupScan) {
      examStartupScanCompleted.value = true;
    }

    _logViolation(
      'Environment scan completed and AI checks refreshed.',
      penalty: 0,
      alert: false,
    );

    if (!isStartupScan) {
      await _startUltrasoundBackgroundCheck();
    }
    await resumeExamAfterScan();
    if (isStartupScan) {
      _resolveStartupEnvironmentScan(success: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final level = currentLevel.value;
    if (level == null) return;

    // Ignore startup permission/app-switch noise until the exam gateway scan
    // has completed successfully.
    if (!examStartupScanCompleted.value) {
      if (state == AppLifecycleState.resumed) {
        appInBackground.value = false;
      }
      return;
    }

    final leaving =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;

    if (leaving) {
      appInBackground.value = true;
      final now = DateTime.now();
      if (now.difference(_lastBackgroundViolation) <
          const Duration(seconds: 2)) {
        return;
      }
      _lastBackgroundViolation = now;

      if (level == AssessmentIntegrityLevel.objectiveQuiz && !_autoSubmitted) {
        _autoSubmitted = true;
        _logViolation(
          'App moved to background during objective quiz. Attempt auto-submitted.',
          penalty: 35,
          alert: true,
        );
        _onAutoSubmit?.call();
        return;
      }

      if (level == AssessmentIntegrityLevel.gradedAssessment) {
        _logViolation(
          'App moved to background during graded assessment.',
          penalty: 12,
          alert: true,
        );
      } else {
        _logViolation(
          'App moved to background during high-stakes exam.',
          penalty: 20,
          alert: true,
        );
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      appInBackground.value = false;
      if (copyPasteBlocked.value) {
        clearClipboard();
      }
    }
  }

  void setTrustedNetworkFingerprint({String? gatewayIp}) {
    _trustedGatewayIp = gatewayIp;
  }

  Future<void> verifyNetworkIntegrity() async {
    if (kIsWeb) return;
    if (_trustedGatewayIp == null || _trustedGatewayIp!.trim().isEmpty) return;

    try {
      final currentGateway = await _networkInfo.getWifiGatewayIP();
      if (currentGateway == null || currentGateway.trim().isEmpty) return;
      if (currentGateway.trim() == _trustedGatewayIp!.trim()) return;

      handleViolation('network gateway mismatch');
      _logViolation(
        'Network mismatch detected. expected=$_trustedGatewayIp current=$currentGateway',
        penalty: 0,
        alert: false,
      );
    } catch (_) {
      // Keep session running if gateway lookup is unavailable.
    }
  }

  Future<void> enableScreenshotProtection() async {
    if (kIsWeb) return;

    try {
      // Android: block screenshots/recordings + recents preview.
      if (GetPlatform.isAndroid) {
        await ScreenProtector.protectDataLeakageOn();
        await ScreenProtector.preventScreenshotOn();
      }

      // iOS: observe screenshot/recording events + apply blur in app switcher.
      if (GetPlatform.isIOS) {
        await ScreenProtector.preventScreenshotOn();
        await ScreenProtector.protectDataLeakageWithBlur();
        await _attachIosScreenCaptureListener();
      }
    } catch (_) {
      // Keep assessment running even if device-level API is unavailable.
    }
  }

  Future<void> disableScreenshotProtection() async {
    if (kIsWeb) return;

    try {
      if (GetPlatform.isAndroid) {
        await ScreenProtector.preventScreenshotOff();
        await ScreenProtector.protectDataLeakageOff();
      }

      if (GetPlatform.isIOS) {
        if (_iosScreenshotListenerAttached) {
          ScreenProtector.removeListener();
          _iosScreenshotListenerAttached = false;
        }
        await ScreenProtector.preventScreenshotOff();
        await ScreenProtector.protectDataLeakageOff();
      }
    } catch (_) {
      // No-op fallback.
    }
  }

  Future<void> clearClipboard() async {
    if (kIsWeb) return;
    try {
      await Clipboard.setData(const ClipboardData(text: ""));
    } catch (_) {
      // Clipboard write may fail on some targets; ignore safely.
    }
  }

  void registerViolation(String reason, {int penalty = 0, bool alert = false}) {
    if (reason.toLowerCase().startsWith('terminal violation')) {
      _terminateSession(reason);
      return;
    }
    _logViolation(reason, penalty: penalty, alert: alert);
  }

  void handleViolation(String type) {
    if (!examMonitoringArmed.value &&
        (type == 'background speech' || type == 'audio accessory')) {
      _resetAcousticDetectionState(clearDbfs: false);
      return;
    }

    final now = DateTime.now();
    if (_lastStrictViolationType == type &&
        now.difference(_lastStrictViolationAt) < const Duration(seconds: 8)) {
      return;
    }
    _lastStrictViolationType = type;
    _lastStrictViolationAt = now;

    strictViolationStrikes.value += 1;
    final strike = strictViolationStrikes.value;

    if (strike == 1) {
      unawaited(_triggerVoiceWarning('Unauthorized activity detected.'));
      _logViolation(
        'Unauthorized $type detected (strike 1).',
        penalty: 12,
        alert: true,
      );
      if (Get.context != null) {
        Get.snackbar(
          'WARNING (1/2)',
          'Unauthorized $type detected. Scan your background immediately.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFF57C00),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 5),
        );
      }
      forceBackgroundScan(
        'Unauthorized $type detected. Complete a 360° environment scan.',
      );
      return;
    }

    if (strike == 2) {
      unawaited(
        _triggerVoiceWarning(
          'Final warning. Next violation will terminate your exam.',
        ),
      );
      _logViolation(
        'Unauthorized $type detected (strike 2).',
        penalty: 18,
        alert: true,
      );
      if (Get.context != null) {
        Get.snackbar(
          'FINAL WARNING (2/2)',
          'Next violation will terminate your exam.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB71C1C),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    _terminateSession('Maximum violations reached: $type');
  }

  void forceBackgroundScan(String reason) {
    _forceEnvironmentScan(reason: reason);
  }

  void _pauseExamClock() {
    if (isExamPaused.value) return;
    isExamPaused.value = true;
    _onPauseExamTimer?.call();
  }

  void _resumeExamClock({bool notifyTimer = true}) {
    if (!isExamPaused.value) return;
    isExamPaused.value = false;
    if (notifyTimer) {
      _onResumeExamTimer?.call();
    }
  }

  Future<void> resumeExamAfterScan() async {
    if (!(scanAiChecksPassed.value && scanRotationConfirmed.value)) {
      return;
    }
    _resumeExamClock();
    _closeEnvironmentScanOverlayIfNeeded();
  }

  Future<void> _triggerVoiceWarning(String text) async {
    try {
      await _hardwareChannel.invokeMethod<void>('speakWarning', {'text': text});
    } on MissingPluginException {
      // Optional native TTS implementation may not exist.
    } catch (_) {
      // Best-effort warning path.
    }
  }

  Future<void> _startUltrasoundBackgroundCheck() async {
    if (!_supportsAcousticWatchdog) return;
    if (_isAcousticDetectionBlocked) return;

    final watchdog = _ensureAcousticWatchdog();
    if (watchdog.isRunning) return;

    try {
      await RustBrainService.instance.warmUp();
      final started = await watchdog.start();
      if (!started) {
        if (examMonitoringArmed.value) {
          _logViolation(
            'Microphone permission denied; acoustic watchdog disabled.',
            penalty: 10,
            alert: true,
          );
        }
        ultrasoundWatchdogActive.value = false;
        ultrasoundDbfs.value = null;
        return;
      }

      _acousticSignalLossStreak = 0;
      ultrasoundWatchdogActive.value = true;
    } catch (_) {
      ultrasoundWatchdogActive.value = false;
      ultrasoundDbfs.value = null;
      _logViolation(
        'Acoustic watchdog stream failed.',
        penalty: 0,
        alert: false,
      );
    }
  }

  AcousticWatchdog _ensureAcousticWatchdog() {
    return _acousticWatchdog ??= AcousticWatchdog(
      onPcmChunk: _handleAcousticPcmChunk,
    );
  }

  void _handleAcousticPcmChunk(Uint8List chunk) {
    if (_isAcousticDetectionBlocked) {
      _resetAcousticDetectionState(clearDbfs: true);
      return;
    }

    final now = DateTime.now();
    final decision = RustBrainService.instance.analyzeAcousticChunk(
      pcm16Bytes: chunk,
      lossThresholdDbfs: _acousticLossThresholdDbfs,
      lossStreak: _acousticSignalLossStreak,
      lossSamplesToTrigger: _acousticLossSamples,
      speechThresholdDbfs: _acousticWhisperThresholdDb,
      speechStreak: _acousticSpeechStreak,
      speechSamplesToTrigger: _acousticSpeechSamplesToTrigger,
      lastSpeechStrikeAt: _lastSpeechStrikeAt,
      now: now,
    );
    ultrasoundDbfs.value = decision.dbfs;
    _acousticSignalLossStreak = decision.updatedLossStreak;
    _acousticSpeechStreak = decision.updatedSpeechStreak;
    _lastSpeechStrikeAt = decision.updatedLastSpeechStrikeAt;

    if (!examMonitoringArmed.value) {
      return;
    }

    if (decision.shouldTriggerSpeech) {
      _handleSpeechStrike(
        'Speech-like acoustic formants detected in exam area.',
      );
    }

    if (!decision.shouldTriggerScan) {
      return;
    }

    _acousticSignalLossStreak = 0;
    _logViolation(
      'Acoustic tether lost. Environment scan required.',
      penalty: 16,
      alert: true,
    );
    _forceEnvironmentScan(
      reason: 'Acoustic tether dropped. Rotate your device 360° to continue.',
    );
  }

  Future<void> _stopUltrasoundBackgroundCheck({
    required bool disposeWatchdog,
  }) async {
    ultrasoundWatchdogActive.value = false;
    ultrasoundDbfs.value = null;
    _acousticSignalLossStreak = 0;
    _acousticSpeechStreak = 0;

    final watchdog = _acousticWatchdog;
    if (watchdog != null) {
      await watchdog.stop(dispose: disposeWatchdog);
      if (disposeWatchdog) {
        _acousticWatchdog = null;
      }
    }
  }

  Future<void> _attachIosScreenCaptureListener() async {
    if (!GetPlatform.isIOS) return;
    if (_iosScreenshotListenerAttached) return;

    try {
      ScreenProtector.addListener(
        () {
          final now = DateTime.now();
          if (now.difference(_lastScreenshotViolation) <
              const Duration(seconds: 2)) {
            return;
          }
          _lastScreenshotViolation = now;
          _logViolation(
            'Screenshot attempt detected.',
            penalty: 18,
            alert: true,
          );
        },
        (isCaptured) {
          isScreenRecorded.value = isCaptured;
          if (!isCaptured) return;

          final now = DateTime.now();
          if (now.difference(_lastScreenRecordViolation) <
              const Duration(seconds: 2)) {
            return;
          }
          _lastScreenRecordViolation = now;
          _logViolation(
            'Screen recording or mirroring detected.',
            penalty: 25,
            alert: true,
          );
        },
      );
      _iosScreenshotListenerAttached = true;
    } catch (_) {
      // iOS listener registration may fail in unsupported environments.
    }
  }

  void _startMotionDetection({required bool highSensitivity}) {
    _accelerometerSubscription?.cancel();

    final xThreshold = highSensitivity ? 1.4 : 2.2;
    final yThreshold = highSensitivity ? 1.4 : 2.2;
    final zThreshold = highSensitivity ? 8.8 : 7.2;

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      final decision = RustBrainService.instance.analyzeMotionSample(
        x: event.x.toDouble(),
        y: event.y.toDouble(),
        z: event.z.toDouble(),
        xThreshold: xThreshold,
        yThreshold: yThreshold,
        zThreshold: zThreshold,
        now: now,
        lastViolationAt: _lastMotionViolation,
        cooldownMs: 2000,
        windowStartAt: _motionBurstWindowStart,
        windowMs: 12000,
        burstCount: _motionBurstCount,
        burstThreshold: highSensitivity ? 3 : 0,
      );

      _lastMotionViolation = decision.updatedLastViolationAt;
      _motionBurstWindowStart = decision.updatedWindowStartAt;
      _motionBurstCount = decision.updatedBurstCount;

      if (!decision.shouldLogViolation) {
        return;
      }

      isPhoneMoved.value = true;
      _logViolation(
        'Physical movement detected.',
        penalty: highSensitivity ? 8 : 4,
        alert: false,
      );

      if (decision.shouldTriggerScan) {
        _forceEnvironmentScan(
          reason: 'Repeated device movement detected during high-stakes exam.',
        );
      }
    });
  }

  void _startRecordingMonitor({required Duration interval}) {
    _recordingPoller?.cancel();
    _recordingPoller = Timer.periodic(interval, (_) async {
      if (!shieldActive.value || kIsWeb) return;

      try {
        final recording = await ScreenProtector.isRecording();
        if (recording && !isScreenRecorded.value) {
          isScreenRecorded.value = true;
          final level = currentLevel.value;
          final penalty = level == AssessmentIntegrityLevel.highStakesExam
              ? 25
              : 15;
          _logViolation(
            'Screen recording detected.',
            penalty: penalty,
            alert: true,
          );
          if (level == AssessmentIntegrityLevel.highStakesExam) {
            _forceEnvironmentScan(
              reason:
                  'Recording signal detected. Perform a full environment sweep.',
            );
          }
        } else if (!recording && isScreenRecorded.value) {
          isScreenRecorded.value = false;
        }
      } catch (_) {
        // Some platforms do not expose recording state; ignore gracefully.
      }
    });
  }

  void _forceEnvironmentScan({required String reason}) {
    final level = currentLevel.value;
    if (level == null || level == AssessmentIntegrityLevel.objectiveQuiz) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastForcedScanAt) < const Duration(seconds: 20)) {
      return;
    }
    _lastForcedScanAt = now;

    _resetAcousticDetectionState(clearDbfs: true);
    scanReason.value = reason;
    scanRequired.value = true;
    scanInProgress.value = true;
    scanProgress.value = 0;
    scanAiChecksPassed.value = false;
    scanForbiddenObjects.clear();
    scanLightingScore.value = 0;
    scanRotationConfirmed.value = false;
    _pauseExamClock();

    _startEnvironmentRotationTracker();

    if (_environmentDialogOpen || Get.context == null) return;
    _environmentDialogOpen = true;
    Get.dialog(
      const EnvironmentScanOverlay(),
      barrierDismissible: false,
    ).whenComplete(() {
      _environmentDialogOpen = false;
    });
  }

  bool get _isWaitingForStartupCameraScan =>
      currentLevel.value == AssessmentIntegrityLevel.highStakesExam &&
      !examStartupScanCompleted.value;

  bool get _isAcousticDetectionBlocked =>
      _isWaitingForStartupCameraScan || _isCameraScanBlockingAcoustics;

  bool get _isCameraScanBlockingAcoustics =>
      scanRequired.value || scanInProgress.value;

  void _resetAcousticDetectionState({bool clearDbfs = false}) {
    _acousticSignalLossStreak = 0;
    _acousticSpeechStreak = 0;
    if (clearDbfs) {
      ultrasoundDbfs.value = null;
    }
  }

  void _resolveStartupEnvironmentScan({required bool success}) {
    final completer = _startupEnvironmentScanCompleter;
    if (completer == null) {
      return;
    }
    _startupEnvironmentScanCompleter = null;
    if (!completer.isCompleted) {
      completer.complete(success);
    }
  }

  void _startEnvironmentRotationTracker() {
    _scanGyroscopeSubscription?.cancel();
    _scanFallbackTimer?.cancel();

    void startFallbackTimer() {
      _scanFallbackTimer?.cancel();
      // Fallback for devices/browsers/tests with weak or blocked sensor streams.
      _scanFallbackTimer = Timer.periodic(const Duration(milliseconds: 900), (
        _,
      ) {
        if (!scanRequired.value || scanProgress.value >= 1.0) return;
        scanProgress.value = (scanProgress.value + 0.08).clamp(0.0, 1.0);
        if (scanProgress.value >= 1.0) {
          scanRotationConfirmed.value = true;
          scanInProgress.value = false;
        }
      });
    }

    if (Get.testMode) {
      _scanGyroscopeSubscription = null;
      startFallbackTimer();
      return;
    }

    var accumulated = 0.0;
    try {
      _scanGyroscopeSubscription =
          gyroscopeEventStream(
            samplingPeriod: SensorInterval.gameInterval,
          ).listen(
            (event) {
              if (!scanRequired.value) return;
              final decision = RustBrainService.instance.updateRotationProgress(
                x: event.x.toDouble(),
                y: event.y.toDouble(),
                z: event.z.toDouble(),
                accumulated: accumulated,
                currentProgress: scanProgress.value,
              );

              accumulated = decision.updatedAccumulated;
              if (decision.updatedProgress > scanProgress.value) {
                scanProgress.value = decision.updatedProgress;
              }

              if (decision.rotationConfirmed) {
                scanRotationConfirmed.value = true;
                scanInProgress.value = false;
              }
            },
            onError: (_, __) {
              // Optional sensor stream: ignore in headless/test environments.
            },
            cancelOnError: false,
          );
    } catch (_) {
      // Sensor stream is optional for environments where plugin channels are absent.
      _scanGyroscopeSubscription = null;
    }
    startFallbackTimer();
  }

  Future<bool> _runRustVisionWarmupChecks() async {
    if (kIsWeb) return false;
    if (!(GetPlatform.isAndroid || GetPlatform.isIOS)) return false;

    try {
      final status = await RustBrainService.instance.ensureVisionModelLoaded();
      if (!status.loaded) return false;
    } catch (_) {
      return false;
    }

    return true;
  }

  void _terminateSession(String reason) {
    if (_terminationHandled) return;
    _terminationHandled = true;
    _resolveStartupEnvironmentScan(success: false);
    final onSessionTerminated = _onSessionTerminated;
    _resumeExamClock(notifyTimer: false);

    sessionTerminated.value = true;
    terminationReason.value = reason;

    _logViolation('Session terminated: $reason', penalty: 100, alert: false);

    if (Get.context != null) {
      Get.dialog<void>(
        PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Exam Terminated'),
            content: Text(reason),
            actions: [
              FilledButton(
                onPressed: () => Get.back<void>(),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      ).then((_) {
        onSessionTerminated?.call();
      });
    } else {
      onSessionTerminated?.call();
    }

    unawaited(stopSession(silent: true));
  }

  void _closeEnvironmentScanOverlayIfNeeded() {
    if ((Get.isDialogOpen ?? false) && _environmentDialogOpen) {
      Get.back<void>();
    }
    _environmentDialogOpen = false;
  }

  void _logViolation(String reason, {int penalty = 0, bool alert = false}) {
    var effectivePenalty = penalty;

    // Prevent aggressive integrity-score drops while forced scan is in progress.
    if (scanRequired.value && effectivePenalty > 0) {
      effectivePenalty = (effectivePenalty / 2).round();
    }

    if (effectivePenalty > 0) {
      integrityScore.value = (integrityScore.value - effectivePenalty).clamp(
        0,
        100,
      );
    }

    final now = DateTime.now().toIso8601String();
    final line = '$now • $reason';
    violationLog.insert(0, line);
    violationCount.value += 1;

    if (violationLog.length > 200) {
      violationLog.removeRange(200, violationLog.length);
    }

    _persistViolation(now, reason, effectivePenalty);

    if (alert && Get.context != null) {
      Get.snackbar(
        'Security Alert',
        reason,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _persistViolation(String timestamp, String reason, int penalty) {
    if (Get.testMode) return;

    try {
      // Backward-compatible local session log.
      final box = GetStorage();
      final raw = (box.read(_storageKey) as List?) ?? const [];
      final current = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      current.insert(0, {
        'at': timestamp,
        'reason': reason,
        'penalty': penalty,
        'level': currentLevel.value?.name,
      });
      box.write(_storageKey, current.take(300).toList());
    } catch (_) {
      // Storage failures must not interrupt assessment flow.
    }

    try {
      final riskPoints = IntegrityLedgerService.riskPointsForViolation(
        reason: reason,
        penalty: penalty,
      );
      final evidenceVault = IntegrityLedgerService.buildEvidenceVaultToken({
        'at': timestamp,
        'reason': reason,
        'penalty': penalty,
        'level': currentLevel.value?.name,
        'integrityScore': integrityScore.value,
        'strictStrikes': strictViolationStrikes.value,
        'aiConfidence': _estimatedAiConfidence(),
        'sensorSnapshot': {
          'phoneMoved': isPhoneMoved.value,
          'screenRecording': isScreenRecorded.value,
          'ultrasoundDbfs': ultrasoundDbfs.value,
          'scanProgress': scanProgress.value,
          'scanLighting': scanLightingScore.value,
          'scanForbiddenObjects': scanForbiddenObjects.toList(),
          'scanRotationConfirmed': scanRotationConfirmed.value,
          'scanAiChecksPassed': scanAiChecksPassed.value,
        },
      });

      final entry = IntegrityLedgerEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}-${violationCount.value}',
        studentId: _studentId,
        sessionId: activeSessionId.value,
        occurredAt: DateTime.tryParse(timestamp) ?? DateTime.now(),
        reason: reason,
        penalty: penalty,
        level: currentLevel.value?.name,
        integrityScoreAfter: integrityScore.value,
        strictStrikesAfter: strictViolationStrikes.value,
        riskTierAtEvent: riskTier.value,
        riskScoreAfter: cumulativeRiskScore.value + riskPoints,
        evidenceVault: evidenceVault,
      );

      IntegrityLedgerService.appendViolationRecord(
        studentId: _studentId,
        entry: entry,
        riskPoints: riskPoints,
      ).then((profile) {
        final previousTier = riskTier.value;
        riskTier.value = profile.riskTier;
        cumulativeRiskScore.value = profile.cumulativeRiskScore;
        pendingLedgerSyncCount.value = profile.unsyncedLedgerCount;

        _configureRiskAdaptiveSensitivity(
          currentLevel.value ?? AssessmentIntegrityLevel.gradedAssessment,
        );

        if (shieldActive.value &&
            currentLevel.value == AssessmentIntegrityLevel.highStakesExam &&
            previousTier != profile.riskTier) {
          unawaited(_restartAcousticWatchdog());
        }
      });

      unawaited(syncIntegrityLedger());
      unawaited(
        ExamProctoringBackendService.recordProctoringAlert(
          eventType: _eventTypeFromReason(reason),
          message: reason,
          severity: penalty >= 50
              ? 'critical'
              : penalty > 0
              ? 'warning'
              : 'info',
          integrityScore: integrityScore.value,
          evidence: {
            'at': timestamp,
            'penalty': penalty,
            'level': currentLevel.value?.name,
            'strictStrikes': strictViolationStrikes.value,
            'scanRequired': scanRequired.value,
            'startupScanCompleted': examStartupScanCompleted.value,
          },
        ),
      );
    } catch (_) {
      // Keep session running if ledger/profile persistence fails.
    }
  }

  String _eventTypeFromReason(String reason) {
    final lower = reason.toLowerCase();
    if (lower.contains('speech') || lower.contains('audio')) return 'audio';
    if (lower.contains('background')) return 'app_background';
    if (lower.contains('gaze')) return 'gaze';
    if (lower.contains('multiple') || lower.contains('face')) return 'camera';
    if (lower.contains('terminal')) return 'terminal';
    if (lower.contains('screen')) return 'screen';
    return 'integrity';
  }

  double _estimatedAiConfidence() {
    var score = 0.45;

    if (scanRotationConfirmed.value) score += 0.2;
    if (scanAiChecksPassed.value) score += 0.2;
    if (scanLightingScore.value >= _minimumLightingScore) score += 0.1;
    if (scanForbiddenObjects.isEmpty) score += 0.05;

    return score.clamp(0.0, 1.0);
  }

  Future<void> _restartAcousticWatchdog() async {
    await _stopUltrasoundBackgroundCheck(disposeWatchdog: true);
    await _startUltrasoundBackgroundCheck();
  }

  @override
  void onClose() {
    unawaited(stopSession(silent: true));
    unawaited(_stopUltrasoundBackgroundCheck(disposeWatchdog: true));

    super.onClose();
  }
}
