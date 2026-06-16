import 'package:camera/camera.dart';

import 'evidence_capture_service.dart';

class CameraEvidenceCaptureHook implements EvidenceArtifactCaptureHook {
  CameraEvidenceCaptureHook({
    required this.cameraController,
    this.fallbackHook,
  });

  final CameraController cameraController;
  final EvidenceArtifactCaptureHook? fallbackHook;

  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    if (request.kind != 'cameraClip') {
      return fallbackHook?.captureArtifact(request);
    }

    if (!cameraController.value.isInitialized) {
      return _pending(
        request,
        reason: 'Camera controller is not initialized.',
      );
    }

    if (cameraController.value.isStreamingImages) {
      return _pending(
        request,
        reason: 'Camera image stream is active; snapshot capture deferred.',
      );
    }

    if (cameraController.value.isTakingPicture) {
      return _pending(
        request,
        reason: 'Camera is already taking a picture.',
      );
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
