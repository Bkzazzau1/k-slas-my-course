import 'package:camera/camera.dart';

import '../../../features/local_ai/local_ai.dart';
import '../controller/proctoring_controller.dart';
import 'local_ai_proctoring_adapter.dart';

class LocalAiCameraBinding {
  LocalAiCameraBinding({
    required this.proctoringController,
    this.faceSource,
    this.evidenceArtifactCaptureHook,
  });

  final ProctoringController proctoringController;
  final CameraFaceSource? faceSource;
  final EvidenceArtifactCaptureHook? evidenceArtifactCaptureHook;

  LocalAiEngine? _engine;
  LocalAiCameraMonitor? _monitor;
  LocalAiProctoringAdapter? _adapter;

  bool get isActive => _monitor?.isRunning ?? false;
  LocalAiEngine? get engine => _engine;

  Future<void> attach(CameraController controller) async {
    await detach();

    final engine = LocalAiEngine();
    final adapter = LocalAiProctoringAdapter(
      localAiEngine: engine,
      proctoringController: proctoringController,
      evidenceCaptureService: EvidenceCaptureService(
        artifactCaptureHook: CameraEvidenceCaptureHook(
          cameraController: controller,
          fallbackHook: evidenceArtifactCaptureHook,
        ),
      ),
    );
    final monitor = LocalAiCameraMonitor(
      cameraController: controller,
      localAiEngine: engine,
      faceSource: faceSource,
    );

    _engine = engine;
    _adapter = adapter;
    _monitor = monitor;

    adapter.start();

    try {
      await monitor.start();
    } catch (e) {
      proctoringController.registerViolation(
        'Local AI camera monitoring could not start: $e',
        penalty: 0,
        alert: false,
      );
    }
  }

  Future<void> detach() async {
    try {
      await _monitor?.stop();
    } catch (_) {}
    try {
      await _adapter?.stop();
    } catch (_) {}
    try {
      await _engine?.dispose();
    } catch (_) {}

    _monitor = null;
    _adapter = null;
    _engine = null;
  }
}
