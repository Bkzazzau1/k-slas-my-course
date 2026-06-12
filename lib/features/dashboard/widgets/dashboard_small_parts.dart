import 'package:flutter/material.dart';
import 'premium_glass.dart';

class DashboardProgressBar extends StatelessWidget {
  const DashboardProgressBar({
    super.key,
    required this.cs,
    required this.label,
    required this.value,
  });

  final ColorScheme cs;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.65);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 10,
            backgroundColor: cs.onSurface.withValues(alpha: 0.07),
          ),
        ),
      ],
    );
  }
}

class DashboardMiniHint extends StatelessWidget {
  const DashboardMiniHint({super.key, required this.cs, required this.icon, required this.text});

  final ColorScheme cs;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);
    return Row(
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: muted, fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class DashboardPill extends StatelessWidget {
  const DashboardPill({super.key, required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
    );
  }
}

class DashboardDot extends StatelessWidget {
  const DashboardDot({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

Widget premiumEmptyState(
  ColorScheme cs, {
  required String title,
  required String subtitle,
  required VoidCallback onAction,
  required String action,
}) {
  final muted = cs.onSurface.withValues(alpha: 0.70);
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: muted, height: 1.25)),
        const SizedBox(height: 12),
        PremiumFilledButton(label: action, icon: Icons.add_rounded, onPressed: onAction),
      ],
    ),
  );
}
