import 'package:camera/camera.dart';

import '../../../features/local_ai/evidence/audio_evidence_capture_hook.dart';
import '../../../features/local_ai/evidence/camera_evidence_capture_hook.dart';
import '../../../features/local_ai/evidence/evidence_capture_service.dart';
import '../../../features/local_ai/evidence/screenshot_evidence_capture_hook.dart';

class LocalAiEvidenceHookFactory {
  const LocalAiEvidenceHookFactory._();

  static EvidenceArtifactCaptureHook build({
    required CameraController cameraController,
    CameraEvidenceFrameProvider? cameraFrameProvider,
    AudioEvidenceClipProvider? audioClipProvider,
    ScreenshotEvidenceProvider? screenshotProvider,
    EvidenceArtifactCaptureHook? fallbackHook,
  }) {
    return ScreenshotEvidenceCaptureHook(
      provider: screenshotProvider,
      fallbackHook: CameraEvidenceCaptureHook(
        cameraController: cameraController,
        frameProvider: cameraFrameProvider,
        fallbackHook: AudioEvidenceCaptureHook(
          clipProvider: audioClipProvider,
          fallbackHook: fallbackHook,
        ),
      ),
    );
  }
}
