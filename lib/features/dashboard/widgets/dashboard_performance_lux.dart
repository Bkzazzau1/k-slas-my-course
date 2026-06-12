import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/dashboard_controller.dart';

class DashboardPerformanceLux extends GetView<DashboardController> {
  const DashboardPerformanceLux({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.68);

    return Obx(() {
      final p = controller.performance.value;
      final accuracy = p?.accuracyPct ?? 0;
      final studyTime = p?.studyTimeLabel ?? "0m";
      final consistency =
          p?.consistencyLabel ?? "${controller.streakDays.value}-day streak";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This week",
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final tileWidth = isWide
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatTile(
                    cs: cs,
                    icon: Icons.track_changes_outlined,
                    title: "Accuracy",
                    value: "$accuracy%",
                    subtitle: "Based on recent attempts",
                    tone: _Tone.primary,
                    width: tileWidth,
                  ),
                  _StatTile(
                    cs: cs,
                    icon: Icons.timer_outlined,
                    title: "Study time",
                    value: studyTime,
                    subtitle: "Recent practice time",
                    tone: _Tone.secondary,
                    width: tileWidth,
                  ),
                  _StatTile(
                    cs: cs,
                    icon: Icons.local_fire_department_outlined,
                    title: "Consistency",
                    value: consistency,
                    subtitle: "Keep momentum",
                    tone: _Tone.neutral,
                    width: tileWidth,
                  ),
                ],
              );
            },
          ),
        ],
      );
    });
  }
}

enum _Tone { primary, secondary, neutral }

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.cs,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tone,
    this.width,
  });

  final ColorScheme cs;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final _Tone tone;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.68);
    final accent = switch (tone) {
      _Tone.primary => cs.primary,
      _Tone.secondary => cs.secondary,
      _Tone.neutral => cs.onSurface.withValues(alpha: 0.80),
    };

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(accent: accent, icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.accent, required this.icon});
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: accent),
    );
  }
}
