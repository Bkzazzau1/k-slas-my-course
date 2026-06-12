class WhiteboardPoint {
  const WhiteboardPoint({required this.dx, required this.dy});

  final double dx;
  final double dy;

  Map<String, dynamic> toMap() {
    return {'dx': dx, 'dy': dy};
  }

  factory WhiteboardPoint.fromMap(Map<String, dynamic> map) {
    final rawDx = map['dx'];
    final rawDy = map['dy'];
    final dx = rawDx is num ? rawDx.toDouble() : 0.0;
    final dy = rawDy is num ? rawDy.toDouble() : 0.0;

    return WhiteboardPoint(dx: dx, dy: dy);
  }
}

class WhiteboardStroke {
  const WhiteboardStroke({
    required this.points,
    this.colorValue = 0xFF0B1020,
    this.strokeWidth = 3.0,
    this.toolType = 'pen',
    this.timestamp,
    this.userId,
    this.sessionId,
  });

  final List<WhiteboardPoint> points;
  final int colorValue;
  final double strokeWidth;
  final String toolType;
  final DateTime? timestamp;
  final String? userId;
  final String? sessionId;

  bool get isUsable => points.length > 1;

  WhiteboardStroke copyWith({
    List<WhiteboardPoint>? points,
    int? colorValue,
    double? strokeWidth,
    String? toolType,
    DateTime? timestamp,
    String? userId,
    String? sessionId,
  }) {
    return WhiteboardStroke(
      points: points ?? this.points,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      toolType: toolType ?? this.toolType,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => p.toMap()).toList(),
      'colorValue': colorValue,
      'strokeWidth': strokeWidth,
      'toolType': toolType,
      'timestamp': timestamp?.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  factory WhiteboardStroke.fromMap(Map<String, dynamic> map) {
    final rawPoints = (map['points'] as List?) ?? const [];
    final rawStrokeWidth = map['strokeWidth'];

    return WhiteboardStroke(
      points: rawPoints
          .whereType<Map>()
          .map((p) => WhiteboardPoint.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      colorValue: (map['colorValue'] is num)
          ? (map['colorValue'] as num).toInt()
          : 0xFF0B1020,
      strokeWidth: rawStrokeWidth is num ? rawStrokeWidth.toDouble() : 3.0,
      toolType: map['toolType']?.toString() ?? 'pen',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? ''),
      userId: map['userId']?.toString(),
      sessionId: map['sessionId']?.toString(),
    );
  }
}
