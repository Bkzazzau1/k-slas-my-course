import 'dart:async';

import 'local_ai_config.dart';
import 'local_ai_detector.dart';
import 'local_ai_event.dart';
import 'local_ai_score_engine.dart';

class LocalAiEngine {
  LocalAiEngine({
    LocalAiConfig config = const LocalAiConfig(),
    LocalAiScoreEngine? scoreEngine,
  })  : config = config,
        scoreEngine = scoreEngine ?? LocalAiScoreEngine(config: config);

  final LocalAiConfig config;
  final LocalAiScoreEngine scoreEngine;
  final StreamController<LocalAiEvent> _eventController =
      StreamController<LocalAiEvent>.broadcast();

  Stream<LocalAiEvent> get events => _eventController.stream;

  Future<void> ingest(LocalAiEvent event) async {
    scoreEngine.addEvent(event);
    _eventController.add(event);
  }

  Future<void> ingestAll(Iterable<LocalAiEvent> events) async {
    for (final event in events) {
      await ingest(event);
    }
  }

  Future<List<LocalAiEvent>> runDetector<TInput>(
    LocalAiDetector<TInput> detector,
    TInput input,
  ) async {
    if (!detector.isEnabled) return const <LocalAiEvent>[];
    final detectedEvents = await detector.analyze(input);
    await ingestAll(detectedEvents);
    return detectedEvents;
  }

  Future<void> dispose() async {
    await _eventController.close();
  }
}
