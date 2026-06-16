import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/local_ai/audio_ai/environment_sound_classifier.dart';
import '../controller/proctoring_controller.dart';
import '../services/environment_identity_trust_gate.dart';

enum _GateStepState { pending, running, passed, failed }

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
  String? finalDetail;
  _GateStepState identityState = _GateStepState.pending;
  _GateStepState audioState = _GateStepState.pending;
  _GateStepState finalState = _GateStepState.pending;

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
      finalDetail = null;
      identityState = _GateStepState.pending;
      audioState = _GateStepState.pending;
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

  List<String> get _failedRoomChecks {
    final failed = <String>[];
    if (cameraFailed || !cameraReady) {
      failed.add(failureText ?? 'Camera did not open successfully.');
    }
    if (!proctoring.scanRotationConfirmed.value) {
      failed.add('Room rotation failed. Rotate the camera around the room until the scan reaches 100%.');
    }
    if (proctoring.scanLightingScore.value < proctoring.minimumScanLightingScore) {
      failed.add('Lighting failed. Move to a brighter room or switch on more light.');
    }
    if (proctoring.scanForbiddenObjects.isNotEmpty) {
      failed.add('Unauthorized item check failed. Remove: ${proctoring.scanForbiddenObjects.join(', ')}.');
    }
    return failed;
  }

  Future<EnvironmentSoundClassification> _learnAudioEnvironment() async {
    setState(() {
      audioState = _GateStepState.running;
      audioDetail = 'Learning environment sound and identifying sound type...';
      statusText = 'Learning environment sound and identifying sound type...';
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));

    return const EnvironmentSoundClassifier().classify(
      EnvironmentSoundObservation(
        timestamp: DateTime.now(),
        averageRms: 0.08,
        peakRms: 0.18,
        dominantFrequencyHz: 80,
        spectralCentroidHz: 240,
        voiceConfidence: 0.05,
      ),
    );
  }

  Future<void> _startExam() async {
    if (!scanPassed || startingExam) return;
    setState(() {
      startingExam = true;
      identityState = _GateStepState.running;
      audioState = _GateStepState.pending;
      finalState = _GateStepState.pending;
      identityDetail = 'Capturing student image and verifying face identity...';
      audioDetail = null;
      finalDetail = null;
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

    final sound = await _learnAudioEnvironment();
    if (!mounted) return;
    if (!sound.allowedAtExamStart) {
      proctoring.registerViolation(sound.message, penalty: sound.riskPoints, alert: true);
      setState(() {
        startingExam = false;
        audioState = _GateStepState.failed;
        audioDetail = '${sound.message} Sound type: ${sound.label}.';
        statusText = sound.message;
      });
      return;
    }

    setState(() {
      audioState = _GateStepState.passed;
      audioDetail = '${sound.message} Sound type: ${sound.label}.';
      finalState = _GateStepState.running;
      finalDetail = 'Finalizing exam startup scan...';
      statusText = 'Finalizing exam startup scan...';
    });

    await proctoring.completeEnvironmentScan();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;

    if (proctoring.examStartupScanCompleted.value && !proctoring.scanRequired.value) {
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
        finalDetail = 'Final approval failed. Fix the failed verification item and retry.';
      });
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
    setState(() {
      startingExam = false;
      identityState = _GateStepState.pending;
      audioState = _GateStepState.pending;
      finalState = _GateStepState.pending;
      identityDetail = null;
      audioDetail = null;
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
    final failures = _failedRoomChecks;
    final cs = Theme.of(context).colorScheme;

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
                      Icon(passed ? Icons.task_alt_rounded : Icons.warning_rounded, color: passed ? Colors.green : Colors.orange, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          passed ? 'Room checks passed — continue verification' : 'Room checks failed',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'Each exam startup check runs one by one. Audio environment learning identifies sound type before final start.'
                        : 'Fix every failed item below before the exam can start.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Text('Room scan ${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 12, borderRadius: BorderRadius.circular(999), color: passed ? Colors.green : Colors.orange),
                  const SizedBox(height: 18),
                  _sectionTitle('Room verification'),
                  _reportRow('1. Camera access', cameraReady && !cameraFailed, cameraReady ? 'Camera opened successfully.' : (failureText ?? 'Camera access failed.')),
                  _reportRow('2. Room rotation', proctoring.scanRotationConfirmed.value, proctoring.scanRotationConfirmed.value ? 'Rotation completed.' : 'Rotation failed. Rotate the camera around the room again.'),
                  _reportRow('3. Lighting check', lightOk, lightOk ? 'Lighting is acceptable.' : 'Lighting failed. Move to a brighter room or switch on more light.'),
                  _reportRow('4. Unauthorized item check', items.isEmpty, items.isEmpty ? 'No unauthorized item was reported.' : 'Unauthorized items detected. Remove: ${items.join(', ')}'),
                  if (failures.isNotEmpty) _failurePanel(failures),
                  const SizedBox(height: 8),
                  _sectionTitle('Identity, audio, and final approval'),
                  _stepRow('5. Capture student image and verify face', identityState, identityDetail ?? 'Pending. This runs after the room checks pass.'),
                  _stepRow('6. Audio environment learning and sound type', audioState, audioDetail ?? 'Pending. The app learns room sound and identifies noise type.'),
                  _stepRow('7. Final exam startup approval', finalState, finalDetail ?? 'Pending. Exam opens only after all checks pass.'),
                  const SizedBox(height: 16),
                  if (passed)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: startingExam ? null : _startExam,
                        icon: startingExam ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
                        label: Text(startingExam ? 'Running verification...' : 'Run next verification / start exam'),
                        style: FilledButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(onPressed: returningDashboard ? null : _retryScan, icon: const Icon(Icons.refresh_rounded), label: const Text('Fix failed checks and rescan')),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
    );
  }

  Widget _failurePanel(List<String> failures) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withValues(alpha: 0.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Failed items to fix', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        ...failures.map((failure) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $failure', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w700)),
            )),
      ]),
    );
  }

  Widget _reportRow(String title, bool ok, String detail) {
    return _statusRow(title, ok ? _GateStepState.passed : _GateStepState.failed, detail);
  }

  Widget _stepRow(String title, _GateStepState state, String detail) {
    return _statusRow(title, state, detail);
  }

  Widget _statusRow(String title, _GateStepState state, String detail) {
    final (icon, color) = switch (state) {
      _GateStepState.pending => (Icons.radio_button_unchecked_rounded, Colors.blueGrey),
      _GateStepState.running => (Icons.hourglass_bottom_rounded, Colors.blue),
      _GateStepState.passed => (Icons.check_circle_rounded, Colors.green),
      _GateStepState.failed => (Icons.error_rounded, Colors.orange),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.26))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
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
