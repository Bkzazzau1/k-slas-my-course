import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/local_ai.dart';

void main() {
  test(
    'ScreenshotEvidenceCaptureHook returns pending when provider is missing',
    () async {
      final hook = ScreenshotEvidenceCaptureHook();

      final artifact = await hook.captureArtifact(_request());

      expect(artifact, isNotNull);
      expect(artifact!.kind, 'screenshot');
      expect(artifact.status, 'pendingPlatformCapture');
      expect(artifact.metadata['reason'], contains('not attached'));
    },
  );

  test(
    'ScreenshotEvidenceCaptureHook returns captured provider artifact',
    () async {
      final hook = ScreenshotEvidenceCaptureHook(
        provider: _ScreenshotProvider(),
      );

      final artifact = await hook.captureArtifact(_request());

      expect(artifact, isNotNull);
      expect(artifact!.status, 'captured');
      expect(artifact.path, 'file:///tmp/evidence/screen.png');
    },
  );

  test('ScreenshotEvidenceCaptureHook records provider failures', () async {
    final hook = ScreenshotEvidenceCaptureHook(provider: _FailingProvider());

    final artifact = await hook.captureArtifact(_request());

    expect(artifact, isNotNull);
    expect(artifact!.status, 'captureHookFailed');
    expect(artifact.metadata['error'], contains('screenshot failed'));
  });

  test(
    'ScreenshotEvidenceCaptureHook delegates non-screenshot requests',
    () async {
      final fallback = _FallbackHook();
      final hook = ScreenshotEvidenceCaptureHook(fallbackHook: fallback);

      final artifact = await hook.captureArtifact(
        _request(kind: 'audioClip', mimeType: 'audio/wav'),
      );

      expect(artifact, isNotNull);
      expect(artifact!.kind, 'audioClip');
      expect(fallback.calls, 1);
    },
  );
}

EvidenceArtifactRequest _request({
  String kind = 'screenshot',
  String mimeType = 'image/png',
}) {
  return EvidenceArtifactRequest(
    evidenceId: 'evidence-screen-1',
    kind: kind,
    mimeType: mimeType,
    studentId: 'KASU/CSC/001',
    sessionId: 'session-1',
    event: LocalAiEvent(
      type: LocalAiEventType.tabSwitchDetected,
      severity: LocalAiSeverity.high,
      timestamp: DateTime.now(),
      riskPoints: 25,
    ),
  );
}

class _ScreenshotProvider implements ScreenshotEvidenceProvider {
  @override
  Future<EvidenceArtifact?> captureScreenshot(
    EvidenceArtifactRequest request,
  ) async {
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'file:///tmp/evidence/screen.png',
      status: 'captured',
      mimeType: 'image/png',
      sizeBytes: 256,
    );
  }
}

class _FailingProvider implements ScreenshotEvidenceProvider {
  @override
  Future<EvidenceArtifact?> captureScreenshot(
    EvidenceArtifactRequest request,
  ) async {
    throw StateError('screenshot failed');
  }
}

class _FallbackHook implements EvidenceArtifactCaptureHook {
  var calls = 0;

  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    calls += 1;
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'file:///tmp/evidence/${request.kind}.bin',
      status: 'captured',
      mimeType: request.mimeType,
    );
  }
}
