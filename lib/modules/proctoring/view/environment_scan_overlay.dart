import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _imageStreamAvailable = false;

  String _alertMessage = 'Slowly rotate your device 360°';
  String? _cameraErrorDetails;
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
      _stopImageStreamIfNeeded();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _startImageStreamIfReady();
    }
  }

  Future<void> _initializeScanPipeline() async {
    if (_initializingCamera) return;
    _initializingCamera = true;

    if (mounted) {
      setState(() {
        _cameraPermissionFailed = false;
        _cameraUnavailable = false;
        _isCameraReady = false;
        _scanDetectorReady = false;
        _imageStreamAvailable = false;
        _cameraErrorDetails = null;
        _detectedLabels = const [];
        _alertMessage = 'Opening camera for live verification...';
      });
    }

    await _disposeCameraController();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraUnavailable = true;
          _alertMessage = 'No camera was found on this device.';
          _cameraErrorDetails =
              'Connect a webcam and confirm Windows privacy settings allow desktop apps to use the camera.';
        });
        return;
      }

      final front = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      final back = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final selected = front.isNotEmpty
          ? front.first
          : (back.isNotEmpty ? back.first : cameras.first);

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
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
      } catch (_) {
        // The scan can still continue with preview + rotation if local AI warm-up fails.
      }

      await _startImageStreamIfReady();

      if (!mounted) return;
      setState(() {
        _scanDetectorReady = true;
        _isCameraReady = true;
        _alertMessage = _imageStreamAvailable
            ? 'Camera ready. Rotate slowly while the AI checks the room.'
            : 'Camera preview ready. Rotate slowly to complete verification.';
      });
    } on CameraException catch (e) {
      _showCameraFailure(
        message: 'Camera permission is required. Allow access to continue scan.',
        details: '${e.code}: ${e.description ?? 'Camera access failed.'}',
      );
    } on MissingPluginException catch (_) {
      _showCameraFailure(
        message: 'Desktop camera module is not available.',
        details:
            'Run flutter clean, flutter pub get, then rebuild the Windows app. The project now includes the Windows camera implementation.',
      );
    } catch (e) {
      _showCameraFailure(
        message: 'Camera could not be opened for verification.',
        details: e.toString(),
      );
    } finally {
      _initializingCamera = false;
    }
  }

  void _showCameraFailure({required String message, required String details}) {
    if (!mounted) return;
    setState(() {
      _cameraPermissionFailed = true;
      _cameraUnavailable = false;
      _isCameraReady = false;
      _scanDetectorReady = false;
      _alertMessage = message;
      _cameraErrorDetails = details;
    });
  }

  Future<void> _stopImageStreamIfNeeded() async {
    final controller = _cameraController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;
    if (!controller.value.isStreamingImages) return;
    try {
      await controller.stopImageStream();
    } catch (_) {}
  }

  Future<void> _disposeCameraController() async {
    await _stopImageStreamIfNeeded();
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;
  }

  Future<void> _startImageStreamIfReady() async {
    final controller = _cameraController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_processFrame);
      _imageStreamAvailable = true;
    } catch (_) {
      _imageStreamAvailable = false;
      // Windows/web camera preview may work even when image stream callbacks are
      // unavailable. The preview + rotation scan still proves live camera access.
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

  Future<void> _completeScanAndContinue() async {
    await _proctoring.completeEnvironmentScan();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    if (_proctoring.examStartupScanCompleted.value &&
        !_proctoring.scanRequired.value) {
      await _disposeCameraController();
      if (Get.isDialogOpen ?? false) {
        Get.back<void>();
      }
    }
  }

  Future<void> _returnToDashboard() async {
    await _disposeCameraController();
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
    _disposeCameraController();
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
                    if (_cameraErrorDetails != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _cameraErrorDetails!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_cameraPermissionFailed || _cameraUnavailable) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: _retryCameraPermission,
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
                          _isCameraReady &&
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
                                ? _completeScanAndContinue
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

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
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
