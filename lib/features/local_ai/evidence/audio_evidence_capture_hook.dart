import 'evidence_capture_service.dart';

abstract class AudioEvidenceClipProvider {
  Future<EvidenceArtifact?> latestClip(EvidenceArtifactRequest request);
}

class AudioEvidenceCaptureHook implements EvidenceArtifactCaptureHook {
  AudioEvidenceCaptureHook({
    this.clipProvider,
    this.fallbackHook,
  });

  final AudioEvidenceClipProvider? clipProvider;
  final EvidenceArtifactCaptureHook? fallbackHook;

  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    if (request.kind != 'audioClip') {
      return fallbackHook?.captureArtifact(request);
    }

    final provider = clipProvider;
    if (provider == null) {
      return _pending(
        request,
        reason: 'Audio clip provider is not attached.',
      );
    }

    try {
      final artifact = await provider.latestClip(request);
      if (artifact != null) return artifact;
      return _pending(
        request,
        reason: 'Audio clip provider returned no clip.',
      );
    } catch (error) {
      return EvidenceArtifact(
        id: '${request.evidenceId}-${request.kind}',
        kind: request.kind,
        path: 'evidence://pending/${request.evidenceId}/${request.kind}.wav',
        status: 'captureHookFailed',
        mimeType: 'audio/wav',
        metadata: <String, Object?>{
          'captureMode': 'rollingAudioClip',
          'requestedMimeType': request.mimeType,
          'error': error.toString(),
          'studentId': request.studentId,
          'sessionId': request.sessionId,
          'eventType': request.event.type.name,
          'reason': request.reason,
        },
      );
    }
  }

  EvidenceArtifact _pending(
    EvidenceArtifactRequest request, {
    required String reason,
  }) {
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'evidence://pending/${request.evidenceId}/${request.kind}.wav',
      status: 'pendingPlatformCapture',
      mimeType: 'audio/wav',
      metadata: <String, Object?>{
        'captureMode': 'rollingAudioClip',
        'requestedMimeType': request.mimeType,
        'reason': reason,
        'studentId': request.studentId,
        'sessionId': request.sessionId,
        'eventType': request.event.type.name,
      },
    );
  }
}

class StaticAudioEvidenceClipProvider implements AudioEvidenceClipProvider {
  const StaticAudioEvidenceClipProvider({
    required this.path,
    this.sizeBytes,
    this.mimeType = 'audio/wav',
    this.metadata = const <String, Object?>{},
  });

  final String path;
  final int? sizeBytes;
  final String mimeType;
  final Map<String, Object?> metadata;

  @override
  Future<EvidenceArtifact?> latestClip(EvidenceArtifactRequest request) async {
    if (path.trim().isEmpty) return null;
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: path,
      status: 'captured',
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      metadata: <String, Object?>{
        'captureMode': 'rollingAudioClip',
        'studentId': request.studentId,
        'sessionId': request.sessionId,
        'eventType': request.event.type.name,
        'reason': request.reason,
        ...metadata,
      },
    );
  }
}
