import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/core/local_ai_event.dart';
import 'package:my_courses/features/local_ai/evidence/audio_evidence_capture_hook.dart';
import 'package:my_courses/features/local_ai/evidence/evidence_capture_service.dart';

void main() {
  test('AudioEvidenceCaptureHook should return pending when provider is missing', () async {
    final hook = AudioEvidenceCaptureHook();

    final artifact = await hook.captureArtifact(_request());

    expect(artifact, isNotNull);
    expect(artifact!.kind, 'audioClip');
    expect(artifact.status, 'pendingPlatformCapture');
    expect(artifact.path, startsWith('evidence://pending/'));
  });

  test('AudioEvidenceCaptureHook should use static rolling clip provider', () async {
    final hook = AudioEvidenceCaptureHook(
      clipProvider: const StaticAudioEvidenceClipProvider(
        path: 'file:///tmp/evidence/voice.wav',
        sizeBytes: 2048,
      ),
    );

    final artifact = await hook.captureArtifact(_request());

    expect(artifact, isNotNull);
    expect(artifact!.status, 'captured');
    expect(artifact.path, 'file:///tmp/evidence/voice.wav');
    expect(artifact.sizeBytes, 2048);
    expect(artifact.metadata['captureMode'], 'rollingAudioClip');
  });

  test('AudioEvidenceCaptureHook should record failure when provider throws', () async {
    final hook = AudioEvidenceCaptureHook(clipProvider: _FailingClipProvider());

    final artifact = await hook.captureArtifact(_request());

    expect(artifact, isNotNull);
    expect(artifact!.status, 'captureHookFailed');
    expect(artifact.metadata['error'], contains('audio provider failed'));
  });

  test('AudioEvidenceCaptureHook should delegate non-audio requests', () async {
    final fallback = _FallbackHook();
    final hook = AudioEvidenceCaptureHook(fallbackHook: fallback);

    final artifact = await hook.captureArtifact(
      _request(kind: 'screenshot', mimeType: 'image/png'),
    );

    expect(artifact, isNotNull);
    expect(artifact!.kind, 'screenshot');
    expect(fallback.calls, 1);
  });
}

EvidenceArtifactRequest _request({
  String kind = 'audioClip',
  String mimeType = 'audio/wav',
}) {
  return EvidenceArtifactRequest(
    evidenceId: 'evidence-voice-1',
    kind: kind,
    mimeType: mimeType,
    studentId: 'KASU/CSC/001',
    sessionId: 'session-1',
    event: LocalAiEvent(
      type: LocalAiEventType.humanVoiceDetected,
      severity: LocalAiSeverity.high,
      timestamp: DateTime.now(),
      riskPoints: 20,
    ),
  );
}

class _FailingClipProvider implements AudioEvidenceClipProvider {
  @override
  Future<EvidenceArtifact?> latestClip(EvidenceArtifactRequest request) async {
    throw StateError('audio provider failed');
  }
}

class _FallbackHook implements EvidenceArtifactCaptureHook {
  var calls = 0;

  @override
  Future<EvidenceArtifact?> captureArtifact(EvidenceArtifactRequest request) async {
    calls += 1;
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'file:///tmp/evidence/${request.kind}.png',
      status: 'captured',
      mimeType: request.mimeType,
    );
  }
}
