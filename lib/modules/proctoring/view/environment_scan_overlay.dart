import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/proctoring_controller.dart';

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
      statusText = 'Opening camera for live room verification...';
    });

    await _disposeCamera();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          cameraFailed = true;
          statusText = 'No camera was found.';
          failureText = 'Connect a webcam and allow camera access from Windows privacy settings.';
        });
        return;
      }

      final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
      final selected = front.isNotEmpty ? front.first : cameras.first;
      final controller = CameraController(selected, ResolutionPreset.medium, enableAudio: false);
      camera = controller;
      await controller.initialize();

      await proctoring.registerEnvironmentFrameAnalysis(
        objectLabels: const <String>[],
        lightingScore: 1.0,
        rotationCovered: false,
      );

      if (!mounted) return;
      setState(() {
        cameraReady = true;
        statusText = 'Camera ready. Slowly rotate your device until the scan reaches 100%.';
      });
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
        proctoring.scanLightingScore.value >= proctoring.minimumScanLightingScore &&
        proctoring.scanForbiddenObjects.isEmpty;
  }

  Future<void> _startExam() async {
    if (!scanPassed || startingExam) return;
    setState(() => startingExam = true);
    await proctoring.completeEnvironmentScan();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    if (proctoring.examStartupScanCompleted.value && !proctoring.scanRequired.value) {
      await _disposeCamera();
      if (Get.isDialogOpen ?? false) Get.back<void>();
    } else {
      setState(() => startingExam = false);
    }
  }

  Future<void> _retryScan() async {
    proctoring.scanRequired.value = true;
    proctoring.scanInProgress.value = true;
    proctoring.scanProgress.value = 0;
    proctoring.scanAiChecksPassed.value = false;
    proctoring.scanForbiddenObjects.clear();
    proctoring.scanLightingScore.value = 0;
    proctoring.scanRotationConfirmed.value = false;
    await _openCamera();
  }

  Future<void> _returnToDashboard() async {
    if (returningDashboard) return;
    setState(() => returningDashboard = true);
    await _disposeCamera();

    // Do not let stopSession pop the overlay after navigating. That was removing
    // the new main route on Windows and made the desktop shell close.
    await proctoring.stopSession(silent: true, closeOverlay: false);

    if (Get.isDialogOpen ?? false) {
      Get.back<void>();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    Get.offAllNamed('/main');
  }

  Future<void> _disposeCamera() async {
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
              _topPill('Light ${(proctoring.scanLightingScore.value * 100).round()}%', proctoring.scanLightingScore.value >= proctoring.minimumScanLightingScore),
              const SizedBox(width: 8),
              _topPill('Rotation', proctoring.scanRotationConfirmed.value),
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
    final lightOk = proctoring.scanLightingScore.value >= proctoring.minimumScanLightingScore;
    final items = proctoring.scanForbiddenObjects.toList();
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
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
                      Icon(passed ? Icons.verified_rounded : Icons.warning_rounded, color: passed ? Colors.green : Colors.orange, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          passed ? 'Room scan passed' : 'Room scan needs correction',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Scan ${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 12, borderRadius: BorderRadius.circular(999), color: passed ? Colors.green : Colors.orange),
                  const SizedBox(height: 18),
                  _reportRow('Camera', cameraReady && !cameraFailed, cameraReady ? 'Camera opened successfully.' : (failureText ?? 'Camera access failed.')),
                  _reportRow('Room rotation', proctoring.scanRotationConfirmed.value, proctoring.scanRotationConfirmed.value ? 'Rotation completed.' : 'Rotate the camera around the room again.'),
                  _reportRow('Lighting', lightOk, lightOk ? 'Lighting is acceptable.' : 'Move to a brighter room or switch on more light.'),
                  _reportRow('Unauthorized item check', items.isEmpty, items.isEmpty ? 'No unauthorized item was reported.' : 'Remove: ${items.join(', ')}'),
                  const SizedBox(height: 16),
                  if (passed)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: startingExam ? null : _startExam,
                        icon: startingExam ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
                        label: Text(startingExam ? 'Starting exam...' : 'Start exam'),
                        style: FilledButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(onPressed: returningDashboard ? null : _retryScan, icon: const Icon(Icons.refresh_rounded), label: const Text('Try scan again')),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: returningDashboard ? null : _returnToDashboard,
                        icon: const Icon(Icons.dashboard_rounded),
                        label: Text(returningDashboard ? 'Returning...' : 'Return to dashboard / change environment'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: 0.35))),
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
      return Center(child: Text(failureText ?? 'Camera failed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)));
    }
    final c = camera;
    if (!cameraReady || c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: AspectRatio(aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio, child: CameraPreview(c)),
    );
  }

  Widget _bottomPanel(double progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.16))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(999), color: Colors.green),
        const SizedBox(height: 12),
        Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: returningDashboard ? null : _returnToDashboard, style: OutlinedButton.styleFrom(foregroundColor: Colors.white), icon: const Icon(Icons.dashboard_rounded), label: Text(returningDashboard ? 'Returning...' : 'Return to dashboard')),
      ]),
    );
  }

  Widget _reportRow(String title, bool ok, String detail) {
    final color = ok ? Colors.green : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.22))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(detail, style: TextStyle(color: Colors.white.withValues(alpha: 0.76), fontWeight: FontWeight.w600))])),
      ]),
    );
  }

  Widget _topPill(String text, bool ok) {
    final color = ok ? Colors.green : Colors.orange;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.62), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.45))),
        child: Text(text, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
      ),
    );
  }
}
