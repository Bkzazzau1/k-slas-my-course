import 'local_ai_config.dart';
import 'local_ai_event.dart';
import '../risk/risk_level.dart';

class LocalAiScoreSnapshot {
  const LocalAiScoreSnapshot({
    required this.score,
    required this.level,
    required this.eventsCount,
    required this.updatedAt,
    this.lastEvent,
  });

  final int score;
  final RiskLevel level;
  final int eventsCount;
  final DateTime updatedAt;
  final LocalAiEvent? lastEvent;

  bool get needsReview => level.requiresInvigilatorReview;
}

class LocalAiScoreEngine {
  LocalAiScoreEngine({LocalAiConfig config = const LocalAiConfig()})
      : _config = config;

  final LocalAiConfig _config;
  final List<LocalAiEvent> _events = <LocalAiEvent>[];
  int _score = 0;

  LocalAiScoreSnapshot get snapshot => LocalAiScoreSnapshot(
        score: _score,
        level: _config.riskLevelForScore(_score),
        eventsCount: _events.length,
        updatedAt: DateTime.now(),
        lastEvent: _events.isEmpty ? null : _events.last,
      );

  LocalAiScoreSnapshot addEvent(LocalAiEvent event) {
    _events.add(event);
    _score = (_score + event.riskPoints).clamp(0, 100).toInt();
    return snapshot;
  }

  void reset() {
    _events.clear();
    _score = 0;
  }
}
