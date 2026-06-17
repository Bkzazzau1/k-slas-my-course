import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

import '../../../data/services/exam_proctoring_backend_service.dart';
import '../../../features/local_ai/audio_ai/audio_environment_learning_service.dart';
import '../../../features/local_ai/audio_ai/environment_sound_classifier.dart';
import '../../../features/local_ai/object_ai/camera_object_source.dart';
import '../../../features/local_ai/object_ai/rust_scan_camera_object_source.dart';
import '../../../rust/api/proctoring.dart' as rust_proctoring;
import '../controller/proctoring_controller.dart';
import '../services/environment_identity_trust_gate.dart';

enum _GateStepState { pending, running, passed, failed }

enum ExamRoomEnvironmentType {
  privateIndoorRoom,
  openOutdoorSpace,
  publicSharedSpace,
  vehicle,
  darkRoom,
  unknown,
}

class EnvironmentSuitabilityDecision {
  const EnvironmentSuitabilityDecision({
    required this.type,
    required this.allowed,
    required this.message,
    required this.severity,
  });

  final ExamRoomEnvironmentType type;
  final bool allowed;
  final String message;
  final String severity;
}

class EnvironmentScanOverlay extends StatefulWidget {
  const EnvironmentScanOverlay({super.key});

  @override
  State<EnvironmentScanOverlay> createState() => _EnvironmentScanOverlayState();
}

class _EnvironmentScanOverlayState extends State<EnvironmentScanOverlay> {
  late final ProctoringController proctoring;
  CameraController? camera;
  bool cameraReady = false;
  bool cameraFailed = false;
  bool startingExam = false;
  bool returningDashboard = false;
  String statusText = 'Opening camera for live room verification...';
  String? failureText;
  String? identityDetail;
  String? audioDetail;
  String? connectionDetail;
  String? finalDetail;
  Timer? stillScanTimer;
  bool frameScanActive = false;
  bool analyzingScanFrame = false;
  bool usingStillCaptureFallback = false;
  int scanFrameCount = 0;
  List<int>? previousFrameSignature;
  double targetMotionScore = 0;
  int targetMovingFrames = 0;
  double scanLightingAverage = 0;
  double latestMovementScore = 0;
  double latestSceneDiversityScore = 1;
  double latestLightingScore = 0;
  String latestScanMode = 'not-started';
  String latestAiSource = 'none';
  bool scanCompletionReviewed = false;
  bool environmentAlertReported = false;
  final Set<String> rotationCoverage = <String>{};
  final Set<String> materialCoverage = <String>{};
  final Set<String> environmentFindings = <String>{};
  final Set<String> reportedForbiddenLabels = <String>{};
  final Map<String, String> environmentFindingTargets = <String, String>{};
  final Map<String, List<int>> acceptedSceneSignatures = <String, List<int>>{};
  final CameraObjectSource objectSource = const RustScanCameraObjectSource();
  _GateStepState identityState = _GateStepState.pending;
  _GateStepState audioState = _GateStepState.pending;
  _GateStepState connectionState = _GateStepState.pending;
  _GateStepState finalState = _GateStepState.pending;

  static const List<String> _rotationTargets = <String>[
    'front',
    'left wall',
    'back-left corner',
    'behind / back wall',
    'back-right corner',
    'right wall',
    'ceiling / up',
    'floor / down',
  ];
  static const List<String> _materialTargets = <String>[
    'desk surface',
    'lap area',
    'walls',
    'surroundings',
  ];
  static const double _movementThreshold = 0.010;
  static const double _minimumSceneChangeScore = 0.032;
  static const double _targetMotionRequired = 0.075;
  static const int _targetMovingFramesRequired = 3;
  static const Set<String> _allowedScanLabels = <String>{
    'background',
    'none',
    'clean',
  };

  @override
  void initState() {
    super.initState();
    proctoring = Get.find<ProctoringController>();
    _openCamera();
  }

  Future<void> _openCamera() async {
    setState(() {
      cameraReady = false;
      cameraFailed = false;
      failureText = null;
      identityDetail = null;
      audioDetail = null;
      connectionDetail = null;
      finalDetail = null;
      identityState = _GateStepState.pending;
      audioState = _GateStepState.pending;
      connectionState = _GateStepState.pending;
      finalState = _GateStepState.pending;
      statusText = 'Opening camera for live room verification...';
    });

    await _disposeCamera();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          cameraFailed = true;
          statusText = 'No camera was found.';
          failureText =
              'Connect a webcam and allow camera access from Windows privacy settings.';
        });
        return;
      }

      final front = cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      final selected = front.isNotEmpty ? front.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      camera = controller;
      await controller.initialize();

      await proctoring.registerEnvironmentFrameAnalysis(
        objectLabels: const <String>[],
        lightingScore: 0,
        rotationCovered: false,
      );

      if (!mounted) return;
      setState(() {
        cameraReady = true;
        statusText =
            'Camera ready. Start at the front, then rotate through each wall, back corners, ceiling, floor, desk, lap, and surroundings.';
      });
      await _startAutomaticRoomScan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cameraFailed = true;
        statusText = 'Camera could not be opened.';
        failureText = e.toString();
      });
    }
  }

  bool get scanFinished => proctoring.scanProgress.value >= 1.0 || cameraFailed;

  bool get scanPassed {
    return !cameraFailed &&
        cameraReady &&
        proctoring.scanProgress.value >= 1.0 &&
        proctoring.scanRotationConfirmed.value &&
        proctoring.scanUnauthorizedItemsReviewed.value &&
        proctoring.scanLightingScore.value >=
            proctoring.minimumScanLightingScore &&
        proctoring.scanForbiddenObjects.isEmpty &&
        _currentEnvironmentDecision.allowed;
  }

  List<String> get _failedRoomChecks {
    final failed = <String>[];
    if (cameraFailed || !cameraReady) {
      failed.add(failureText ?? 'Camera did not open successfully.');
    }
    if (!proctoring.scanRotationConfirmed.value) {
      failed.add(
        '360 room rotation failed. Capture front, left wall, back-left corner, behind/back wall, back-right corner, right wall, ceiling, and floor.',
      );
    }
    if (!proctoring.scanUnauthorizedItemsReviewed.value) {
      failed.add(
        'Unauthorized material scan was not completed. Show the desk surface, lap area, walls, and surrounding room until each area is captured.',
      );
    }
    if (proctoring.scanLightingScore.value <
        proctoring.minimumScanLightingScore) {
      failed.add(
        'Lighting failed. Move to a brighter room or switch on more light.',
      );
    }
    if (proctoring.scanForbiddenObjects.isNotEmpty) {
      failed.add(
        'Unauthorized item check failed. Remove: ${proctoring.scanForbiddenObjects.join(', ')}.',
      );
    }
    final environmentDecision = _currentEnvironmentDecision;
    if (!environmentDecision.allowed) {
      failed.add(environmentDecision.message);
    }
    return failed;
  }

  Future<EnvironmentSoundClassification> _learnAudioEnvironment() async {
    setState(() {
      audioState = _GateStepState.running;
      audioDetail =
          'Stay silent. Learning the sound of this environment before classification...';
      statusText =
          'Stay silent. Learning the sound of this environment before classification...';
    });

    try {
      final result = await AudioEnvironmentLearningService().learn(
        onProgress: (snapshot) {
          if (!mounted) return;
          final percent = (snapshot.progress * 100).round();
          setState(() {
            audioDetail =
                '${snapshot.feedback} Learning $percent%. '
                'Level ${(snapshot.averageRms * 100).round()}%, peak ${(snapshot.peakRms * 100).round()}%, voice ${(snapshot.voiceConfidence * 100).round()}%.';
            statusText = snapshot.feedback;
          });
        },
      );
      return result.classification;
    } catch (e) {
      return EnvironmentSoundClassification(
        type: EnvironmentSoundType.unknownNoise,
        label: 'microphone unavailable',
        confidence: 0,
        riskPoints: 25,
        message:
            'Microphone audio could not be captured for environment learning: $e',
      );
    }
  }

  Future<bool> _reviewSystemConnections() async {
    setState(() {
      connectionState = _GateStepState.running;
      connectionDetail = 'Reviewing system connections and accessories...';
      statusText = 'Reviewing system connections and accessories...';
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));

    const flaggedItems = <String>[];
    if (flaggedItems.isNotEmpty) {
      final message =
          'Unsupported system connection detected: ${flaggedItems.join(', ')}.';
      proctoring.registerViolation(message, penalty: 25, alert: true);
      setState(() {
        connectionState = _GateStepState.failed;
        connectionDetail = message;
        statusText = message;
      });
      return false;
    }

    setState(() {
      connectionState = _GateStepState.passed;
      connectionDetail = 'System connection review passed.';
    });
    return true;
  }

  Future<void> _startExam() async {
    if (!scanPassed || startingExam) return;
    setState(() {
      startingExam = true;
      audioState = _GateStepState.running;
      connectionState = _GateStepState.pending;
      identityState = _GateStepState.pending;
      finalState = _GateStepState.pending;
      audioDetail =
          'Stay silent. Learning the sound of this environment before classification...';
      connectionDetail = null;
      identityDetail = null;
      finalDetail = null;
      statusText =
          'Stay silent. Learning the sound of this environment before classification...';
    });

    final sound = await _learnAudioEnvironment();
    if (!mounted) return;
    if (!sound.allowedAtExamStart) {
      proctoring.registerViolation(
        sound.message,
        penalty: sound.riskPoints,
        alert: true,
      );
      setState(() {
        startingExam = false;
        audioState = _GateStepState.failed;
        audioDetail =
            '${sound.message} Sound type: ${sound.label}. Confidence ${(sound.confidence * 100).round()}%.';
        statusText = sound.message;
      });
      return;
    }

    setState(() {
      audioState = _GateStepState.passed;
      audioDetail =
          '${sound.message} Sound type: ${sound.label}. Confidence ${(sound.confidence * 100).round()}%.';
    });

    final connectionsOk = await _reviewSystemConnections();
    if (!mounted) return;
    if (!connectionsOk) {
      setState(() => startingExam = false);
      return;
    }

    setState(() {
      identityState = _GateStepState.running;
      identityDetail = 'Capturing student image and verifying face identity...';
      statusText = 'Capturing student image for identity verification...';
    });

    final c = camera;
    if (c == null || !c.value.isInitialized) {
      setState(() {
        startingExam = false;
        identityState = _GateStepState.failed;
        identityDetail = 'Camera is no longer available. Retry the room scan.';
      });
      return;
    }

    final identityResult = await const EnvironmentIdentityTrustGate().verify(
      proctoring: proctoring,
      cameraController: c,
    );
    if (!mounted) return;
    if (!identityResult.allowed) {
      setState(() {
        startingExam = false;
        identityState = _GateStepState.failed;
        identityDetail = identityResult.message;
        statusText = identityResult.message;
      });
      return;
    }

    setState(() {
      identityState = _GateStepState.passed;
      identityDetail = identityResult.configured
          ? 'Student image captured and face identity passed.'
          : 'Student image step completed in fallback mode because identity trust is not configured.';
    });

    setState(() {
      finalState = _GateStepState.running;
      finalDetail = 'Finalizing exam startup scan...';
      statusText = 'Finalizing exam startup scan...';
    });

    await proctoring.completeEnvironmentScan();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;

    if (proctoring.examStartupScanCompleted.value &&
        !proctoring.scanRequired.value) {
      setState(() {
        finalState = _GateStepState.passed;
        finalDetail = 'All checks passed. Starting exam...';
      });
      await Future<void>.delayed(const Duration(milliseconds: 260));
      await _disposeCamera();
      if (Get.isDialogOpen ?? false) Get.back<void>();
    } else {
      setState(() {
        startingExam = false;
        finalState = _GateStepState.failed;
        finalDetail =
            'Final approval failed. Fix the failed verification item and retry.';
      });
    }
  }

  Future<void> _retryScan() async {
    await _stopAutomaticRoomScan();
    proctoring.scanRequired.value = true;
    proctoring.scanInProgress.value = true;
    proctoring.scanProgress.value = 0;
    proctoring.scanAiChecksPassed.value = false;
    proctoring.scanForbiddenObjects.clear();
    proctoring.scanLightingScore.value = 0;
    proctoring.scanRotationConfirmed.value = false;
    proctoring.scanUnauthorizedItemsReviewed.value = false;
    setState(() {
      startingExam = false;
      identityState = _GateStepState.pending;
      audioState = _GateStepState.pending;
      connectionState = _GateStepState.pending;
      finalState = _GateStepState.pending;
      identityDetail = null;
      audioDetail = null;
      connectionDetail = null;
      finalDetail = null;
    });
    await _openCamera();
  }

  Future<void> _returnToDashboard() async {
    if (returningDashboard) return;
    setState(() => returningDashboard = true);
    await _disposeCamera();
    await proctoring.stopSession(silent: true, closeOverlay: false);

    if (Get.isDialogOpen ?? false) {
      Get.back<void>();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    Get.offAllNamed('/main');
  }

  Future<void> _disposeCamera() async {
    await _stopAutomaticRoomScan();
    try {
      await camera?.dispose();
    } catch (_) {}
    camera = null;
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  Future<void> _startAutomaticRoomScan() async {
    if (!cameraReady || cameraFailed || frameScanActive) return;
    scanFrameCount = 0;
    previousFrameSignature = null;
    targetMotionScore = 0;
    targetMovingFrames = 0;
    scanLightingAverage = 0;
    latestMovementScore = 0;
    latestSceneDiversityScore = 1;
    latestLightingScore = 0;
    latestScanMode = 'starting';
    latestAiSource = 'none';
    scanCompletionReviewed = false;
    environmentAlertReported = false;
    rotationCoverage.clear();
    materialCoverage.clear();
    environmentFindings.clear();
    reportedForbiddenLabels.clear();
    environmentFindingTargets.clear();
    acceptedSceneSignatures.clear();
    frameScanActive = true;

    final controller = camera;
    if (controller == null || !controller.value.isInitialized) return;

    if (_shouldUseStillCaptureFirst) {
      _startStillCaptureScan();
      return;
    }

    try {
      await controller.startImageStream(_onRoomScanFrame);
      latestScanMode = 'live-frame';
    } catch (_) {
      latestScanMode = 'stream-unavailable';
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted || !frameScanActive) return;
      _startStillCaptureScan();
    }
  }

  bool get _shouldUseStillCaptureFirst {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<void> _stopAutomaticRoomScan() async {
    stillScanTimer?.cancel();
    stillScanTimer = null;
    frameScanActive = false;
    analyzingScanFrame = false;
    usingStillCaptureFallback = false;
    final controller = camera;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
  }

  void _startStillCaptureScan() {
    usingStillCaptureFallback = true;
    latestScanMode = 'still-frame';
    stillScanTimer?.cancel();
    if (!mounted) return;
    setState(() {
      statusText =
          'Camera stream is limited, so still-frame AI scan is active. Slowly move through each target.';
    });

    stillScanTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      _captureStillScanFrame();
    });
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted && frameScanActive) _captureStillScanFrame();
    });
  }

  Future<void> _captureStillScanFrame() async {
    final controller = camera;
    if (!mounted ||
        !frameScanActive ||
        analyzingScanFrame ||
        scanFinished ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    analyzingScanFrame = true;
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _registerScanMotion(
          lightingScore: proctoring.scanLightingScore.value,
          movementScore: 0,
          signature: null,
          sceneDiversityScore: 0,
        );
        return;
      }

      scanFrameCount++;
      final luma = _averageDecodedLuma(decoded);
      final signature = _decodedFrameSignature(decoded);
      if (scanFrameCount % 3 == 0) {
        _analyzeDecodedEnvironmentObjects(decoded);
      }
      _processScanSample(luma: luma, signature: signature);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        statusText =
            'Camera is busy during still-frame scan. Keep the camera open and move slowly; the app will keep retrying. $e';
      });
    } finally {
      analyzingScanFrame = false;
    }
  }

  Future<void> _onRoomScanFrame(CameraImage image) async {
    if (!mounted || !frameScanActive || analyzingScanFrame || scanFinished) {
      return;
    }
    analyzingScanFrame = true;
    try {
      scanFrameCount++;
      final luma = _averageLuma(image);
      final signature = _frameSignature(image);
      if (scanFrameCount % 10 == 0) {
        await _analyzeEnvironmentObjects(image);
      }
      _processScanSample(luma: luma, signature: signature);
    } finally {
      analyzingScanFrame = false;
    }
  }

  void _processScanSample({
    required double luma,
    required List<int> signature,
  }) {
    final movement = _frameChangeScore(previousFrameSignature, signature);
    final sceneDiversity = _sceneDiversityScore(signature);
    previousFrameSignature = signature;
    scanLightingAverage = scanFrameCount <= 1
        ? luma
        : ((scanLightingAverage * (scanFrameCount - 1)) + luma) /
              scanFrameCount;
    latestMovementScore = movement;
    latestSceneDiversityScore = sceneDiversity;
    latestLightingScore = _lightingScoreFromLuma(scanLightingAverage);

    _registerScanMotion(
      lightingScore: latestLightingScore,
      movementScore: movement,
      signature: signature,
      sceneDiversityScore: sceneDiversity,
    );
  }

  double _averageLuma(CameraImage image) {
    if (image.planes.isEmpty || image.planes.first.bytes.isEmpty) return 0.5;
    final bytes = image.planes.first.bytes;
    final step = math.max(1, bytes.length ~/ 600);
    var total = 0;
    var count = 0;
    for (var i = 0; i < bytes.length; i += step) {
      total += bytes[i];
      count++;
    }
    if (count == 0) return 0.5;
    return (total / count / 255).clamp(0.0, 1.0);
  }

  List<int> _frameSignature(CameraImage image) {
    if (image.planes.isEmpty || image.planes.first.bytes.isEmpty) {
      return const <int>[128];
    }
    final bytes = image.planes.first.bytes;
    const buckets = 48;
    final signature = <int>[];
    for (var bucket = 0; bucket < buckets; bucket++) {
      final start = (bytes.length * bucket / buckets).floor();
      final end = (bytes.length * (bucket + 1) / buckets).floor();
      if (end <= start) {
        signature.add(bytes[start.clamp(0, bytes.length - 1)]);
        continue;
      }
      var total = 0;
      var count = 0;
      final step = math.max(1, (end - start) ~/ 12);
      for (var i = start; i < end; i += step) {
        total += bytes[i];
        count++;
      }
      signature.add(count == 0 ? 128 : (total / count).round());
    }
    return signature;
  }

  double _averageDecodedLuma(img.Image image) {
    final stepX = math.max(1, image.width ~/ 24);
    final stepY = math.max(1, image.height ~/ 24);
    var total = 0.0;
    var count = 0;
    for (var y = 0; y < image.height; y += stepY) {
      for (var x = 0; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        total += (pixel.r * 0.299) + (pixel.g * 0.587) + (pixel.b * 0.114);
        count++;
      }
    }
    if (count == 0) return 0.5;
    return (total / count / 255).clamp(0.0, 1.0);
  }

  List<int> _decodedFrameSignature(img.Image image) {
    const buckets = 48;
    final signature = <int>[];
    for (var bucket = 0; bucket < buckets; bucket++) {
      final x = ((bucket % 8) + 0.5) * image.width / 8;
      final y = ((bucket ~/ 8) + 0.5) * image.height / 6;
      final pixel = image.getPixel(
        x.floor().clamp(0, image.width - 1),
        y.floor().clamp(0, image.height - 1),
      );
      final luma = (pixel.r * 0.299) + (pixel.g * 0.587) + (pixel.b * 0.114);
      signature.add(luma.round().clamp(0, 255));
    }
    return signature;
  }

  double _frameChangeScore(List<int>? previous, List<int> current) {
    if (previous == null || previous.isEmpty || current.isEmpty) return 0;
    final length = math.min(previous.length, current.length);
    var totalDifference = 0;
    for (var i = 0; i < length; i++) {
      totalDifference += (current[i] - previous[i]).abs();
    }
    return (totalDifference / length / 255).clamp(0.0, 1.0);
  }

  double _sceneDiversityScore(List<int> current) {
    if (acceptedSceneSignatures.isEmpty) return 1.0;

    var bestDifference = 1.0;
    for (final previous in acceptedSceneSignatures.values) {
      final length = math.min(previous.length, current.length);
      if (length == 0) continue;

      var totalDifference = 0;
      for (var i = 0; i < length; i++) {
        totalDifference += (current[i] - previous[i]).abs();
      }

      final difference = (totalDifference / length / 255).clamp(0.0, 1.0);
      bestDifference = math.min(bestDifference, difference);
    }

    return bestDifference;
  }

  double _lightingScoreFromLuma(double luma) {
    final distanceFromIdeal = (luma - 0.55).abs();
    return (1 - (distanceFromIdeal * 1.6)).clamp(0.0, 1.0);
  }

  Future<void> _analyzeEnvironmentObjects(CameraImage image) async {
    try {
      final observations = await objectSource.analyzeFrame(
        image: image,
        timestamp: DateTime.now(),
      );
      if (observations.isEmpty) return;
      final scanTarget = _currentScanTarget ?? 'startup room scan';
      latestAiSource = usingStillCaptureFallback
          ? 'still-frame rust'
          : 'live-frame rust';
      for (final observation in observations) {
        final label = observation.label.trim();
        if (label.isEmpty) continue;
        environmentFindings.add(label);
        environmentFindingTargets[label] = scanTarget;
      }
    } catch (_) {
      // Frame coverage still proceeds when the local detector is unavailable.
    }
  }

  void _analyzeDecodedEnvironmentObjects(img.Image image) {
    try {
      final decision = rust_proctoring.analyzeScanFrame(
        plane0Bytes: _decodedLumaPlane(image),
        width: image.width,
        height: image.height,
        bytesPerRow: image.width,
        pixelFormat: 'luma8',
      );
      final scanTarget = _currentScanTarget ?? 'startup room scan';
      latestAiSource = 'still-frame rust';
      for (final rawLabel in decision.objectLabels) {
        final label = rawLabel.trim();
        if (label.isEmpty) continue;
        if (_allowedScanLabels.contains(label.toLowerCase())) continue;
        environmentFindings.add(label);
        environmentFindingTargets[label] = scanTarget;
      }
    } catch (_) {
      // Still-frame scan should continue even if the detector is unavailable.
    }
  }

  List<int> _decodedLumaPlane(img.Image image) {
    final bytes = List<int>.filled(image.width * image.height, 0);
    var offset = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        bytes[offset++] =
            ((pixel.r * 0.299) + (pixel.g * 0.587) + (pixel.b * 0.114))
                .round()
                .clamp(0, 255);
      }
    }
    return bytes;
  }

  Future<void> _reportScanAlertToBackend({
    required String eventType,
    required String message,
    required String severity,
    required Map<String, dynamic> evidence,
  }) async {
    await ExamProctoringBackendService.recordProctoringAlert(
      eventType: eventType,
      message: message,
      severity: severity,
      integrityScore: proctoring.integrityScore.value,
      evidence: evidence,
    );
  }

  Future<void> _handleForbiddenScanFindings({
    required List<String> labels,
    required String scanTarget,
  }) async {
    final newLabels = labels
        .where((label) => !reportedForbiddenLabels.contains(label))
        .toList(growable: false);
    if (newLabels.isEmpty) return;

    reportedForbiddenLabels.addAll(newLabels);
    final message =
        'Possible unauthorized item detected: ${newLabels.join(', ')}. Remove it and rescan before the exam can start.';

    proctoring.registerViolation(
      message,
      penalty: 25,
      alert: true,
      eventType: 'forbiddenItemDetected',
      severity: 'high',
      confidence: 0.80,
      metadata: <String, Object?>{
        'labels': newLabels,
        'scanTarget': scanTarget,
        'source': 'startup_room_scan',
        'lightingScore': proctoring.scanLightingScore.value,
        'scanProgress': proctoring.scanProgress.value,
      },
    );

    await _reportScanAlertToBackend(
      eventType: 'forbidden_item_detected',
      message: message,
      severity: 'high',
      evidence: <String, dynamic>{
        'labels': newLabels,
        'scan_target': scanTarget,
        'environment_type': _currentEnvironmentDecision.type.name,
        'lighting_score': proctoring.scanLightingScore.value,
        'scan_progress': proctoring.scanProgress.value,
        'source': 'startup_room_scan',
      },
    );

    if (!mounted) return;
    setState(() {
      statusText =
          '$message This event has been recorded for exam integrity review.';
    });
  }

  Future<void> _handleEnvironmentSuitability(
    EnvironmentSuitabilityDecision decision,
  ) async {
    if (decision.allowed || environmentAlertReported) return;
    environmentAlertReported = true;

    proctoring.registerViolation(
      decision.message,
      penalty: decision.severity == 'high' ? 25 : 15,
      alert: true,
      eventType: 'environmentNotSuitable',
      severity: decision.severity,
      confidence: 0.75,
      metadata: <String, Object?>{
        'environmentType': decision.type.name,
        'labels': environmentFindings.toList(growable: false),
        'lightingScore': proctoring.scanLightingScore.value,
        'source': 'startup_room_scan',
      },
    );

    await _reportScanAlertToBackend(
      eventType: 'environment_not_suitable',
      message: decision.message,
      severity: decision.severity,
      evidence: <String, dynamic>{
        'environment_type': decision.type.name,
        'labels': environmentFindings.toList(growable: false),
        'lighting_score': proctoring.scanLightingScore.value,
        'source': 'startup_room_scan',
      },
    );
  }

  EnvironmentSuitabilityDecision get _currentEnvironmentDecision {
    return _classifyEnvironment(
      labels: environmentFindings.toList(growable: false),
      lightingScore: proctoring.scanLightingScore.value,
    );
  }

  EnvironmentSuitabilityDecision _classifyEnvironment({
    required List<String> labels,
    required double lightingScore,
  }) {
    final lower = labels.map((label) => label.toLowerCase()).toList();

    if (lightingScore < proctoring.minimumScanLightingScore) {
      return const EnvironmentSuitabilityDecision(
        type: ExamRoomEnvironmentType.darkRoom,
        allowed: false,
        severity: 'medium',
        message:
            'Lighting is too low for exam monitoring. Move to a brighter room or switch on more light.',
      );
    }

    final vehicleHints = <String>['car', 'vehicle', 'bus', 'taxi'];
    if (vehicleHints.any(
      (hint) => lower.any((label) => label.contains(hint)),
    )) {
      return const EnvironmentSuitabilityDecision(
        type: ExamRoomEnvironmentType.vehicle,
        allowed: false,
        severity: 'high',
        message:
            'Vehicle environment detected. This environment is not acceptable for this exam. Move to a private, quiet room and rescan.',
      );
    }

    final outdoorHints = <String>['road', 'street', 'outdoor'];
    if (outdoorHints.any(
      (hint) => lower.any((label) => label.contains(hint)),
    )) {
      return const EnvironmentSuitabilityDecision(
        type: ExamRoomEnvironmentType.openOutdoorSpace,
        allowed: false,
        severity: 'high',
        message:
            'Open outdoor environment detected. This environment is not acceptable for this exam. Move to a private, quiet room and rescan.',
      );
    }

    final publicHints = <String>[
      'market',
      'shop',
      'restaurant',
      'cafe',
      'crowd',
      'multiple person',
      'multiple people',
      'person group',
      'corridor',
      'classroom',
    ];
    if (publicHints.any((hint) => lower.any((label) => label.contains(hint)))) {
      return const EnvironmentSuitabilityDecision(
        type: ExamRoomEnvironmentType.publicSharedSpace,
        allowed: false,
        severity: 'high',
        message:
            'Open or public environment detected. This environment is not acceptable for this exam. Move to a private, quiet room and rescan.',
      );
    }

    return const EnvironmentSuitabilityDecision(
      type: ExamRoomEnvironmentType.privateIndoorRoom,
      allowed: true,
      severity: 'low',
      message:
          'Environment detected: private indoor room. This is acceptable for the exam.',
    );
  }

  List<String> _forbiddenScanLabels(List<String> labels) {
    return labels
        .where((label) {
          final lower = label.toLowerCase();
          return lower.contains('phone') ||
              lower.contains('mobile') ||
              lower.contains('paper') ||
              lower.contains('book') ||
              lower.contains('note') ||
              lower.contains('second monitor') ||
              lower.contains('tablet') ||
              lower.contains('earpiece') ||
              lower.contains('headphone') ||
              lower.contains('earphone') ||
              lower.contains('calculator') ||
              lower.contains('another person') ||
              lower.contains('multiple person') ||
              lower.contains('multiple people') ||
              lower.contains('screen') ||
              lower.contains('television');
        })
        .toList(growable: false);
  }

  void _registerScanMotion({
    required double lightingScore,
    required double movementScore,
    required List<int>? signature,
    required double sceneDiversityScore,
  }) {
    if (!mounted || !cameraReady || cameraFailed || startingExam) return;

    proctoring.registerEnvironmentFrameAnalysis(
      objectLabels: environmentFindings.toList(growable: false),
      lightingScore: lightingScore,
      rotationCovered: rotationCoverage.length == _rotationTargets.length,
    );

    final target = _currentScanTarget;
    if (target == null) return;

    if (movementScore < _movementThreshold) {
      final lightingPercent = (lightingScore * 100).round();
      statusText =
          'Light $lightingPercent%. Camera is still. Slowly move the camera to capture $target before scan progress can continue.';
      _setScanProgressFromCoverage();
      setState(() {});
      return;
    }

    if (signature == null) {
      statusText =
          'Camera frame could not be read clearly. Move slowly and keep the room visible.';
      targetMotionScore = 0;
      targetMovingFrames = 0;
      _setScanProgressFromCoverage();
      setState(() {});
      return;
    }

    if (acceptedSceneSignatures.isNotEmpty &&
        sceneDiversityScore < _minimumSceneChangeScore) {
      statusText =
          'This looks like the same area already captured. Rotate further until a different part of the room is visible.';
      targetMotionScore = 0;
      targetMovingFrames = 0;
      _setScanProgressFromCoverage();
      setState(() {});
      return;
    }

    targetMotionScore = (targetMotionScore + movementScore).clamp(
      0.0,
      _targetMotionRequired,
    );
    targetMovingFrames++;

    if (targetMotionScore >= _targetMotionRequired &&
        targetMovingFrames >= _targetMovingFramesRequired) {
      if (rotationCoverage.length < _rotationTargets.length) {
        rotationCoverage.add(target);
      } else {
        materialCoverage.add(target);
      }
      acceptedSceneSignatures[target] = List<int>.from(signature);
      targetMotionScore = 0;
      targetMovingFrames = 0;
    }

    final rotationCovered = rotationCoverage.length == _rotationTargets.length;
    final materialCovered = materialCoverage.length == _materialTargets.length;

    _setScanProgressFromCoverage();
    proctoring.registerEnvironmentFrameAnalysis(
      objectLabels: environmentFindings.toList(growable: false),
      lightingScore: lightingScore,
      rotationCovered: rotationCovered,
    );
    proctoring.scanUnauthorizedItemsReviewed.value = materialCovered;

    if (rotationCovered && materialCovered) {
      proctoring.scanProgress.value = 1.0;
      statusText = environmentFindings.isEmpty
          ? 'Automatic AI room scan completed. No unauthorized item was reported.'
          : 'Automatic AI room scan completed. Review detected item: ${environmentFindings.join(', ')}.';
      unawaited(_reviewCompletedRoomScan());
      _stopAutomaticRoomScan();
    } else if (!rotationCovered) {
      final nextTarget = _rotationTargets[rotationCoverage.length];
      final mode = usingStillCaptureFallback ? 'still-frame' : 'live-frame';
      statusText =
          '360 $mode scan in progress. Slowly move camera to capture $nextTarget.';
    } else {
      final nextTarget = _materialTargets[materialCoverage.length];
      final mode = usingStillCaptureFallback ? 'still-frame' : 'live-frame';
      statusText =
          'Rotation captured. $mode scan: slowly move camera to show $nextTarget for AI unauthorized scan.';
    }
    setState(() {});
  }

  Future<void> _reviewCompletedRoomScan() async {
    if (scanCompletionReviewed) return;
    scanCompletionReviewed = true;

    final labels = environmentFindings.toList(growable: false);
    final forbiddenLabels = _forbiddenScanLabels(labels);
    if (forbiddenLabels.isNotEmpty) {
      final targets = forbiddenLabels
          .map((label) => environmentFindingTargets[label])
          .whereType<String>()
          .toSet()
          .join(', ');
      await _handleForbiddenScanFindings(
        labels: forbiddenLabels,
        scanTarget: targets.isEmpty ? 'startup room scan' : targets,
      );
    }

    final environmentDecision = _currentEnvironmentDecision;
    await _handleEnvironmentSuitability(environmentDecision);
    if (!mounted) return;
    if (forbiddenLabels.isEmpty) {
      setState(() {
        statusText = environmentDecision.allowed
            ? environmentDecision.message
            : environmentDecision.message;
      });
    }
  }

  String? get _currentScanTarget {
    if (rotationCoverage.length < _rotationTargets.length) {
      return _rotationTargets[rotationCoverage.length];
    }
    if (materialCoverage.length < _materialTargets.length) {
      return _materialTargets[materialCoverage.length];
    }
    return null;
  }

  void _setScanProgressFromCoverage() {
    final targetPartial = (targetMotionScore / _targetMotionRequired).clamp(
      0.0,
      1.0,
    );
    final rotationUnit = 0.55 / _rotationTargets.length;
    final materialUnit = 0.45 / _materialTargets.length;
    final partial = rotationCoverage.length < _rotationTargets.length
        ? targetPartial * rotationUnit
        : materialCoverage.length < _materialTargets.length
        ? targetPartial * materialUnit
        : 0.0;
    final progress =
        (rotationCoverage.length * rotationUnit) +
        (materialCoverage.length * materialUnit) +
        partial;
    proctoring.scanProgress.value = progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          if (scanFinished) return _reportPage(context);
          return _scanPage(context);
        }),
      ),
    );
  }

  Widget _scanPage(BuildContext context) {
    final progress = proctoring.scanProgress.value.clamp(0.0, 1.0);
    return Stack(
      children: [
        Positioned.fill(child: _cameraLayer()),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        Positioned(
          top: 48,
          left: 14,
          right: 14,
          child: Row(
            children: [
              _topPill('Scan ${(progress * 100).round()}%', progress >= 1.0),
              const SizedBox(width: 8),
              _topPill(
                'Light ${(proctoring.scanLightingScore.value * 100).round()}%',
                proctoring.scanLightingScore.value >=
                    proctoring.minimumScanLightingScore,
              ),
              const SizedBox(width: 8),
              _topPill('Rotation', proctoring.scanRotationConfirmed.value),
              const SizedBox(width: 8),
              _topPill(
                'Materials',
                proctoring.scanUnauthorizedItemsReviewed.value,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: _bottomPanel(progress),
        ),
      ],
    );
  }

  Widget _reportPage(BuildContext context) {
    final progress = proctoring.scanProgress.value.clamp(0.0, 1.0);
    final passed = scanPassed;
    final lightOk =
        proctoring.scanLightingScore.value >=
        proctoring.minimumScanLightingScore;
    final items = proctoring.scanForbiddenObjects.toList();
    final failures = _failedRoomChecks;
    final cs = Theme.of(context).colorScheme;
    final environmentDecision = _currentEnvironmentDecision;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF101827),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        passed ? Icons.task_alt_rounded : Icons.warning_rounded,
                        color: passed ? Colors.green : Colors.orange,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          passed
                              ? 'Room checks passed — continue verification'
                              : 'Room checks failed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'Each exam startup check runs one by one. Audio learning and system connection review happen before final start.'
                        : 'Fix every failed item below before the exam can start.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Room scan ${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(999),
                    color: passed ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('Room verification'),
                  _reportRow(
                    '1. Camera access',
                    cameraReady && !cameraFailed,
                    cameraReady
                        ? 'Camera opened successfully.'
                        : (failureText ?? 'Camera access failed.'),
                  ),
                  _reportRow(
                    '2. 360 room rotation capture',
                    proctoring.scanRotationConfirmed.value,
                    proctoring.scanRotationConfirmed.value
                        ? 'Front, side walls, back wall/corners, ceiling, and floor capture completed.'
                        : 'Rotation failed. Rotate the camera around the room again.',
                  ),
                  _reportRow(
                    '3. Lighting check',
                    lightOk,
                    lightOk
                        ? 'Lighting is acceptable.'
                        : 'Lighting failed. Move to a brighter room or switch on more light.',
                  ),
                  _reportRow(
                    '4. AI unauthorized item scan',
                    proctoring.scanUnauthorizedItemsReviewed.value &&
                        items.isEmpty,
                    !proctoring.scanUnauthorizedItemsReviewed.value
                        ? 'Pending. Show your desk surface, lap area, walls, and surrounding room before this can pass.'
                        : items.isEmpty
                        ? 'No unauthorized item was reported.'
                        : 'Unauthorized items detected. Remove: ${items.join(', ')}',
                  ),
                  _reportRow(
                    '5. Environment suitability',
                    environmentDecision.allowed,
                    environmentDecision.allowed
                        ? '${environmentDecision.message} Status: acceptable.'
                        : environmentDecision.message,
                  ),
                  if (failures.isNotEmpty) _failurePanel(failures),
                  const SizedBox(height: 8),
                  _sectionTitle(
                    'Identity, audio, connections, and final approval',
                  ),
                  _stepRow(
                    '6. Audio environment learning and sound type',
                    audioState,
                    audioDetail ??
                        'Pending. The app learns room sound and identifies noise type.',
                  ),
                  _stepRow(
                    '7. System connection review',
                    connectionState,
                    connectionDetail ??
                        'Pending. System connections are reviewed before final start.',
                  ),
                  _stepRow(
                    '8. Capture student image and verify face',
                    identityState,
                    identityDetail ??
                        'Pending. This runs after audio and system checks pass.',
                  ),
                  _stepRow(
                    '9. Final exam startup approval',
                    finalState,
                    finalDetail ??
                        'Pending. Exam opens only after all checks pass.',
                  ),
                  const SizedBox(height: 16),
                  if (passed)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: startingExam ? null : _startExam,
                        icon: startingExam
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          startingExam
                              ? 'Running verification...'
                              : 'Run next verification / start exam',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: returningDashboard ? null : _retryScan,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Fix failed checks and rescan'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: returningDashboard
                            ? null
                            : _returnToDashboard,
                        icon: const Icon(Icons.dashboard_rounded),
                        label: Text(
                          returningDashboard
                              ? 'Returning...'
                              : 'Return to dashboard / change environment',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cameraLayer() {
    if (cameraFailed) {
      return Center(
        child: Text(
          failureText ?? 'Camera failed',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    final c = camera;
    if (!cameraReady || c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
        child: CameraPreview(c),
      ),
    );
  }

  Widget _bottomPanel(double progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _coveragePanel(),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: returningDashboard ? null : _returnToDashboard,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.dashboard_rounded),
            label: Text(
              returningDashboard ? 'Returning...' : 'Return to dashboard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _coveragePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _coverageGroup(
          title: '360 rotation capture',
          icon: Icons.threesixty_rounded,
          targets: _rotationTargets,
          covered: rotationCoverage,
        ),
        const SizedBox(height: 8),
        _coverageGroup(
          title: 'AI unauthorized scan',
          icon: Icons.manage_search_rounded,
          targets: _materialTargets,
          covered: materialCoverage,
        ),
        if (environmentFindings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: Text(
              'Detected item: ${environmentFindings.join(', ')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _calibrationPanel(),
      ],
    );
  }

  Widget _calibrationPanel() {
    final currentTarget = _currentScanTarget ?? 'complete';
    final accepted = acceptedSceneSignatures.keys.join(', ');
    final findings = environmentFindings.isEmpty
        ? 'none'
        : environmentFindings.join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Calibration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                latestScanMode,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _debugChip('target', currentTarget),
              _debugChip('frames', '$scanFrameCount'),
              _debugChip('light', '${(latestLightingScore * 100).round()}%'),
              _debugChip('motion', latestMovementScore.toStringAsFixed(3)),
              _debugChip('scene', latestSceneDiversityScore.toStringAsFixed(3)),
              _debugChip(
                'target motion',
                '${targetMotionScore.toStringAsFixed(3)}/${_targetMotionRequired.toStringAsFixed(3)}',
              ),
              _debugChip(
                'moving frames',
                '$targetMovingFrames/$_targetMovingFramesRequired',
              ),
              _debugChip('AI', latestAiSource),
              _debugChip('labels', findings),
              _debugChip('accepted', accepted.isEmpty ? 'none' : accepted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _debugChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _coverageGroup({
    required String title,
    required IconData icon,
    required List<String> targets,
    required Set<String> covered,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: targets
              .map((target) {
                final captured = covered.contains(target);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: captured
                        ? Colors.green.withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: captured
                          ? Colors.greenAccent
                          : Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        captured
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: captured
                            ? Colors.greenAccent
                            : Colors.white.withValues(alpha: 0.72),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        target,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _failurePanel(List<String> failures) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Failed items to fix',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          ...failures.map(
            (failure) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $failure',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String title, bool ok, String detail) {
    return _statusRow(
      title,
      ok ? _GateStepState.passed : _GateStepState.failed,
      detail,
    );
  }

  Widget _stepRow(String title, _GateStepState state, String detail) {
    return _statusRow(title, state, detail);
  }

  Widget _statusRow(String title, _GateStepState state, String detail) {
    final (icon, color) = switch (state) {
      _GateStepState.pending => (
        Icons.radio_button_unchecked_rounded,
        Colors.blueGrey,
      ),
      _GateStepState.running => (Icons.hourglass_bottom_rounded, Colors.blue),
      _GateStepState.passed => (Icons.check_circle_rounded, Colors.green),
      _GateStepState.failed => (Icons.error_rounded, Colors.orange),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topPill(String text, bool ok) {
    final color = ok ? Colors.green : Colors.orange;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
