import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class DashboardGradesLux extends StatelessWidget {
  const DashboardGradesLux({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    // MVP demo (later from backend)
    final grades = const [
      _GradeItem(title: "Mid-term paper", term: "Summer term", score: 98),
      _GradeItem(title: "Algorithms", term: "Spring term", score: 82),
      _GradeItem(title: "Maths & Stats", term: "Spring term", score: 74),
    ];

    final muted = cs.onSurface.withValues(alpha: 0.68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...grades.map((g) => _GradeRow(cs: cs, g: g)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                "Preview only • full transcript has details.",
                style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            _TranscriptButton(cs: cs),
          ],
        ),
      ],
    );
  }
}

class _GradeItem {
  const _GradeItem({
    required this.title,
    required this.term,
    required this.score,
  });

  final String title;
  final String term;
  final int score;
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.cs, required this.g});
  final ColorScheme cs;
  final _GradeItem g;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.68);
    final letter = _letter(g.score);
    final badge = _badgeColor(cs, letter);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Letter badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: badge.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badge.withValues(alpha: 0.22)),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: badge,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  g.term,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Score pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.secondary.withValues(alpha: 0.18)),
            ),
            child: Text(
              "${g.score}",
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _letter(int score) {
    final s = score.clamp(0, 100);
    if (s >= 70) return "A";
    if (s >= 60) return "B";
    if (s >= 50) return "C";
    if (s >= 45) return "D";
    return "F";
  }

  static Color _badgeColor(ColorScheme cs, String letter) {
    switch (letter) {
      case "A":
        return cs.secondary; // green-ish
      case "B":
        return const Color(0xFFF59E0B); // amber
      case "C":
        return cs.primary; // blue
      case "D":
        return const Color(0xFFFB7185); // pink-ish
      default:
        return const Color(0xFFEF4444); // red
    }
  }
}

class _TranscriptButton extends StatelessWidget {
  const _TranscriptButton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(Routes.courses),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              "Transcript",
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
