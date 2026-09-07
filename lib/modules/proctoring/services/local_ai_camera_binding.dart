import 'package:camera/camera.dart';

import '../../../features/local_ai/local_ai.dart';
import '../controller/proctoring_controller.dart';
import 'local_ai_evidence_hook_factory.dart';
import 'local_ai_proctoring_adapter.dart';

class LocalAiCameraBinding {
  LocalAiCameraBinding({
    required this.proctoringController,
    this.faceSource,
    this.audioEvidenceClipProvider,
    this.screenshotEvidenceProvider,
    this.cameraFrameEvidenceProvider,
    this.evidenceArtifactCaptureHook,
  });

  final ProctoringController proctoringController;
  final CameraFaceSource? faceSource;
  final AudioEvidenceClipProvider? audioEvidenceClipProvider;
  final ScreenshotEvidenceProvider? screenshotEvidenceProvider;
  final LatestCameraFrameEvidenceProvider? cameraFrameEvidenceProvider;
  final EvidenceArtifactCaptureHook? evidenceArtifactCaptureHook;

  LocalAiEngine? _engine;
  LocalAiCameraMonitor? _monitor;
  LocalAiProctoringAdapter? _adapter;
  CameraController? _cameraController;

  bool get isActive {
    final controller = _cameraController;
    return (_monitor?.isRunning ?? false) &&
        controller != null &&
        controller.value.isInitialized &&
        controller.value.isStreamingImages;
  }

  LocalAiEngine? get engine => _engine;

  Future<void> attach(CameraController controller) async {
    await detach();

    final engine = LocalAiEngine();
    final frameEvidenceProvider =
        cameraFrameEvidenceProvider ?? LatestCameraFrameEvidenceProvider();
    final adapter = LocalAiProctoringAdapter(
      localAiEngine: engine,
      proctoringController: proctoringController,
      evidenceCaptureService: EvidenceCaptureService(
        artifactCaptureHook: LocalAiEvidenceHookFactory.build(
          cameraController: controller,
          cameraFrameProvider: frameEvidenceProvider,
          audioClipProvider: audioEvidenceClipProvider,
          screenshotProvider: screenshotEvidenceProvider,
          fallbackHook: evidenceArtifactCaptureHook,
        ),
      ),
    );
    final monitor = LocalAiCameraMonitor(
      cameraController: controller,
      localAiEngine: engine,
      faceSource: faceSource,
      onFrameAvailable: frameEvidenceProvider.rememberFrame,
    );

    _cameraController = controller;
    _engine = engine;
    _adapter = adapter;
    _monitor = monitor;

    adapter.start();

    try {
      await monitor.start();
    } catch (_) {
      await detach();
      proctoringController.registerViolation(
        'Camera monitoring could not start. Please check camera access.',
        penalty: 0,
        alert: false,
        eventType: 'camera_monitoring_unavailable',
        severity: 'warning',
        metadata: const <String, Object?>{
          'source': 'local_exam_camera',
          'monitoring_state': 'unavailable',
        },
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
    _cameraController = null;
  }
}
