import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/rust/rust_brain_service.dart';
import '../controller/proctoring_controller.dart';

class EnvironmentScanOverlay extends StatefulWidget {
  const EnvironmentScanOverlay({super.key});

  @override
  State<EnvironmentScanOverlay> createState() => _EnvironmentScanOverlayState();
}

class _EnvironmentScanOverlayState extends State<EnvironmentScanOverlay>
    with WidgetsBindingObserver {
  late final ProctoringController _proctoring;
  CameraController? _cameraController;

  bool _isProcessingFrame = false;
  bool _scanDetectorReady = false;
  bool _isObjectDetected = false;
  bool _isCameraReady = false;

  String _alertMessage = "Slowly rotate your device 360°";
  List<String> _detectedLabels = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _proctoring = Get.find<ProctoringController>();
    _initializeScanPipeline();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController?.stopImageStream();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _startImageStreamIfReady();
    }
  }

  Future<void> _initializeScanPipeline() async {
    try {
      await RustBrainService.instance.ensureVisionModelLoaded();
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _proctoring.handleViolation('camera unavailable');
        if (!mounted) return;
        setState(() {
          _alertMessage = "Camera not available for environment scan.";
        });
        return;
      }

      final back = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      final selected = back.isNotEmpty ? back.first : cameras.first;

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      _cameraController = controller;
      await controller.initialize();
      await _startImageStreamIfReady();

      if (!mounted) return;
      setState(() {
        _scanDetectorReady = true;
        _isCameraReady = true;
      });
    } catch (_) {
      _proctoring.handleViolation('camera access denied');
      if (!mounted) return;
      setState(() {
        _alertMessage =
            "Camera permission is required. Allow access to continue scan.";
      });
    }
  }

  Future<void> _startImageStreamIfReady() async {
    final controller = _cameraController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_processFrame);
    } catch (_) {
      // ignore repeated stream start failures.
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame || !_scanDetectorReady) return;
    _isProcessingFrame = true;

    try {
      final analysis = RustBrainService.instance.analyzeScanFrame(
        plane0Bytes: image.planes.first.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: image.planes.first.bytesPerRow,
        pixelFormat: Platform.isIOS ? 'bgra8888' : 'luma8',
      );
      await _proctoring.registerEnvironmentFrameAnalysis(
        objectLabels: analysis.objectLabels,
        lightingScore: analysis.lightingScore,
        rotationCovered: _proctoring.scanProgress.value >= 1.0,
      );

      if (analysis.faces.length > 1) {
        _proctoring.processDetectedFaces(analysis.faces, includeGaze: false);
      }

      final forbidden = _proctoring.scanForbiddenObjects.toList();

      if (!mounted) return;
      setState(() {
        _detectedLabels = analysis.objectLabels.toList()..sort();
        _isObjectDetected = forbidden.isNotEmpty;
        if (_isObjectDetected) {
          _alertMessage =
              "Forbidden device detected in scan (${forbidden.join(", ")}).";
        } else if (analysis.lightingScore <
            _proctoring.minimumScanLightingScore) {
          _alertMessage = "Increase room lighting to complete scan.";
        } else {
          _alertMessage = "Scan in progress. Keep rotating your device.";
        }
      });
    } catch (_) {
      // Keep scan running even when single-frame inference fails.
    } finally {
      _isProcessingFrame = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _buildCameraLayer()),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isObjectDetected ? Colors.red : Colors.green,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              top: 48,
              left: 14,
              right: 14,
              child: Obx(
                () => _TopStatusBar(
                  progress: _proctoring.scanProgress.value.clamp(0.0, 1.0),
                  lightingScore: _proctoring.scanLightingScore.value,
                  lightingMin: _proctoring.minimumScanLightingScore,
                  rotationOk: _proctoring.scanRotationConfirmed.value,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => LinearProgressIndicator(
                        value: _proctoring.scanProgress.value.clamp(0.0, 1.0),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _alertMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (_detectedLabels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Detected: ${_detectedLabels.join(", ")}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    Obx(() {
                      final canComplete =
                          _proctoring.scanProgress.value >= 1.0 &&
                          _proctoring.scanRotationConfirmed.value &&
                          _proctoring.scanLightingScore.value >=
                              _proctoring.minimumScanLightingScore &&
                          _proctoring.scanForbiddenObjects.isEmpty &&
                          !_proctoring.scanInProgress.value;

                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: canComplete
                                ? () => _proctoring.completeEnvironmentScan()
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                            ),
                            child: Text(
                              canComplete
                                  ? "Complete scan and continue"
                                  : "Keep scanning...",
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    final controller = _cameraController;
    if (!_isCameraReady ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return CameraPreview(controller);
  }
}

class _TopStatusBar extends StatelessWidget {
  const _TopStatusBar({
    required this.progress,
    required this.lightingScore,
    required this.lightingMin,
    required this.rotationOk,
  });

  final double progress;
  final double lightingScore;
  final double lightingMin;
  final bool rotationOk;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill("Scan ${(progress * 100).round()}%", progress >= 1.0),
        const SizedBox(width: 8),
        _pill(
          "Light ${(lightingScore * 100).round()}%",
          lightingScore >= lightingMin,
        ),
        const SizedBox(width: 8),
        _pill("Rotation", rotationOk),
      ],
    );
  }

  Widget _pill(String text, bool ok) {
    final tone = ok ? Colors.green : Colors.orange;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tone.withValues(alpha: 0.45)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tone,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
