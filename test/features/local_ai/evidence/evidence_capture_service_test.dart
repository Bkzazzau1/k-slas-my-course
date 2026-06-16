import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_courses/features/local_ai/local_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  test('capture should skip low severity events', () async {
    final service = EvidenceCaptureService();
    await service.clearAllForStudent('KASU/CSC/001');

    final event = LocalAiEvent(
      type: LocalAiEventType.facePresent,
      severity: LocalAiSeverity.info,
      timestamp: DateTime.now(),
      riskPoints: 0,
      studentId: 'KASU/CSC/001',
      sessionId: 'session-1',
    );

    final result = await service.capture(
      EvidenceCaptureRequest(
        sessionId: 'session-1',
        studentId: 'KASU/CSC/001',
        event: event,
        captureCameraClip: true,
      ),
    );

    expect(result.hasEvidence, isFalse);
    expect(service.loadManifests('KASU/CSC/001'), isEmpty);
  });

  test('capture should create manifest for high severity events', () async {
    final service = EvidenceCaptureService();
    await service.clearAllForStudent('KASU/CSC/001');

    final event = LocalAiEvent(
      type: LocalAiEventType.multipleFacesDetected,
      severity: LocalAiSeverity.high,
      timestamp: DateTime.now(),
      riskPoints: 25,
      studentId: 'KASU/CSC/001',
      sessionId: 'session-1',
      message: 'Multiple faces detected.',
    );

    final result = await service.capture(
      EvidenceCaptureRequest(
        sessionId: 'session-1',
        studentId: 'KASU/CSC/001',
        event: event,
        captureCameraClip: true,
        reason: 'Multiple faces detected.',
      ),
    );

    expect(result.hasEvidence, isTrue);
    expect(result.manifestPath, startsWith('evidence://'));
    expect(result.cameraClipPath, startsWith('evidence://pending/'));

    final manifests = service.loadManifests('KASU/CSC/001');
    expect(manifests, hasLength(1));
    expect(manifests.first.eventType, 'multipleFacesDetected');
    expect(
      manifests.first.artifacts.any((artifact) => artifact.kind == 'manifest'),
      isTrue,
    );
    expect(
      manifests.first.artifacts.any(
        (artifact) => artifact.kind == 'cameraClip',
      ),
      isTrue,
    );
  });

  test('capture should use artifact hook when attached', () async {
    final service = EvidenceCaptureService(
      artifactCaptureHook: _FakeEvidenceHook(),
    );
    await service.clearAllForStudent('KASU/CSC/003');

    final event = LocalAiEvent(
      type: LocalAiEventType.tabSwitchDetected,
      severity: LocalAiSeverity.high,
      timestamp: DateTime.now(),
      riskPoints: 25,
      studentId: 'KASU/CSC/003',
      sessionId: 'session-3',
    );

    final result = await service.capture(
      EvidenceCaptureRequest(
        sessionId: 'session-3',
        studentId: 'KASU/CSC/003',
        event: event,
        captureScreenshot: true,
      ),
    );

    expect(result.screenshotPath, 'file:///tmp/evidence/screenshot.png');
    final manifests = service.loadManifests('KASU/CSC/003');
    final screenshot = manifests.first.artifacts.firstWhere(
      (artifact) => artifact.kind == 'screenshot',
    );
    expect(screenshot.status, 'captured');
    expect(screenshot.isCaptured, isTrue);
  });

  test('capture should mark artifact failure when hook throws', () async {
    final service = EvidenceCaptureService(
      artifactCaptureHook: _FailingEvidenceHook(),
    );
    await service.clearAllForStudent('KASU/CSC/004');

    final event = LocalAiEvent(
      type: LocalAiEventType.humanVoiceDetected,
      severity: LocalAiSeverity.high,
      timestamp: DateTime.now(),
      riskPoints: 20,
      studentId: 'KASU/CSC/004',
      sessionId: 'session-4',
    );

    await service.capture(
      EvidenceCaptureRequest(
        sessionId: 'session-4',
        studentId: 'KASU/CSC/004',
        event: event,
        captureAudioClip: true,
      ),
    );

    final manifests = service.loadManifests('KASU/CSC/004');
    final audio = manifests.first.artifacts.firstWhere(
      (artifact) => artifact.kind == 'audioClip',
    );
    expect(audio.status, 'captureHookFailed');
    expect(audio.metadata['error'], contains('capture failed'));
  });

  test('toEvidenceEvent should expose manifest metadata', () async {
    final service = EvidenceCaptureService();
    await service.clearAllForStudent('KASU/CSC/002');

    final event = LocalAiEvent(
      type: LocalAiEventType.humanVoiceDetected,
      severity: LocalAiSeverity.high,
      timestamp: DateTime.now(),
      riskPoints: 20,
      studentId: 'KASU/CSC/002',
      sessionId: 'session-2',
    );

    final result = await service.capture(
      EvidenceCaptureRequest(
        sessionId: 'session-2',
        studentId: 'KASU/CSC/002',
        event: event,
        captureAudioClip: true,
      ),
    );

    final evidenceEvent = result.toEvidenceEvent();

    expect(evidenceEvent.type, LocalAiEventType.evidenceCaptured);
    expect(evidenceEvent.riskPoints, 0);
    expect(evidenceEvent.evidencePath, result.manifestPath);
    expect(evidenceEvent.metadata['manifestPath'], result.manifestPath);
  });
}

class _FakeEvidenceHook implements EvidenceArtifactCaptureHook {
  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: 'file:///tmp/evidence/${request.kind}.png',
      status: 'captured',
      mimeType: request.mimeType,
      sizeBytes: 128,
      metadata: <String, Object?>{
        'studentId': request.studentId,
        'sessionId': request.sessionId,
      },
    );
  }
}

class _FailingEvidenceHook implements EvidenceArtifactCaptureHook {
  @override
  Future<EvidenceArtifact?> captureArtifact(
    EvidenceArtifactRequest request,
  ) async {
    throw StateError('capture failed for ${request.kind}');
  }
}
