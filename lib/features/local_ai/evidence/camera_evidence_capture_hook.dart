import 'package:camera/camera.dart';

import 'evidence_capture_service.dart';

abstract class CameraEvidenceFrameProvider {
  Future<EvidenceArtifact?> latestFrame(EvidenceArtifactRequest request);
}

class CameraEvidenceCaptureHook implements EvidenceArtifactCaptureHook {
  CameraEvidenceCaptureHook({
    required this.cameraController,
    this.frameProvider,
    this.fallbackHook,
  });

  final CameraController cameraController;
  final CameraEvidenceFrameProvider? frameProvider;
  final EvidenceArtifactCaptureHook? fallbackHook;

  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    if (request.kind != 'cameraClip') {
      return fallbackHook?.captureArtifact(request);
    }

    if (!cameraController.value.isInitialized) {
      final artifact = await _latestFrameArtifact(request);
      if (artifact != null) return artifact;
      return _pending(request, reason: 'Camera controller is not initialized.');
    }

    if (cameraController.value.isStreamingImages) {
      final artifact = await _latestFrameArtifact(request);
      if (artifact != null) return artifact;
      return _pending(
        request,
        reason: 'Camera image stream is active; snapshot capture deferred.',
      );
    }

    if (cameraController.value.isTakingPicture) {
      return _pending(request, reason: 'Camera is already taking a picture.');
    }

    final file = await cameraController.takePicture();
    final sizeBytes = await file.length();

    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: Uri.file(file.path).toString(),
      status: 'captured',
      mimeType: 'image/jpeg',
      sizeBytes: sizeBytes,
      metadata: <String, Object?>{
        'captureMode': 'cameraSnapshot',
        'requestedMimeType': request.mimeType,
        'studentId': request.studentId,
        'sessionId': request.sessionId,
        'eventType': request.event.type.name,
        'reason': request.reason,
      },
    );
  }

  Future<EvidenceArtifact?> _latestFrameArtifact(
    EvidenceArtifactRequest request,
  ) async {
    final provider = frameProvider;
    if (provider == null) return null;
    return provider.latestFrame(request);
  }

  EvidenceArtifact _pending(
    EvidenceArtifactRequest request, {
    required String reason,
  }) {
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'evidence://pending/${request.evidenceId}/${request.kind}.jpg',
      status: 'pendingPlatformCapture',
      mimeType: 'image/jpeg',
      metadata: <String, Object?>{
        'captureMode': 'cameraSnapshot',
        'requestedMimeType': request.mimeType,
        'reason': reason,
        'studentId': request.studentId,
        'sessionId': request.sessionId,
        'eventType': request.event.type.name,
      },
    );
  }
}
