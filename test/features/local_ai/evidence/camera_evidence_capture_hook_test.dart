import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/local_ai.dart';

void main() {
  test('fallback hook should receive non-camera evidence requests', () async {
    final fallback = _FakeFallbackHook();
    final hook = _DelegatingCameraEvidenceHook(fallbackHook: fallback);

    final artifact = await hook.captureArtifact(
      EvidenceArtifactRequest(
        evidenceId: 'evidence-1',
        kind: 'screenshot',
        mimeType: 'image/png',
        studentId: 'KASU/CSC/001',
        sessionId: 'session-1',
        event: LocalAiEvent(
          type: LocalAiEventType.tabSwitchDetected,
          severity: LocalAiSeverity.high,
          timestamp: DateTime.now(),
          riskPoints: 25,
        ),
      ),
    );

    expect(artifact, isNotNull);
    expect(artifact!.kind, 'screenshot');
    expect(artifact.status, 'captured');
    expect(fallback.calls, 1);
  });
}

class _DelegatingCameraEvidenceHook implements EvidenceArtifactCaptureHook {
  _DelegatingCameraEvidenceHook({this.fallbackHook});

  final EvidenceArtifactCaptureHook? fallbackHook;

  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    if (request.kind != 'cameraClip') {
      return fallbackHook?.captureArtifact(request);
    }
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'file:///tmp/evidence/${request.kind}.jpg',
      status: 'captured',
      mimeType: 'image/jpeg',
    );
  }
}

class _FakeFallbackHook implements EvidenceArtifactCaptureHook {
  var calls = 0;

  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
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
