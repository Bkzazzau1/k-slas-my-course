import '../core/local_ai_detector.dart';
import '../core/local_ai_event.dart';

class ScreenActivityObservation {
  const ScreenActivityObservation({
    required this.timestamp,
    required this.kind,
    this.appName,
    this.windowTitle,
    this.details = const <String, Object?>{},
  });

  final DateTime timestamp;
  final ScreenActivityKind kind;
  final String? appName;
  final String? windowTitle;
  final Map<String, Object?> details;
}

enum ScreenActivityKind {
  tabSwitch,
  appSwitch,
  copyPaste,
  remoteDesktop,
  screenSharing,
  multipleMonitor,
}

class ScreenActivityDetector
    implements LocalAiDetector<ScreenActivityObservation> {
  ScreenActivityDetector({this.enabled = true});

  final bool enabled;

  @override
  String get detectorId => 'screen_activity_detector';

  @override
  bool get isEnabled => enabled;

  @override
  Future<List<LocalAiEvent>> analyze(ScreenActivityObservation input) async {
    final eventType = _eventTypeFor(input.kind);
    final points = _pointsFor(input.kind);
    final severity = _severityFor(input.kind);

    return <LocalAiEvent>[
      LocalAiEvent(
        type: eventType,
        severity: severity,
        timestamp: input.timestamp,
        riskPoints: points,
        message: _messageFor(input.kind),
        metadata: <String, Object?>{
          'appName': input.appName,
          'windowTitle': input.windowTitle,
          ...input.details,
        },
      ),
    ];
  }

  LocalAiEventType _eventTypeFor(ScreenActivityKind kind) {
    switch (kind) {
      case ScreenActivityKind.tabSwitch:
        return LocalAiEventType.tabSwitchDetected;
      case ScreenActivityKind.appSwitch:
        return LocalAiEventType.appSwitchDetected;
      case ScreenActivityKind.copyPaste:
        return LocalAiEventType.copyPasteDetected;
      case ScreenActivityKind.remoteDesktop:
        return LocalAiEventType.remoteDesktopDetected;
      case ScreenActivityKind.screenSharing:
        return LocalAiEventType.screenSharingDetected;
      case ScreenActivityKind.multipleMonitor:
        return LocalAiEventType.multipleMonitorDetected;
    }
  }

  int _pointsFor(ScreenActivityKind kind) {
    switch (kind) {
      case ScreenActivityKind.tabSwitch:
      case ScreenActivityKind.appSwitch:
        return 15;
      case ScreenActivityKind.copyPaste:
        return 20;
      case ScreenActivityKind.remoteDesktop:
      case ScreenActivityKind.screenSharing:
        return 50;
      case ScreenActivityKind.multipleMonitor:
        return 25;
    }
  }

  LocalAiSeverity _severityFor(ScreenActivityKind kind) {
    switch (kind) {
      case ScreenActivityKind.remoteDesktop:
      case ScreenActivityKind.screenSharing:
        return LocalAiSeverity.critical;
      case ScreenActivityKind.copyPaste:
      case ScreenActivityKind.multipleMonitor:
        return LocalAiSeverity.high;
      case ScreenActivityKind.tabSwitch:
      case ScreenActivityKind.appSwitch:
        return LocalAiSeverity.medium;
    }
  }

  String _messageFor(ScreenActivityKind kind) {
    switch (kind) {
      case ScreenActivityKind.tabSwitch:
        return 'Student switched browser tab.';
      case ScreenActivityKind.appSwitch:
        return 'Student switched application or window.';
      case ScreenActivityKind.copyPaste:
        return 'Copy or paste activity detected.';
      case ScreenActivityKind.remoteDesktop:
        return 'Remote desktop tool detected.';
      case ScreenActivityKind.screenSharing:
        return 'Screen sharing activity detected.';
      case ScreenActivityKind.multipleMonitor:
        return 'Multiple monitor or display detected.';
    }
  }
}
