import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/local_ai.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('latest frame provider should capture camera image evidence', () async {
    final directory = await Directory.systemTemp.createTemp('camera_evidence_');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final provider = LatestCameraFrameEvidenceProvider(
      outputDirectory: directory,
    )..rememberFrame(_fakeImage(), DateTime.now());
    final hook = CameraEvidenceCaptureHook(
      cameraController: _cameraController(),
      frameProvider: provider,
    );

    final artifact = await hook.captureArtifact(
      EvidenceArtifactRequest(
        evidenceId: 'evidence-camera-1',
        kind: 'cameraClip',
        mimeType: 'image/jpeg',
        studentId: 'KASU/CSC/001',
        sessionId: 'session-1',
        event: LocalAiEvent(
          type: LocalAiEventType.multipleFacesDetected,
          severity: LocalAiSeverity.high,
          timestamp: DateTime.now(),
          riskPoints: 25,
        ),
      ),
    );

    expect(artifact, isNotNull);
    expect(artifact!.status, 'captured');
    expect(artifact.path, startsWith('file://'));
    expect(artifact.metadata['captureMode'], 'latestCameraFrame');
  });

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

CameraImage _fakeImage() {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // ignore: deprecated_member_use
  return CameraImage.fromPlatformData(<dynamic, dynamic>{
    'format': 35,
    'height': 2,
    'width': 2,
    'lensAperture': 0.0,
    'sensorExposureTime': 0,
    'sensorSensitivity': 0.0,
    'planes': <dynamic>[
      <dynamic, dynamic>{
        'bytes': Uint8List.fromList(<int>[20, 80, 160, 240]),
        'bytesPerRow': 2,
        'bytesPerPixel': 1,
        'height': 2,
        'width': 2,
      },
    ],
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
