import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/local_ai.dart';

void main() {
  test('face detector flags multiple faces with high severity', () async {
    final detector = FacePresenceDetector();
    final events = await detector.analyze(
      FacePresenceObservation(
        timestamp: DateTime(2026, 1, 1, 9),
        faceCount: 2,
        primaryFaceConfidence: 0.92,
      ),
    );

    expect(events, hasLength(1));
    expect(events.first.type, LocalAiEventType.multipleFacesDetected);
    expect(events.first.severity, LocalAiSeverity.high);
    expect(events.first.riskPoints, 25);
  });

  test('voice detector flags voice while mouth is not moving', () async {
    final detector = VoiceActivityDetector();
    final events = await detector.analyze(
      VoiceActivityObservation(
        timestamp: DateTime(2026, 1, 1, 9, 10),
        hasHumanVoice: true,
        durationSeconds: 6,
        confidence: 0.86,
        mouthMoving: false,
        sourceLabel: 'same_room_external',
      ),
    );

    expect(events, hasLength(1));
    expect(events.first.type, LocalAiEventType.voiceSourceEstimated);
    expect(events.first.severity, LocalAiSeverity.high);
    expect(events.first.riskPoints, 25);
  });

  test('local AI engine updates score from detector events', () async {
    final engine = LocalAiEngine();
    final detector = ScreenActivityDetector();

    await engine.runDetector(
      detector,
      ScreenActivityObservation(
        timestamp: DateTime(2026, 1, 1, 9, 15),
        kind: ScreenActivityKind.copyPaste,
      ),
    );

    expect(engine.scoreEngine.snapshot.score, 20);
    expect(engine.scoreEngine.snapshot.level, RiskLevel.low);
  });
}
