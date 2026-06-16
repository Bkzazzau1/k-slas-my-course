import 'dart:io';

import 'audio_evidence_capture_hook.dart';
import 'evidence_capture_service.dart';

class RollingAudioEvidenceProvider implements AudioEvidenceClipProvider {
  RollingAudioEvidenceProvider({required this.latestClipPathProvider});

  final Future<String?> Function() latestClipPathProvider;

  @override
  Future<EvidenceArtifact?> latestClip(EvidenceArtifactRequest request) async {
    final path = await latestClipPathProvider();
    if (path == null || path.trim().isEmpty) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: file.uri.toString(),
      status: 'captured',
      mimeType: 'audio/wav',
      sizeBytes: await file.length(),
      metadata: <String, Object?>{
        'captureMode': 'rollingAudioClip',
        'studentId': request.studentId,
        'sessionId': request.sessionId,
        'eventType': request.event.type.name,
        'reason': request.reason,
      },
    );
  }
}
