enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

extension RiskLevelX on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.critical:
        return 'Critical';
    }
  }

  bool get requiresInvigilatorReview =>
      this == RiskLevel.high || this == RiskLevel.critical;

  bool get requiresImmediateEscalation => this == RiskLevel.critical;
}
