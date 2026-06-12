import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modules/proctoring/controller/proctoring_controller.dart';

class DashboardIntegrityStatusCard extends StatelessWidget {
  const DashboardIntegrityStatusCard({
    super.key,
    required this.cs,
    required this.proctor,
  });

  final ColorScheme cs;
  final ProctoringController proctor;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = proctor.shieldActive.value;
      final score = proctor.integrityScore.value;
      final violations = proctor.violationCount.value;
      final level = proctor.currentLevel.value;
      final tier = proctor.riskTier.value.name.toUpperCase();
      final pendingSync = proctor.pendingLedgerSyncCount.value;

      final statusColor = active ? cs.primary : cs.onSurface;
      final statusText = active
          ? "Shield active for ${_levelLabel(level)}"
          : "Shield idle (starts automatically for remote proctored sessions)";

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface.withValues(alpha: 0.76),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "K-SLAS Integrity",
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                _MetricPill(
                  cs: cs,
                  label: active ? "Active" : "Idle",
                  accent: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              statusText,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricPill(
                  cs: cs,
                  label: "Score $score",
                  accent: score >= 70 ? cs.primary : cs.error,
                ),
                _MetricPill(
                  cs: cs,
                  label: "Violations $violations",
                  accent: violations == 0 ? cs.primary : cs.error,
                ),
                _MetricPill(
                  cs: cs,
                  label: _levelLabel(level),
                  accent: cs.secondary,
                ),
                _MetricPill(
                  cs: cs,
                  label: "Risk $tier",
                  accent: tier == 'HIGH'
                      ? cs.error
                      : (tier == 'MEDIUM' ? Colors.orange : cs.primary),
                ),
                _MetricPill(
                  cs: cs,
                  label: "Unsynced $pendingSync",
                  accent: pendingSync == 0 ? cs.primary : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  String _levelLabel(AssessmentIntegrityLevel? level) {
    switch (level) {
      case AssessmentIntegrityLevel.objectiveQuiz:
        return "Quiz";
      case AssessmentIntegrityLevel.gradedAssessment:
        return "Assessment";
      case AssessmentIntegrityLevel.highStakesExam:
        return "Examination";
      case null:
        return "Not running";
    }
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.cs,
    required this.label,
    required this.accent,
  });

  final ColorScheme cs;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
