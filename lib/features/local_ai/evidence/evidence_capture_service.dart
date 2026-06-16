import '../core/local_ai_event.dart';

class EvidenceCaptureRequest {
  const EvidenceCaptureRequest({
    required this.sessionId,
    required this.studentId,
    required this.event,
    this.captureScreenshot = false,
    this.captureAudioClip = false,
    this.captureCameraClip = false,
  });

  final String sessionId;
  final String studentId;
  final LocalAiEvent event;
  final bool captureScreenshot;
  final bool captureAudioClip;
  final bool captureCameraClip;
}

class EvidenceCaptureResult {
  const EvidenceCaptureResult({
    required this.event,
    this.screenshotPath,
    this.audioClipPath,
    this.cameraClipPath,
  });

  final LocalAiEvent event;
  final String? screenshotPath;
  final String? audioClipPath;
  final String? cameraClipPath;

  LocalAiEvent toEvidenceEvent() {
    return LocalAiEvent(
      type: LocalAiEventType.evidenceCaptured,
      severity: LocalAiSeverity.info,
      timestamp: DateTime.now(),
      riskPoints: 0,
      sessionId: event.sessionId,
      studentId: event.studentId,
      message: 'Evidence captured for ${event.type.name}.',
      metadata: <String, Object?>{
        'sourceEvent': event.toJson(),
        'screenshotPath': screenshotPath,
        'audioClipPath': audioClipPath,
        'cameraClipPath': cameraClipPath,
      },
    );
  }
}

class EvidenceCaptureService {
  Future<EvidenceCaptureResult> capture(EvidenceCaptureRequest request) async {
    // Future integration: platform screenshot, audio, and camera clip capture.
    // The MVP should only call this for high-risk events to reduce storage cost.
    return EvidenceCaptureResult(event: request.event);
  }

  bool shouldCaptureEvidence(LocalAiEvent event) {
    return event.severity == LocalAiSeverity.high ||
        event.severity == LocalAiSeverity.critical;
  }
}
