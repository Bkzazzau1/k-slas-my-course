import '../risk/risk_level.dart';

class LocalAiConfig {
  const LocalAiConfig({
    this.faceMissingWarningSeconds = 10,
    this.faceMissingHighRiskSeconds = 30,
    this.audioBaselineSeconds = 15,
    this.voiceShortSeconds = 3,
    this.voiceLongSeconds = 10,
    this.lowRiskMax = 20,
    this.mediumRiskMax = 50,
    this.highRiskMax = 80,
    this.riskDecayPerMinute = 2,
    this.enableEvidenceForHighRisk = true,
    this.enableCloudAiForHighRiskOnly = true,
  });

  final int faceMissingWarningSeconds;
  final int faceMissingHighRiskSeconds;
  final int audioBaselineSeconds;
  final int voiceShortSeconds;
  final int voiceLongSeconds;
  final int lowRiskMax;
  final int mediumRiskMax;
  final int highRiskMax;
  final int riskDecayPerMinute;
  final bool enableEvidenceForHighRisk;
  final bool enableCloudAiForHighRiskOnly;

  RiskLevel riskLevelForScore(int score) {
    if (score <= lowRiskMax) return RiskLevel.low;
    if (score <= mediumRiskMax) return RiskLevel.medium;
    if (score <= highRiskMax) return RiskLevel.high;
    return RiskLevel.critical;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'faceMissingWarningSeconds': faceMissingWarningSeconds,
      'faceMissingHighRiskSeconds': faceMissingHighRiskSeconds,
      'audioBaselineSeconds': audioBaselineSeconds,
      'voiceShortSeconds': voiceShortSeconds,
      'voiceLongSeconds': voiceLongSeconds,
      'lowRiskMax': lowRiskMax,
      'mediumRiskMax': mediumRiskMax,
      'highRiskMax': highRiskMax,
      'riskDecayPerMinute': riskDecayPerMinute,
      'enableEvidenceForHighRisk': enableEvidenceForHighRisk,
      'enableCloudAiForHighRiskOnly': enableCloudAiForHighRiskOnly,
    };
  }
}
