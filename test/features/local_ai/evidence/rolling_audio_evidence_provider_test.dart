import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/local_ai.dart';

void main() {
  test(
    'RollingAudioEvidenceProvider returns captured clip when path exists',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'audio_evidence_',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final file = File(
        '${directory.path}${Platform.pathSeparator}last_30.wav',
      );
      await file.writeAsBytes(<int>[1, 2, 3, 4]);

      final provider = RollingAudioEvidenceProvider(
        latestClipPathProvider: () async => file.path,
      );

      final artifact = await provider.latestClip(_request());

      expect(artifact, isNotNull);
      expect(artifact!.status, 'captured');
      expect(artifact.path, file.uri.toString());
      expect(artifact.sizeBytes, 4);
      expect(artifact.metadata['captureMode'], 'rollingAudioClip');
    },
  );

  test(
    'AudioEvidenceCaptureHook returns pending when rolling path is missing',
    () async {
      final provider = RollingAudioEvidenceProvider(
        latestClipPathProvider: () async => 'C:/definitely/missing/audio.wav',
      );
      final hook = AudioEvidenceCaptureHook(clipProvider: provider);

      final artifact = await hook.captureArtifact(_request());

      expect(artifact, isNotNull);
      expect(artifact!.status, 'pendingPlatformCapture');
      expect(artifact.metadata['reason'], contains('returned no clip'));
    },
  );
}

EvidenceArtifactRequest _request() {
  return EvidenceArtifactRequest(
    evidenceId: 'evidence-audio-1',
    kind: 'audioClip',
    mimeType: 'audio/wav',
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
