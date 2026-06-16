import 'evidence_capture_service.dart';

abstract class ScreenshotEvidenceProvider {
  Future<EvidenceArtifact?> captureScreenshot(EvidenceArtifactRequest request);
}

class ScreenshotEvidenceCaptureHook implements EvidenceArtifactCaptureHook {
  ScreenshotEvidenceCaptureHook({this.provider, this.fallbackHook});

  final ScreenshotEvidenceProvider? provider;
  final EvidenceArtifactCaptureHook? fallbackHook;

  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    if (request.kind != 'screenshot') {
      return fallbackHook?.captureArtifact(request);
    }

    final screenshotProvider = provider;
    if (screenshotProvider == null) {
      return _pending(request, reason: 'Screenshot provider is not attached.');
    }

    try {
      final artifact = await screenshotProvider.captureScreenshot(request);
      if (artifact != null) return artifact;
    } catch (error) {
      return EvidenceArtifact(
        id: '${request.evidenceId}-${request.kind}',
        kind: request.kind,
        path: 'evidence://pending/${request.evidenceId}/screenshot.png',
        status: 'captureHookFailed',
        mimeType: 'image/png',
        metadata: <String, Object?>{
          'captureMode': 'screenshot',
          'error': error.toString(),
          'studentId': request.studentId,
          'sessionId': request.sessionId,
          'eventType': request.event.type.name,
        },
      );
    }

    return _pending(request, reason: 'Screenshot provider returned no image.');
  }

  EvidenceArtifact _pending(
    EvidenceArtifactRequest request, {
    required String reason,
  }) {
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'evidence://pending/${request.evidenceId}/screenshot.png',
      status: 'pendingPlatformCapture',
      mimeType: 'image/png',
      metadata: <String, Object?>{
        'captureMode': 'screenshot',
        'reason': reason,
        'studentId': request.studentId,
        'sessionId': request.sessionId,
        'eventType': request.event.type.name,
      },
    );
  }
}
