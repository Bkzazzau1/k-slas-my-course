import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../rust/api/proctoring.dart' as rust_proctoring;
import '../../rust/frb_generated.dart';

class RustBrainService {
  RustBrainService._();

  static final RustBrainService instance = RustBrainService._();

  Future<void>? _initFuture;
  bool _initAttempted = false;
  bool _isAvailable = false;
  Future<VisionModelLoadStatus>? _visionModelFuture;
  VisionModelLoadStatus _visionModelStatus = const VisionModelLoadStatus(
    loaded: false,
    modelName: 'unloaded',
    inputWidth: 0,
    inputHeight: 0,
    confidenceThreshold: 0,
    labelCount: 0,
    message: 'vision model not loaded',
  );

  bool get isAvailable => _isAvailable;
  VisionModelLoadStatus get visionModelStatus => _visionModelStatus;

  Future<void> warmUp() async {
    if (kIsWeb) return;
    if (_isAvailable) return;

    _initFuture ??= _init();
    await _initFuture;
  }

  Future<void> _init() async {
    if (_initAttempted) return;
    _initAttempted = true;
    try {
      await BrainCoreApi.init();
      _isAvailable = true;
    } catch (_) {
      _isAvailable = false;
    }
  }

  Future<VisionModelLoadStatus> ensureVisionModelLoaded() async {
    if (kIsWeb) {
      return _visionModelStatus;
    }

    await warmUp();
    if (!_isAvailable) {
      _visionModelStatus = const VisionModelLoadStatus(
        loaded: false,
        modelName: 'unloaded',
        inputWidth: 0,
        inputHeight: 0,
        confidenceThreshold: 0,
        labelCount: 0,
        message: 'rust runtime unavailable',
      );
      return _visionModelStatus;
    }

    if (_visionModelStatus.loaded) {
      return _visionModelStatus;
    }

    try {
      final status = rust_proctoring.currentVisionModelStatus();
      if (status.loaded) {
        _visionModelStatus = VisionModelLoadStatus(
          loaded: status.loaded,
          modelName: status.modelName,
          inputWidth: status.inputWidth,
          inputHeight: status.inputHeight,
          confidenceThreshold: status.confidenceThreshold,
          labelCount: status.labelCount,
          message: status.message,
        );
        return _visionModelStatus;
      }
    } catch (_) {
      _isAvailable = false;
      return const VisionModelLoadStatus(
        loaded: false,
        modelName: 'unloaded',
        inputWidth: 0,
        inputHeight: 0,
        confidenceThreshold: 0,
        labelCount: 0,
        message: 'rust runtime unavailable',
      );
    }

    _visionModelFuture ??= _loadVisionModelFromAssets();
    _visionModelStatus = await _visionModelFuture!;
    if (!_visionModelStatus.loaded) {
      _visionModelFuture = null;
    }
    return _visionModelStatus;
  }

  Future<VisionModelLoadStatus> _loadVisionModelFromAssets() async {
    try {
      final manifestSource = await rootBundle.loadString(
        'assets/ml_models/vision_manifest.json',
      );
      final manifestMap = jsonDecode(manifestSource) as Map<String, dynamic>;
      final modelAsset = (manifestMap['modelAsset'] ?? '').toString().trim();
      if (modelAsset.isEmpty) {
        rust_proctoring.clearVisionModel();
        return const VisionModelLoadStatus(
          loaded: false,
          modelName: 'unloaded',
          inputWidth: 0,
          inputHeight: 0,
          confidenceThreshold: 0,
          labelCount: 0,
          message: 'vision manifest does not declare a model asset',
        );
      }

      final modelData = await rootBundle.load(modelAsset);
      final status = rust_proctoring.loadVisionModel(
        manifestJson: manifestSource,
        modelBytes: modelData.buffer.asUint8List(),
      );
      return VisionModelLoadStatus(
        loaded: status.loaded,
        modelName: status.modelName,
        inputWidth: status.inputWidth,
        inputHeight: status.inputHeight,
        confidenceThreshold: status.confidenceThreshold,
        labelCount: status.labelCount,
        message: status.message,
      );
    } catch (error) {
      rust_proctoring.clearVisionModel();
      return VisionModelLoadStatus(
        loaded: false,
        modelName: 'unloaded',
        inputWidth: 0,
        inputHeight: 0,
        confidenceThreshold: 0,
        labelCount: 0,
        message: error.toString(),
      );
    }
  }

  AcousticChunkDecision analyzeAcousticChunk({
    required Uint8List pcm16Bytes,
    required double lossThresholdDbfs,
    required int lossStreak,
    required int lossSamplesToTrigger,
    required double speechThresholdDbfs,
    required int speechStreak,
    required int speechSamplesToTrigger,
    required DateTime lastSpeechStrikeAt,
    required DateTime now,
    int speechCooldownMs = 8000,
  }) {
    if (_isAvailable) {
      try {
        final decision = rust_proctoring.analyzeAcousticChunk(
          pcm16Bytes: pcm16Bytes,
          lossThresholdDbfs: lossThresholdDbfs,
          lossStreak: lossStreak,
          lossSamplesToTrigger: lossSamplesToTrigger,
          speechThresholdDbfs: speechThresholdDbfs,
          speechStreak: speechStreak,
          speechSamplesToTrigger: speechSamplesToTrigger,
          lastSpeechStrikeAtMs: _toPlatformInt64(
            lastSpeechStrikeAt.millisecondsSinceEpoch,
          ),
          speechCooldownMs: _toPlatformInt64(speechCooldownMs),
          nowMs: _toPlatformInt64(now.millisecondsSinceEpoch),
        );
        return AcousticChunkDecision(
          dbfs: decision.dbfs,
          updatedLossStreak: decision.updatedLossStreak,
          shouldTriggerScan: decision.shouldTriggerScan,
          normalizedTetherSignal: decision.normalizedTetherSignal,
          updatedSpeechStreak: decision.updatedSpeechStreak,
          shouldTriggerSpeech: decision.shouldTriggerSpeech,
          updatedLastSpeechStrikeAt: DateTime.fromMillisecondsSinceEpoch(
            _fromPlatformInt64(decision.updatedLastSpeechStrikeAtMs),
          ),
        );
      } catch (_) {
        _isAvailable = false;
      }
    }

    final dbfs = _pcm16RmsDbfs(pcm16Bytes);
    final belowThreshold = dbfs <= lossThresholdDbfs;
    final updatedLossStreak = belowThreshold ? lossStreak + 1 : 0;
    final shouldTriggerScan =
        lossSamplesToTrigger > 0 && updatedLossStreak >= lossSamplesToTrigger;

    final speechDetected = dbfs > speechThresholdDbfs;
    final nextSpeechStreak = speechDetected ? speechStreak + 1 : 0;
    final shouldTriggerSpeech =
        speechSamplesToTrigger > 0 &&
        nextSpeechStreak >= speechSamplesToTrigger &&
        now.difference(lastSpeechStrikeAt).inMilliseconds >= speechCooldownMs;

    return AcousticChunkDecision(
      dbfs: dbfs,
      updatedLossStreak: updatedLossStreak,
      shouldTriggerScan: shouldTriggerScan,
      normalizedTetherSignal: _normalizeSignal(dbfs),
      updatedSpeechStreak: shouldTriggerSpeech ? 0 : nextSpeechStreak,
      shouldTriggerSpeech: shouldTriggerSpeech,
      updatedLastSpeechStrikeAt: shouldTriggerSpeech ? now : lastSpeechStrikeAt,
    );
  }

  MotionDecision analyzeMotionSample({
    required double x,
    required double y,
    required double z,
    required double xThreshold,
    required double yThreshold,
    required double zThreshold,
    required DateTime now,
    required DateTime lastViolationAt,
    required int cooldownMs,
    required DateTime windowStartAt,
    required int windowMs,
    required int burstCount,
    required int burstThreshold,
  }) {
    if (_isAvailable) {
      try {
        final decision = rust_proctoring.analyzeMotionSample(
          x: x,
          y: y,
          z: z,
          xThreshold: xThreshold,
          yThreshold: yThreshold,
          zThreshold: zThreshold,
          nowMs: _toPlatformInt64(now.millisecondsSinceEpoch),
          lastViolationAtMs: _toPlatformInt64(
            lastViolationAt.millisecondsSinceEpoch,
          ),
          cooldownMs: _toPlatformInt64(cooldownMs),
          windowStartMs: _toPlatformInt64(windowStartAt.millisecondsSinceEpoch),
          windowMs: _toPlatformInt64(windowMs),
          burstCount: burstCount,
          burstThreshold: burstThreshold,
        );
        return MotionDecision(
          moved: decision.moved,
          shouldLogViolation: decision.shouldLogViolation,
          shouldTriggerScan: decision.shouldTriggerScan,
          updatedLastViolationAt: DateTime.fromMillisecondsSinceEpoch(
            _fromPlatformInt64(decision.updatedLastViolationAtMs),
          ),
          updatedWindowStartAt: DateTime.fromMillisecondsSinceEpoch(
            _fromPlatformInt64(decision.updatedWindowStartMs),
          ),
          updatedBurstCount: decision.updatedBurstCount,
        );
      } catch (_) {
        _isAvailable = false;
      }
    }

    final moved =
        x.abs() > xThreshold || y.abs() > yThreshold || z.abs() < zThreshold;
    if (!moved) {
      return MotionDecision(
        moved: false,
        shouldLogViolation: false,
        shouldTriggerScan: false,
        updatedLastViolationAt: lastViolationAt,
        updatedWindowStartAt: windowStartAt,
        updatedBurstCount: burstCount,
      );
    }

    if (now.difference(lastViolationAt).inMilliseconds < cooldownMs) {
      return MotionDecision(
        moved: true,
        shouldLogViolation: false,
        shouldTriggerScan: false,
        updatedLastViolationAt: lastViolationAt,
        updatedWindowStartAt: windowStartAt,
        updatedBurstCount: burstCount,
      );
    }

    var nextWindowStart = windowStartAt;
    var nextBurstCount = burstCount;
    var shouldTriggerScan = false;

    if (burstThreshold > 0) {
      if (now.difference(windowStartAt).inMilliseconds > windowMs) {
        nextWindowStart = now;
        nextBurstCount = 1;
      } else {
        nextBurstCount += 1;
      }

      if (nextBurstCount >= burstThreshold) {
        shouldTriggerScan = true;
        nextBurstCount = 0;
        nextWindowStart = now;
      }
    }

    return MotionDecision(
      moved: true,
      shouldLogViolation: true,
      shouldTriggerScan: shouldTriggerScan,
      updatedLastViolationAt: now,
      updatedWindowStartAt: nextWindowStart,
      updatedBurstCount: nextBurstCount,
    );
  }

  RotationDecision updateRotationProgress({
    required double x,
    required double y,
    required double z,
    required double accumulated,
    required double currentProgress,
    double deltaScale = 0.03,
    double minDelta = 0.015,
    double targetAccumulated = 6.4,
  }) {
    if (_isAvailable) {
      try {
        final decision = rust_proctoring.updateRotationProgress(
          x: x,
          y: y,
          z: z,
          accumulated: accumulated,
          currentProgress: currentProgress,
          deltaScale: deltaScale,
          minDelta: minDelta,
          targetAccumulated: targetAccumulated,
        );
        return RotationDecision(
          updatedAccumulated: decision.updatedAccumulated,
          updatedProgress: decision.updatedProgress,
          rotationConfirmed: decision.rotationConfirmed,
        );
      } catch (_) {
        _isAvailable = false;
      }
    }

    final delta = (x.abs() + y.abs() + z.abs()) * deltaScale;
    if (delta <= minDelta) {
      return RotationDecision(
        updatedAccumulated: accumulated,
        updatedProgress: currentProgress,
        rotationConfirmed: currentProgress >= 1.0,
      );
    }

    final updatedAccumulated = accumulated + delta;
    final computedProgress = targetAccumulated <= 0
        ? 1.0
        : (updatedAccumulated / targetAccumulated).clamp(0.0, 1.0);
    final updatedProgress = math.max(currentProgress, computedProgress);

    return RotationDecision(
      updatedAccumulated: updatedAccumulated,
      updatedProgress: updatedProgress,
      rotationConfirmed: updatedProgress >= 1.0,
    );
  }

  FaceDecision analyzeFaceState({
    required int faceCount,
    required bool includeGaze,
    required double yaw,
    required double pitch,
    required DateTime now,
    required DateTime lastMultiFaceStrikeAt,
    required int multiFaceCooldownMs,
    required DateTime? gazeAwayStartedAt,
    required int gazeAwayDurationMs,
    required DateTime lastGazeWarningAt,
    required int gazeWarningCooldownMs,
    double yawThreshold = 20.0,
    double pitchThreshold = 15.0,
  }) {
    if (_isAvailable) {
      try {
        final decision = rust_proctoring.analyzeFaceState(
          faceCount: faceCount,
          includeGaze: includeGaze,
          yaw: yaw,
          pitch: pitch,
          nowMs: _toPlatformInt64(now.millisecondsSinceEpoch),
          lastMultiFaceStrikeAtMs: _toPlatformInt64(
            lastMultiFaceStrikeAt.millisecondsSinceEpoch,
          ),
          multiFaceCooldownMs: _toPlatformInt64(multiFaceCooldownMs),
          gazeAwayStartedAtMs: gazeAwayStartedAt == null
              ? null
              : _toPlatformInt64(gazeAwayStartedAt.millisecondsSinceEpoch),
          gazeAwayDurationMs: _toPlatformInt64(gazeAwayDurationMs),
          lastGazeWarningAtMs: _toPlatformInt64(
            lastGazeWarningAt.millisecondsSinceEpoch,
          ),
          gazeWarningCooldownMs: _toPlatformInt64(gazeWarningCooldownMs),
          yawThreshold: yawThreshold,
          pitchThreshold: pitchThreshold,
        );
        return FaceDecision(
          shouldFlagMultiFace: decision.shouldFlagMultiFace,
          shouldWarnGaze: decision.shouldWarnGaze,
          updatedLastMultiFaceStrikeAt: DateTime.fromMillisecondsSinceEpoch(
            _fromPlatformInt64(decision.updatedLastMultiFaceStrikeAtMs),
          ),
          updatedLastGazeWarningAt: DateTime.fromMillisecondsSinceEpoch(
            _fromPlatformInt64(decision.updatedLastGazeWarningAtMs),
          ),
          updatedGazeAwayStartedAt: decision.updatedGazeAwayStartedAtMs == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  _fromPlatformInt64(decision.updatedGazeAwayStartedAtMs!),
                ),
        );
      } catch (_) {
        _isAvailable = false;
      }
    }

    final shouldFlagMultiFace =
        faceCount > 1 &&
        now.difference(lastMultiFaceStrikeAt).inMilliseconds >=
            multiFaceCooldownMs;
    final updatedLastMultiFaceStrikeAt = shouldFlagMultiFace
        ? now
        : lastMultiFaceStrikeAt;

    var updatedGazeAwayStartedAt = gazeAwayStartedAt;
    var updatedLastGazeWarningAt = lastGazeWarningAt;
    var shouldWarnGaze = false;

    if (includeGaze) {
      final gazeAway = yaw.abs() > yawThreshold || pitch.abs() > pitchThreshold;
      if (gazeAway) {
        updatedGazeAwayStartedAt ??= now;
        if (now.difference(updatedGazeAwayStartedAt).inMilliseconds >=
                gazeAwayDurationMs &&
            now.difference(lastGazeWarningAt).inMilliseconds >=
                gazeWarningCooldownMs) {
          shouldWarnGaze = true;
          updatedLastGazeWarningAt = now;
          updatedGazeAwayStartedAt = now;
        }
      } else {
        updatedGazeAwayStartedAt = null;
      }
    }

    return FaceDecision(
      shouldFlagMultiFace: shouldFlagMultiFace,
      shouldWarnGaze: shouldWarnGaze,
      updatedLastMultiFaceStrikeAt: updatedLastMultiFaceStrikeAt,
      updatedLastGazeWarningAt: updatedLastGazeWarningAt,
      updatedGazeAwayStartedAt: updatedGazeAwayStartedAt,
    );
  }

  EnvironmentDecision analyzeEnvironmentFrame({
    required List<String> objectLabels,
    required double lightingScore,
    required bool rotationCovered,
    required List<String> forbiddenKeywords,
  }) {
    if (_isAvailable) {
      try {
        final decision = rust_proctoring.analyzeEnvironmentFrame(
          objectLabels: objectLabels,
          lightingScore: lightingScore,
          rotationCovered: rotationCovered,
          forbiddenKeywords: forbiddenKeywords,
        );
        return EnvironmentDecision(
          normalizedLightingScore: decision.normalizedLightingScore,
          rotationConfirmed: decision.rotationConfirmed,
          forbiddenObjects: decision.forbiddenObjects,
        );
      } catch (_) {
        _isAvailable = false;
      }
    }

    final forbidden =
        objectLabels
            .map(_normalizeLabel)
            .where((label) => label.isNotEmpty)
            .where(
              (label) => forbiddenKeywords.any(
                (keyword) => label.contains(_normalizeLabel(keyword)),
              ),
            )
            .toSet()
            .toList()
          ..sort();

    return EnvironmentDecision(
      normalizedLightingScore: lightingScore.clamp(0.0, 1.0),
      rotationConfirmed: rotationCovered,
      forbiddenObjects: forbidden,
    );
  }

  VisionScanFrameAnalysis analyzeScanFrame({
    required Uint8List plane0Bytes,
    required int width,
    required int height,
    required int bytesPerRow,
    required String pixelFormat,
  }) {
    if (_isAvailable) {
      try {
        final decision = rust_proctoring.analyzeScanFrame(
          plane0Bytes: plane0Bytes,
          width: width,
          height: height,
          bytesPerRow: bytesPerRow,
          pixelFormat: pixelFormat,
        );
        return VisionScanFrameAnalysis(
          lightingScore: decision.lightingScore,
          objectLabels: decision.objectLabels,
          faces: decision.faceCount <= 0
              ? const []
              : List.generate(
                  decision.faceCount,
                  (_) => VisionFaceObservation(
                    yaw: decision.estimatedYaw,
                    pitch: decision.estimatedPitch,
                  ),
                ),
        );
      } catch (_) {
        _isAvailable = false;
      }
    }

    return VisionScanFrameAnalysis(
      lightingScore: estimateLightingFromLuma(plane0Bytes),
      objectLabels: const [],
      faces: const [],
    );
  }

  double estimateLightingFromLuma(
    Uint8List lumaBytes, {
    int sampleStride = 16,
  }) {
    if (_isAvailable) {
      try {
        return rust_proctoring.estimateLightingFromLuma(
          lumaBytes: lumaBytes,
          sampleStride: sampleStride,
        );
      } catch (_) {
        _isAvailable = false;
      }
    }

    if (lumaBytes.isEmpty) return 0.0;
    final stride = sampleStride < 1 ? 1 : sampleStride;
    var total = 0;
    var count = 0;
    for (var i = 0; i < lumaBytes.length; i += stride) {
      total += lumaBytes[i];
      count += 1;
    }
    if (count == 0) return 0.0;
    return ((total / count) / 255.0).clamp(0.0, 1.0);
  }

  double _pcm16RmsDbfs(Uint8List pcm16Bytes) {
    if (pcm16Bytes.lengthInBytes < 2) return -90.0;

    final data = ByteData.sublistView(pcm16Bytes);
    var count = 0;
    var sumSquares = 0.0;
    for (var i = 0; i + 1 < pcm16Bytes.lengthInBytes; i += 2) {
      final sample = data.getInt16(i, Endian.little) / 32768.0;
      sumSquares += sample * sample;
      count += 1;
    }

    if (count == 0) return -90.0;
    final rms = math.sqrt(sumSquares / count);
    if (rms <= 1e-9) return -90.0;
    return (20 * math.log(rms) / math.ln10).clamp(-90.0, 0.0);
  }

  double _normalizeSignal(double dbfs) {
    return ((dbfs + 90.0) / 90.0).clamp(0.0, 1.0);
  }

  static String _normalizeLabel(String label) {
    return label
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  dynamic _toPlatformInt64(int value) => kIsWeb ? BigInt.from(value) : value;

  int _fromPlatformInt64(dynamic value) {
    if (value is BigInt) return value.toInt();
    return value as int;
  }
}

class AcousticChunkDecision {
  const AcousticChunkDecision({
    required this.dbfs,
    required this.updatedLossStreak,
    required this.shouldTriggerScan,
    required this.normalizedTetherSignal,
    required this.updatedSpeechStreak,
    required this.shouldTriggerSpeech,
    required this.updatedLastSpeechStrikeAt,
  });

  final double dbfs;
  final int updatedLossStreak;
  final bool shouldTriggerScan;
  final double normalizedTetherSignal;
  final int updatedSpeechStreak;
  final bool shouldTriggerSpeech;
  final DateTime updatedLastSpeechStrikeAt;
}

class MotionDecision {
  const MotionDecision({
    required this.moved,
    required this.shouldLogViolation,
    required this.shouldTriggerScan,
    required this.updatedLastViolationAt,
    required this.updatedWindowStartAt,
    required this.updatedBurstCount,
  });

  final bool moved;
  final bool shouldLogViolation;
  final bool shouldTriggerScan;
  final DateTime updatedLastViolationAt;
  final DateTime updatedWindowStartAt;
  final int updatedBurstCount;
}

class RotationDecision {
  const RotationDecision({
    required this.updatedAccumulated,
    required this.updatedProgress,
    required this.rotationConfirmed,
  });

  final double updatedAccumulated;
  final double updatedProgress;
  final bool rotationConfirmed;
}

class FaceDecision {
  const FaceDecision({
    required this.shouldFlagMultiFace,
    required this.shouldWarnGaze,
    required this.updatedLastMultiFaceStrikeAt,
    required this.updatedLastGazeWarningAt,
    required this.updatedGazeAwayStartedAt,
  });

  final bool shouldFlagMultiFace;
  final bool shouldWarnGaze;
  final DateTime updatedLastMultiFaceStrikeAt;
  final DateTime updatedLastGazeWarningAt;
  final DateTime? updatedGazeAwayStartedAt;
}

class EnvironmentDecision {
  const EnvironmentDecision({
    required this.normalizedLightingScore,
    required this.rotationConfirmed,
    required this.forbiddenObjects,
  });

  final double normalizedLightingScore;
  final bool rotationConfirmed;
  final List<String> forbiddenObjects;
}

class VisionScanFrameAnalysis {
  const VisionScanFrameAnalysis({
    required this.lightingScore,
    required this.objectLabels,
    required this.faces,
  });

  final double lightingScore;
  final List<String> objectLabels;
  final List<VisionFaceObservation> faces;
}

class VisionFaceObservation {
  const VisionFaceObservation({required this.yaw, required this.pitch});

  final double yaw;
  final double pitch;
}

class VisionModelLoadStatus {
  const VisionModelLoadStatus({
    required this.loaded,
    required this.modelName,
    required this.inputWidth,
    required this.inputHeight,
    required this.confidenceThreshold,
    required this.labelCount,
    required this.message,
  });

  final bool loaded;
  final String modelName;
  final int inputWidth;
  final int inputHeight;
  final double confidenceThreshold;
  final int labelCount;
  final String message;
}
