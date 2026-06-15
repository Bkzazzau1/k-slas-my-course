enum LocalAiEventType {
  cameraReadinessFailed,
  cameraBlocked,
  facePresent,
  faceMissing,
  multipleFacesDetected,
  lookingAway,
  mouthMovementDetected,
  mouthNotMoving,
  phoneDetected,
  prohibitedMaterialDetected,
  microphoneReadinessFailed,
  audioBaselineCaptured,
  humanVoiceDetected,
  whisperDetected,
  multipleVoicesDetected,
  backgroundNoiseDetected,
  voiceSourceEstimated,
  tabSwitchDetected,
  appSwitchDetected,
  copyPasteDetected,
  remoteDesktopDetected,
  screenSharingDetected,
  multipleMonitorDetected,
  suspiciousPatternDetected,
  evidenceCaptured,
}

enum LocalAiSeverity {
  info,
  low,
  medium,
  high,
  critical,
}

class LocalAiEvent {
  const LocalAiEvent({
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.riskPoints,
    this.confidence,
    this.sessionId,
    this.studentId,
    this.message,
    this.evidencePath,
    this.metadata = const <String, Object?>{},
  });

  final LocalAiEventType type;
  final LocalAiSeverity severity;
  final DateTime timestamp;
  final int riskPoints;
  final double? confidence;
  final String? sessionId;
  final String? studentId;
  final String? message;
  final String? evidencePath;
  final Map<String, Object?> metadata;

  bool get shouldAlertInvigilator =>
      severity == LocalAiSeverity.high || severity == LocalAiSeverity.critical;

  LocalAiEvent copyWith({
    LocalAiEventType? type,
    LocalAiSeverity? severity,
    DateTime? timestamp,
    int? riskPoints,
    double? confidence,
    String? sessionId,
    String? studentId,
    String? message,
    String? evidencePath,
    Map<String, Object?>? metadata,
  }) {
    return LocalAiEvent(
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      riskPoints: riskPoints ?? this.riskPoints,
      confidence: confidence ?? this.confidence,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      message: message ?? this.message,
      evidencePath: evidencePath ?? this.evidencePath,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type.name,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'riskPoints': riskPoints,
      'confidence': confidence,
      'sessionId': sessionId,
      'studentId': studentId,
      'message': message,
      'evidencePath': evidencePath,
      'metadata': metadata,
    };
  }

  factory LocalAiEvent.fromJson(Map<String, Object?> json) {
    return LocalAiEvent(
      type: LocalAiEventType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => LocalAiEventType.suspiciousPatternDetected,
      ),
      severity: LocalAiSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => LocalAiSeverity.info,
      ),
      timestamp: DateTime.tryParse('${json['timestamp']}') ?? DateTime.now(),
      riskPoints: (json['riskPoints'] as num?)?.toInt() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble(),
      sessionId: json['sessionId'] as String?,
      studentId: json['studentId'] as String?,
      message: json['message'] as String?,
      evidencePath: json['evidencePath'] as String?,
      metadata: (json['metadata'] as Map?)?.cast<String, Object?>() ??
          const <String, Object?>{},
    );
  }
}
