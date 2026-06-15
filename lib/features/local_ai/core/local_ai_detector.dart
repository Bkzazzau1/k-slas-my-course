import 'local_ai_event.dart';

abstract class LocalAiDetector<TInput> {
  String get detectorId;
  bool get isEnabled;

  Future<List<LocalAiEvent>> analyze(TInput input);
}

class LocalAiFrameInput {
  const LocalAiFrameInput({
    required this.timestamp,
    this.width,
    this.height,
    this.metadata = const <String, Object?>{},
  });

  final DateTime timestamp;
  final int? width;
  final int? height;
  final Map<String, Object?> metadata;
}

class LocalAiAudioInput {
  const LocalAiAudioInput({
    required this.timestamp,
    required this.durationMs,
    required this.rms,
    this.sampleRate,
    this.metadata = const <String, Object?>{},
  });

  final DateTime timestamp;
  final int durationMs;
  final double rms;
  final int? sampleRate;
  final Map<String, Object?> metadata;
}
