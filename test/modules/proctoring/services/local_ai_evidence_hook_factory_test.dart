import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/local_ai.dart';
import 'package:my_courses/modules/proctoring/services/local_ai_evidence_hook_factory.dart';

void main() {
  test('factory routes screenshot requests to screenshot provider', () async {
    final screenshotProvider = _ScreenshotProvider();
    final hook = LocalAiEvidenceHookFactory.build(
      cameraController: _cameraController(),
      screenshotProvider: screenshotProvider,
      fallbackHook: _FallbackHook(),
    );

    final artifact = await hook.captureArtifact(_request(kind: 'screenshot'));

    expect(artifact, isNotNull);
    expect(artifact!.status, 'captured');
    expect(artifact.metadata['captureMode'], 'screenshot');
    expect(screenshotProvider.calls, 1);
  });

  test('factory routes camera requests to camera hook', () async {
    final hook = LocalAiEvidenceHookFactory.build(
      cameraController: _cameraController(),
      fallbackHook: _FallbackHook(),
    );

    final artifact = await hook.captureArtifact(_request(kind: 'cameraClip'));

    expect(artifact, isNotNull);
    expect(artifact!.kind, 'cameraClip');
    expect(artifact.metadata['captureMode'], 'cameraSnapshot');
  });

  test('factory routes audio requests to audio hook', () async {
    final hook = LocalAiEvidenceHookFactory.build(
      cameraController: _cameraController(),
      audioClipProvider: const StaticAudioEvidenceClipProvider(
        path: 'file:///tmp/evidence/voice.wav',
        sizeBytes: 128,
      ),
      fallbackHook: _FallbackHook(),
    );

    final artifact = await hook.captureArtifact(_request(kind: 'audioClip'));

    expect(artifact, isNotNull);
    expect(artifact!.status, 'captured');
    expect(artifact.metadata['captureMode'], 'rollingAudioClip');
  });
}

CameraController _cameraController() {
  return CameraController(
    const CameraDescription(
      name: 'test-camera',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 0,
    ),
    ResolutionPreset.low,
  );
}

EvidenceArtifactRequest _request({required String kind}) {
  final mimeType = switch (kind) {
    'screenshot' => 'image/png',
    'audioClip' => 'audio/wav',
    'cameraClip' => 'image/jpeg',
    _ => 'application/octet-stream',
  };
  return EvidenceArtifactRequest(
    evidenceId: 'evidence-factory-1',
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
  var calls = 0;

  @override
  Future<EvidenceArtifact?> captureScreenshot(
    EvidenceArtifactRequest request,
  ) async {
    calls += 1;
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'file:///tmp/evidence/screen.png',
      status: 'captured',
      mimeType: 'image/png',
      metadata: const <String, Object?>{'captureMode': 'screenshot'},
    );
  }
}

class _FallbackHook implements EvidenceArtifactCaptureHook {
  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'file:///tmp/evidence/${request.kind}.bin',
      status: 'captured',
      mimeType: request.mimeType,
    );
  }
}
