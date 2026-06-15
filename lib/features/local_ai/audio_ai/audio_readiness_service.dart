import '../core/local_ai_event.dart';

class AudioReadinessResult {
  const AudioReadinessResult({
    required this.microphoneAvailable,
    required this.permissionGranted,
    required this.inputLevelOk,
    this.message,
  });

  final bool microphoneAvailable;
  final bool permissionGranted;
  final bool inputLevelOk;
  final String? message;

  bool get canStartExam =>
      microphoneAvailable && permissionGranted && inputLevelOk;

  List<LocalAiEvent> toEvents({String? sessionId, String? studentId}) {
    if (canStartExam) return const <LocalAiEvent>[];

    return <LocalAiEvent>[
      LocalAiEvent(
        type: LocalAiEventType.microphoneReadinessFailed,
        severity: LocalAiSeverity.high,
        timestamp: DateTime.now(),
        riskPoints: 0,
        sessionId: sessionId,
        studentId: studentId,
        message: message ?? 'Microphone readiness check failed.',
        metadata: <String, Object?>{
          'microphoneAvailable': microphoneAvailable,
          'permissionGranted': permissionGranted,
          'inputLevelOk': inputLevelOk,
        },
      ),
    ];
  }
}

class AudioReadinessService {
  Future<AudioReadinessResult> evaluate({
    required bool microphoneAvailable,
    required bool permissionGranted,
    required bool inputLevelOk,
  }) async {
    return AudioReadinessResult(
      microphoneAvailable: microphoneAvailable,
      permissionGranted: permissionGranted,
      inputLevelOk: inputLevelOk,
      message: _messageFor(
        microphoneAvailable: microphoneAvailable,
        permissionGranted: permissionGranted,
        inputLevelOk: inputLevelOk,
      ),
    );
  }

  String? _messageFor({
    required bool microphoneAvailable,
    required bool permissionGranted,
    required bool inputLevelOk,
  }) {
    if (!microphoneAvailable) return 'No microphone detected.';
    if (!permissionGranted) return 'Microphone permission is not granted.';
    if (!inputLevelOk) return 'Microphone input level is not valid.';
    return null;
  }
}
