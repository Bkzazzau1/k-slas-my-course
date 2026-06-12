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
  bool _cameraPermissionFailed = false;
  bool _cameraUnavailable = false;
  bool _initializingCamera = false;
  bool _desktopCameraFallback = false;

  String _alertMessage = 'Slowly rotate your device 360°';
  List<String> _detectedLabels = const [];

  bool get _isDesktopRuntime =>
      GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux;

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
    if (_initializingCamera) return;
    _initializingCamera = true;

    setState(() {
      _cameraPermissionFailed = false;
      _cameraUnavailable = false;
      _desktopCameraFallback = false;
      _isCameraReady = false;
      _scanDetectorReady = false;
      _alertMessage = 'Preparing camera permission request...';
    });

    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
    await _cameraController?.dispose();
    _cameraController = null;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (_isDesktopRuntime) {
          await _activateDesktopCameraFallback();
          return;
        }
        if (!mounted) return;
        setState(() {
          _cameraUnavailable = true;
          _alertMessage = 'No camera was found on this device.';
        });
        return;
      }

      final back = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final selected = back.isNotEmpty ? back.first : cameras.first;

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _cameraController = controller;
      await controller.initialize();

      await _proctoring.registerEnvironmentFrameAnalysis(
        objectLabels: const <String>[],
        lightingScore: 1.0,
        rotationCovered: false,
      );

      try {
        await RustBrainService.instance.ensureVisionModelLoaded();
      } catch (_) {}

      await _startImageStreamIfReady();

      if (!mounted) return;
      setState(() {
        _scanDetectorReady = true;
        _isCameraReady = true;
        _alertMessage = 'Camera ready. Rotate slowly to complete verification.';
      });
    } catch (_) {
      if (_isDesktopRuntime) {
        await _activateDesktopCameraFallback();
        return;
      }
      if (!mounted) return;
      setState(() {
        _cameraPermissionFailed = true;
        _alertMessage =
            'Camera permission is required. Allow access to continue scan.';
      });
    } finally {
      _initializingCamera = false;
    }
  }

  Future<void> _activateDesktopCameraFallback() async {
    await _proctoring.registerEnvironmentFrameAnalysis(
      objectLabels: const <String>[],
      lightingScore: 1.0,
      rotationCovered: _proctoring.scanProgress.value >= 1.0,
    );
    if (!mounted) return;
    setState(() {
      _desktopCameraFallback = true;
      _cameraPermissionFailed = false;
      _cameraUnavailable = false;
      _scanDetectorReady = true;
      _isCameraReady = false;
      _alertMessage =
          'Desktop verification fallback is active. Complete the rotation, then continue.';
    });
  }

  Future<void> _startImageStreamIfReady() async {
    final controller = _cameraController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_processFrame);
    } catch (_) {
      // Some desktop/web camera implementations allow preview but not image streaming.
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame || !_scanDetectorReady) return;
    _isProcessingFrame = true;

    try {
      final pixelFormat = image.format.group == ImageFormatGroup.bgra8888
          ? 'bgra8888'
          : 'luma8';
      final analysis = RustBrainService.instance.analyzeScanFrame(
        plane0Bytes: image.planes.first.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: image.planes.first.bytesPerRow,
        pixelFormat: pixelFormat,
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
              'Forbidden device detected in scan (${forbidden.join(', ')}).';
        } else if (analysis.lightingScore <
            _proctoring.minimumScanLightingScore) {
          _alertMessage = 'Increase room lighting to complete scan.';
        } else {
          _alertMessage = 'Scan in progress. Keep rotating your device.';
        }
      });
    } catch (_) {
      // Keep scan running even when one frame cannot be analysed.
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _returnToDashboard() async {
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;

    // Navigate first. Calling stopSession first can close this dialog and leave
    // the Windows desktop shell with an empty route stack.
    Get.offAllNamed('/main');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await _proctoring.stopSession(silent: true);
  }

  Future<void> _retryCameraPermission() async {
    await _initializeScanPipeline();
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
                  color: Colors.black.withValues(alpha: 0.72),
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
                    if (_desktopCameraFallback) ...[
                      const SizedBox(height: 8),
                      Text(
                        'The Windows desktop build could not open the camera plugin, so this demo uses a reduced-assurance desktop fallback. The production desktop app should use the native Windows camera bridge.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_cameraPermissionFailed || _cameraUnavailable) ...[
                      const SizedBox(height: 8),
                      Text(
                        _cameraUnavailable
                            ? 'Connect a camera, then return to verification.'
                            : 'Use the browser or system permission popup to allow camera access. If you already denied it, enable camera permission from the address bar or app settings.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: _cameraUnavailable
                                ? null
                                : _retryCameraPermission,
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Try camera again'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _returnToDashboard,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                            icon: const Icon(Icons.dashboard_rounded),
                            label: const Text('Return to dashboard'),
                          ),
                        ],
                      ),
                    ],
                    if (_detectedLabels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Detected: ${_detectedLabels.join(', ')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    Obx(() {
                      final canComplete =
                          !_cameraPermissionFailed &&
                          !_cameraUnavailable &&
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
                                  ? 'Complete scan and continue'
                                  : 'Keep scanning...',
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _returnToDashboard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.38),
                        ),
                      ),
                      icon: const Icon(Icons.dashboard_rounded),
                      label: const Text('Return to dashboard'),
                    ),
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
    if (_desktopCameraFallback) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.desktop_windows_rounded,
                color: Colors.white,
                size: 58,
              ),
              SizedBox(height: 14),
              Text(
                'Desktop verification fallback',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraPermissionFailed || _cameraUnavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_rounded,
                color: Colors.white,
                size: 58,
              ),
              const SizedBox(height: 14),
              Text(
                _cameraUnavailable
                    ? 'Camera not available'
                    : 'Camera permission needed',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        _pill('Scan ${(progress * 100).round()}%', progress >= 1.0),
        const SizedBox(width: 8),
        _pill(
          'Light ${(lightingScore * 100).round()}%',
          lightingScore >= lightingMin,
        ),
        const SizedBox(width: 8),
        _pill('Rotation', rotationOk),
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
